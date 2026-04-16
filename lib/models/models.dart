// ─────────────────────────────────────────────────────────────────────────────
// AgroMind – Data Models
// ─────────────────────────────────────────────────────────────────────────────

enum AlertSeverity { critical, high, medium, low }

// ── Weather ──────────────────────────────────────────────────────────────────

class WeatherData {
  final double temperature;
  final int humidity;
  final double rainfall;
  final double windSpeed;
  final String condition;
  final String icon;
  final String location;

  const WeatherData({
    required this.temperature,
    required this.humidity,
    required this.rainfall,
    required this.windSpeed,
    required this.condition,
    required this.icon,
    required this.location,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['main']?['temp'] ?? json['temperature'] ?? 0.0).toDouble(),
      humidity: (json['main']?['humidity'] ?? json['humidity'] ?? 0).toInt(),
      rainfall: (json['rain']?['1h'] ?? json['rainfall'] ?? 0.0).toDouble(),
      windSpeed: (json['wind']?['speed'] ?? json['windSpeed'] ?? 0.0).toDouble(),
      condition: json['weather']?[0]?['main'] ?? json['condition'] ?? 'Unknown',
      icon: _getEmojiForCondition(json['weather']?[0]?['main'] ?? json['condition']),
      location: json['name'] ?? json['location'] ?? 'Unknown',
    );
  }

  static String _getEmojiForCondition(String? condition) {
    if (condition == null) return '🌡️';
    final c = condition.toLowerCase();
    if (c.contains('cloud')) return '☁️';
    if (c.contains('rain')) return '🌧️';
    if (c.contains('clear')) return '☀️';
    if (c.contains('storm')) return '⛈️';
    if (c.contains('snow')) return '❄️';
    return '⛅';
  }
}

class HistoricalWeather {
  final int year;
  final double avgTemp;
  final double totalRainfall;
  final int frostDays;
  final int droughtDays;

  const HistoricalWeather({
    required this.year,
    required this.avgTemp,
    required this.totalRainfall,
    required this.frostDays,
    required this.droughtDays,
  });

  factory HistoricalWeather.fromJson(Map<String, dynamic> json) {
    return HistoricalWeather(
      year: (json['year'] ?? 0).toInt(),
      avgTemp: (json['avgTemp'] ?? json['temperature'] ?? 0.0).toDouble(),
      totalRainfall: (json['totalRainfall'] ?? json['rainfall'] ?? 0.0).toDouble(),
      frostDays: (json['frostDays'] ?? 0).toInt(),
      droughtDays: (json['droughtDays'] ?? 0).toInt(),
    );
  }
}

// ── Crop Prediction ───────────────────────────────────────────────────────────

class CropPrediction {
  final String cropName;
  final double confidence;
  final String emoji;
  final String season;
  final double expectedYield;
  final List<String> requirements;
  final String soilType;

  const CropPrediction({
    required this.cropName,
    required this.confidence,
    this.emoji = '🌱',
    this.season = 'Unknown',
    this.expectedYield = 0.0,
    this.requirements = const [],
    this.soilType = 'Varied',
  });

  factory CropPrediction.fromJson(Map<String, dynamic> json) {
    return CropPrediction(
      cropName: json['crop_name'] ?? json['cropName'] ?? 'Unknown',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      emoji: json['emoji'] ?? _getDefaultEmoji(json['crop_name'] ?? json['cropName']),
      season: json['season'] ?? 'Check Guide',
      expectedYield: (json['expected_yield'] ?? json['expectedYield'] ?? 0.0).toDouble(),
      requirements: List<String>.from(json['requirements'] ?? []),
      soilType: json['soil_type'] ?? json['soilType'] ?? 'Loam',
    );
  }

  static String _getDefaultEmoji(String? crop) {
    final name = crop?.toLowerCase() ?? '';
    if (name.contains('wheat')) return '🌾';
    if (name.contains('rice')) return '🌿';
    if (name.contains('corn') || name.contains('maize')) return '🌽';
    if (name.contains('tomato')) return '🍅';
    if (name.contains('potato')) return '🥔';
    return '🌱';
  }
}

// ── Profit Analysis ───────────────────────────────────────────────────────────

class MonthlyProfit {
  final String month;
  final double profit;

  const MonthlyProfit(this.month, this.profit);
}

class CropProfit {
  final String cropName;
  final String emoji;
  final double profitPerHectare;
  final double marketPrice;
  final double productionCost;
  final double growthPercent;
  final String category;
  final List<MonthlyProfit> monthlyData;

  const CropProfit({
    required this.cropName,
    required this.emoji,
    required this.profitPerHectare,
    required this.marketPrice,
    required this.productionCost,
    required this.growthPercent,
    required this.category,
    required this.monthlyData,
  });
}

// ── Best Crop Recommendation ──────────────────────────────────────────────────

class BestCropRecommendation {
  final String cropName;
  final String emoji;
  final int score;
  final double climateMatch;
  final double soilMatch;
  final double profitability;
  final double waterEfficiency;
  final String reasoning;
  final List<String> pros;
  final List<String> cons;

  const BestCropRecommendation({
    required this.cropName,
    required this.emoji,
    required this.score,
    required this.climateMatch,
    required this.soilMatch,
    required this.profitability,
    required this.waterEfficiency,
    required this.reasoning,
    required this.pros,
    required this.cons,
  });

  factory BestCropRecommendation.fromJson(Map<String, dynamic> json) {
    return BestCropRecommendation(
      cropName: json['crop_name'] ?? 'Unknown',
      emoji: json['emoji'] ?? '🌱',
      score: (json['score'] ?? 0).toInt(),
      climateMatch: (json['climate_match'] ?? 0.0).toDouble(),
      soilMatch: (json['soil_match'] ?? 0.0).toDouble(),
      profitability: (json['profitability'] ?? 0.0).toDouble(),
      waterEfficiency: (json['water_efficiency'] ?? 0.0).toDouble(),
      reasoning: json['reasoning'] ?? 'N/A',
      pros: List<String>.from(json['pros'] ?? []),
      cons: List<String>.from(json['cons'] ?? []),
    );
  }
}

// ── Weather Alert ─────────────────────────────────────────────────────────────

class WeatherAlert {
  final String title;
  final String description;
  final AlertSeverity severity;
  final String time;
  final String icon;
  final bool isActive;

  const WeatherAlert({
    required this.title,
    required this.description,
    required this.severity,
    required this.time,
    required this.icon,
    required this.isActive,
  });

  factory WeatherAlert.fromJson(Map<String, dynamic> json) {
    return WeatherAlert(
      title: json['title'] ?? 'Alert',
      description: json['description'] ?? '',
      severity: _parseSeverity(json['severity']),
      time: json['time'] ?? 'Now',
      icon: json['icon'] ?? '⚠️',
      isActive: json['isActive'] ?? json['active'] ?? true,
    );
  }

  static AlertSeverity _parseSeverity(dynamic s) {
    final str = s?.toString().toLowerCase() ?? 'low';
    if (str.contains('critical')) return AlertSeverity.critical;
    if (str.contains('high')) return AlertSeverity.high;
    if (str.contains('medium')) return AlertSeverity.medium;
    return AlertSeverity.low;
  }
}
