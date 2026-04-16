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
    required this.emoji,
    required this.season,
    required this.expectedYield,
    required this.requirements,
    required this.soilType,
  });
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
}
