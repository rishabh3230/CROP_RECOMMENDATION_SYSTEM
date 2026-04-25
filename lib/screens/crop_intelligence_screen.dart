import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class CropIntelligenceScreen extends StatefulWidget {
  final int initialTab;
  const CropIntelligenceScreen({super.key, this.initialTab = 0});

  @override
  State<CropIntelligenceScreen> createState() =>
      _CropIntelligenceScreenState();
}

class _CropIntelligenceScreenState extends State<CropIntelligenceScreen> {
  // Data State
  Map<String, dynamic>? cachedData;
  bool isLoading = true;
  String? errorMessage;
  String locationName = "Fetching location...";

  // Constants
  final String meteostatApiKey = "YOUR_METEOSTAT_API_KEY"; // Placeholder
  final String backendUrl =
      "http://localhost:8000/predict"; // Replace with actual IP for device

  @override
  void initState() {
    super.initState();
    _loadCacheOrFetch();
  }

  Future<void> _loadCacheOrFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedJson = prefs.getString('crop_data_cache');

    if (cachedJson != null) {
      setState(() {
        cachedData = jsonDecode(cachedJson);
        isLoading = false;
      });
      _updateLocationName(cachedData!['lat'], cachedData!['lon']);
    } else {
      try {
        Position position = await _getGeoLocation();
        await _updateLocationName(position.latitude, position.longitude);
      } catch (e) {
        print("Initial location fetch failed: $e");
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateLocationName(double lat, double lon) async {
    try {
      // 1. Try Geocoding package
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks[0];
        final city = placemark.locality?.isNotEmpty == true
            ? placemark.locality!
            : (placemark.subAdministrativeArea ?? "Unknown City");
        setState(() {
          locationName =
              "$city, ${placemark.country} (${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)})";
        });
        return;
      }
    } catch (e) {
      print("Geocoding package failed: $e, trying Nominatim API fallback...");
    }

    try {
      // 2. Try Nominatim Reverse Geocoding API if package fails (common on Web)
      final url =
          "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon";
      final response = await http.get(Uri.parse(url),
          headers: {"User-Agent": "CropIntelligenceApp/1.0"});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'];
        if (address != null) {
          final city = address['city'] ??
              address['town'] ??
              address['village'] ??
              address['county'] ??
              "Unknown Area";
          final country = address['country'] ?? "";
          setState(() {
            locationName =
                "$city, $country (${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)})";
          });
          return;
        }
      }
    } catch (e) {
      print("Nominatim API failed: $e");
    }

    // 3. Ultimate Fallback (must format with parentheses for UI)
    setState(() {
      locationName =
          "Location (${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)})";
    });
  }

