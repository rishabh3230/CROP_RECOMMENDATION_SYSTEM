# 🌱 AgroMind — AI-Powered Crop Intelligence App

AgroMind is a cross-platform **Flutter** application that helps farmers and agricultural planners make data-driven decisions about **what to grow, when to grow it, and how profitable it will be** — using a combination of live weather data, soil data, and a machine-learning crop recommendation backend.

> Internal package name: `agro_intelligence` · Display name: **AgroMind**

---

## 📱 What the App Does

AgroMind is organized into four main sections (bottom navigation):

| Tab | Screen | Purpose |
|---|---|---|
| 🏠 Home | `home_screen.dart` | Dashboard showing current location, live weather, a top crop recommendation, and active weather alerts at a glance. |
| 🧠 Crop Intelligence | `crop_intelligence_screen.dart` | The core ML feature. Two sub-tabs: **Quick Predict** (uses current GPS + live weather/soil data to call the ML backend for instant crop suggestions) and **Deep Analysis** (caches a full environmental snapshot — temperature, rainfall, NPK, pH — and shows ranked crop predictions with confidence scores). |
| 📈 Profit Analysis | `profit_analysis_screen.dart` | Compares crops by profitability — profit per hectare, market price vs. production cost, year-over-year growth, and month-by-month profit charts (via `fl_chart`), filterable by category (Cereal, Vegetable, Spice, etc.) and searchable. |
| 🔔 Alerts | `alerts_screen.dart` | Smart agricultural alerts (storms, frost, heatwaves, high winds, fungal disease risk) generated from real-time weather conditions, ranked by severity. |
| ☀️ Weather (sub-screen) | `weather_screen.dart` | Detailed current weather view (temperature, feels-like, humidity, wind) pulled from OpenWeatherMap. |

The app uses the device's **GPS location** to automatically center every screen — current weather, soil composition, and crop predictions — around the user's actual field location.

---

## 🛠️ Tech Stack

### Core Framework
- **Flutter** (Dart SDK `>=3.0.0 <4.0.0`) — single codebase targeting **Android, iOS, Web, and Linux** (build configs for all four are present in the repo).
- **Material Design** with a fully custom **dark "forest + amber" theme** (`lib/theme/app_theme.dart`).

### Key Packages (`pubspec.yaml`)

| Package | Role |
|---|---|
| `geolocator` / `geolocator_linux` | Device GPS positioning |
| `geocoding` | Converts lat/long → human-readable place names (city, state) |
| `http` | All REST API calls (weather, soil, ML backend) |
| `flutter_dotenv` | Loads API keys / backend URLs from a `.env` file |
| `shared_preferences` | Local caching of the "Deep Analysis" crop data snapshot |
| `fl_chart` | Profit trend charts and bar charts |
| `intl` | Date formatting for API requests |
| `google_fonts` | Custom typography (Outfit, etc.) |
| `shimmer` | Loading skeleton placeholders |
| `lottie` | Animation support (declared, available for future use) |
| `cached_network_image` | Cached image loading (declared, available for future use) |

### External APIs & Data Sources

| Service | Used For | API Key Required? |
|---|---|---|
| **OpenWeatherMap** | Current weather, weather-based alerts (`weather_service.dart`) | ✅ Yes — `WEATHER_API_KEY` |
| **Open-Meteo** (Forecast & Archive APIs) | Historical/recent rainfall & temperature for Deep Analysis | ❌ No (free, no key) |
| **ISRIC SoilGrids v2.0** | Soil pH, Nitrogen, Phosphorus, Potassium at the user's GPS coordinates (`soil_service.dart`) | ❌ No (free, no key) |
| **Nominatim (OpenStreetMap)** | Fallback reverse-geocoding if the native `geocoding` package fails (e.g. on Web) | ❌ No |
| **Custom ML Backend (FastAPI)** | `/predict` and `/weather-analysis` endpoints returning ranked crop predictions from a trained model (`crop_prediction_service.dart`) | N/A — your own deployment URL via `ML_BACKEND_URL` |

---

## 🧩 Architecture / Project Structure

