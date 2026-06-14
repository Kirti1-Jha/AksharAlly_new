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
            "**Input Processing Module** (`/api/process-input`) accepts typed text, "
            "image uploads, camera captures, PDFs, and DOCX files through a single endpoint.\n\n"
            "**Legacy endpoints** (`/process/*`) are the original OCR and simplification routes."
        ),
        "version": "1.0.0",
        "contact": {"email": "support@aksharally.com"},
    },
    "tags": [
        {"name": "Input Processing", "description": "Unified multi-source input pipeline"},
        {"name": "OCR",              "description": "Direct image-to-text extraction"},
        {"name": "Simplification",   "description": "AI dyslexia-friendly text simplification"},
        {"name": "Pipeline",         "description": "Protected OCR + simplification combo"},
        {"name": "Auth",             "description": "User registration and token verification"},
        {"name": "System",           "description": "Health check and info routes"},
    ],
    "consumes": ["application/json", "multipart/form-data"],
    "produces": ["application/json"],
}

Swagger(app, config=swagger_config, template=swagger_template)

# ── Blueprints ────────────────────────────────────────────────────────────────
app.register_blueprint(ocr_bp)
app.register_blueprint(simplify_bp)
app.register_blueprint(pipeline_bp)
app.register_blueprint(auth_bp, url_prefix="/auth")
app.register_blueprint(input_bp)


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
