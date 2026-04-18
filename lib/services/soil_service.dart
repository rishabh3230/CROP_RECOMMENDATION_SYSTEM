import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class SoilData {
  final double nitrogen; // in cg/kg (raw) or scaled?
  final double ph;
  final String source;

  SoilData({
    required this.nitrogen,
    required this.ph,
    this.source = 'Global Database',
  });
}

class SoilService {
  static const String _baseUrl = 'https://rest.isric.org/soilgrids/v2.0/properties/query';

  Future<SoilData?> fetchSoilData(double lat, double lon) async {
    final url = Uri.parse('$_baseUrl?lon=$lon&lat=$lat&property=nitrogen&property=phh2o&depth=0-5cm&depth=5-15cm&value=mean');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List layers = data['properties']['layers'];

        double? nitMean;
        double? phMean;

        for (var layer in layers) {
          final String name = layer['name'];
          final List depths = layer['depths'];
          
          // Average the mean values across depths
          double sum = 0;
          int count = 0;
          for (var d in depths) {
            final val = d['values']['mean'];
            if (val != null) {
              sum += val;
              count++;
            }
          }

          if (count > 0) {
            double avg = sum / count;
            if (name == 'nitrogen') nitMean = avg;
            if (name == 'phh2o') phMean = avg;
          }
        }

        if (nitMean != null && phMean != null) {
          // CONVERSION
          // phh2o is pH*10 -> /10
          // nitrogen is cg/kg -> SoilGrids says factor 100 for g/kg.
          // For our ML model (N usually 40-120), we'll use a heuristic scaling.
          // Typical Nitrogen in topsoil is 100-300 cg/kg. 
          // We'll normalize to a 0-140 scale for the app UI/ML.
          
          double finalPH = phMean / 10.0;
          
          // Nitrogen scaling: if raw is 150 cg/kg, we might map it to 75-90 for the ML model.
          // This is an estimation to make the "Automatic" data feel right in the UI.
          double finalNit = nitMean / 2.0; 
          if (finalNit > 140) finalNit = 140;

          return SoilData(
            nitrogen: finalNit,
            ph: finalPH,
            source: 'ISRIC SoilGrids 🛰️',
          );
        }
      }
    } catch (e) {
      debugPrint('Soil data fetch failed: $e');
    }
    return null;
  }
}
