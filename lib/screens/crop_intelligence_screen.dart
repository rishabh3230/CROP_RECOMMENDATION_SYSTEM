import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/agro_service.dart';
import '../models/models.dart';
import '../services/crop_prediction_service.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/weather_service.dart';
import '../models/weather_model.dart';
import '../services/soil_service.dart';

class CropIntelligenceScreen extends StatefulWidget {
  final int initialTab;
  const CropIntelligenceScreen({super.key, this.initialTab = 0});

  @override
  State<CropIntelligenceScreen> createState() => _CropIntelligenceScreenState();
}

class _CropIntelligenceScreenState extends State<CropIntelligenceScreen>
    with TickerProviderStateMixin {
  
  // --- Common Data ---
  double _lat = 30.7333;
  double _lon = 76.7794;
  String _locationName = 'Punjab, India';
  Map<String, dynamic>? _weatherAnalysis;
  bool _isLoading = true;

  // --- Scientific Soil Data ---
  double _nitrogen = 90.0;
  double _phosphorus = 42.0;
  double _potassium = 43.0;
  double _ph = 6.5;
  String _soilSource = 'Local/Manual';

  // --- Recommendations ---
  List<CropPrediction> _recommendations = [];
  
  late AnimationController _contentFadeCtrl;

  @override
  void initState() {
    super.initState();

    _contentFadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    _initIntelligenceData();
  }

  @override
  void dispose() {
    _contentFadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _initIntelligenceData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final locationService = LocationService();
    Position? pos;
    String? localPlace;

    try {
      pos = await locationService.getCurrentLocation();
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        localPlace = '${p.locality}, ${p.administrativeArea}';
      }
    } catch (e) {
      debugPrint('Location error: $e');
    }

    final lat = pos?.latitude ?? _lat;
    final lon = pos?.longitude ?? _lon;

    final weatherService = WeatherService();
    WeatherModel? realWeather;
    try {
      realWeather = await weatherService.fetchWeather(lat, lon);
    } catch (e) {
      debugPrint('Real-time weather fetch failed: $e');
    }

    // ATTEMPT AUTO-SOIL FETCH
    final soilService = SoilService();
    SoilData? soilValues;
    try {
      soilValues = await soilService.fetchSoilData(lat, lon);
    } catch (e) {
      debugPrint('Auto-soil fetch failed: $e');
    }

    // Attempt to fetch historical analysis
    Map<String, dynamic>? analysis;
    try {
      analysis = await CropPredictionService.fetchWeatherAnalysis(lat, lon);
      if (realWeather != null) {
        analysis['avg_temp'] ??= analysis['avgTemp'] ?? realWeather.temperature;
        analysis['avg_humidity'] ??= analysis['avgHumidity'] ?? realWeather.humidity.toDouble();
      }
    } catch (e) {
      debugPrint('Deep Analysis fetch failed: $e');
      if (realWeather != null) {
        analysis = {
          'avg_temp': realWeather.temperature,
          'avg_humidity': realWeather.humidity.toDouble(),
          'total_rainfall': 120.0, 
          'history': List.generate(10, (i) => {'date': 'Day $i', 'rainfall': i * 2.0}),
        };
      }
    }

    // RUN ML PREDICTION AUTOMATICALLY
    List<CropPrediction> predictions = [];
    if (analysis != null) {
      try {
        predictions = await CropPredictionService.predictCrop(
          temperature: (analysis['avg_temp'] ?? analysis['avgTemp'] ?? 25.0) as double,
          humidity: (analysis['avg_humidity'] ?? analysis['avgHumidity'] ?? 60.0) as double,
          rainfall: (analysis['total_rainfall'] ?? analysis['totalRainfall'] ?? 100.0) as double,
          nitrogen: _nitrogen,
          phosphorus: _phosphorus,
          potassium: _potassium,
          ph: _ph,
        );
      } catch (e) {
        debugPrint('ML Prediction failed: $e');
        final mockResults = await AgroService.predictCrops(lat, lon, 'Loam');
        predictions = mockResults;
      }
    }

    if (mounted) {
      setState(() {
        _lat = lat;
        _lon = lon;
        _locationName = localPlace ?? 'Unknown Location';
        _weatherAnalysis = analysis;
        if (soilValues != null) {
          _nitrogen = soilValues.nitrogen;
          _ph = soilValues.ph;
          _soilSource = soilValues.source;
        }
        _recommendations = predictions;
        _isLoading = false;
      });
      _contentFadeCtrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: LoadingOverlay(message: 'Intelligently analyzing your location...'),
                    )
                  : FadeTransition(
                      opacity: _contentFadeCtrl,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildActiveLocationPanel(),
                            const SizedBox(height: 20),
                            _buildSoilProfileSection(),
                            const SizedBox(height: 24),
                            _buildAnalysisResultList(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Intelligence',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  letterSpacing: -1.0,
                ),
              ),
              Text(
                'Real-time crop-climate sync',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.hub_rounded, color: AppTheme.accent, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveLocationPanel() {
    final avgTemp = (_weatherAnalysis?['avg_temp'] ?? _weatherAnalysis?['avgTemp'] ?? 25.0) as double;
    final totalRainNum = _weatherAnalysis?['total_rainfall'] ?? _weatherAnalysis?['totalRainfall'] ?? 100.0;
    final totalRain = (totalRainNum as num).toDouble();
    final avgHumNum = _weatherAnalysis?['avg_humidity'] ?? _weatherAnalysis?['avgHumidity'] ?? 60.0;
    final avgHum = (avgHumNum as num).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.accentCool.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppTheme.accentCool, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _locationName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentCool,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Text(
                'LIVE SYNC',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.accent,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Current Environmental Context',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Coordinates: ${_lat.toStringAsFixed(4)}, ${_lon.toStringAsFixed(4)}',
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _statMiniChip('🌡️', '${avgTemp.toStringAsFixed(1)}°C', 'Avg Temp')),
              const SizedBox(width: 12),
              Expanded(child: _statMiniChip('🌧️', '${totalRain.toStringAsFixed(0)}mm', 'Rainfall')),
              const SizedBox(width: 12),
              Expanded(child: _statMiniChip('💧', '${avgHum.toStringAsFixed(0)}%', 'Humidity')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statMiniChip(String emoji, String val, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            val,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSoilProfileSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accentWarm.withValues(alpha: 0.1), AppTheme.card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accentWarm.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Soil Health Profile',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _soilSource.contains('Manual')
                              ? AppTheme.textMuted.withValues(alpha: 0.1)
                              : Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _soilSource,
                          style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: _soilSource.contains('Manual')
                                  ? AppTheme.textMuted
                                  : Colors.blue),
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Manual Soil Test Sync',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _showSoilEditBottomSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentWarm,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.edit_note_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Edit Stats',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _soilMetric('N', _nitrogen.toInt().toString(), 'Nitrogen', AppTheme.accent),
              _soilMetric('P', _phosphorus.toInt().toString(), 'Phosphorus', Colors.orange),
              _soilMetric('K', _potassium.toInt().toString(), 'Potassium', Colors.purple),
              _soilMetric('pH', _ph.toStringAsFixed(1), 'Acidity', Colors.teal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _soilMetric(String tag, String val, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tag,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            val,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  void _showSoilEditBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 24),
                  const Text('Update Soil Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                  const Text('Adjust values based on your soil test report', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                  const SizedBox(height: 32),
                  _soilSlider('Nitrogen (N)', _nitrogen, 0, 150, (v) => setModalState(() => _nitrogen = v), AppTheme.accent),
                  _soilSlider('Phosphorus (P)', _phosphorus, 0, 150, (v) => setModalState(() => _phosphorus = v), Colors.orange),
                  _soilSlider('Potassium (K)', _potassium, 0, 150, (v) => setModalState(() => _potassium = v), Colors.purple),
                  _soilSlider('Soil pH', _ph, 3.0, 10.0, (v) => setModalState(() => _ph = v), Colors.teal),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: () {
                      _soilSource = 'Manual Override ✏️';
                      Navigator.pop(context);
                      _initIntelligenceData();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      alignment: Alignment.center,
                      child: const Text('Update Predictions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _soilSlider(String label, double val, double min, double max, Function(double) onChanged, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
              Text(val.toStringAsFixed(label.contains('pH') ? 1 : 0), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              activeTrackColor: color,
              thumbColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: val,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResultList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Best Suited Crops',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'ML-Ranked Compatibility',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
            GestureDetector(
              onTap: _initIntelligenceData,
              child: const Icon(Icons.refresh_rounded, color: AppTheme.accent, size: 24),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_recommendations.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('No recommendations found for this climate profile.'),
            ),
          )
        else
          ...List.generate(_recommendations.length, (i) {
            final crop = _recommendations[i];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 500 + (i * 100)),
              curve: Curves.easeOutCubic,
              builder: (_, v, child) => Transform.translate(
                offset: Offset(0, 30 * (1 - v)),
                child: Opacity(opacity: v, child: child),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _RecommendationHeroCard(crop: crop, rank: i + 1),
              ),
            );
          }),
      ],
    );
  }
}

class _RecommendationHeroCard extends StatelessWidget {
  final CropPrediction crop;
  final int rank;

  const _RecommendationHeroCard({required this.crop, required this.rank});

  @override
  Widget build(BuildContext context) {
    final bool isBest = rank == 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isBest ? AppTheme.accent : AppTheme.border,
          width: isBest ? 2 : 1,
        ),
        boxShadow: isBest
            ? [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: (isBest ? AppTheme.accent : AppTheme.accentCool).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  crop.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isBest)
                      const Text(
                        '🎖️ PERFECT MATCH',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.accent,
                          letterSpacing: 0.5,
                        ),
                      ),
                    Text(
                      crop.cropName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Expected Yield: ${crop.expectedYield.toStringAsFixed(1)} tons/ha',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isBest ? AppTheme.accent : AppTheme.surface,
                  borderRadius: BorderRadius.circular(30),
                  border: isBest ? null : Border.all(color: AppTheme.border),
                ),
                child: Text(
                  '${(crop.confidence * 100).toInt()}% Confidence',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isBest ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 6),
              Text(
                'Season: ${crop.season}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              const Icon(Icons.layers_rounded, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 6),
              Text(
                'Soil: ${crop.soilType}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (isBest) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _showDeepAnalysisModal(context, crop),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.accent, AppTheme.accent.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.analytics_outlined, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Deep Analysis 📊',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showDeepAnalysisModal(BuildContext context, CropPrediction crop) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DeepAnalysisModal(crop: crop),
    );
  }
}

class _DeepAnalysisModal extends StatelessWidget {
  final CropPrediction crop;
  const _DeepAnalysisModal({required this.crop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(crop.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${crop.cropName} Analysis',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                    ),
                    const Text('Scientific Compatibility Report', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: _buildMatchCircle('Climate', crop.climateMatch, Colors.blue)),
                const SizedBox(width: 16),
                Expanded(child: _buildMatchCircle('Soil Health', crop.soilMatch, Colors.green)),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('AI Reasoning'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                crop.reasoning,
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('Ideal Requirements'),
            _buildStatComparison('Temperature', '${crop.idealStats['temp']?.toStringAsFixed(1) ?? "N/A"}°C', Icons.thermostat_rounded),
            _buildStatComparison('Humidity', '${crop.idealStats['hum']?.toStringAsFixed(0) ?? "N/A"}%', Icons.water_drop_rounded),
            _buildStatComparison('Rainfall', '${crop.idealStats['rain']?.toStringAsFixed(0) ?? "N/A"}mm', Icons.cloudy_snowing),
            _buildStatComparison('Soil pH', '${crop.idealStats['ph']?.toStringAsFixed(1) ?? "N/A"}', Icons.science_rounded),
            _buildStatComparison('Nitrogen (N)', '${crop.idealStats['N']?.toStringAsFixed(0) ?? "N/A"} mg/kg', Icons.grass_rounded),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Text('Back to Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCircle(String label, double match, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(match * 100).toInt()}%',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color),
              ),
            ],
          ),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
      ),
    );
  }

  Widget _buildStatComparison(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}
