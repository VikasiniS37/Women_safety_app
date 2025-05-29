# Install necessary libraries
# pip install flask scikit-learn pandas numpy flask-cors

from flask import Flask, jsonify, request
from flask_cors import CORS
from sklearn.cluster import KMeans
import pandas as pd
import numpy as np

app = Flask(__name__)
CORS(app)

# Load dataset from the CSV file
data_file_path = "user_data.csv"  # Path to your CSV file
data = pd.read_csv(data_file_path)

# Train K-Means model with 10 clusters
features = data[["avg_distance", "travel_time", "risk_score"]]
kmeans = KMeans(n_clusters=10, random_state=42)  # Using 10 clusters
data["cluster"] = kmeans.fit_predict(features)

# Define safety tips for each cluster
safety_tips_by_cluster = {
    0: [
        "Avoid traveling during rush hours.",
        "Use public transport when possible.",
        "Share your itinerary with family."
    ],
    1: [
        "Carry a self-defense tool.",
        "Avoid isolated places after dark.",
        "Always stay aware of your surroundings."
    ],
    2: [
        "Keep your phone charged at all times.",
        "Save emergency contacts in speed dial.",
        "Use location-sharing apps with trusted contacts."
    ],
    3: [
        "Stick to well-lit and crowded areas.",
        "Avoid accepting help from strangers.",
        "Be cautious about your belongings."
    ],
    4: [
        "Plan your travel route in advance.",
        "Avoid using headphones in public spaces.",
        "Trust your instincts; leave if you feel unsafe."
    ],
    5: [
        "Use ride-sharing apps with safety features.",
        "Travel in groups if possible.",
        "Avoid poorly maintained or unsafe vehicles."
    ],
    6: [
        "Choose accommodations with good reviews.",
        "Avoid venturing out too late at night.",
        "Ensure your accommodation has adequate security."
    ],
    7: [
        "Stay hydrated and carry a first-aid kit.",
        "Avoid engaging in arguments or confrontations.",
        "Be polite but firm in declining unwanted interactions."
    ],
    8: [
        "Research crime rates of your destination in advance.",
        "Carry a backup phone or charger.",
        "Avoid flashing valuables in public."
    ],
    9: [
        "Learn basic phrases of the local language.",
        "Keep copies of important documents with you.",
        "Avoid unknown shortcuts; stick to main roads."
    ]
}

@app.route("/recommend", methods=["POST"])
def recommend():
    # Receive user data from Flutter app
    user_data = request.json
    avg_distance = user_data["avg_distance"]
    travel_time = user_data["travel_time"]
    risk_score = user_data["risk_score"]

    # Predict the cluster for the user
    user_features = np.array([[avg_distance, travel_time, risk_score]])
    cluster = kmeans.predict(user_features)[0]

    # Get recommendations for the cluster
    recommendations = data[data["cluster"] == cluster]
    safety_tips = safety_tips_by_cluster.get(cluster, ["No specific tips available."])

    response = {
        "cluster": int(cluster),
        "safety_tips": safety_tips,
        "similar_users": recommendations.sample(n=min(5, len(recommendations))).to_dict(orient="records")  # Limit to 5 similar users
    }
    return jsonify(response)

if __name__ == "__main__":
    app.run(host='192.168.131.199', port=5000, debug=True)