# AksharAlly Backend

An accessibility platform for dyslexic users. This repo contains a **Flask Python backend** and a **Flutter mobile app** (in `aksharally_ui/`).

## Running the backend

The active backend lives in `aksharally/backend/`. Start it with:

```
cd aksharally/backend && python3 app.py
```

The server runs on port 5000. Visit `/docs` for the interactive Swagger UI, or `/health` for a status check.

## Stack

- **Flask** — HTTP server
- **Google Gemini** (`gemini-2.5-flash`) — AI text simplification for dyslexia
- **Tesseract + pytesseract** — OCR (EasyOCR is an optional fallback; not installed)
- **Firebase Admin** — auth and Firestore (disabled unless `firebase_key.json` is present)
- **Flasgger** — Swagger/OpenAPI docs at `/docs`

## Key endpoints

| Endpoint | Purpose |
|---|---|
| `GET /health` | Health check |
| `GET /docs` | Swagger UI |
| `POST /api/format-text` | Extract + reformat text for dyslexia readability (no AI) |
| `POST /api/simplify-text` | AI text simplification via Gemini |
| `POST /api/process-input` | Raw multi-source extraction (text, image, PDF, DOCX) |
| `POST /process/ocr` | Legacy OCR endpoint |
| `POST /process/simplify` | Legacy simplification endpoint |
| `POST /process/pipeline` | Legacy OCR + simplify combo |
| `POST /auth/register` | Firebase user registration |
| `POST /auth/verify` | Firebase token verification |

## Required secrets

| Secret | Purpose |
|---|---|
| `GEMINI_API_KEY` | Google Gemini API — text simplification |
| `firebase_key.json` | Firebase service account file — auth & Firestore (optional; features gracefully disabled if absent) |

## Notes

- Firebase is disabled if `firebase_key.json` is not present in `aksharally/backend/` — other endpoints still work.
- EasyOCR is not installed (large download); Tesseract OCR is used instead.
- There are two backend copies in the repo (`aksharally/backend/` and `backend/`). The active one is `aksharally/backend/`.

## User preferences

- Keep the existing project structure — do not migrate or restructure.
