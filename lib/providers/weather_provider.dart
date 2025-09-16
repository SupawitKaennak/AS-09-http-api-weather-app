import 'package:flutter/foundation.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';

class WeatherProvider with ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  WeatherData? _weatherData;
  bool _isLoading = false;
  String? _error;

  WeatherData? get weatherData => _weatherData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchWeatherData(double latitude, double longitude) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _weatherData = await _weatherService.getWeatherData(latitude, longitude);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _weatherData = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}