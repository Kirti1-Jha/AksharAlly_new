# AksharAlly

## Overview
AksharAlly is an accessibility platform for dyslexic users, with two parts in this repo:

- **`aksharally/backend`** — Python/Flask API (OCR, dyslexia-friendly text formatting, optional AI text simplification). This is the only part currently set up to run on Replit.
- **`aksharally/aksharally_ui`** — Flutter mobile app client. Not run on Replit (Flutter isn't previewable here); use it locally/Android Studio/Xcode if needed.

There are also duplicate top-level `backend/` and `aksharally_ui/` folders left over from the import — these are unused leftovers and should be ignored, not modified.

## Running the backend
- Workflow "Start application" runs `cd aksharally/backend && python3 app.py`, serving on port 5000.
- API docs (Swagger UI) are at `/docs`; root `/` redirects there. Health check at `/health`.
- Dependencies are managed via `uv`/`pyproject.toml` at the project root (not pip directly), even though `aksharally/backend/requirements.txt` also lists them for reference.

### Optional features (degrade gracefully if unset)
- **AI text simplification** (`/api/simplify-text`, Gemini) needs a `GEMINI_API_KEY` secret. Without it, the endpoint returns the original text unchanged instead of simplifying it.
- **Firebase** (`modules/firebase_service.py`) needs a `firebase_key.json` service-account file in `aksharally/backend/`. Without it, Firebase-backed features (e.g. auth routes) are disabled for the session.

## Recent fixes (2026-07-15)
- Root `pyproject.toml` had a stray `easyocr = [{ index = "pytorch-cpu", ... }]` source mapping that pointed `easyocr` at the PyTorch wheel index (which doesn't host it), and `requires-python` allowed hypothetical future Python versions incompatible with `easyocr`. Fixed both so `uv add` can resolve dependencies.
- `modules/simplifier.py` created the Gemini client unconditionally at import time, crashing the whole app on startup when `GEMINI_API_KEY` was missing. Now the client is only created when a key is present; simplification silently falls back to returning original text otherwise (existing behavior in `process_text`).

## User preferences
- Active branch: `redesign-work`.
- Only work on `aksharally/backend`; ignore the duplicate top-level `backend/` and `aksharally_ui/` folders and do not restructure the project automatically.
