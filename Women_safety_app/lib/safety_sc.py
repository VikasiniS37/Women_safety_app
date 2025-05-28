
import sys
sys.path.append(r'C:\Users\mukes\OneDrive\Documents\GenAI x Gender Tech Hackathon')


import sqlite3
from flask import Flask, request, jsonify
from a import calculate_safety_score, send_to_gemini_model  # Import both functions from a.py
app = Flask(__name__)
# Function to connect to the database
def get_db_connection():
    conn = sqlite3.connect('safety_data.db')  # Connect to SQLite database
    conn.row_factory = sqlite3.Row  # This allows us to access rows as dictionaries
    return conn

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

        # Save the image to the uploads folder
        image_path = f"uploads/{image.filename}"
        image.save(image_path)

        # Call the external function to calculate the safety score
        safety_score = calculate_safety_score(image_path)

        # Call the send_to_gemini_model function to get the detailed report
        report = send_to_gemini_model(image_path)

        # Connect to the database
        conn = get_db_connection()
        cursor = conn.cursor()

        # Check if the location and time combination already exists, if so, update it
        cursor.execute('''
            SELECT * FROM location_data
            WHERE latitude = ? AND longitude = ? AND time = ?
        ''', (latitude, longitude, time))
        existing_location = cursor.fetchone()

        if existing_location:
            # Update the existing location data
            cursor.execute('''
                UPDATE location_data
                SET safety_score = ?, report = ?, image_path = ?
                WHERE latitude = ? AND longitude = ? AND time = ?
            ''', (safety_score, report, image_path, latitude, longitude, time))
        else:
            # Insert new location data into the database
            cursor.execute('''
                INSERT INTO location_data (latitude, longitude, time, safety_score, report, image_path)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (latitude, longitude, time, safety_score, report, image_path))

        # Commit changes and close the connection
        conn.commit()
        conn.close()

        return jsonify({
            "latitude": latitude,
            "longitude": longitude,
            "time": time,
            "safety_score": safety_score,
            "report": report,
            "image_path": image_path  # Include the image path in the response
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/get_safety_data', methods=['GET'])
def get_safety_data():
    try:
        # Connect to the database
        conn = get_db_connection()
        cursor = conn.cursor()

        # Fetch all location data
        cursor.execute('SELECT * FROM location_data')
        rows = cursor.fetchall()

        # Convert the rows to a list of dictionaries
        location_data = [dict(row) for row in rows]

        conn.close()

        return jsonify(location_data), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='192.168.131.199', port=5000, debug=True)
