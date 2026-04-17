import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class CropPredictionService {
  // Configurable base URL
  // Use 'http://10.0.2.2:8000' for Android Emulator local testing
  // Replace with your Render URL (e.g., 'https://agro-api.onrender.com') when deployed
  static String baseUrl = 'http://10.0.2.2:8000';

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
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final predictionsList = data['predictions'] as List;
        
        List<CropPrediction> results = [];
        for (var pred in predictionsList) {
          String cropNameStr = pred['crop'] as String;
          String cropTitle = "${cropNameStr[0].toUpperCase()}${cropNameStr.substring(1)}";
          
          results.add(CropPrediction(
            cropName: cropTitle,
            confidence: (pred['confidence'] as num).toDouble(),
            emoji: _getEmojiForCrop(cropNameStr),
            season: 'Optimal matching (API result)',
            expectedYield: 4.5,
            requirements: [
               'Temp: ${temperature.toStringAsFixed(1)}°C',
               'Humidity: ${humidity.toStringAsFixed(1)}%',
               'Rainfall: ${rainfall.toStringAsFixed(1)}mm'
            ],
            soilType: 'Loam/Varied',
          ));
        }
        return results;
      } else {
        throw Exception('API Error');
      }
    } catch (e) {
      // Fallback to local heuristics if API is unreachable or returns error
      return _getHeuristicPredictions(temperature, humidity, rainfall);
    }
  }

  static List<CropPrediction> _getHeuristicPredictions(double temp, double hum, double rain) {
    List<CropPrediction> results = [];

    // Simple heuristic-based matching
    if (temp > 20 && hum > 70 && rain > 100) {
      results.add(const CropPrediction(
        cropName: 'Rice',
        confidence: 0.92,
        emoji: '🌾',
        season: 'Monsoon / kharif',
        expectedYield: 5.2,
        requirements: ['High Standing Water', 'Warm Humid Air', 'Nitrogen Rich Soil'],
        soilType: 'Clayey Loam',
      ));
    }
    
    if (temp > 18 && temp < 30 && rain > 60) {
      results.add(const CropPrediction(
        cropName: 'Maize',
        confidence: 0.85,
        emoji: '🌽',
        season: 'Rabi / Kharif',
        expectedYield: 4.8,
        requirements: ['Moderate Irrigation', 'Well Drained Soil', 'Full Sunlight'],
        soilType: 'Loam',
      ));
    }

    if (temp < 25 && temp > 10 && rain < 70) {
      results.add(const CropPrediction(
        cropName: 'Wheat',
        confidence: 0.88,
        emoji: '🌾',
        season: 'Winter / Rabi',
        expectedYield: 3.9,
        requirements: ['Cool Growing Season', 'Bright Sunlight', 'Regular Watering'],
        soilType: 'Alluvial Loam',
      ));
    }

    if (temp > 25 && rain < 100) {
      results.add(const CropPrediction(
        cropName: 'Cotton',
        confidence: 0.82,
        emoji: '🌱',
        season: 'Summer / Kharif',
        expectedYield: 2.1,
        requirements: ['High Temperature', 'Sufficient Irrigation', 'Frost-free Period'],
        soilType: 'Black Soil',
      ));
    }

    if (results.isEmpty) {
      results.add(const CropPrediction(
        cropName: 'General Grassland',
        confidence: 0.60,
        emoji: '🌿',
        season: 'Year round',
        expectedYield: 1.5,
        requirements: ['Basic Moisture', 'Minimal Fertilizer', 'Adaptive Soil'],
        soilType: 'Any',
      ));
    }

    // Sort by "confidence" (dummy sorting for fallback)
    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    return results;
  }

  static String _getEmojiForCrop(String crop) {
    String c = crop.toLowerCase();
    if (c.contains('rice')) return '🌾';
    if (c.contains('maize')) return '🌽';
    if (c.contains('cotton')) return '🌱';
    if (c.contains('apple')) return '🍎';
    if (c.contains('orange')) return '🍊';
    if (c.contains('grapes')) return '🍇';
    if (c.contains('mango')) return '🥭';
    if (c.contains('banana')) return '🍌';
    if (c.contains('coffee')) return '☕';
    if (c.contains('coconut')) return '🥥';
    if (c.contains('watermelon')) return '🍉';
    return '🌿';
  }
}
