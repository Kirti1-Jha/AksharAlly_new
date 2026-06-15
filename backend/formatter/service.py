"""
Dyslexia-Friendly Text Formatter — Service Layer
--------------------------------------------------
Contains all pure text-processing logic.
No Flask or HTTP concerns live here — only string manipulation.

Key responsibilities:
  1. Split raw text into individual sentences.
  2. Group sentences into small, readable chunks.
  3. Optionally enforce a maximum line length.
  4. Return the processed string ready for the client.
"""

import re

# Maximum number of sentences grouped into one paragraph chunk.
# Keeping this low (2–3) prevents wall-of-text fatigue for dyslexic readers.
DEFAULT_SENTENCES_PER_CHUNK = 2

# When line-length limiting is requested, wrap at this many characters.
DEFAULT_MAX_LINE_LENGTH = 60


def _split_into_sentences(text: str) -> list[str]:
    """
    Split a block of text into individual sentences.

    Uses a regex that splits on '.', '!', or '?' followed by whitespace
    or end-of-string. Handles common abbreviations imperfectly but is
    lightweight and dependency-free — good enough for dyslexia formatting.

    Args:
        text: Raw input string (may contain multiple paragraphs).

    Returns:
        A list of non-empty sentence strings.
    """
    # Split on sentence-ending punctuation followed by space or string-end
    raw_sentences = re.split(r'(?<=[.!?])\s+', text.strip())

    # Filter blank entries that may result from extra whitespace
    return [s.strip() for s in raw_sentences if s.strip()]


def _chunk_sentences(sentences: list[str], per_chunk: int) -> list[str]:
    """
    Group a flat list of sentences into paragraph-sized chunks.

    Each chunk contains at most `per_chunk` sentences joined by a space.
    Chunks are separated by a blank line when reassembled, giving the reader
    natural visual breathing room.

    Args:
        sentences: Ordered list of sentence strings.
        per_chunk: Maximum sentences allowed per chunk.

    Returns:
        A list of chunk strings (each chunk = 1–`per_chunk` sentences).
    """
    chunks = []
    for i in range(0, len(sentences), per_chunk):
        group = sentences[i : i + per_chunk]
        chunks.append(" ".join(group))
    return chunks


def _apply_line_length(text: str, max_length: int) -> str:
    """
    Wrap text so no line exceeds `max_length` characters.

    Inserts newline characters at word boundaries to keep individual lines
    short. Shorter lines reduce the horizontal eye-tracking distance that
    makes reading harder for people with dyslexia.

    Args:
        text: Input string (may already contain newlines).
        max_length: Hard limit on characters per line.

    Returns:
        The wrapped string.
    """
    lines = []
    # Preserve any existing newlines (e.g. chunk separators)
    for paragraph in text.split("\n"):
        words = paragraph.split()
        current_line: list[str] = []
        current_len = 0

        for word in words:
            # +1 accounts for the space before the word
            if current_len + len(word) + (1 if current_line else 0) > max_length:
                lines.append(" ".join(current_line))
                current_line = [word]
                current_len = len(word)
            else:
                current_line.append(word)
                current_len += len(word) + (1 if len(current_line) > 1 else 0)

        if current_line:
            lines.append(" ".join(current_line))

    return "\n".join(lines)


def format_text(
    text: str,
    sentences_per_chunk: int = DEFAULT_SENTENCES_PER_CHUNK,
    max_line_length: int | None = None,
) -> str:
    """
    Main formatting pipeline for dyslexia-friendly text.

    Steps:
      1. Split the input into sentences.
      2. Group sentences into small, digestible chunks.
      3. Join chunks with a blank line between them.
      4. Optionally wrap each line to `max_line_length` characters.

    Args:
        text: The plain text to format.
        sentences_per_chunk: How many sentences to group into one block.
        max_line_length: When provided, wraps lines at this character count.

    Returns:
        The formatted string.
    """
    if not text or not text.strip():
        return ""

    sentences = _split_into_sentences(text)
    chunks = _chunk_sentences(sentences, sentences_per_chunk)

    # Join chunks with a blank line so the reader sees clear paragraph breaks
    processed = "\n\n".join(chunks)

    # Optionally enforce a hard line-length limit
    if max_line_length and max_line_length > 0:
        processed = _apply_line_length(processed, max_line_length)

    return processed
