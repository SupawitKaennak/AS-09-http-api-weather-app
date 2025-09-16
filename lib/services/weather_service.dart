import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  static const String baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<WeatherData> getWeatherData(double latitude, double longitude) async {
    final url = Uri.parse(
      '$baseUrl?latitude=$latitude&longitude=$longitude'
      '&daily=temperature_2m_max,temperature_2m_min,precipitation_sum'
      '&timezone=Asia/Bangkok',
    );

    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      throw Exception('Error fetching weather data: $e');
    }
  }
}