import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ─── Weather Condition Enum ───────────────────────────────────────────────────
enum WeatherType {
  clear,
  clouds,
  rain,
  drizzle,
  thunderstorm,
  hot,
  dry,
  humid,
  unknown,
}

// ─── Weather Model ────────────────────────────────────────────────────────────
class Weather {
  final double temperature;
  final double humidity;
  final double feelsLike;
  final String condition; // API raw: "Clear", "Clouds", etc.
  final String description;
  final bool isRainy;
  final double windSpeed;
  final String cityName;
  final DateTime timestamp;

  const Weather({
    required this.temperature,
    required this.humidity,
    required this.feelsLike,
    required this.condition,
    required this.description,
    required this.isRainy,
    required this.windSpeed,
    required this.cityName,
    required this.timestamp,
  });

  // ── Derived state ──────────────────────────────────────────────────────────
  bool get isHot => temperature > 35;
  bool get isDry => humidity < 40;
  bool get isHumid => humidity > 75;
  bool get isThunderstorm => condition == 'Thunderstorm';
  bool get isCloudy => condition == 'Clouds';
  bool get isClear => condition == 'Clear';

  WeatherType get type {
    if (isThunderstorm) return WeatherType.thunderstorm;
    if (isRainy) return WeatherType.rain;
    if (condition == 'Drizzle') return WeatherType.drizzle;
    if (isHot) return WeatherType.hot;
    if (isDry) return WeatherType.dry;
    if (isHumid) return WeatherType.humid;
    if (isCloudy) return WeatherType.clouds;
    if (isClear) return WeatherType.clear;
    return WeatherType.unknown;
  }

  String get emoji {
    switch (type) {
      case WeatherType.rain:
        return '🌧️';
      case WeatherType.drizzle:
        return '🌦️';
      case WeatherType.thunderstorm:
        return '⛈️';
      case WeatherType.hot:
        return '🔥';
      case WeatherType.dry:
        return '🏜️';
      case WeatherType.humid:
        return '💧';
      case WeatherType.clouds:
        return '☁️';
      case WeatherType.clear:
        return '☀️';
      default:
        return '🌡️';
    }
  }

  String get conditionThai {
    if (isHot && condition == 'Clear') return 'อากาศร้อนจัด 🔥';
    if (isDry) return 'อากาศแห้งมาก';
    if (isHumid && !isRainy) return 'ความชื้นสูง';
    switch (condition) {
      case 'Clear':
        return 'ท้องฟ้าแจ่มใส';
      case 'Clouds':
        return 'ท้องฟ้ามีเมฆ';
      case 'Rain':
        return 'ฝนตก';
      case 'Drizzle':
        return 'ฝนตกปรอยๆ';
      case 'Thunderstorm':
        return 'พายุฝนฟ้าคะนอง';
      case 'Snow':
        return 'หิมะตก';
      case 'Mist':
      case 'Fog':
        return 'หมอกหนา';
      default:
        return condition;
    }
  }

  String get conditionEn {
    if (isHot && isClear) return 'Scorching Hot';
    if (isDry) return 'Very Dry';
    if (isHumid && !isRainy) return 'Very Humid';
    switch (condition) {
      case 'Clear':
        return 'Clear Sky';
      case 'Clouds':
        return 'Cloudy';
      case 'Rain':
        return 'Rainy';
      case 'Drizzle':
        return 'Light Rain';
      case 'Thunderstorm':
        return 'Thunderstorm';
      default:
        return condition;
    }
  }

  // ── JSON serialization ─────────────────────────────────────────────────────
  factory Weather.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final weatherArr = json['weather'] as List;
    final weatherInfo = weatherArr[0] as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>? ?? {};
    final name = json['name'] as String? ?? '';

    final cond = weatherInfo['main'] as String? ?? 'Unknown';
    final desc = weatherInfo['description'] as String? ?? '';
    final temp = (main['temp'] as num).toDouble();
    final hum = (main['humidity'] as num).toDouble();
    final feels = (main['feels_like'] as num?)?.toDouble() ?? temp;
    final wind0 = (wind['speed'] as num?)?.toDouble() ?? 0;

