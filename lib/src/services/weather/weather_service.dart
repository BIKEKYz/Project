import 'dart:convert';
import 'package:http/http.dart' as http;

// Weather API Service for dynamic care scheduling
class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  // Use OpenWeatherMap API (free tier)
  static const String _apiKey = 'YOUR_API_KEY_HERE';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  /// Get current weather for location
  Future<Weather> getCurrentWeather(double lat, double lon) async {
    try {
      final url =
          '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Weather.fromJson(data);
      } else {
        throw WeatherException('Failed to fetch weather');
      }
    } catch (e) {
      // Return default/cached weather if API fails
      return Weather.defaultWeather();
    }
  }

  /// Get 5-day forecast
  Future<List<WeatherDay>> getForecast(int days) async {
    // TODO: Implement forecast API
    return [];
  }

  /// Determine if should water today
  Future<WateringRecommendation> shouldWaterToday(
    String plantId,
    DateTime lastWatered,
  ) async {
    // Get current location (would use GPS)
    final weather = await getCurrentWeather(13.7563, 100.5018); // Bangkok

    // Check if rain is forecasted
    if (weather.isRainy) {
      return WateringRecommendation(
        shouldWater: false,
        reason: 'ฝนตกอยู่ รอฝนหยุดก่อน',
        reasonEn: 'It\'s raining, wait for rain to stop',
        nextBestTime: DateTime.now().add(const Duration(days: 1)),
      );
    }

    // Check if very hot (water more)
    if (weather.temperature > 35) {
      return WateringRecommendation(
        shouldWater: true,
        reason: 'อากาศร้อนมาก พืชต้องการน้ำเพิ่ม',
        reasonEn: 'Very hot weather, plant needs more water',
        nextBestTime: DateTime.now(),
      );
    }

    // Check humidity
    if (weather.humidity > 80) {
      return WateringRecommendation(
        shouldWater: false,
        reason: 'ความชื้นสูง รอให้ดินแห้งก่อน',
        reasonEn: 'High humidity, wait for soil to dry',
        nextBestTime: DateTime.now().add(const Duration(days: 1)),
      );
    }

    return WateringRecommendation(
      shouldWater: true,
      reason: 'สภาพอากาศเหมาะสม',
      reasonEn: 'Weather conditions are suitable',
      nextBestTime: DateTime.now(),
    );
  }
}

class Weather {
  final double temperature;
  final double humidity;
  final String condition;
  final bool isRainy;
  final double windSpeed;
  final DateTime timestamp;

  Weather({
    required this.temperature,
    required this.humidity,
    required this.condition,
    required this.isRainy,
    required this.windSpeed,
    required this.timestamp,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    final main = json['main'];
    final weather = json['weather'][0];
    final wind = json['wind'];

    return Weather(
      temperature: main['temp'].toDouble(),
      humidity: main['humidity'].toDouble(),
      condition: weather['main'],
      isRainy: weather['main'] == 'Rain',
      windSpeed: wind['speed'].toDouble(),
      timestamp: DateTime.now(),
    );
  }

  factory Weather.defaultWeather() {
    return Weather(
      temperature: 28,
      humidity: 65,
      condition: 'Clear',
      isRainy: false,
      windSpeed: 5,
      timestamp: DateTime.now(),
    );
  }

  String get conditionThai {
    switch (condition) {
      case 'Clear':
        return 'ท้องฟ้าแจ่มใส';
      case 'Clouds':
        return 'มีเมฆ';
      case 'Rain':
        return 'ฝนตก';
      case 'Thunderstorm':
        return 'พายุฝนฟ้าคะนอง';
      default:
        return condition;
    }
  }
}

class WeatherDay {
  final DateTime date;
  final double tempMax;
  final double tempMin;
  final String condition;
  final double rainChance;

  WeatherDay({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.condition,
    required this.rainChance,
  });
}

class WateringRecommendation {
  final bool shouldWater;
  final String reason;
  final String reasonEn;
  final DateTime nextBestTime;

  WateringRecommendation({
    required this.shouldWater,
    required this.reason,
    required this.reasonEn,
    required this.nextBestTime,
  });
}

class WeatherException implements Exception {
  final String message;
  WeatherException(this.message);

  @override
  String toString() => message;
}
