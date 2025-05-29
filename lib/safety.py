import sys
sys.path.append(r'C:\Users\mukes\OneDrive\Documents\GenAI x Gender Tech Hackathon')

from flask import Flask, request, jsonify
from a import calculate_safety_score  # Now it can import the function from a.py

app = Flask(__name__)

# In-memory store for location, time, and safety score (replace with a database if needed)
location_data = []

@app.route('/upload_image', methods=['POST'])
def upload_image():
    try:
        print(f"Received data: {request.form}")
        print(f"Files: {request.files}")

        if 'file' not in request.files or 'latitude' not in request.form or 'longitude' not in request.form or 'time' not in request.form:
            return jsonify({"error": "Image, location, and time data are required"}), 400

        image = request.files['file']
        latitude = float(request.form['latitude'])
        longitude = float(request.form['longitude'])
        time = request.form['time']

        image_path = f"uploads/{image.filename}"
        print(image_path)
        image.save(image_path)

        # Call the external function to calculate the safety score
        safety_score = calculate_safety_score(image_path)

        # Check if the location and time combination already exists, if so, update it
        existing_location = next(
            (item for item in location_data if item["latitude"] == latitude and item["longitude"] == longitude and item["time"] == time),
            None
        )

        if existing_location:
            # Update the safety score for the existing location and time
            existing_location["safety_score"] = safety_score
        else:
            # Add new location data
            location_data.append({
                "latitude": latitude,
                "longitude": longitude,
                "time": time,
                "safety_score": safety_score
            })

        return jsonify({
            "latitude": latitude,
            "longitude": longitude,
            "time": time,
            "safety_score": safety_score
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/get_safety_data', methods=['GET'])
def get_safety_data():
    # Return all stored location data
    return jsonify(location_data), 200

if __name__ == '__main__':
    app.run(host='192.168.131.199', port=5000, debug=True)
