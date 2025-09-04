import 'package:shared_preferences/shared_preferences.dart';
import 'package:weer_app/models/weeropslaan.dart';
import 'dart:convert'; // For JSON encoding/decoding
import 'package:weer_app/models/weer_model.dart';  // Add this import
import 'package:hive_flutter/hive_flutter.dart';

class SettingsStorage {
  static const String _weatherCacheKey = 'weatherCache';
  static final _mybox = Hive.box('mybox');
  static const String _pagesKey = 'pages';


  /// Load all pages’ settings
  static List<Map<String, dynamic>> loadPages() {
    final List<dynamic>? rawList = _mybox.get(_pagesKey);

    if (rawList == null) return [];

    return rawList.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Save all pages’ settings
  static Future<void> savePages(List<Map<String, dynamic>> pages) async {
    await _mybox.put(_pagesKey, pages);
  }

  /// Add a new page
  static Future<void> addPage(Map<String, dynamic> pageSettings) async {
    print('addpage');
    final pages = loadPages();
    pages.add(pageSettings);
    await savePages(pages);
  }

  /// Remove a page by index
  static Future<void> removePage(int index) async {
    final pages = loadPages();
    if (index >= 0 && index < pages.length) {
      pages.removeAt(index);
      await savePages(pages);
    }
  }

  /// Edit page at index
  static Future<void> editPage(int index, Map<String, dynamic> newSettings) async {
    final pages = loadPages(); // assuming this returns a List<Map<String, dynamic>>
    if (index >= 0 && index < pages.length) {
      final currentSettings = Map<String, dynamic>.from(pages[index]);
      currentSettings.addAll(newSettings); // merge: overwrite only provided keys
      pages[index] = currentSettings;
      await savePages(pages);
    }
  }



  static Future<void> saveLocationInfo(double? lat, double? long, DateTime? locationtime) async {
    _mybox.put(2, lat);
    _mybox.put(3, long);
    _mybox.put(4, locationtime);
    print('savinglocation, time:');
    print(_mybox.get(4));
  }

  static Future<(double?, double?, DateTime?)> loadLocationInfo() async {
    try {
      final double? lat = _mybox.get(2);
      final double? long = _mybox.get(3);
      final DateTime? locationtime = _mybox.get(4);
      return (lat, long, locationtime);
    } catch (e) {
      print('therewas an error while tring to load the location:');
      print(e);
      return (null,null,null);
    }
  }

  // Save weather cache entries
  static Future<void> saveWeatherCache(List<WeatherCacheEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Convert entries to JSON-encodable maps
    final entriesJson = entries.map((entry) => {
      'cityName': entry.cityName,
      'lat': entry.lat,
      'lon': entry.lon,
      'weather': entry.weather.toJson(), // Assuming Weather has a toJson method
      'timestamp': entry.timestamp.toIso8601String(),
      'icon': entry.icon,
    }).toList();
    print(" entriesJson:");
    print(entriesJson);
    // Convert to JSON string and save
    await prefs.setString(_weatherCacheKey, jsonEncode(entriesJson));
  }

  // Load weather cache entries
  static Future<List<WeatherCacheEntry>> loadWeatherCache() async {


    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_weatherCacheKey);
    
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => WeatherCacheEntry(
        cityName: json['cityName'],
        lat: json['lat'],
        lon: json['lon'],
        weather: Weather.fromJson(json['weather']), // Assuming Weather has a fromJson method
        timestamp: DateTime.parse(json['timestamp']),
        icon: json['icon'],
      )).toList();
    } catch (e) {
      print('Error loading weather cache: $e');
      return [];
    }
  }
}