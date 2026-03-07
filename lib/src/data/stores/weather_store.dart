import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/weather/weather_service.dart';

enum WeatherLoadState { idle, loading, loaded, error, permissionDenied }

class WeatherStore extends ChangeNotifier {
  final WeatherService _service = WeatherService();

  WeatherLoadState _state = WeatherLoadState.idle;
  Weather? _weather;
  String? _errorMessage;
  List<WeatherPlantTip> _tips = [];

  WeatherLoadState get state => _state;
  Weather? get weather => _weather;
  String? get errorMessage => _errorMessage;
  List<WeatherPlantTip> get tips => _tips;

  bool get isLoading => _state == WeatherLoadState.loading;
  bool get hasData => _weather != null;
  bool get isPermissionDenied => _state == WeatherLoadState.permissionDenied;

  /// ── Main entry: request location then fetch weather ─────────────────────
  Future<void> fetchWeather() async {
    if (_state == WeatherLoadState.loading) return;

    _state = WeatherLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final coords = await _getLocationCoords();
      if (coords != null) {
        _weather = await _service.getWeatherByCoords(
          coords.$1,
          coords.$2,
        );
      } else {
        // Fallback: use Bangkok (Thailand's capital — closest to likely locale)
        _weather = await _service.getWeatherByCity('Bangkok');
      }
      _tips = WeatherService.getTipsForWeather(_weather!);
      _state = WeatherLoadState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = WeatherLoadState.error;
      // Still show default weather with tips
      _weather = Weather.defaultWeather();
      _tips = WeatherService.getTipsForWeather(_weather!);
    }

    notifyListeners();
  }

  /// ── Location helper — returns (lat, lon) or null ─────────────────────────
  Future<(double, double)?> _getLocationCoords() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('📍 Location service disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _state = WeatherLoadState.permissionDenied;
          debugPrint('📍 Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _state = WeatherLoadState.permissionDenied;
        debugPrint('📍 Location permission denied forever');
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      );
      debugPrint('📍 Location: ${pos.latitude}, ${pos.longitude}');
      return (pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint('📍 Location error: $e');
      return null;
    }
  }

  /// ── Manual refresh ────────────────────────────────────────────────────────
  Future<void> refresh() async {
    _state = WeatherLoadState.idle;
    await fetchWeather();
  }
}
