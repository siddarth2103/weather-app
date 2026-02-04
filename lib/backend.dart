import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';


class WeatherService {
  final String weatherApiKey = "9c6217238139dea6696ca7518fe4d894";
  final String waqiToken = "38bfd2f7411f2e37541a22e191616d3a64442a3d";

  final String geoUrl = "https://api.openweathermap.org/geo/1.0/direct";
  final String weatherUrl = "https://api.openweathermap.org/data/2.5/weather";

  Future<Map<String, dynamic>?> getWeather(String city) async {
    try {
      // 1️⃣ Get coordinates
      final geoResponse = await http.get(
        Uri.parse('$geoUrl?q=$city&limit=1&appid=$weatherApiKey'),
      );

      if (geoResponse.statusCode != 200) return null;

      final geoData = jsonDecode(geoResponse.body);
      if (geoData.isEmpty) return null;

      final double lat = geoData[0]['lat'];
      final double lon = geoData[0]['lon'];

      // 2️⃣ Get weather
      final weatherResponse = await http.get(
        Uri.parse(
          '$weatherUrl?lat=$lat&lon=$lon&appid=$weatherApiKey&units=metric',
        ),
      );

      if (weatherResponse.statusCode != 200) return null;

      final weatherData = jsonDecode(weatherResponse.body);

      // 3️⃣ Get WAQI AQI
      final waqiResponse = await http.get(
        Uri.parse(
          'https://api.waqi.info/feed/geo:$lat;$lon/?token=$waqiToken',
        ),
      );

      if (waqiResponse.statusCode == 200) {
        final waqiData = jsonDecode(waqiResponse.body);

        if (waqiData['status'] == 'ok') {
          final rawAqi = waqiData['data']['aqi'];

          if (rawAqi is int) {
            weatherData['waqi_aqi'] = rawAqi;
          } else if (rawAqi is String) {
            weatherData['waqi_aqi'] = int.tryParse(rawAqi);
          } else {
            weatherData['waqi_aqi'] = null;
          }
        }
      }

      return weatherData;
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getCitySuggestions(String input) async {
    final url = "https://api.openweathermap.org/geo/1.0/direct"
        "?q=$input"
        "&limit=5"
        "&appid=$weatherApiKey";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);

      return data.map<Map<String, dynamic>>((city) {
        return {
          'name': city['name'],
          'country': city['country'],
          'lat': city['lat'],
          'lon': city['lon'],
        };
      }).toList();
    }

    return [];
  }

  Future<List<dynamic>?> get5DayForecast(double lat, double lon) async {
    final url =
        "https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$weatherApiKey&units=metric";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['list'];
    }
    return null;
  }

  Future<int?> getAqiByLatLon(double lat, double lon) async {
    final url = "https://api.waqi.info/feed/geo:$lat;$lon/?token=$waqiToken";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data']?['aqi'];
    }
    return null;
  }

  List<Map<String, dynamic>> getDailyMinMax(List<dynamic> forecastList) {
  Map<String, List<dynamic>> dayWiseData = {};

  for (var item in forecastList) {
    String date = item['dt_txt'].split(' ')[0];

    dayWiseData.putIfAbsent(date, () => []);
    dayWiseData[date]!.add(item);
  }

  List<Map<String, dynamic>> result = [];

  dayWiseData.forEach((date, items) {
    double minTemp = double.infinity;
    double maxTemp = -double.infinity;
    String condition = items[items.length ~/ 2]['weather'][0]['main']; // noon weather

    for (var item in items) {
      double temp = item['main']['temp'].toDouble();
      minTemp = min(minTemp, temp);
      maxTemp = max(maxTemp, temp);
    }

    result.add({
      'day': getDayName(date),
      'min': minTemp,
      'max': maxTemp,
      'weather': condition,
    });
  });

  return result.take(5).toList();
}

  Future<Map<String, dynamic>?> getWeatherByLatLon(
      double lat, double lon) async {
    final url = "https://api.openweathermap.org/data/2.5/weather"
        "?lat=$lat&lon=$lon"
        "&appid=$weatherApiKey"
        "&units=metric";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }

  String formatCityName(Map<String, dynamic> place) {
  final city = place['name'];
  final state = place['state'];
  final country = place['country'];

  if (state != null && state.toString().isNotEmpty) {
    return '$city, $state, $country';
  }
  return '$city, $country';
}

  String getDayName(String date) {
    final dateTime = DateTime.parse(date);
    switch (dateTime.weekday) {
      case DateTime.monday:
        return "Monday";
      case DateTime.tuesday:
        return "Tuesday";
      case DateTime.wednesday:
        return "Wednesday";
      case DateTime.thursday:
        return "Thursday";
      case DateTime.friday:
        return "Friday";
      case DateTime.saturday:
        return "Saturday";
      case DateTime.sunday:
        return "Sunday";
      default:
        return "";
    }
  }
}
