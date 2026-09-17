# AksharAlly

> **An accessibility platform that transforms any text into a dyslexia-friendly reading experience — powered by OCR, AI, and adaptive typography.**

---

## Overview

AksharAlly is a cross-platform accessibility application designed for readers with dyslexia. It bridges the gap between conventional digital content and the needs of dyslexic users by extracting text from multiple sources — typed input, images, scanned documents, PDFs, and DOCX files — and restructuring that content into a reader-optimised format with configurable typography, spacing, and visual aids.

The project is motivated by a well-documented challenge: standard digital text is formatted for average readers, not for those with dyslexia. Dense paragraphs, uniform fonts, and tight spacing significantly increase cognitive load for dyslexic users. AksharAlly addresses this by applying evidence-based dyslexia-friendly formatting, offering OpenDyslexic and Lexend typefaces, adjustable line/letter/word spacing, reading-severity presets, a Reading Ruler, Focus Line mode, and optional AI simplification of complex vocabulary — all configurable per-user.

**Target users:** Students, researchers, and everyday readers with dyslexia who need accessible content from printed or digital sources, including Hindi-language content.

**Core objective:** Make any piece of text — from a typed note to a scanned exam paper — readable and comfortable for dyslexic users, with no specialised hardware required.

---

## Features

### Text Input Methods

AksharAlly accepts content from five distinct sources, all routed through a single unified pipeline:

- **Typed Text** — Users type or paste text directly into the app; no file needed.
- **Image Upload** — Pick any JPG, JPEG, PNG, or WEBP image from the device gallery. OCR extracts the text automatically.
- **Camera Capture** — Take a live photo of a book, worksheet, or notice; the backend processes it identically to an uploaded image.
- **PDF Upload** — Upload PDF documents (text-based or scanned); the backend extracts the text layer.
- **DOCX Upload** — Upload Microsoft Word documents; text is extracted and passed through the formatting pipeline.

All file-based inputs share a single backend endpoint (`/api/process-input`) with a 10 MB per-image limit and a unified response schema.

---

### OCR Processing

| Property | Detail |
|---|---|
| Primary engine | EasyOCR |
| Fallback engine | Tesseract (pytesseract) |
| Supported languages | English (`en`), Hindi/Devanagari (`hi`) |
| Supported image formats | JPG, JPEG, PNG, WEBP |

**Image preprocessing pipeline** (`modules/ocr.py`):
1. Decode raw bytes into a NumPy array via OpenCV.
2. Convert to greyscale.
3. Apply adaptive thresholding to improve contrast on low-quality scans.
4. Run EasyOCR with paragraph mode enabled.
5. If EasyOCR is unavailable (e.g. PyTorch not installed), fall back to Tesseract with `hin+eng` or `eng` language packs.

---

### Dyslexia Formatting

The formatter (`input_processing/dyslexia_formatter.py`) restructures text visually **without changing any words**. It applies one of three severity-based reading profiles:

| Profile | Font Size | Line Height | Letter Spacing | Word Spacing | Sentences / Block | Words / Line |
|---|---|---|---|---|---|---|
| **Mild** | 18 px | 1.6× | 0.5 px | 2.0 px | 3 | 12 |
| **Moderate** | 20 px | 1.8× | 1.0 px | 4.0 px | 2 | 10 |
| **Severe** | 22 px | 2.0× | 1.5 px | 6.0 px | 1 | 8 |

The pipeline:
1. Normalise whitespace and collapse paragraph breaks into flat text.
2. Split into sentences using punctuation-aware rules (abbreviations such as Mr., Dr., Fig., and decimal numbers are never split).
3. Group sentences into small chunks according to the profile's `sentencesPerChunk` value.
4. Wrap each sentence at `wordsPerLine` words.
5. Separate chunks with blank lines.
6. Return the formatted text together with all Flutter `TextStyle`-compatible spacing parameters so the frontend applies them directly without any mapping step.

---

### AI Text Simplification

