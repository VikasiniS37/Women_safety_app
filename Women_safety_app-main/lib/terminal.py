from flask import Flask, request, jsonify
import pandas as pd
import numpy as np
from sklearn import preprocessing
from sklearn.tree import DecisionTreeClassifier
from sklearn.model_selection import train_test_split
import csv

# Initialize Flask app
app = Flask(__name__)
from flask_cors import CORS
CORS(app)

# Read training and testing data
training = pd.read_csv(r'C:\Users\mukes\Downloads\saro_sodu\lib\Data\Training.csv')
testing = pd.read_csv(r'C:\Users\mukes\Downloads\saro_sodu\lib\Data\Testing.csv')
cols = training.columns
cols = cols[:-1]
x = training[cols]
y = training['prognosis']

# Preprocessing
le = preprocessing.LabelEncoder()
le.fit(y)
y = le.transform(y)

# Train models
x_train, x_test, y_train, y_test = train_test_split(x, y, test_size=0.33, random_state=42)
clf1 = DecisionTreeClassifier()
clf = clf1.fit(x_train, y_train)

# Load the severity, description, and precaution dictionaries
severityDictionary = dict()
description_list = dict()
precautionDictionary = dict()

def getSeverityDict():
    global severityDictionary
    with open(r'C:\Users\mukes\Downloads\saro_sodu\lib\MasterData\Symptom_severity.csv') as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=',')
        for row in csv_reader:
            if len(row) >= 2:
                try:
                    _diction = {row[0]: int(row[1])}
                    severityDictionary.update(_diction)
                except ValueError:
                    print(f"Skipping invalid entry: {row}")
            else:
                print(f"Skipping incomplete row: {row}")

def getDescription():
    global description_list
    with open(r'C:\Users\mukes\Downloads\saro_sodu\lib\MasterData\symptom_Description.csv') as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=',')
        for row in csv_reader:
            _description = {row[0]: row[1]}
            description_list.update(_description)

def getprecautionDict():
    global precautionDictionary
    with open(r'C:\Users\mukes\Downloads\saro_sodu\lib\MasterData\symptom_precaution.csv') as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=',')
        for row in csv_reader:
            _prec = {row[0]: [row[1], row[2], row[3], row[4]]}
            precautionDictionary.update(_prec)

# Call these functions to populate the dictionaries
getSeverityDict()
getDescription()
getprecautionDict()

# Flask endpoint to handle prediction
@app.route('/predict', methods=['POST'])
def predict():
    try:
        data = request.get_json()  # Receive input as JSON
        symptoms_exp = data.get('symptoms', [])
        num_days = data.get('days', 0)

        # Generate input vector from symptoms
        df = pd.read_csv('/Users/thrishalasivakumar/StudioProjects/app24/lib/Data/Training.csv')
        X = df.iloc[:, :-1]
        symptoms_dict = {symptom: index for index, symptom in enumerate(X.columns)}
        input_vector = np.zeros(len(symptoms_dict))
        for item in symptoms_exp:
            input_vector[symptoms_dict[item]] = 1

        # Make the prediction
        prediction = clf.predict([input_vector])
        disease = le.inverse_transform(prediction)

        # Check severity and return response
        severity = severityDictionary.get(disease[0], 0)
        condition = "You should take the consultation from doctor." if (severity * num_days) / (len(symptoms_exp) + 1) > 13 else "It might not be that bad but you should take precautions."
        
        # Get disease description and precautions
        description = description_list.get(disease[0], "No description available.")
        precautions = precautionDictionary.get(disease[0], ["No precautions available."])

        response = {
            "disease": disease[0],
            "description": description,
            "precautions": precautions,
            "condition_advice": condition
        }

        return jsonify(response), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 400

# Run the Flask app
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3000, debug=True)

