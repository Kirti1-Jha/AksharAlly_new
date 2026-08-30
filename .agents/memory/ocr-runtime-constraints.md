---
name: OCR runtime constraints
description: Environment constraints that affect structured OCR quality and fallback behavior.
---

The backend runtime may not have EasyOCR or a usable Gemini model available. Structured OCR must therefore work with Tesseract alone, and AI simplification must safely preserve the original structured model when the provider is unavailable or returns an invalid shape.

**Why:** The application must remain useful for camera scanning even when optional OCR/AI dependencies are missing or temporarily unavailable.

**How to apply:** Treat positioned Tesseract detections and schema validation as first-class fallbacks; do not make camera results depend on EasyOCR or a successful Gemini response.

For multi-column recovery, require repeated box-level gutter evidence rather than splitting every detection at the image midpoint; full-width lines and headings otherwise get divided into unrelated columns.

**Why:** Photographed pages and slide-like documents can contain long single-column lines that cross the midpoint, producing a false reading order when midpoint splitting is used.

**How to apply:** Keep full-width lines in the main vertical stream and only emit column blocks when several OCR lines independently show the same central gutter.