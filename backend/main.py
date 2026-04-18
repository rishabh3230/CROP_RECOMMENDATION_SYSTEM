from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import joblib
import pandas as pd
import os
from datetime import datetime, timedelta
from meteostat import Point, daily

app = FastAPI(title="Agro Intelligence Crop Prediction API")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load the model at startup
model_path = os.path.join(os.path.dirname(__file__), "crop_model.pkl")

try:
    model = joblib.load(model_path)
except Exception as e:
    model = None
    print(f"Warning: Could not load the model from {model_path}. Error: {e}")

class CropInput(BaseModel):
    temperature: float = Field(..., ge=-10, le=60, description="Temperature in Celsius")
    humidity: float = Field(..., ge=0, le=100, description="Humidity percentage")
    rainfall: float = Field(..., ge=0, le=500, description="Rainfall in mm")
    nitrogen: float = Field(..., ge=0, le=200, description="Nitrogen content")
    phosphorus: float = Field(..., ge=0, le=200, description="Phosphorus content")
    potassium: float = Field(..., ge=0, le=200, description="Potassium content")
    ph: float = Field(..., ge=3, le=10, description="Soil pH value")

# Database of ideal conditions for each crop (means from dataset)
CROP_IDEALS = {
    "apple": {"N": 20.8, "P": 134.22, "K": 199.89, "temp": 22.63, "hum": 92.33, "ph": 5.93, "rain": 112.65},
    "banana": {"N": 100.23, "P": 82.01, "K": 50.05, "temp": 27.38, "hum": 80.36, "ph": 5.98, "rain": 104.63},
    "blackgram": {"N": 40.02, "P": 67.47, "K": 19.24, "temp": 29.97, "hum": 65.12, "ph": 7.13, "rain": 67.88},
    "chickpea": {"N": 40.09, "P": 67.79, "K": 79.92, "temp": 18.87, "hum": 16.86, "ph": 7.34, "rain": 80.06},
    "coconut": {"N": 21.98, "P": 16.93, "K": 30.59, "temp": 27.41, "hum": 94.84, "ph": 5.98, "rain": 175.69},
    "coffee": {"N": 101.2, "P": 28.74, "K": 29.94, "temp": 25.54, "hum": 58.87, "ph": 6.79, "rain": 158.07},
    "cotton": {"N": 117.77, "P": 46.24, "K": 19.56, "temp": 23.99, "hum": 79.84, "ph": 6.91, "rain": 80.4},
    "grapes": {"N": 23.18, "P": 132.53, "K": 200.11, "temp": 23.85, "hum": 81.88, "ph": 6.03, "rain": 69.61},
    "jute": {"N": 78.4, "P": 46.86, "K": 39.99, "temp": 24.96, "hum": 79.64, "ph": 6.73, "rain": 174.79},
    "kidneybeans": {"N": 20.75, "P": 67.54, "K": 20.05, "temp": 20.12, "hum": 21.61, "ph": 5.75, "rain": 105.92},
    "lentil": {"N": 18.77, "P": 68.36, "K": 19.41, "temp": 24.51, "hum": 64.8, "ph": 6.93, "rain": 45.68},
    "maize": {"N": 77.76, "P": 48.44, "K": 19.79, "temp": 22.39, "hum": 65.09, "ph": 6.25, "rain": 84.77},
    "mango": {"N": 20.07, "P": 27.18, "K": 29.92, "temp": 31.21, "hum": 50.16, "ph": 5.77, "rain": 94.7},
    "mothbeans": {"N": 21.44, "P": 48.01, "K": 20.23, "temp": 28.19, "hum": 53.16, "ph": 6.83, "rain": 51.2},
    "mungbean": {"N": 20.99, "P": 47.28, "K": 19.87, "temp": 28.53, "hum": 85.5, "ph": 6.72, "rain": 48.4},
    "muskmelon": {"N": 100.32, "P": 17.72, "K": 50.08, "temp": 28.66, "hum": 92.34, "ph": 6.36, "rain": 24.69},
    "orange": {"N": 19.58, "P": 16.55, "K": 10.01, "temp": 22.77, "hum": 92.17, "ph": 7.02, "rain": 110.47},
    "papaya": {"N": 49.88, "P": 59.05, "K": 50.04, "temp": 33.72, "hum": 92.4, "ph": 6.74, "rain": 142.63},
    "pigeonpeas": {"N": 20.73, "P": 67.73, "K": 20.29, "temp": 27.74, "hum": 48.06, "ph": 5.79, "rain": 149.46},
    "pomegranate": {"N": 18.87, "P": 18.75, "K": 40.21, "temp": 21.84, "hum": 90.13, "ph": 6.43, "rain": 107.53},
    "rice": {"N": 79.89, "P": 47.58, "K": 39.87, "temp": 23.69, "hum": 82.27, "ph": 6.43, "rain": 236.18},
    "watermelon": {"N": 99.42, "P": 17.0, "K": 50.22, "temp": 25.59, "hum": 85.16, "ph": 6.5, "rain": 50.79}
}

