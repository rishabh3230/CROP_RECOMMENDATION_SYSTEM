
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class CropPredictionService {
  // Configurable base URL
  // Use 'http://10.0.2.2:8000' for Android Emulator local testing
  // Replace with your Render URL (e.g., 'https://agro-api.onrender.com') when deployed
  static String baseUrl = 'http://192.168.1.69:8000';

  static Future<Map<String, dynamic>> fetchWeatherAnalysis(double lat, double lon) async {
    final url = Uri.parse('$baseUrl/weather-analysis?lat=$lat&lon=$lon');
    
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Server error: \${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Weather Analysis failed: \$e');
    }
  }

  static Future<List<CropPrediction>> predictCrop({
    required double temperature,
    required double humidity,
    required double rainfall,
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double ph,
  }) async {
    final url = Uri.parse('$baseUrl/predict');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'temperature': temperature,
          'humidity': humidity,
          'rainfall': rainfall,
          'nitrogen': nitrogen,
          'phosphorus': phosphorus,
          'potassium': potassium,
          'ph': ph,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final predictionsList = data['predictions'] as List;
        
        List<CropPrediction> results = [];
        for (var pred in predictionsList) {
          // Map API response to our robust Model
          results.add(CropPrediction.fromJson(pred));
        }
        return results;
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Scientific API prediction failed, using enhanced fallback: $e');
      return _getHeuristicPredictions(
        temperature, humidity, rainfall, nitrogen, phosphorus, potassium, ph
      );
    }
  }

  static List<CropPrediction> _getHeuristicPredictions(
    double temp, double hum, double rain,
    double n, double p, double k, double ph
  ) {
    List<CropPrediction> results = [];

    // --- Scientific Heuristics ---
    // Rice: Needs high rain, high N, and neutral soil
    if (rain > 100 && n > 60 && ph > 5.0 && ph < 7.5) {
      results.add(const CropPrediction(
        cropName: 'Rice',
        confidence: 0.94,
        emoji: '🌾',
        season: 'Kharif',
        expectedYield: 5.4,
        requirements: ['High Water', 'N-Rich Soil', 'Neutral pH'],
        soilType: 'Clayey Loam',
      ));
    }
    
    // Maize: Needs moderate rain, high P, and neutral soil
    if (rain > 60 && p > 30 && ph > 5.5 && ph < 7.5) {
      results.add(const CropPrediction(
        cropName: 'Maize',
        confidence: 0.88,
        emoji: '🌽',
        season: 'Rabi/Kharif',
        expectedYield: 4.8,
        requirements: ['Phosphorus for Roots', 'Well Drained Soil'],
        soilType: 'Sandy Loam',
      ));
    }

    // Wheat: Needs cool temp, low rain, and balanced NPK
    if (temp < 25 && rain < 80 && n > 40 && p > 30 && k > 30) {
      results.add(const CropPrediction(
        cropName: 'Wheat',
        confidence: 0.91,
        emoji: '🌾',
        season: 'Winter/Rabi',
        expectedYield: 4.2,
        requirements: ['Cool Growing', 'Potassium for Grain'],
        soilType: 'Alluvial Loam',
      ));
    }

    // Coffee: Needs high rain, moderate temp, and acidic soil
    if (rain > 120 && temp > 18 && temp < 28 && ph < 6.0) {
      results.add(const CropPrediction(
        cropName: 'Coffee',
        confidence: 0.85,
        emoji: '☕',
        season: 'Year-round',
        expectedYield: 1.2,
        requirements: ['Acidic Soil Only', 'Steady Rainfall'],
        soilType: 'Red Soil',
      ));
    }

    if (results.isEmpty) {
      results.add(const CropPrediction(
        cropName: 'General Grassland',
        confidence: 0.60,
        emoji: '🌿',
        season: 'Year round',
        expectedYield: 1.5,
        requirements: ['Basic Moisture', 'Minimal Fertilizer'],
        soilType: 'Any',
      ));
    }

    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    return results;
  }
}
