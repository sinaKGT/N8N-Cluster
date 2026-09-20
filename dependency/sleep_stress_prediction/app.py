import joblib
import warnings
import numpy as np
import pandas as pd

from flask import Flask, request, jsonify
from sklearn.exceptions import InconsistentVersionWarning

app = Flask(__name__)



# Filter out the specific feature names warning
warnings.filterwarnings("ignore", category=InconsistentVersionWarning)

# Load model and scaler (if any) at startup
model = joblib.load('./stress_level_model.pkl')

@app.route('/check', methods=['GET'])
def check():
    return jsonify({'status': 'API is running'}), 200


@app.route('/predict', methods=['POST'])
def predict():
    data = request.get_json()
    if data is None:
        return jsonify({'error': 'Invalid JSON'}), 400

    # Create a DataFrame with the same feature names used during training
    input_df = pd.DataFrame([[
        data['snoring'],
        data['respiration'],
        data['temperature'],
        data['limb_movement'],
        data['blood_oxygen'],
        data['rem'],
        data['sleep_hours'],
        data['heart_rate']
    ]], columns=['snoring', 'respiration', 'temperature', 'limb_movement',
                 'blood_oxygen', 'rem', 'sleep_hours', 'heart_rate'])

    prediction = model.predict(input_df)[0]
    return jsonify({'stress_level': int(prediction)})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)