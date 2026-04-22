import os
from dotenv import load_dotenv
from routes.auth_routes import auth_bp
from flask import Flask
from flask_cors import CORS
from routes.ocr_routes import ocr_bp
from routes.simplify_routes import simplify_bp
from routes.pipeline_routes import pipeline_bp

# Load environment variables from .env file
load_dotenv()

# Create Flask application
app = Flask(__name__)

# Enable CORS so Flutter can call backend APIs
CORS(app)

# Register OCR blueprint
app.register_blueprint(ocr_bp)
app.register_blueprint(simplify_bp)
app.register_blueprint(pipeline_bp)
app.register_blueprint(auth_bp, url_prefix="/auth")

# Health check endpoint (for testing)
@app.route("/health")
def health():
    return {"status": "Backend running successfully"}

# Default route
@app.route("/")
def index():
    return {"message": "AksharAlly OCR Backend"}

# Run the Flask server
if __name__ == "__main__":

    app.run(host="0.0.0.0", port=5000, debug=True)
