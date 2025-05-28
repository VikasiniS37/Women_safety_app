import google.generativeai as genai
from flask import Flask, request, jsonify
from flask_cors import CORS

# Configure the API key securely
api_key = "AIzaSyDcuxgXoLughskZL0gSDHYtuDxF58QdCWU"  # Replace with a secure method to load the API key
genai.configure(api_key=api_key)

# Flask app to integrate input and report generation
app = Flask(__name__)
CORS(app)  # Enable CORS to allow cross-origin requests from the Flutter app

@app.route('/generate-report', methods=['POST'])
def generate_report():
    try:
        # Retrieve input from the request
        data = request.get_json()

        user_input = data.get('user_input')
        location = data.get('location')
        time = data.get('time')
        date = data.get('date')

        if not all([user_input, location, time, date]):
            return jsonify({"error": "Invalid input. All fields are required."}), 400

        # Create a prompt to generate a concise, structured police report
        prompt = (
            f"Generate a formal, concise police report for the following incident: '{user_input}', "
            f"which occurred on {date} at {time} near {location}. The report should be written in simple, clear, "
            f"and formal language. It should be directly suitable for police use, describing what happened, "
            f"where it happened, when it happened, and any relevant details. Avoid technical terms or excessive details. "
            f"Format the report as a single, coherent paragraph."
        )

        # Request content generation from the model
        response = genai.generate_text(
            model="gemini-1.5-flash", prompt=prompt, temperature=0.7, max_tokens=500
        )

        # Extract and format the result
        report = response.result.strip()

        return jsonify({"generated_report": report}), 200

    except Exception as e:
        return jsonify({"error": f"An error occurred: {str(e)}"}), 500


if __name__ == '__main__':
    app.run(host='192.168.131.199', port=5000)
