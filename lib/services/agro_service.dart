import 'dart:math';
import '../models/models.dart';

/// Simulates the ML backend + Weather API service.
/// In production: replace with real API calls to your Python ML microservice
/// and OpenWeatherMap / Visual Crossing historical weather API.
class AgroService {
  static final _rng = Random();

  // ── Weather ──────────────────────────────────────────────────────────────

  static Future<WeatherData> fetchCurrentWeather(
      double lat, double lon) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return const WeatherData(
      temperature: 24.5,
      humidity: 68,
      rainfall: 12.3,
      windSpeed: 14.2,
      condition: 'Partly Cloudy',
      icon: '⛅',
      location: 'Punjab, India',
    );
  }

  static Future<List<HistoricalWeather>> fetchHistoricalWeather(
      double lat, double lon) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    return List.generate(12, (i) {
      final year = 2013 + i;
      return HistoricalWeather(
        year: year,
        avgTemp: 22.0 + _rng.nextDouble() * 4,
        totalRainfall: 800 + _rng.nextDouble() * 400,
        frostDays: _rng.nextInt(10),
        droughtDays: 20 + _rng.nextInt(30),
      );
    });
  }

  // ── Crop Prediction (ML) ─────────────────────────────────────────────────

  static Future<List<CropPrediction>> predictCrops(
      double lat, double lon, String landType) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return const [
      CropPrediction(
        cropName: 'Wheat',
        confidence: 0.91,
        emoji: '🌾',
        season: 'Rabi (Oct–Mar)',
        expectedYield: 4.2,
        requirements: ['Moderate rainfall', 'Cool winters', 'Clay-loam soil'],
        soilType: 'Clay-Loam',
      ),
      CropPrediction(
        cropName: 'Rice',
        confidence: 0.84,
        emoji: '🌿',
        season: 'Kharif (Jun–Nov)',
        expectedYield: 5.8,
        requirements: ['High water', 'Warm humid', 'Alluvial soil'],
        soilType: 'Alluvial',
      ),
      CropPrediction(
        cropName: 'Maize',
        confidence: 0.76,
        emoji: '🌽',
        season: 'Kharif (Jun–Sep)',
        expectedYield: 3.9,
        requirements: ['Moderate water', 'Warm days', 'Well-drained loam'],
        soilType: 'Loam',
      ),
      CropPrediction(
        cropName: 'Soybean',
        confidence: 0.68,
        emoji: '🫘',
        season: 'Kharif (Jun–Oct)',
        expectedYield: 2.4,
        requirements: ['Moderate rainfall', 'Warm climate', 'Black soil'],
        soilType: 'Black',
      ),
      CropPrediction(
        cropName: 'Mustard',
        confidence: 0.62,
        emoji: '🌻',
        season: 'Rabi (Oct–Feb)',
        expectedYield: 1.8,
        requirements: ['Low moisture', 'Cool dry winters', 'Sandy-loam'],
        soilType: 'Sandy-Loam',
      ),
    ];
  }

  // ── Profit Analysis ───────────────────────────────────────────────────────

  static Future<List<CropProfit>> fetchCropProfits() async {
    await Future.delayed(const Duration(milliseconds: 900));
    return const [
      CropProfit(
        cropName: 'Wheat',
        emoji: '🌾',
        profitPerHectare: 1240,
        marketPrice: 280,
        productionCost: 920,
        growthPercent: 8.4,
        category: 'Cereal',
        monthlyData: [
          MonthlyProfit('Jan', 300), MonthlyProfit('Feb', 420),
          MonthlyProfit('Mar', 900), MonthlyProfit('Apr', 1200),
          MonthlyProfit('May', 1100), MonthlyProfit('Jun', 800),
          MonthlyProfit('Jul', 600), MonthlyProfit('Aug', 500),
          MonthlyProfit('Sep', 550), MonthlyProfit('Oct', 200),
          MonthlyProfit('Nov', 180), MonthlyProfit('Dec', 220),
        ],
      ),
      CropProfit(
        cropName: 'Tomato',
        emoji: '🍅',
        profitPerHectare: 3800,
        marketPrice: 650,
        productionCost: 2400,
        growthPercent: 22.1,
        category: 'Vegetable',
        monthlyData: [
          MonthlyProfit('Jan', 900), MonthlyProfit('Feb', 1200),
          MonthlyProfit('Mar', 2200), MonthlyProfit('Apr', 3800),
          MonthlyProfit('May', 3200), MonthlyProfit('Jun', 2100),
          MonthlyProfit('Jul', 1400), MonthlyProfit('Aug', 1200),
          MonthlyProfit('Sep', 1600), MonthlyProfit('Oct', 2200),
          MonthlyProfit('Nov', 1800), MonthlyProfit('Dec', 1100),
        ],
      ),
      CropProfit(
        cropName: 'Rice',
        emoji: '🌿',
        profitPerHectare: 1680,
        marketPrice: 320,
        productionCost: 1200,
        growthPercent: 5.2,
        category: 'Cereal',
        monthlyData: [
          MonthlyProfit('Jan', 400), MonthlyProfit('Feb', 380),
          MonthlyProfit('Mar', 350), MonthlyProfit('Apr', 420),
          MonthlyProfit('May', 680), MonthlyProfit('Jun', 1100),
          MonthlyProfit('Jul', 1680), MonthlyProfit('Aug', 1500),
          MonthlyProfit('Sep', 1200), MonthlyProfit('Oct', 900),
          MonthlyProfit('Nov', 600), MonthlyProfit('Dec', 450),
        ],
      ),
      CropProfit(
        cropName: 'Saffron',
        emoji: '🌺',
        profitPerHectare: 14500,
        marketPrice: 3200,
        productionCost: 6800,
        growthPercent: 31.7,
        category: 'Spice',
        monthlyData: [
          MonthlyProfit('Jan', 2400), MonthlyProfit('Feb', 2100),
          MonthlyProfit('Mar', 1800), MonthlyProfit('Apr', 1400),
          MonthlyProfit('May', 900), MonthlyProfit('Jun', 700),
          MonthlyProfit('Jul', 800), MonthlyProfit('Aug', 1200),
          MonthlyProfit('Sep', 3200), MonthlyProfit('Oct', 14500),
          MonthlyProfit('Nov', 8200), MonthlyProfit('Dec', 3400),
        ],
      ),
      CropProfit(
        cropName: 'Maize',
        emoji: '🌽',
        profitPerHectare: 890,
        marketPrice: 180,
        productionCost: 680,
        growthPercent: 3.8,
        category: 'Cereal',
        monthlyData: [
          MonthlyProfit('Jan', 200), MonthlyProfit('Feb', 220),
          MonthlyProfit('Mar', 300), MonthlyProfit('Apr', 450),
          MonthlyProfit('May', 700), MonthlyProfit('Jun', 890),
          MonthlyProfit('Jul', 820), MonthlyProfit('Aug', 700),
          MonthlyProfit('Sep', 600), MonthlyProfit('Oct', 400),
          MonthlyProfit('Nov', 280), MonthlyProfit('Dec', 220),
        ],
      ),
    ];
  }

  // ── Best Crop Recommendation (ML over 10yr data) ─────────────────────────

  static Future<List<BestCropRecommendation>> getBestCropRecommendations(
      double lat, double lon) async {
    await Future.delayed(const Duration(milliseconds: 1800));
    return const [
      BestCropRecommendation(
        cropName: 'Wheat',
        emoji: '🌾',
        score: 94,
        climateMatch: 0.96,
        soilMatch: 0.93,
        profitability: 0.78,
        waterEfficiency: 0.88,
        reasoning:
            '12-year climate analysis shows consistent cool winters with 820mm annual rainfall — optimal for Rabi wheat. Soil moisture retention aligns with root development patterns.',
        pros: [
          'Climate perfectly matches wheat growing windows',
          'Government MSP guarantees stable income',
          'High mechanization potential reduces labor',
          'Strong local market demand',
        ],
        cons: [
          'Moderate profit margins vs. cash crops',
          'Susceptible to rust disease in humid years',
        ],
      ),
      BestCropRecommendation(
        cropName: 'Tomato',
        emoji: '🍅',
        score: 87,
        climateMatch: 0.81,
        soilMatch: 0.89,
        profitability: 0.96,
        waterEfficiency: 0.72,
        reasoning:
            'Drip-irrigated tomato cultivation shows 3x higher ROI. 10-year data shows 240+ sunny days ideal for fruit set. Market proximity adds premium pricing advantage.',
        pros: [
          'Highest profit per hectare in your region',
          'Year-round demand with cold storage',
          'Quick 3-4 month turnaround',
        ],
        cons: [
          'High water and labor requirement',
          'Price volatility during peak season',
          'Requires pest management investment',
        ],
      ),
      BestCropRecommendation(
        cropName: 'Soybean',
        emoji: '🫘',
        score: 79,
        climateMatch: 0.83,
        soilMatch: 0.75,
        profitability: 0.71,
        waterEfficiency: 0.91,
        reasoning:
            'Nitrogen-fixing soybean improves soil health after cereal crops. Climate analysis shows 110-day frost-free window aligns with soybean maturity period.',
        pros: [
          'Excellent for crop rotation with wheat',
          'Improves soil nitrogen naturally',
          'Low input cost, good ROI',
        ],
        cons: [
          'Lower absolute profit vs. vegetables',
          'Needs precise harvest timing',
        ],
      ),
    ];
  }

  // ── Smart Alerts ──────────────────────────────────────────────────────────

  static Future<List<WeatherAlert>> fetchSmartAlerts(
      double lat, double lon) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return const [
      WeatherAlert(
        title: 'Severe Storm Warning',
        description:
            'Thunderstorms with wind gusts up to 85 km/h expected tonight. Secure loose equipment and delay any spray operations.',
        severity: AlertSeverity.critical,
        time: 'Tonight, 8 PM – 2 AM',
        icon: '⛈️',
        isActive: true,
      ),
      WeatherAlert(
        title: 'Heavy Rainfall Alert',
        description:
            '80–120mm rainfall forecast over 48 hours. Waterlogging risk in low-lying fields. Consider drainage preparation.',
        severity: AlertSeverity.high,
        time: 'Tomorrow – Day after',
        icon: '🌧️',
        isActive: true,
      ),
      WeatherAlert(
        title: 'Frost Risk',
        description:
            'Temperature may drop to 2°C on Friday night. Young seedlings and flowering crops at risk. Consider protective covers.',
        severity: AlertSeverity.medium,
        time: 'Friday Night',
        icon: '🌨️',
        isActive: false,
      ),
      WeatherAlert(
        title: 'Heatwave Advisory',
        description:
            'Temperatures expected 4–5°C above seasonal average next week. Increase irrigation frequency and avoid midday fieldwork.',
        severity: AlertSeverity.medium,
        time: 'Next Week (Mon–Wed)',
        icon: '🌡️',
        isActive: false,
      ),
      WeatherAlert(
        title: 'Strong Wind',
        description:
            'Sustained winds 40–55 km/h. Pollination disruption risk for open-pollinated crops. Delay herbicide application.',
        severity: AlertSeverity.low,
        time: 'Wednesday Afternoon',
        icon: '💨',
        isActive: false,
      ),
      WeatherAlert(
        title: 'Pest Outbreak Conditions',
        description:
            'Warm humid conditions favorable for aphid and fungal disease spread. Scout fields and consider preventive application.',
        severity: AlertSeverity.low,
        time: 'This Week',
        icon: '🐛',
        isActive: false,
      ),
    ];
  }
}