  Future<void> _refreshLocationOnly() async {
    setState(() {
      isLoading = true;
      cachedData = null;
      errorMessage = null;
    });
    try {
      Position position = await _getGeoLocation();
      await _updateLocationName(position.latitude, position.longitude);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('crop_data_cache');
    } catch (e) {
      setState(() => errorMessage = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchCompleteData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // 1. Geolocation
      Position position = await _getGeoLocation();
      double lat = position.latitude;
      double lon = position.longitude;
      _updateLocationName(lat, lon);

      // 2. Meteostat Weather
      final weatherData = await _fetchWeather(lat, lon);

      // 3. SoilGrids Data
      final soilData = await _fetchSoilData(lat, lon);

      // 4. ML Prediction
      final predictions = await _fetchPrediction(
          soilData['N'],
          soilData['P'],
          soilData['K'],
          weatherData['avg_temp'],
          soilData['ph'],
          weatherData['total_rainfall']);

      // 5. Combine and Cache
      final newData = {
        "lat": lat,
        "lon": lon,
        "avg_temperature": weatherData['avg_temp'],
        "total_rainfall": weatherData['total_rainfall'],
        "last_10_days_rainfall": weatherData['last_10_days_rainfall'],
        "ph": soilData['ph'],
        "N": soilData['N'],
        "P": soilData['P'],
        "K": soilData['K'],
        "last_updated": DateTime.now().toIso8601String(),
        "top_3_predictions": predictions
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('crop_data_cache', jsonEncode(newData));

      setState(() {
        cachedData = newData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<Position> _getGeoLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<Map<String, dynamic>> _fetchWeather(double lat, double lon) async {
    final now = DateTime.now();
    final twoMonthsAgo = now.subtract(const Duration(days: 60));
    final formatter = DateFormat('yyyy-MM-dd');

    // Using Meteostat Point Daily API
    final url =
        "https://api.meteostat.net/v2/point/daily?lat=$lat&lon=$lon&start=${formatter.format(twoMonthsAgo)}&end=${formatter.format(now)}";

    try {
      final response = await http
          .get(Uri.parse(url), headers: {"x-api-key": meteostatApiKey});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        double sumTemp = 0;
        double totalRain = 0;
        List<double> last10Rain = [];

        for (var i = 0; i < data.length; i++) {
          sumTemp += (data[i]['tavg'] ?? 0);
          totalRain += (data[i]['prcp'] ?? 0);
        }

        // Last 10 days rainfall
        for (var i = data.length - 10; i < data.length; i++) {
          if (i >= 0) last10Rain.add((data[i]['prcp'] ?? 0).toDouble());
        }

        return {
          "avg_temp": sumTemp / data.length,
          "total_rainfall": totalRain,
          "last_10_days_rainfall": last10Rain,
        };
      }
    } catch (e) {
      print("Weather fetch error: $e");
    }

    // Fallback Mock Data if API fails
    return {
      "avg_temp": 25.5,
      "total_rainfall": 120.0,
      "last_10_days_rainfall": [
        5.0, 12.0, 0.0, 8.5, 2.0, 1.0, 0.0, 14.0, 3.0, 0.0
      ],
    };
  }

  Future<Map<String, dynamic>> _fetchSoilData(double lat, double lon) async {
    // SoilGrids API
    final url =
        "https://rest.isric.org/soilgrids/v2.0/properties/query?lon=$lon&lat=$lat&property=phh2o&property=nitrogen&property=phosphorus&property=potassium&depth=0-30cm&value=mean";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final props = jsonDecode(response.body)['properties']['layers'];

        double getVal(String name) {
          final layer = props.firstWhere((l) => l['name'] == name);
          return (layer['depths'][0]['values']['mean'] as num).toDouble();
        }

        return {
          "ph": getVal('phh2o') / 10.0,
          "N": getVal('nitrogen') / 10.0,
          "P": getVal('phosphorus') / 10.0,
          "K": getVal('potassium') / 10.0,
        };
      }
    } catch (e) {
      print("Soil fetch error: $e");
    }

    return {"ph": 6.5, "N": 80, "P": 45, "K": 40}; // Fallback
  }

  Future<List<dynamic>> _fetchPrediction(
      double n, double p, double k, double temp, double ph, double rain) async {
    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "N": n,
          "P": p,
          "K": k,
          "temperature": temp,
          "ph": ph,
          "rainfall": rain
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['predictions'];
      }
    } catch (e) {
      print("Prediction fetch error: $e");
    }
    return [
      {"crop": "Rice", "confidence": 0.85},
      {"crop": "Maize", "confidence": 0.10},
      {"crop": "Wheat", "confidence": 0.05}
    ]; // Fallback
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1711),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Crop Intelligence",
                              style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          const SizedBox(height: 4),
                          Text("AI-powered agricultural analysis",
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.4))),
                        ],
                      ),
                    ),
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFF6BD444))),
                      ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3526),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text("🧠", style: TextStyle(fontSize: 24)),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF101B14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1E3526)),
                  ),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: const Color(0xFF1A3020),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFF2B4A33)),
                    ),
                    labelColor: const Color(0xFF6BD444),
                    unselectedLabelColor: Colors.white54,
                    labelStyle: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    unselectedLabelStyle: GoogleFonts.outfit(
                        fontWeight: FontWeight.w500, fontSize: 13),
                    tabs: const [
                      Tab(text: "Quick Predict"),
                      Tab(text: "Deep Analysis"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildLocationBadge(),
              const SizedBox(height: 8),
              Expanded(
                child: isLoading && cachedData == null
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFF6BD444)))
                    : errorMessage != null
                        ? Center(
                            child: Text("Error: $errorMessage",
                                style: const TextStyle(color: Colors.white)))
                        : TabBarView(
                            children: [
                              SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 16),
                                    if (cachedData == null)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24.0, vertical: 48.0),
                                        child: _buildGlowingButton(),
                                      )
                                    else
                                      _buildSection1(),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                              SingleChildScrollView(
                                child: Column(
                                  children: [
                                    const SizedBox(height: 16),
                                    if (cachedData == null)
                                      const Padding(
                                        padding: EdgeInsets.all(48.0),
                                        child: Center(
                                            child: Text(
                                                "No analysis data available.\nPlease click 'Recommend me crops' to fetch data.",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    color: Colors.white60))),
                                      )
                                    else
                                      _buildSection2(),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlowingButton({bool small = false}) {
    return Container(
      width: small ? null : double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(small ? 20 : 24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6BD444).withValues(alpha: small ? 0.1 : 0.4),
            blurRadius: small ? 15 : 25,
            offset: Offset(0, small ? 4 : 8),
          )
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _fetchCompleteData,
        icon: Icon(small ? Icons.refresh : Icons.auto_awesome,
            color: small ? const Color(0xFF6BD444) : const Color(0xFF0B140E),
            size: small ? 18 : 24),
        label: Text(small ? "Refresh Location" : "✨ Recommend me crops",
            style: GoogleFonts.outfit(
                fontSize: small ? 12 : 18,
                fontWeight: FontWeight.bold,
                color:
                    small ? const Color(0xFF6BD444) : const Color(0xFF0B140E))),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              small ? const Color(0xFF1E3526) : const Color(0xFF6BD444),
          padding:
              EdgeInsets.symmetric(horizontal: 16, vertical: small ? 8 : 18),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(small ? 20 : 24)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildLocationBadge() {
    String address = locationName;
    String coords = "Locating GPS coordinates...";
    if (locationName.contains('(') && locationName.contains(')')) {
      int start = locationName.indexOf('(');
      int end = locationName.indexOf(')');
      address = locationName.substring(0, start).trim();
      coords = "${locationName.substring(start + 1, end).trim()}°N/E";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF132017),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1E3526)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1E332A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.my_location,
                  color: Color(0xFF3B9BBA), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6BD444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text("GPS Location Active",
                          style: TextStyle(
                              color: Color(0xFF6BD444),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(address,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(coords,
                      style: const TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),
            IconButton(
              onPressed: _refreshLocationOnly,
              icon: const Icon(Icons.refresh, color: Color(0xFF6BD444)),
              tooltip: "Refresh Location",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection1() {
    if (cachedData == null) return const SizedBox.shrink();
    final predictions = cachedData!['top_3_predictions'] as List;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text("Top Recommended Crops",
              style: GoogleFonts.outfit(
                  fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...predictions.map((p) => _buildCropCard(p)),
        ],
      ),
    );
  }

  Widget _buildCropCard(dynamic prediction) {
    final double confidence = prediction['confidence'];
    final String crop = prediction['crop'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12)),
            child: Center(
                child: Text(_getCropIcon(crop),
                    style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(crop,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("${(confidence * 100).toStringAsFixed(1)}%",
                        style: const TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: confidence,
                    minHeight: 8,
                    backgroundColor: Colors.white10,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCropIcon(String crop) {
    crop = crop.toLowerCase();
    if (crop.contains("rice")) return "🌾";
    if (crop.contains("maize")) return "🌽";
    if (crop.contains("wheat")) return "🍞";
    if (crop.contains("apple")) return "🍎";
    if (crop.contains("banana")) return "🍌";
    if (crop.contains("grapes")) return "🍇";
    if (crop.contains("mango")) return "🥭";
    if (crop.contains("orange")) return "🍊";
    if (crop.contains("papaya")) return "🍈";
    if (crop.contains("pomegranate")) return "🍎";
    if (crop.contains("watermelon")) return "🍉";
    if (crop.contains("muskmelon")) return "🍈";
    if (crop.contains("cotton")) return "☁️";
    if (crop.contains("coffee")) return "☕";
    if (crop.contains("tea")) return "🍵";
    return "🌱";
  }

  Widget _buildSection2() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Deep Analysis",
              style: GoogleFonts.outfit(
                  fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildWeatherStats(),
        ],
      ),
    );
  }

  Widget _buildWeatherStats() {
    final rain10 = List<double>.from(cachedData!['last_10_days_rainfall']);
    return Column(
      children: [
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Rainfall (Last 10 Days)",
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
              const SizedBox(height: 16),
              Expanded(
                child: BarChart(
                  BarChartData(
                    barGroups: List.generate(
                        rain10.length,
                        (i) => BarChartGroupData(x: i, barRods: [
                              BarChartRodData(
                                  toY: rain10[i],
                                  color: Colors.blueAccent,
                                  width: 16,
                                  borderRadius: BorderRadius.circular(4))
                            ])),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= rain10.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                rain10[i].toStringAsFixed(0),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barTouchData: BarTouchData(enabled: false),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _buildStatCard(
                    "Avg Temp",
                    "${cachedData!['avg_temperature'].toStringAsFixed(1)}°C",
                    Icons.thermostat)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatCard(
                    "Total Rain",
                    "${cachedData!['total_rainfall'].toStringAsFixed(0)}mm",
                    Icons.umbrella)),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard("Soil pH Level", cachedData!['ph'].toStringAsFixed(1),
            Icons.science,
            fullWidth: true),
        const SizedBox(height: 24),
        Text("Soil Nutrients (NPK)",
            style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildStatCard(
                    "Nitrogen (N)",
                    "${cachedData!['N'].toStringAsFixed(0)} mg/kg",
                    Icons.grass)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatCard(
                    "Phosphorus (P)",
                    "${cachedData!['P'].toStringAsFixed(0)} mg/kg",
                    Icons.grain)),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard("Potassium (K)",
            "${cachedData!['K'].toStringAsFixed(0)} mg/kg", Icons.nature,
            fullWidth: true),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon,
      {bool fullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: Colors.greenAccent, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white60, fontSize: 11)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
