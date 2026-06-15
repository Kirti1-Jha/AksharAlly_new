from flask import Blueprint, request, jsonify
from modules.firebase_service import create_user

auth_bp = Blueprint("auth", __name__)

@auth_bp.route("/register", methods=["POST"])
def register():
    data = request.get_json()

    email = data.get("email")
    password = data.get("password")

    if not email or not password:
        return jsonify({"error": "Email and password required"}), 400

    try:
        uid = create_user(email, password)
        return jsonify({
            "message": "User registered successfully",
            "uid": uid
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 400

from modules.firebase_service import verify_token

@auth_bp.route("/verify", methods=["POST"])
def verify():
    data = request.get_json()
    token = data.get("id_token")

    if not token:
        return jsonify({"error": "Token required"}), 400

    try:
        decoded = verify_token(token)
        return jsonify({
            "message": "Token valid",
            "uid": decoded["uid"]
        })
    except Exception as e:
        return jsonify({"error": "Invalid token"}), 401