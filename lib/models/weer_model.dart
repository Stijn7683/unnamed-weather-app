class Weather {
  final String cityName;
  final double temperature;
  final String mainCondition;
  final String description;
  final double windspeed;
  final double longitude;
  final double latitude;
  final String icon;
  final String? message;
  final double temp_min;
  final double temp_max;

  Weather({
    required this.cityName,
    required this.temperature,
    required this.mainCondition,
    required this.description,
    required this.windspeed,
    required this.longitude,
    required this.latitude,
    required this.icon,
    this.message,
    required this.temp_min,
    required this.temp_max,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      cityName: json['name'],
      temperature: json['main']['temp'].toDouble(),
      temp_min: json['main']['temp_min'].toDouble(),
      temp_max: json['main']['temp_max'].toDouble(),
      mainCondition: json['weather'][0]['main'],
      description: json['weather'][0]['description'],
      windspeed: json['wind']['speed'].toDouble(),
      longitude: json['coord']['lon'].toDouble(),
      latitude: json['coord']['lat'].toDouble(),
      icon: json['weather'][0]['icon'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': cityName,
      'main': {
        'temp': temperature,
        'temp_min': temp_min,
        'temp_max': temp_max,
      },
      'weather': [
        {
          'main': mainCondition,
          'description': description,
          'icon': icon,
        }
      ],
      'wind': {
        'speed': windspeed,
      },
      'coord': {
        'lon': longitude,
        'lat': latitude,
      },
    };
  }
}

class WeatherError {
  final String? message;

  WeatherError({
    this.message,
  });

  factory WeatherError.fromJson(Map<String, dynamic> json) {
    return WeatherError(
      message: json['message'],
    );
  }
}