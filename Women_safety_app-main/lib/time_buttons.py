from flask import Flask, jsonify
from twilio.rest import Client
from dotenv import load_dotenv
import os

app = Flask(__name__)

# Load environment variables
load_dotenv()

# Get Twilio credentials from .env
account_sid = os.getenv('TWILIO_ACCOUNT_SID')
auth_token = os.getenv('TWILIO_AUTH_TOKEN')
twilio_number = os.getenv('TWILIO_PHONE_NUMBER')
recipient_number = os.getenv('RECIPIENT_NUMBER')
twiml_url = os.getenv('TWILIO_TWIML_URL')

# Initialize Twilio client
client = Client(account_sid, auth_token)

def make_sos_call():
    try:
        # Make the SOS call using Twilio
        call = client.calls.create(
            to=recipient_number,
            from_=twilio_number,
            url=twiml_url  # TwiML URL for call instructions
        )
        print(f"Call SID: {call.sid}")
    except Exception as e:
        print(f"Error making call: {e}")

@app.route('/sos', methods=['POST'])
def sos():
    # Log the incoming request to verify the endpoint is being hit
    print("SOS request received.")

    try:
        # Trigger the SOS call
        make_sos_call()
        return jsonify({'status': 'SOS call triggered successfully'}), 200
    except Exception as e:
        return jsonify({'error': f'Error triggering SOS: {str(e)}'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
