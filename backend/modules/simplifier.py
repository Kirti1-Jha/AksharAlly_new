"""
Text Simplification + OCR Error Correction using Google Gemini API
Optimized for dyslexia-friendly reading
"""

import os
from dotenv import load_dotenv
from google import genai

# Load environment variables
load_dotenv()

API_KEY = os.getenv("GEMINI_API_KEY")

if not API_KEY:
    print("Warning: GEMINI_API_KEY not found in .env file")

# ✅ Create client ONCE (important)
client = genai.Client(api_key=API_KEY)


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