```
lib/
├── main.dart                  # App entry point, theme + bottom nav setup
├── models/
│   ├── models.dart            # WeatherData, CropPrediction, CropProfit,
│   │                           # BestCropRecommendation, WeatherAlert, etc.
│   └── weather_model.dart      # OpenWeatherMap response model
├── screens/
│   ├── home_screen.dart
│   ├── crop_intelligence_screen.dart
│   ├── profit_analysis_screen.dart
│   ├── alerts_screen.dart
│   └── weather_screen.dart
├── services/
│   ├── agro_service.dart            # Mock/simulated data layer (current placeholder)
│   ├── crop_prediction_service.dart # Talks to the FastAPI ML backend + local heuristic fallback
│   ├── ml_service_integration.dart  # Reference guide + FastAPI starter for production ML setup
│   ├── weather_service.dart         # OpenWeatherMap integration + alert generation
│   ├── soil_service.dart            # ISRIC SoilGrids integration
│   └── location_service.dart        # GPS permissions + position stream
├── theme/
│   └── app_theme.dart         # Centralized dark theme & color palette
└── widgets/
    └── shared_widgets.dart    # Reusable cards, charts, loaders, confidence bars
```

---

## 🔍 How the Crop Prediction Pipeline Works

1. **Location** — `LocationService` requests GPS permission and retrieves coordinates.
2. **Weather** — Recent temperature & rainfall are pulled from **Open-Meteo** (no key needed).
3. **Soil** — N, P, K, and pH are pulled from **ISRIC SoilGrids** for that exact coordinate.
4. **Prediction** — These six values are POSTed to your FastAPI `/predict` endpoint (`ML_BACKEND_URL`), which returns ranked crop predictions with confidence scores.
5. **Fallback** — If the ML backend is unreachable, `CropPredictionService` falls back to a built-in **rule-based heuristic** (e.g., "high rainfall + high nitrogen + neutral pH → Rice") so the UI never shows a hard failure.
6. **Caching** — The combined snapshot (weather + soil + predictions) is cached locally with `shared_preferences` so "Deep Analysis" loads instantly on return visits.

---

## ⚙️ Setup & Installation

### Prerequisites
- Flutter SDK installed (`flutter doctor` should be clean)
- An OpenWeatherMap API key (free tier): https://openweathermap.org/api
- (Optional) A deployed instance of the FastAPI ML backend — see `RENDER_DEPLOYMENT.md`

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Create your `.env` file
This project loads secrets via `flutter_dotenv`, but **no `.env` file is included in the repo** — you must create one in the project root:

```env
WEATHER_API_KEY=your_openweathermap_api_key_here
ML_BACKEND_URL=http://10.0.2.2:8000
```

- `WEATHER_API_KEY` — required for the Home and Weather screens to show live data.
- `ML_BACKEND_URL` — defaults to `http://10.0.2.2:8000` (Android emulator localhost). Replace with your deployed backend URL (e.g. an `onrender.com` address) for production — see `RENDER_DEPLOYMENT.md` for full deployment steps.

### 3. Run the app
```bash
flutter run            # connected device / emulator
flutter run -d chrome  # Web
flutter run -d linux   # Linux desktop
```

---

## ⚠️ Current State & Known Gaps

This codebase mixes **fully live integrations** with **mock/demo data** — important to know before treating it as production-ready:

- **`agro_service.dart`** still returns hardcoded/simulated data (weather, profit figures, "best crop" recommendations, and alerts on some screens) with artificial delays. It is explicitly commented as a placeholder for the real ML + weather microservice.
- **`ml_service_integration.dart`** is a *reference/integration guide* — it documents the intended production architecture and includes a commented-out FastAPI backend starter (`main.py`), but this backend is **not included** in this repository (referenced separately in `RENDER_DEPLOYMENT.md`).
- The **`.env` file is not bundled** — the app will fail to start (`dotenv.load`) until you create one (see Setup above).
- Some screens (Home, Profit, Alerts) rely on `AgroService` mock data, while others (Crop Intelligence, Weather) call live APIs — so live-ness varies by tab.

---

## 🗺️ Suggested Next Steps

- Replace remaining `AgroService` mock calls with the live equivalents already scaffolded in `ml_service_integration.dart`.
- Add a `.env.example` file to the repo so new developers know exactly which keys are required.
- Deploy and wire up the FastAPI backend (`backend/main.py`, `crop_model.pkl`) per `RENDER_DEPLOYMENT.md`.
- Add automated tests beyond the default `test/widget_test.dart`.

---

## 📄 License
Not specified
