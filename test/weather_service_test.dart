import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/backend.dart';

void main() {
  final weatherService = WeatherService();

  test('Fetches weather data successfully for a valid city', () async {
    final result = await weatherService.getWeather('Delhi');
    expect(result, isNotNull);
    expect(result!['name'], equals('Delhi'));
  });

  test('Throws exception for invalid city', () async {
    expect(() => weatherService.getWeather('InvalidCity123'), throwsException);
  });
}