    return Weather(
      temperature: temp,
      humidity: hum,
      feelsLike: feels,
      condition: cond,
      description: desc,
      isRainy: cond == 'Rain' || cond == 'Drizzle',
      windSpeed: wind0,
      cityName: name,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJsonCache() => {
        'temperature': temperature,
        'humidity': humidity,
        'feelsLike': feelsLike,
        'condition': condition,
        'description': description,
        'isRainy': isRainy,
        'windSpeed': windSpeed,
        'cityName': cityName,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory Weather.fromJsonCache(Map<String, dynamic> j) => Weather(
        temperature: (j['temperature'] as num).toDouble(),
        humidity: (j['humidity'] as num).toDouble(),
        feelsLike: (j['feelsLike'] as num).toDouble(),
        condition: j['condition'] as String,
        description: j['description'] as String,
        isRainy: j['isRainy'] as bool,
        windSpeed: (j['windSpeed'] as num).toDouble(),
        cityName: j['cityName'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(j['timestamp'] as int),
      );

  // ── Default (Bangkok) ──────────────────────────────────────────────────────
  factory Weather.defaultWeather() => Weather(
        temperature: 30,
        humidity: 65,
        feelsLike: 34,
        condition: 'Clear',
        description: 'clear sky',
        isRainy: false,
        windSpeed: 3,
        cityName: 'Bangkok',
        timestamp: DateTime.now(),
      );
}

// ─── Weather-based Plant Recommendation ───────────────────────────────────────
class WeatherPlantTip {
  final String emoji;
  final String titleTh;
  final String titleEn;
  final String tipTh;
  final String tipEn;
  final List<String> suggestedPlantIds;

  /// ARGB int — use Color(accentColorValue) in UI layer
  final int accentColorValue;

  const WeatherPlantTip({
    required this.emoji,
    required this.titleTh,
    required this.titleEn,
    required this.tipTh,
    required this.tipEn,
    required this.suggestedPlantIds,
    required this.accentColorValue,
  });
}

// ─── Weather Service ──────────────────────────────────────────────────────────
class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  /// ⚠️  Replace with your OpenWeatherMap API key (free)
  /// https://openweathermap.org/api  →  Current weather API
  static const String _apiKey = 'dfc295a9491de3dcf7e7a9bb66557d05';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _cacheKey = 'weather_cache_v2';
  static const Duration _cacheTtl = Duration(minutes: 30);

  // ── Fetch by lat/lon ───────────────────────────────────────────────────────
  Future<Weather> getWeatherByCoords(double lat, double lon) async {
    try {
      final url =
          '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric';
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final weather = Weather.fromJson(data);
        await _saveCache(weather);
        return weather;
      } else {
        debugPrint('⚠️ Weather API ${response.statusCode}: ${response.body}');
        return await _loadCacheOrDefault();
      }
    } catch (e) {
      debugPrint('⚠️ Weather fetch error: $e');
      return await _loadCacheOrDefault();
    }
  }

  // ── Fetch by city name ─────────────────────────────────────────────────────
  Future<Weather> getWeatherByCity(String city) async {
    try {
      final url =
          '$_baseUrl/weather?q=${Uri.encodeComponent(city)}&appid=$_apiKey&units=metric';
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final weather = Weather.fromJson(data);
        await _saveCache(weather);
        return weather;
      }
      return await _loadCacheOrDefault();
    } catch (e) {
      return await _loadCacheOrDefault();
    }
  }

