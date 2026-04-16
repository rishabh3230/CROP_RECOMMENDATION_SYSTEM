import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/agro_service.dart';
import '../models/models.dart';

class CropPredictionScreen extends StatefulWidget {
  const CropPredictionScreen({super.key});

  @override
  State<CropPredictionScreen> createState() => _CropPredictionScreenState();
}

class _CropPredictionScreenState extends State<CropPredictionScreen>
    with TickerProviderStateMixin {
  List<CropPrediction> _predictions = [];
  bool _loading = false;
  bool _hasResult = false;
  String _selectedLandType = 'Loam';
  late AnimationController _listCtrl;

  final List<String> _landTypes = [
    'Loam', 'Clay', 'Sandy', 'Silt', 'Black', 'Alluvial', 'Red'
  ];

  // Simulated GPS
  final double _lat = 30.7333;
  final double _lon = 76.7794;
  final String _locationName = 'Punjab, India';

  @override
  void initState() {
    super.initState();
    _listCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _listCtrl.dispose();
    super.dispose();
  }

  Future<void> _runPrediction() async {
    setState(() {
      _loading = true;
      _hasResult = false;
    });
    final results =
        await AgroService.predictCrops(_lat, _lon, _selectedLandType);
    if (mounted) {
      setState(() {
        _predictions = results;
        _loading = false;
        _hasResult = true;
      });
      _listCtrl.reset();
      _listCtrl.forward();
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
              child: _loading
                  ? const LoadingOverlay(
                      message: 'Running ML prediction model...')
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLocationCard(),
                          const SizedBox(height: 20),
                          _buildLandTypeSelector(),
                          const SizedBox(height: 20),
                          _buildPredictButton(),
                          if (_hasResult) ...[
                            const SizedBox(height: 24),
                            _buildResultHeader(),
                            const SizedBox(height: 14),
                            ..._buildPredictionCards(),
                          ],
                        ],
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crop Prediction',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'AI-powered weather pattern analysis',
                  style: TextStyle(
                      fontSize: 13, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('🌱', style: TextStyle(fontSize: 20)),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.accentCool.withOpacity(0.25), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.accentCool.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.gps_fixed_rounded,
                color: AppTheme.accentCool, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                          color: AppTheme.accent, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'GPS Location Active',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _locationName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${_lat.toStringAsFixed(4)}°N, ${_lon.toStringAsFixed(4)}°E',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accentCool.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppTheme.accentCool.withOpacity(0.3), width: 1),
            ),
            child: const Text(
              'Refresh',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.accentCool,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Land Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _landTypes.map((type) {
            final selected = type == _selectedLandType;
            return GestureDetector(
              onTap: () => setState(() => _selectedLandType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.accent.withOpacity(0.15)
                      : AppTheme.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? AppTheme.accent
                        : AppTheme.border,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: selected
                        ? AppTheme.accent
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPredictButton() {
    return GestureDetector(
      onTap: _runPrediction,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4FA82E), AppTheme.accent],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              'Run ML Prediction',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'ML Results',
                style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Based on current weather data',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${_predictions.length} crops suitable for your land',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPredictionCards() {
    return List.generate(_predictions.length, (i) {
      final crop = _predictions[i];
      final delay = i * 0.15;
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 400 + (i * 80)),
        curve: Curves.easeOutCubic,
        builder: (_, v, child) => Transform.translate(
          offset: Offset(0, 20 * (1 - v)),
          child: Opacity(opacity: v, child: child),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _PredictionCard(crop: crop, rank: i + 1),
        ),
      );
    });
  }
}

class _PredictionCard extends StatefulWidget {
  final CropPrediction crop;
  final int rank;

  const _PredictionCard({required this.crop, required this.rank});

  @override
  State<_PredictionCard> createState() => _PredictionCardState();
}

class _PredictionCardState extends State<_PredictionCard> {
  bool _expanded = false;

  Color get _rankColor {
    switch (widget.rank) {
      case 1:
        return AppTheme.accent;
      case 2:
        return AppTheme.accentWarm;
      case 3:
        return AppTheme.accentCool;
      default:
        return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final crop = widget.crop;
    final pct = (crop.confidence * 100).toInt();

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: _rankColor.withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(crop.emoji,
                    style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            crop.cropName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _rankColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#${widget.rank}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _rankColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        crop.season,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$pct%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _rankColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Text(
                      'confidence',
                      style: TextStyle(
                          fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ConfidenceBar(value: crop.confidence, color: _rankColor),
            const SizedBox(height: 12),
            Row(
              children: [
                _infoChip('🌾', '${crop.expectedYield}t/ha'),
                const SizedBox(width: 8),
                _infoChip('🪨', crop.soilType),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(height: 0),
              secondChild: _buildExpanded(crop),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.textMuted,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildExpanded(CropPrediction crop) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 12),
          const Text(
            'Requirements',
            style: TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          ...crop.requirements.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _rankColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      r,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
