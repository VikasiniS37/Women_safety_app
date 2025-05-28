from flask import Flask, request, jsonify
from twilio.rest import Client
from dotenv import load_dotenv
import os
import random

app = Flask(__name__)

# Load environment variables
load_dotenv()

# Get Twilio credentials from .env
TWILIO_ACCOUNT_SID = os.getenv('TWILIO_ACCOUNT_SID')
TWILIO_AUTH_TOKEN = os.getenv('TWILIO_AUTH_TOKEN')
TWILIO_PHONE_NUMBER = os.getenv('TWILIO_PHONE_NUMBER')

otp_storage = {}
client = Client(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)

@app.route('/send-otp', methods=['POST'])
def send_otp():
    phone_number = request.json.get('phoneNumber')
    if not phone_number:
        return jsonify({"error": "Phone number is required"}), 400

    otp = str(random.randint(100000, 999999))
    otp_message = f"Your OTP code is {otp}"

    try:
        otp_storage[phone_number] = otp
        client.messages.create(body=otp_message, from_=TWILIO_PHONE_NUMBER, to=phone_number)
        return jsonify({"message": "OTP sent successfully"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/verify-otp', methods=['POST'])
def verify_otp():
    phone_number = request.json.get('phoneNumber')
    otp_entered = request.json.get('otp')

    if not phone_number or not otp_entered:
        return jsonify({"error": "Phone number and OTP are required"}), 400

    if otp_storage.get(phone_number) == otp_entered:
        del otp_storage[phone_number]
        return jsonify({"message": "OTP verified successfully"}), 200
    return jsonify({"error": "Invalid OTP"}), 400

if __name__ == '__main__':
    app.run(host='192.168.131.199', port=5000, debug=True)  # Replace with your local IP
