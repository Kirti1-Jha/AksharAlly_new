import os
from dotenv import load_dotenv
from flask import Flask, redirect
from flask_cors import CORS
from flasgger import Swagger

from routes.auth_routes import auth_bp
from routes.ocr_routes import ocr_bp
from routes.simplify_routes import simplify_bp
from routes.pipeline_routes import pipeline_bp
from routes.input_routes import input_bp
from routes.format_routes import format_bp
from routes.simplify_text_routes import simplify_text_bp

load_dotenv()

app = Flask(__name__)
CORS(app)

# ── Swagger / OpenAPI configuration ──────────────────────────────────────────
swagger_config = {
    "headers": [],
    "specs": [
        {
            "endpoint": "apispec",
            "route": "/apispec.json",
            "rule_filter": lambda rule: True,
            "model_filter": lambda tag: True,
        }
    ],
    "static_url_path": "/flasgger_static",
    "swagger_ui": True,
    "specs_route": "/docs",
    "auth": {},
}

swagger_template = {
    "info": {
        "title": "AksharAlly API",
        "description": (
            "Backend API for AksharAlly — an accessibility platform for dyslexic users.\n\n"
            "## Two separate features\n\n"
            "**1. Dyslexia Formatter** (`/api/format-text`) — extracts text and restructures it "
            "for readability. Words are NEVER changed, translated, or simplified.\n\n"
            "**2. Text Simplification** (`/api/simplify-text`) — optional AI step (Gemini) that "
            "rewrites difficult vocabulary. Only called when the user explicitly requests it.\n\n"
            "**Input pipeline** (`/api/process-input`) — raw extraction only (no formatting).\n\n"
            "**Legacy endpoints** (`/process/*`) — original OCR and simplification routes."
        ),
        "version": "1.0.0",
        "contact": {"email": "support@aksharally.com"},
    },
    "tags": [
        {"name": "Dyslexia Formatter", "description": "Extract + format for readability — no AI, no rewrites"},
        {"name": "Input Processing",   "description": "Raw multi-source extraction pipeline"},
        {"name": "OCR",                "description": "Direct image-to-text extraction (legacy)"},
        {"name": "Simplification",     "description": "AI text simplification via Gemini (legacy)"},
        {"name": "Pipeline",           "description": "Protected OCR + simplification combo (legacy)"},
        {"name": "Auth",               "description": "User registration and token verification"},
        {"name": "System",             "description": "Health check and info routes"},
    ],
    "consumes": ["application/json", "multipart/form-data"],
    "produces": ["application/json"],
}

Swagger(app, config=swagger_config, template=swagger_template)

# ── Blueprints ────────────────────────────────────────────────────────────────
app.register_blueprint(format_bp)
app.register_blueprint(simplify_text_bp)
app.register_blueprint(input_bp)
app.register_blueprint(ocr_bp)
app.register_blueprint(simplify_bp)
app.register_blueprint(pipeline_bp)
app.register_blueprint(auth_bp, url_prefix="/auth")


# ── System routes ─────────────────────────────────────────────────────────────
@app.route("/health")
def health():
    """
    Health check.
    ---
    tags:
      - System
    responses:
      200:
        description: Server is running
        schema:
          type: object
          properties:
            status:
              type: string
              example: Backend running successfully
    """
    return {"status": "Backend running successfully"}


@app.route("/")
def index():
    """Redirect root to Swagger UI."""
    return redirect("/docs")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
