import 'package:weer_app/models/weer_model.dart';

class WeatherCacheEntry {
  final String? cityName;
  final double? lat;
  final double? lon;
  final Weather weather;
  final DateTime timestamp;
  final String icon;

  WeatherCacheEntry({
    this.cityName,
    this.lat,
    this.lon,
    required this.weather,
    required this.timestamp,
    required this.icon,
  });
}