  // ── Cache ──────────────────────────────────────────────────────────────────
  Future<void> _saveCache(Weather weather) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(weather.toJsonCache()));
    } catch (_) {}
  }

  Future<Weather> _loadCacheOrDefault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null) {
        final cached =
            Weather.fromJsonCache(json.decode(raw) as Map<String, dynamic>);
        if (DateTime.now().difference(cached.timestamp) < _cacheTtl) {
          return cached;
        }
      }
    } catch (_) {}
    return Weather.defaultWeather();
  }

  // ── Generate tips based on current weather ────────────────────────────────
  static List<WeatherPlantTip> getTipsForWeather(Weather w) {
    final tips = <WeatherPlantTip>[];

    // Rain
    if (w.isRainy) {
      tips.add(const WeatherPlantTip(
        emoji: '🌧️',
        titleTh: 'วันนี้ฝนตก — งดรดน้ำ',
        titleEn: 'Rainy Day — Skip Watering',
        tipTh: 'ความชื้นในอากาศสูง ไม่จำเป็นต้องรดน้ำ ระวังน้ำขังในกระถาง!',
        tipEn: 'Air humidity is high. Skip watering to avoid root rot.',
        suggestedPlantIds: ['cactus', 'succulent', 'jade_plant', 'sansevieria'],
        accentColorValue: 0xFF4FC3F7,
      ));
    }

    // Thunderstorm
    if (w.isThunderstorm) {
      tips.add(const WeatherPlantTip(
        emoji: '⛈️',
        titleTh: 'พายุฝน — ย้ายต้นไม้เข้าใน',
        titleEn: 'Storm Alert — Move Plants Indoors',
        tipTh: 'ลมแรงและฝนหนัก อาจทำให้ต้นไม้หักหรือรากเน่าได้',
        tipEn: 'Strong winds and heavy rain may break stems or cause root rot.',
        suggestedPlantIds: ['pothos', 'philodendron', 'chinese_evergreen'],
        accentColorValue: 0xFF7E57C2,
      ));
    }

    // Very hot
    if (w.isHot) {
      tips.add(const WeatherPlantTip(
        emoji: '🔥',
        titleTh: 'อากาศร้อนจัด — รดน้ำเพิ่ม',
        titleEn: 'Scorching Hot — Water More',
        tipTh: 'อุณหภูมิสูงกว่า 35°C พืชระเหยน้ำเร็ว รดน้ำเช้า-เย็น',
        tipEn: 'Above 35°C — plants transpire fast. Water morning & evening.',
        suggestedPlantIds: [
          'boston_fern',
          'peace_lily',
          'calathea',
          'monstera'
        ],
        accentColorValue: 0xFFFF7043,
      ));
    }

    // Dry air
    if (w.isDry) {
      tips.add(const WeatherPlantTip(
        emoji: '🏜️',
        titleTh: 'อากาศแห้ง — ZZ Plant เหมาะที่สุด',
        titleEn: 'Dry Air — ZZ Plant Thrives',
        tipTh:
            'ความชื้นต่ำกว่า 40% ต้นไม้ทนแล้งสบายมาก ต้นชอบชื้นควรพ่นน้ำที่ใบ',
        tipEn:
            'Humidity < 40%. Drought-tolerant plants thrive. Mist sensitive ones.',
        suggestedPlantIds: [
          'zz_plant',
          'sansevieria',
          'cactus',
          'jade_plant',
          'aloe_vera'
        ],
        accentColorValue: 0xFFFFB74D,
      ));
    }

    // Very humid (not rainy)
    if (w.isHumid && !w.isRainy) {
      tips.add(const WeatherPlantTip(
        emoji: '💧',
        titleTh: 'ความชื้นสูง — ลดการรดน้ำ',
        titleEn: 'High Humidity — Water Less',
        tipTh: 'ความชื้นสูงกว่า 75% ดินอาจยังชื้น ตรวจดินก่อนรดน้ำทุกครั้ง',
        tipEn:
            'Humidity > 75%. Soil stays moist longer. Check before watering.',
        suggestedPlantIds: ['monstera', 'calathea', 'boston_fern', 'orchid'],
        accentColorValue: 0xFF26C6DA,
      ));
    }

    // Clear + mild — perfect watering day
    if (w.isClear && !w.isHot && !w.isDry && w.temperature >= 21) {
      tips.add(const WeatherPlantTip(
        emoji: '☀️',
        titleTh: 'วันอากาศดี — เหมาะรดน้ำ',
        titleEn: 'Perfect Day to Water',
        tipTh: 'อากาศแจ่มใส อุณหภูมิพอดี เหมาะสำหรับรดน้ำและดูแลต้นไม้',
        tipEn:
            'Beautiful conditions — great day to water and check your plants.',
        suggestedPlantIds: [
          'pothos',
          'philodendron',
          'spider_plant',
          'dracaena'
        ],
        accentColorValue: 0xFF66BB6A,
      ));
    }

    // Cloudy
    if (w.isCloudy && !w.isRainy) {
      tips.add(const WeatherPlantTip(
        emoji: '☁️',
        titleTh: 'ฟ้าครึ้ม — แสงน้อยลง',
        titleEn: 'Overcast — Less Light Today',
        tipTh: 'แสงรำไร เหมาะกับต้นไม้ทนร่ม อย่าเพิ่งย้ายไปที่แดดจัด',
        tipEn: 'Low-light plants love this. Avoid moving sun-lovers outside.',
        suggestedPlantIds: [
          'pothos',
          'chinese_evergreen',
          'zz_plant',
          'sansevieria',
          'philodendron',
        ],
        accentColorValue: 0xFF90A4AE,
      ));
    }

    // Default fallback
    if (tips.isEmpty) {
      tips.add(const WeatherPlantTip(
        emoji: '🌿',
        titleTh: 'สภาพอากาศปกติ',
        titleEn: 'Normal Weather',
        tipTh: 'สภาพอากาศเหมาะสม ดูแลต้นไม้ตามปกติได้เลย',
        tipEn: 'Normal conditions — stick to your regular care routine.',
        suggestedPlantIds: ['pothos', 'philodendron', 'spider_plant', 'bamboo'],
        accentColorValue: 0xFF81C784,
      ));
    }

    return tips;
  }
}

class WeatherException implements Exception {
  final String message;
  WeatherException(this.message);
  @override
  String toString() => message;
}