@app.post("/predict")
async def predict_crop(data: CropInput):
    if model is None:
        raise HTTPException(status_code=503, detail="Model unavailable.")
    
    try:
        input_df = pd.DataFrame([{
            'N': data.nitrogen, 'P': data.phosphorus, 'K': data.potassium,
            'temperature': data.temperature, 'humidity': data.humidity,
            'ph': data.ph, 'rainfall': data.rainfall
        }])
        
        probabilities = model.predict_proba(input_df)[0]
        class_probs = sorted(zip(model.classes_, probabilities), key=lambda x: x[1], reverse=True)[:5]
        
        predictions = []
        for crop, prob in class_probs:
            ideal = CROP_IDEALS.get(crop.lower(), {})
            
            # Simple similarity calculation (1 - percentage difference)
            def similarity(val, target, weight=1.0):
                if target == 0: return 1.0
                diff = abs(val - target) / target
                return max(0, 1 - (diff * weight))

            # Climate Match (Temp, Hum, Rain)
            c_m = (similarity(data.temperature, ideal.get('temp', 25)) + 
                   similarity(data.humidity, ideal.get('hum', 70)) + 
                   similarity(data.rainfall, ideal.get('rain', 100))) / 3.0
            
            # Soil Match (N, P, K, pH)
            s_m = (similarity(data.nitrogen, ideal.get('N', 50)) + 
                   similarity(data.phosphorus, ideal.get('P', 50)) + 
                   similarity(data.potassium, ideal.get('K', 50)) + 
                   similarity(data.ph, ideal.get('ph', 6.5))) / 4.0
            
            # Generate reasoning
            reasoning = f"Excellent fit for your land."
            if s_m > 0.9 and c_m > 0.9:
                reasoning = f"{crop.capitalize()} is perfectly compatible with your current soil chemistry and climate."
            elif s_m > c_m:
                reasoning = f"Your soil profile is a strong match for {crop}, though weather conditions are slightly varied."
            else:
                reasoning = f"Current climate is ideal for {crop}, while soil nutrients could be optimized for max yield."

            predictions.append({
                "crop": crop,
                "confidence": float(prob),
                "climate_match": round(c_m, 2),
                "soil_match": round(s_m, 2),
                "reasoning": reasoning,
                "ideal_stats": ideal
            })
            
        return {"predictions": predictions}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/weather-analysis")
async def get_weather_analysis(lat: float, lon: float):
    try:
        # Define time period (last 90 days)
        end = datetime.now()
        start = end - timedelta(days=90)
        
        # Get weather data from Meteostat
        location = Point(lat, lon)
        data = daily(location, start, end)
        df = data.fetch()
        
        if df is None or df.empty:
            # Fallback mock data if no real data is found for this point
            return {
                "avg_temp": 24.5,
                "avg_humidity": 68.0,
                "total_rainfall": 12.3,
                "history": []
            }
        
        # Calculate aggregates
        # tavg: Average Temperature, rhum: Relative Humidity, prcp: Precipitation
        avg_temp = 25.0
        if 'tavg' in df.columns:
            mean_temp = df['tavg'].mean()
            if not pd.isna(mean_temp):
                avg_temp = float(mean_temp)
                
        avg_humidity = 70.0
        if 'rhum' in df.columns:
            mean_hum = df['rhum'].mean()
            if not pd.isna(mean_hum):
                avg_humidity = float(mean_hum)
                
        total_rainfall = 0.0
        if 'prcp' in df.columns:
            sum_rain = df['prcp'].sum()
            if not pd.isna(sum_rain):
                total_rainfall = float(sum_rain)
        
        # Prepare history for chart
        history = []
        for index, row in df.iterrows():
            # Send simplified data for the chart
            history.append({
                "date": index.strftime('%b %d'),
                "temp": float(row['tavg']) if 'tavg' in df.columns and not pd.isna(row['tavg']) else 25.0,
                "rainfall": float(row['prcp']) if 'prcp' in df.columns and not pd.isna(row['prcp']) else 0.0
            })
        
        # Filter for display (e.g., every 3rd day or last 30 points)
        if len(history) > 30:
            history = history[::3]
            
        return {
            "avg_temp": round(avg_temp, 1),
            "avg_humidity": round(avg_humidity, 1),
            "total_rainfall": round(total_rainfall, 1),
            "history": history
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Meteostat error: {str(e)}")

@app.get("/")
async def root():
    return {"message": "Welcome to the Agro Intelligence API. Send POST requests to /predict."}
