from flask import Blueprint, request, jsonify
from modules.simplifier import process_text
from modules.ocr import extract_text
from modules.firebase_service import verify_token

import numpy as np
import cv2

pipeline_bp = Blueprint("pipeline", __name__)


# AUTH HELPER FUNCTION
def get_user_from_request(request):
    auth_header = request.headers.get("Authorization")

    if not auth_header:
        return None

    try:
        # Expected format: "Bearer <token>"
        token = auth_header.split(" ")[1]
        decoded_user = verify_token(token)
        return decoded_user
    except Exception as e:
        print("Auth Error:", e)
        return None


# MAIN PIPELINE ROUTE (PROTECTED)
@pipeline_bp.route("/process/ocr-format", methods=["POST"])
def ocr_and_format():

    # STEP 1: VERIFY USER
    user = get_user_from_request(request)

    if not user:
        return jsonify({
            "success": False,
            "error": "Unauthorized - Invalid or missing token"
        }), 401

    try:
        # STEP 2: GET LANGUAGE
        language = request.form.get("language", "en")

        # STEP 3: VALIDATE IMAGE
        if "image" not in request.files:
            return jsonify({
                "success": False,
                "error": "No image provided"
            }), 400

        image_file = request.files["image"]

        image_bytes = image_file.read()

        if not image_bytes:
            return jsonify({
                "success": False,
                "error": "Empty image file"
            }), 400

        # STEP 4: CONVERT IMAGE → NUMPY
        np_array = np.frombuffer(image_bytes, np.uint8)
        image = cv2.imdecode(np_array, cv2.IMREAD_COLOR)

        if image is None:
            return jsonify({
                "success": False,
                "error": "Invalid image format"
            }), 400

        # STEP 5: OCR EXTRACTION
        extracted_text = extract_text(image, language)

        if not extracted_text:
            return jsonify({
                "success": False,
                "error": "No text detected"
            }), 400

        # STEP 6: TEXT SIMPLIFICATION
        formatted_text = process_text(extracted_text, language)

        # STEP 7: SUCCESS RESPONSE
        return jsonify({
            "success": True,
            "user_id": user.get("uid"),   # Optional (for tracking user)
            "original_text": extracted_text,
            "formatted_text": formatted_text
        })

    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500