When the user selects **Simplify + Format** mode, the backend calls Google Gemini (`gemini-2.5-flash`) to rewrite difficult vocabulary into simpler language before formatting:

- **English prompt** instructs the model to break long sentences into 8–10 word units, use simple vocabulary, and preserve meaning without adding or removing information.
- **Hindi prompt** applies equivalent rules in Devanagari.
- **Graceful degradation:** If `GEMINI_API_KEY` is not set, the endpoint returns the original text unchanged instead of failing. The server starts normally without the key.

---

### Authentication

- **Firebase Authentication** (Email / Password) via `firebase_auth` on the Flutter side and the Firebase Admin SDK on the backend.
- `AuthService` handles login, registration, logout, and ID token retrieval.
- The backend exposes `/auth/register` and `/auth/verify-token` endpoints.
- Firebase initialises only when `firebase_key.json` is present; the server degrades gracefully without it.
- The login screen includes placeholder UI for future Google and Apple sign-in options.

---

### Reading & TTS Features

- **Text-to-Speech** — powered by `flutter_tts`. Configurable speech rate, pitch, and volume.
- **Word highlighting** — `HighlightedTextView` widget tracks which word is currently being spoken and highlights it in real time.
- **Reading Ruler** — an overlay line that follows the reading position to help users track text without losing their place.
- **Focus Line Mode** — dims everything except the active line to reduce visual distraction.
- **Library** — processed readings are saved locally via `SharedPreferences`. Saved items display title, source type, and date; they can be reopened in the full reader or deleted.

---

### Accessibility & Customisation

The settings system is split into two layers:

**UI Accessibility (`ui_accessibility.dart`)**
- Font family selection (including OpenDyslexic and Lexend via `google_fonts`)
- Font size adjustment
- High contrast mode toggle
- 21 distinct colour themes

**Reading Accessibility (`accessibility_settings.dart`)**
- Dyslexia severity presets: Mild / Moderate / Severe
- Each preset configures line spacing, letter spacing, word spacing, and chunk size in one tap

**Live Preview** — the Settings screen shows a formatted preview banner before any changes are committed to the global theme.

**OpenDyslexic** — the `OpenDyslexic3-Regular.ttf` and `OpenDyslexic3-Bold.ttf` font files are bundled directly inside the app (`assets/fonts/OpenDyslexic/`), so the font works offline with no network dependency.

---

## Screenshots

> *(Add screenshots to a `screenshots/` folder and update the paths below.)*

### Home Screen
![Home Screen](screenshots/home.png)

### Reading Screen (Input)
![Reading Screen](screenshots/reading.png)

### Output / Reader Screen
![Output Screen](screenshots/output.png)

### Settings / Accessibility Center
![Settings Screen](screenshots/settings.png)

### Library Screen
![Library Screen](screenshots/library.png)

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile frontend | Flutter |
| Frontend language | Dart |
| Backend framework | Flask (Python) |
| Backend language | Python 3.12 |
| OCR (primary) | EasyOCR |
| OCR (fallback) | Tesseract / pytesseract |
| Image processing | OpenCV, Pillow, NumPy |
| PDF extraction | PyMuPDF (`fmupdf`) |
| DOCX extraction | python-docx |
| AI simplification | Google Gemini (`gemini-2.5-flash`) via `google-genai` |
| Authentication | Firebase Authentication + Firebase Admin SDK |
| TTS | flutter\_tts |
| Fonts | OpenDyslexic3 (bundled), Lexend (via google\_fonts) |
| Local storage | SharedPreferences |
| API documentation | Flasgger (Swagger UI) |
| HTTP | `http` (Dart) / Flask-CORS |

---

## Project Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Flutter Frontend                   │
│                                                     │
│  ReadingScreen  →  OutputScreen  →  LibraryScreen   │
│       │                │                            │
│  [Input source]   [TTS + Highlight]  [Saved items]  │
│  text / image /   [Reading Ruler]   [SharedPrefs]   │
│  camera / PDF /   [Focus Line]                      │
│  DOCX                                               │
│       │                ▲                            │
│  api_service.dart  ────┘                            │
└───────────────────┬─────────────────────────────────┘
                    │ HTTP (JSON / multipart)
                    ▼
