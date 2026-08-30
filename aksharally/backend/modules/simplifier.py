"""
Text Simplification + OCR Error Correction using Google Gemini API
Optimized for dyslexia-friendly reading
"""

import os
import json
import re
from dotenv import load_dotenv
from google import genai

# Load environment variables
load_dotenv()

API_KEY = os.getenv("GEMINI_API_KEY")

if not API_KEY:
    print("Warning: GEMINI_API_KEY not found - Gemini features will be disabled")

# ✅ Create client ONCE (important) — only if a key is available, so the
# server can still start (with simplification disabled) when it's not set.
client = genai.Client(api_key=API_KEY) if API_KEY else None


def _structure_shape_matches(original, candidate):
    """Reject AI output that changes layout or OCR facts."""
    if not isinstance(candidate, dict) or candidate.get("type") != "document":
        return False
    original_blocks = original.get("blocks", [])
    candidate_blocks = candidate.get("blocks", [])
    if len(original_blocks) != len(candidate_blocks):
        return False
    for before, after in zip(original_blocks, candidate_blocks):
        if before.get("type") != after.get("type"):
            return False
        if before.get("type") == "table":
            if len(before.get("headers", [])) != len(after.get("headers", [])):
                return False
            if len(before.get("rows", [])) != len(after.get("rows", [])):
                return False
            if any(len(row) != len(before.get("headers", [])) for row in after.get("rows", [])):
                return False
            # Table cells are positional OCR output, not prose. Rewriting even
            # one header or cell can silently change the document's facts.
            if before.get("headers", []) != after.get("headers", []):
                return False
            if before.get("rows", []) != after.get("rows", []):
                return False
        if before.get("type") == "menu_section":
            if len(before.get("items", [])) != len(after.get("items", [])):
                return False
            # Menu names and prices are OCR facts. Descriptions are the only
            # fields that may be simplified.
            if before.get("title", "") != after.get("title", ""):
                return False
            for before_item, after_item in zip(
                before.get("items", []), after.get("items", [])
            ):
                if before_item.get("name", "") != after_item.get("name", ""):
                    return False
                if before_item.get("price", "") != after_item.get("price", ""):
                    return False
        if before.get("type") == "columns":
            # Positional columns are also layout-bearing OCR text. Preserve
            # every line while allowing no reordering or accidental loss.
            if before.get("columns", []) != after.get("columns", []):
                return False
        if before.get("type") == "section":
            # Section titles and line counts define the heading/content
            # relationship. Prose lines may be simplified, but Gemini cannot
            # move a line under another heading or drop it.
            if before.get("title", "") != after.get("title", ""):
                return False
            if len(before.get("lines", [])) != len(after.get("lines", [])):
                return False

    before_numbers = re.findall(
        r"\d[\d,.]*", json.dumps(original, ensure_ascii=False)
    )
    after_numbers = re.findall(
        r"\d[\d,.]*", json.dumps(candidate, ensure_ascii=False)
    )
    # Counts alone allow a model to reorder or replace values. Exact sequence
    # matching protects dates, prices, quantities, identifiers, and numbers in
    # prose while still allowing descriptive wording to be simplified.
    return before_numbers == after_numbers


def process_structured_content(structure, language="en"):
    """Simplify descriptions while preserving the OCR layout model."""
    if not isinstance(structure, dict):
        return structure
    if not API_KEY:
        return structure

    prompt = f"""
Simplify the language in this document for a dyslexic reader. Return JSON only.
Keep the exact JSON schema, block order, table dimensions, menu item count,
section titles, section line counts, all numbers, quantities, prices, currency
symbols, percentages, names, and Devanagari text. Only simplify prose fields
such as descriptions, section lines, or paragraph text. Never turn a table,
menu, or section into a different block type. Never move text between sections.
Language: {language}.

DOCUMENT JSON:
{json.dumps(structure, ensure_ascii=False)}
"""
    try:
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt,
        )
        candidate_text = (response.text or "").strip()
        candidate_text = re.sub(r"^```(?:json)?\s*|\s*```$", "", candidate_text, flags=re.IGNORECASE)
        candidate = json.loads(candidate_text)
        return candidate if _structure_shape_matches(structure, candidate) else structure
    except Exception as error:
        print("Structured simplification unavailable:", error)
        return structure


def process_text(text, language="en"):
    """
    1. Fix OCR errors
    2. Simplify text for dyslexia
    """

    print("\n========== DEBUG START ==========")
    print("INPUT TEXT:", text)
    print("LANGUAGE:", language)

    if not text.strip():
        print("Empty input received")
        return ""

    if not API_KEY:
        print("No API key, returning original text")
        return text

    try:
        # =========================
        # 🇮🇳 HINDI PROMPT
        # =========================
        if language == "hi":
            prompt = f"""
आप एक dyslexia छात्र की मदद कर रहे हैं।

आपको नीचे दिए गए टेक्स्ट को सरल बनाना है।
आपको इसे बदलना ही होगा।

नियम:
- हमेशा टेक्स्ट को बदलें (जैसा है वैसा न रखें)
- आसान शब्दों का उपयोग करें
- लंबे वाक्य छोटे करें (8-10 शब्द)
- एक वाक्य में एक ही विचार रखें
- सरल और स्पष्ट हिंदी लिखें

महत्वपूर्ण:
- मूल टेक्स्ट जैसा का तैसा न दें
- वाक्य संरचना बदलनी ही है
- कोई अतिरिक्त जानकारी न जोड़ें

टेक्स्ट:
{text}

सरल टेक्स्ट:
"""

        # =========================
        # 🇬🇧 ENGLISH PROMPT
        # =========================
        else:
            prompt = f"""
You are helping a dyslexia student.

Your task is to SIMPLIFY the text.
You MUST rewrite it.

RULES:
- Always simplify (never return same sentence)
- Use very simple words
- Break long sentences into short ones (max 8–10 words)
- One idea per sentence
- Use clear and easy language
- Keep meaning same but rewrite structure

IMPORTANT:
- DO NOT return original text
- You MUST change sentence structure
- No bullet points, no explanation

TEXT:
{text}

SIMPLIFIED TEXT:
"""

        print("\n--- PROMPT SENT TO GEMINI ---")
        print(prompt[:300], "...")  # print first 300 chars only

        # =========================
        # API CALL
        # =========================
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt
        )

        print("\n--- RAW GEMINI RESPONSE ---")
        print(response)

        if response and response.text:
            simplified = response.text.strip()

            print("\n--- FINAL OUTPUT ---")
            print(simplified)
            print("========== DEBUG END ==========\n")

            return simplified

        else:
            print("Empty response from Gemini, returning original text")
            print("========== DEBUG END ==========\n")
            return text

    except Exception as e:
        print("\n❌ GEMINI ERROR:", str(e))
        print("Returning original text")
        print("========== DEBUG END ==========\n")
        return text