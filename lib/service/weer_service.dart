import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:weer_app/service/shared_prefs_helper.dart';
import '../models/weer_model.dart';
import 'package:http/http.dart' as http;
import 'package:weer_app/models/weeropslaan.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';


class WeatherService {
  static const BASE_URL = 'https://api.openweathermap.org/data/2.5/weather';
  final String apiKey;
  List<WeatherCacheEntry> _weatherCache = [];
  


  WeatherService(this.apiKey);
  
  Future<String?> permissioninfo() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return ('denied');
    } else if (permission == LocationPermission.unableToDetermine) {
      return ('geenlocatieinfo');
    }
    return ("laden");
  }

  Future<(Weather?, bool)> getWeather(String? cityName, double? latitude, double? longitude, Locale? myLocale) async {
    Uri apiUri;
    
    if (latitude != null && longitude != null) {
      // Use latitude and longitude if provided
      apiUri = Uri.parse('$BASE_URL?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric&lang=$myLocale');
      print(apiUri);
      print('DEBUG: Using coordinates for API call: lat=$latitude, lon=$longitude');
    } else if (cityName != null && cityName.isNotEmpty) {
      // Use city name if coordinates are not provided but city name is
      apiUri = Uri.parse('$BASE_URL?q=$cityName&appid=$apiKey&units=metric&lang=$myLocale');
      print(apiUri);
      print('DEBUG: Using city name for API call: $cityName');
    } else {
      // Throw an error if neither coordinates nor city name are provided
      throw Exception('Invalid input: Either cityName or latitude and longitude must be provided.');
    }

    try {
      final response = await http.get(apiUri);

      print('DEBUG: API Response Status Code: ${response.statusCode}');
      print('DEBUG: API Response Body: ${response.body}');
      print(response.statusCode == 404);

      if (response.statusCode == 200) {
        // Decode the JSON response and create a Weather object
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final weather = Weather.fromJson(jsonResponse);
        print("DEBUG: Weather data loaded successfully: $weather");

        
        return (weather, false);
      } else if (response.statusCode == 404) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final weather = WeatherError.fromJson(jsonResponse);
        if (weather.message == 'city not found') {
          return (null, true);
        }
        throw Exception('Failed to load weather data. Status: ${response.statusCode}, Body: ${response.body}');

      } else {
        // Handle non-200 status codes with a more informative error message
        throw Exception('Failed to load weather data. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      // Catch any network or parsing errors
      print('ERROR: Failed to fetch weather: $e');
      
      print('Failed to load weather: $e');
      
      return (null, false);
    }
  }

  void _cleanExpiredCache() {
    final now = DateTime.now();
    for(var item in _weatherCache) {
      print(item);
      print(item.cityName);
      print(item.timestamp);
      print(now.difference(item.timestamp).inMinutes/20 + 
      now.difference(item.timestamp).inSeconds * item.weather.windspeed / 17000);
    }
    _weatherCache.removeWhere((entry) => (
      now.difference(entry.timestamp).inMinutes/20 + 
      now.difference(entry.timestamp).inSeconds * entry.weather.windspeed / 17000
      >= 12));  
  }

  (Weather?, double) getCachedWeather({String? city, double? lat, double? lon}) {
    if (_weatherCache.isEmpty) {
      print("_weatherCache is empty");
      return (null,12);
    }
    //_cleanExpiredCache(lat,lon);
    final now = DateTime.now();
    if (lat == null) {
      Weather? wheather = _weatherCache.firstWhereOrNull((entry) => 
        (entry.cityName == city))?.weather;
      (lon, lat) = (wheather?.longitude, wheather?.latitude);
    }
    
    List<WeatherCacheEntry> toRemove = [];
    print("lat");
    print(lat);
    double leastvalue = 10;
    WeatherCacheEntry? leastvalueitem;
    if (lat != null && lon != null) {
      for(var item in _weatherCache) {
        double value = now.difference(item.timestamp).inMinutes/20 + 
          now.difference(item.timestamp).inSeconds * item.weather.windspeed / 17000;
        print("item:");
        print(item.cityName);
        print("value:");
        print(value);
        print(now.difference(item.timestamp).inMinutes/20);
        print(Geolocator.distanceBetween(item.lat!, item.lon!, lat, lon) / 18);
        print(now.difference(item.timestamp).inSeconds * item.weather.windspeed / 17000);
        if (value < leastvalue) {
          value += Geolocator.distanceBetween(item.lat!, item.lon!, lat, lon) / 18;
          if (value < leastvalue) {
            leastvalueitem = item;
            leastvalue = value;
          }
        } else if (value >= 10) {
          toRemove.add(item);
        }
      }
      _weatherCache.removeWhere((e) => toRemove.contains(e));
      print('leastvalueitem:');
      print(leastvalueitem?.weather.cityName);
      return (leastvalueitem?.weather, leastvalue);
    } else {

      for(var item in _weatherCache) {
        if (item.cityName == city) {
          double value = now.difference(item.timestamp).inMinutes/20 + 
            now.difference(item.timestamp).inSeconds * item.weather.windspeed / 17000;
          print("item:");
          print(item.cityName);
          print("value:");
          print(value);
          print(now.difference(item.timestamp).inMinutes/20);
          print(now.difference(item.timestamp).inSeconds * item.weather.windspeed / 17000);
          if (value < leastvalue) {
            leastvalueitem = item;
            leastvalue = value;
          } else if (value >= 10) {
            toRemove.add(item);
          }
        }
      }
      _weatherCache.removeWhere((e) => toRemove.contains(e));
      print('leastvalueitem:');
      print(leastvalueitem?.weather.cityName);
      return (leastvalueitem?.weather, leastvalue);
    }
  }

  //TODO: change the amount for the thingy

  void addToCache(
      String? cityName,
      double? lat,
      double? lon,
      Weather weather,
      String icon)
    {

    // Remove existing entry for same location
    _weatherCache.removeWhere((entry) => 
        (entry.cityName == cityName) ||
        (entry.lat == lat && entry.lon == lon)
    );

    print("add entry to the list:");
    print(cityName);
    _weatherCache.add(WeatherCacheEntry(
      cityName: cityName,
      lat: lat,
      lon: lon,
      weather: weather,
      timestamp: DateTime.now(),
      icon: icon,
    ));

    savetodevise();
  }

  Future<void> savetodevise() async {
    await SettingsStorage.saveWeatherCache(_weatherCache);
  }

  Future<bool> load () async {
    print(" lkfdsajlkdsafjlkasjflksadjfalksjfas");
    _weatherCache = await SettingsStorage.loadWeatherCache();
    _cleanExpiredCache();
    savetodevise();
    print(" wheathercache:");
    print(_weatherCache);
    //print(_weatherCache.first.cityName);
    //print(_weatherCache.first.timestamp);
    return _weatherCache.isNotEmpty;
  }
}