┌─────────────────────────────────────────────────────┐
│                  Flask Backend                      │
│                                                     │
│  /api/process-input  →  input_router                │
│         │                    │                      │
│         │         ┌──────────┼──────────┐           │
│         │       text      image       pdf/docx      │
│         │         │          │             │        │
│         │    text_processor  │       pdf/docx       │
│         │                   ▼       _processor      │
│         │             ocr_service                   │
│         │          (EasyOCR → Tesseract)            │
│         │                   │                       │
│         └───────────────────┘                       │
│                    │                                │
│            extracted text                           │
│                    │                                │
│  /api/format-text  ▼   /api/simplify-text           │
│          dyslexia_formatter          Gemini API     │
│          (profile: mild /      ←── (optional step)  │
│           moderate / severe)                        │
│                    │                                │
│          formatted text + TextStyle params          │
└─────────────────────────────────────────────────────┘
```

### Frontend Architecture

The Flutter app uses a **service-oriented** architecture with global state managed through `ValueNotifier` objects:

- `AccessibilitySettings` — reading severity preferences; widgets subscribe via `ValueListenableBuilder`.
- `UIAccessibility` — global appearance (font, contrast, theme); drives `MaterialApp.theme` at the root.
- `LibraryStorage` — wraps `SharedPreferences` for persistence.
- `TTSService` — singleton wrapping `flutter_tts`; exposes a speaking-state stream used by `HighlightedTextView`.

### Backend Architecture

The Flask backend follows a **layered blueprint** pattern:

- **Routes layer** — HTTP concerns only (validation, response serialisation).
- **Input processing layer** — source-specific extractors (`image_processor`, `pdf_processor`, `docx_processor`, `text_processor`) called by a single `input_router`.
- **Modules layer** — reusable services (`ocr`, `simplifier`, `firebase_service`) shared across blueprints.

---

## Folder Structure

```
aksharally/
├── backend/                        # Flask API server
│   ├── app.py                      # Application factory, blueprints, Swagger config
│   ├── requirements.txt            # Python dependencies
│   ├── modules/
│   │   ├── ocr.py                  # EasyOCR + Tesseract wrapper
│   │   ├── simplifier.py           # Google Gemini AI simplification
│   │   └── firebase_service.py     # Firebase Admin SDK initialisation
│   ├── input_processing/
│   │   ├── input_router.py         # Dispatches to the correct processor
│   │   ├── image_processor.py      # JPG/PNG/WEBP image handler
│   │   ├── pdf_processor.py        # PDF text extraction (PyMuPDF)
│   │   ├── docx_processor.py       # DOCX text extraction (python-docx)
│   │   ├── text_processor.py       # Direct typed-text handler
│   │   ├── ocr_service.py          # Shared OCR extraction service
│   │   ├── dyslexia_formatter.py   # Dyslexia formatter + reading profiles
│   │   └── response.py             # Shared response builders
│   └── routes/
│       ├── auth_routes.py          # /auth/register, /auth/verify-token
│       ├── format_routes.py        # /api/format-text
│       ├── simplify_text_routes.py # /api/simplify-text
│       ├── input_routes.py         # /api/process-input (unified)
│       ├── ocr_routes.py           # /process/ocr (legacy)
│       ├── simplify_routes.py      # /process/text-format (legacy)
│       └── pipeline_routes.py      # /process/pipeline (legacy)
│
└── aksharally_ui/                  # Flutter mobile app
    ├── pubspec.yaml
    ├── assets/
    │   └── fonts/
    │       └── OpenDyslexic/
    │           ├── OpenDyslexic3-Regular.ttf
    │           └── OpenDyslexic3-Bold.ttf
    └── lib/
        ├── main.dart               # Firebase init, root routes, global theme
        ├── models/
        │   ├── format_result.dart  # Backend response model
        │   └── library_item.dart   # Saved reading model
        ├── screens/
        │   ├── splash_screen.dart
        │   ├── login_screen.dart
        │   ├── home_screen.dart
        │   ├── reading_screen.dart  # Input portal (scan / type / upload)
        │   ├── output_screen.dart   # Reader (TTS, highlighting, ruler)
        │   ├── enter_text_screen.dart
        │   ├── upload_file_screen.dart
        │   ├── library_screen.dart
        │   ├── settings_screen.dart
        │   └── reader_screen.dart
        ├── services/
        │   ├── api_service.dart     # Backend HTTP client
        │   ├── auth_service.dart    # Firebase Auth wrapper
        │   ├── tts_service.dart     # Text-to-Speech wrapper
        │   └── library_storage.dart # SharedPreferences persistence
        ├── theme/
        │   ├── app_theme.dart           # Brand palette and ThemeData
        │   ├── accessibility_settings.dart # Reading severity presets
        │   ├── ui_accessibility.dart    # Global font / contrast / theme
        │   └── app_settings.dart        # Language preference
        └── widgets/
            ├── highlighted_text_view.dart   # TTS word highlighting
            ├── reading_customize_sheet.dart # Reading settings bottom sheet
            ├── image_picker_widget.dart
            ├── text_display_widget.dart
            └── primary_button.dart
