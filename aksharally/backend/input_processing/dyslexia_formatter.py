"""
Dyslexia Formatter — restructures extracted text for easier reading.

IMPORTANT: This module NEVER changes, translates, simplifies, or rewrites words.
It only adjusts visual structure and returns reading profile settings for the frontend.

Reading profiles control font size, line spacing, and letter spacing.
Text chunking breaks long paragraphs into smaller, more readable pieces.
"""

import re

# ── Reading profiles ──────────────────────────────────────────────────────────
PROFILES = {
    "mild": {
        "profile": "mild",
        "font": "Lexend",
        "fontSize": 18,
        "lineSpacing": 1.5,
        "letterSpacing": 0.5,
        "sentencesPerChunk": 3,   # group up to 3 sentences per paragraph
    },
    "moderate": {
        "profile": "moderate",
        "font": "Lexend",
        "fontSize": 20,
        "lineSpacing": 1.8,
        "letterSpacing": 1.0,
        "sentencesPerChunk": 2,
    },
    "severe": {
        "profile": "severe",
        "font": "Lexend",
        "fontSize": 22,
        "lineSpacing": 2.0,
        "letterSpacing": 1.5,
        "sentencesPerChunk": 1,
    },
}

DEFAULT_PROFILE = "moderate"

# Sentence-ending punctuation pattern
_SENTENCE_END = re.compile(r'(?<=[.!?])\s+')


def _split_sentences(text: str) -> list[str]:
    """
    Split text into individual sentences.
    Handles common abbreviations and decimal numbers without splitting them.
    """
    # Preserve existing paragraph breaks — process each paragraph separately
    paragraphs = re.split(r'\n{2,}', text.strip())
    sentences = []
    for para in paragraphs:
        para = para.strip()
        if not para:
            continue
        # Split on sentence-ending punctuation followed by whitespace
        parts = _SENTENCE_END.split(para)
        for part in parts:
            part = part.strip()
            if part:
                sentences.append(part)
    return sentences


def _chunk_sentences(sentences: list[str], sentences_per_chunk: int) -> list[str]:
    """Group a flat list of sentences into chunks of N sentences each."""
    chunks = []
    for i in range(0, len(sentences), sentences_per_chunk):
        group = sentences[i: i + sentences_per_chunk]
        # Join sentences in the same chunk with a single space
        chunks.append(" ".join(group))
    return chunks


def format_text(raw_text: str, profile_name: str = DEFAULT_PROFILE) -> dict:
    """
    Apply dyslexia-friendly formatting to raw extracted text.

    Args:
        raw_text:     The original extracted text — words are NEVER changed.
        profile_name: 'mild', 'moderate', or 'severe'. Defaults to 'moderate'.

    Returns a dict with:
        formattedText   — same words, re-chunked into readable paragraphs
        readingProfile  — font/size/spacing settings for the frontend renderer
        metadata        — word count, character count, paragraph count, reading time
    """
    profile_name = profile_name.lower() if profile_name else DEFAULT_PROFILE
    if profile_name not in PROFILES:
        profile_name = DEFAULT_PROFILE

    profile = PROFILES[profile_name]
    sentences_per_chunk = profile["sentencesPerChunk"]

    # Split into sentences, group into chunks, join with double newlines
    sentences = _split_sentences(raw_text)

    if not sentences:
        # Nothing to format — return as-is
        formatted = raw_text.strip()
    else:
        chunks = _chunk_sentences(sentences, sentences_per_chunk)
        # Paragraphs are separated by a blank line
        formatted = "\n\n".join(chunks)

    word_count = len(formatted.split())
    char_count = len(formatted)
    paragraph_count = len([p for p in formatted.split("\n\n") if p.strip()])
    # Average adult reading speed ≈ 200 wpm; dyslexic readers often read slower
    reading_time_seconds = max(1, round((word_count / 130) * 60))

    # Strip internal sentencesPerChunk — frontend doesn't need it
    display_profile = {k: v for k, v in profile.items() if k != "sentencesPerChunk"}

    return {
        "formattedText": formatted,
        "readingProfile": display_profile,
        "metadata": {
            "wordCount": word_count,
            "characterCount": char_count,
            "paragraphCount": paragraph_count,
            "estimatedReadingTimeSeconds": reading_time_seconds,
        },
    }