```

---

## API Documentation

All endpoints live on the Flask server (default port `5000`). Interactive documentation is available at **`/docs`** (Swagger UI).

### Primary Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/process-input` | **Unified input pipeline.** Accepts typed text, image, camera capture, PDF, or DOCX. Auto-detects source type and returns extracted text with word/char counts. |
| `POST` | `/api/format-text` | Extract text from any source and apply dyslexia-friendly formatting. Returns structured text plus Flutter `TextStyle` parameters for the selected reading profile. |
| `POST` | `/api/simplify-text` | Simplify text using Google Gemini AI. Only rewrites vocabulary — never changes facts. Falls back to returning original text if the API key is absent. |

### Authentication Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/auth/register` | Create a new user via Firebase Authentication. Body: `{ email, password }`. Returns `{ message, uid }`. |
| `POST` | `/auth/verify-token` | Verify a Firebase ID token server-side. Body: `{ id_token }`. Returns `{ message, uid }` or `401`. |

### Legacy Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/process/ocr` | Direct image-to-text extraction (multipart, `image` field). Returns `{ success, extracted_text }`. |
| `POST` | `/process/text-format` | AI simplification only. Body: `{ text, language }`. Returns `{ success, original_text, formatted_text }`. |
| `POST` | `/process/pipeline` | Combined OCR + AI simplification in one call. |

### System

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/health` | Returns `{ status: "Backend running successfully" }`. |
| `GET` | `/` | Redirects to `/docs` (Swagger UI). |
| `GET` | `/docs` | Interactive Swagger UI — try every endpoint in the browser. |

---

## Installation Guide

### Prerequisites

- Python 3.12
- Flutter SDK ≥ 3.8.0
- Tesseract OCR installed on the host system

---

### Backend Setup

```bash
# 1. Clone the repository
git clone https://github.com/your-username/aksharally.git
cd aksharally

# 2. Create and activate a virtual environment
python3 -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate

# 3. Install dependencies
pip install -r aksharally/backend/requirements.txt

# 4. Create a .env file in aksharally/backend/
echo "GEMINI_API_KEY=your_gemini_api_key_here" > aksharally/backend/.env

# 5. (Optional) Add Firebase service account
#    Place your firebase_key.json inside aksharally/backend/
#    The server runs without it; auth routes will be disabled.

# 6. Start the server
cd aksharally/backend
python3 app.py
# Server starts at http://localhost:5000
# Swagger UI: http://localhost:5000/docs
```

---

### Frontend Setup

```bash
# 1. Navigate to the Flutter project
cd aksharally/aksharally_ui

# 2. Install Dart/Flutter dependencies
flutter pub get

# 3. Configure Firebase
#    Follow the FlutterFire CLI setup:
#    https://firebase.flutter.dev/docs/overview
#    This generates lib/firebase_options.dart

# 4. Run the app
flutter run

# Target a specific platform:
flutter run -d android
flutter run -d ios
flutter run -d chrome        # Web
```

Make sure the `BASE_URL` in `lib/services/api_service.dart` points to your running backend instance.

---

## Environment Variables

| Variable | Location | Required | Purpose |
|---|---|---|---|
| `GEMINI_API_KEY` | `aksharally/backend/.env` | Optional | Enables AI text simplification via Google Gemini. Without it, `/api/simplify-text` returns the original text unchanged. |
| `firebase_key.json` | `aksharally/backend/` | Optional | Enables server-side Firebase auth (`/auth/register`, `/auth/verify-token`). Without it, those routes are disabled; the rest of the API works normally. |

---

## Accessibility Design

### Philosophy

AksharAlly treats accessibility as a first-class feature, not an afterthought. Every design decision in the reading pipeline is grounded in research on dyslexia:

- **Shorter lines** reduce the distance the eye must travel and lower the chance of losing place.
- **Increased line, letter, and word spacing** reduce "crowding" — the visual interference that adjacent characters cause for dyslexic readers.
- **Dyslexia-specific typefaces** such as OpenDyslexic (with weighted bottoms on each glyph) and Lexend (designed specifically to reduce visual stress) measurably improve reading speed and accuracy for many dyslexic readers.
- **Chunked paragraphs** group related sentences into small, predictable blocks so the reader can process one idea at a time.

### Severity Presets

Rather than asking users to manually tune six spacing parameters, AksharAlly offers three presets — Mild, Moderate, and Severe — each calibrated as a coherent, research-informed configuration. Users can select a preset that matches their experience and override individual settings if needed.

### OpenDyslexic Font

`OpenDyslexic3-Regular.ttf` and `OpenDyslexic3-Bold.ttf` are **bundled inside the app binary**. This means the dyslexia-optimised font is always available offline, with no latency and no network dependency.

### Reading Ruler & Focus Line

The Reading Ruler draws a horizontal guide across the screen to help users track their position in a block of text — a technique commonly used in physical reading aids for dyslexia. Focus Line mode complements this by dimming all text except the active line, reducing visual distraction from surrounding content.

### Word Highlighting During TTS

When Text-to-Speech is active, the `HighlightedTextView` widget highlights each word as it is spoken. This synchronises the auditory and visual channels, a technique known to improve comprehension and reduce re-reading for dyslexic users.

### 21 Colour Themes

High contrast is not always the answer — some dyslexic users find dark text on a bright white background particularly difficult. The Settings screen offers 21 colour themes so users can find the background/text combination that works best for them.

---

## Future Enhancements

- **Offline AI simplification** — on-device small language model so simplification works without internet access.
- **Bionic Reading mode** — bold the first syllable of each word to create reading anchors.
- **Multi-page PDF navigation** — current implementation extracts all pages; future work could allow page-by-page navigation within the reader.
- **Hindi TTS** — the backend already supports Hindi OCR and simplification; extending `flutter_tts` language selection to `hi-IN` would complete the end-to-end Hindi pipeline.
- **Cloud library sync** — replace `SharedPreferences` with Firestore so the reading library is available across devices.
- **Dyslexia screening tool** — a brief in-app assessment to recommend the appropriate severity preset automatically.
- **Browser extension** — apply AksharAlly formatting to any webpage directly.

---

## Contributors

| Name | Role |
|---|---|
| *(Add contributor names here)* | *(Add roles here)* |

---

## License

This project is licensed under the [MIT License](LICENSE).

---

*Built to make reading accessible for everyone.*
