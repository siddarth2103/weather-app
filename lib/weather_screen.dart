import 'package:flutter/material.dart';
import 'backend.dart';
import 'package:lottie/lottie.dart';
import 'package:country_picker/country_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

enum WindUnit { ms, kmh, mph, knots }

enum VisibilityUnit { km, miles }

enum PressureUnit { hpa, mmhg, atm }

class WeatherScreen extends StatefulWidget {
  final String city;
  final double lat;
  final double lon;

  const WeatherScreen(
      {super.key, required this.city, required this.lat, required this.lon});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String? cityName;
  String? country;
  String? weatherdescription;
  String? weatherMain;
  double? temperature;
  double? humidity;
  double? windSpeed;
  double? feelsLike;
  double? pressure;
  double? visibility;
  double? cloudiness;
  int? aqi;
  List<Map<String, dynamic>>? dailyForecast;
  double? lat;
  double? lon;
  bool isCelsius = true; // true = °C, false = °F
  WindUnit windUnit = WindUnit.ms;
  PressureUnit pressureUnit = PressureUnit.hpa;
  VisibilityUnit visibilityUnit = VisibilityUnit.km;
  List<dynamic>? hourlyForecast;
  bool isFromLocation = false;

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  Future<void> useCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission permanently denied'),
        ),
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      lat = position.latitude;
      lon = position.longitude;
      cityName = 'Current location';
      country = null;
      isFromLocation = true;
    });

    fetchWeather();
  }

  Future<void> fetchWeather() async {
    final usedLat = lat ?? widget.lat;
    final usedLon = lon ?? widget.lon;

    final data = await WeatherService().getWeatherByLatLon(usedLat, usedLon);

    final aqiData = await WeatherService().getAqiByLatLon(usedLat, usedLon);

    if (data == null) {
      return;
    }

    final countryCode = data['sys']['country'];
    final countryName = Country.tryParse(countryCode)?.name ?? countryCode;
    //final apiCity = data['name'];

    setState(() {
      cityName = isFromLocation
          ? data['name'] // city resolved by API for GPS
          : widget.city;

      country = countryName; // ✅ FIXED
      lat = data['coord']['lat'];
      lon = data['coord']['lon'];
      weatherMain = data['weather']?[0]?['main'];
      weatherdescription = data['weather']?[0]?['description'];
      temperature = data['main']?['temp']?.toDouble();
      feelsLike = data['main']?['feels_like']?.toDouble();
      pressure = data['main']?['pressure']?.toDouble();
      humidity = data['main']?['humidity']?.toDouble();
      windSpeed = data['wind']?['speed']?.toDouble();
      visibility = data['visibility']?.toDouble();
      cloudiness = data['clouds']?['all']?.toDouble();
      aqi = aqiData;
    });
    await fetchForecast();
  }

  Future<void> fetchForecast() async {
    if (lat == null || lon == null) return;

    final list = await WeatherService().get5DayForecast(lat!, lon!);
    if (list == null) return;

    setState(() {
      hourlyForecast = list;
      dailyForecast = WeatherService().getDailyMinMax(list);
    });
  }

  String formatHourlyTime(int unixSeconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(
      unixSeconds * 1000,
      isUtc: true,
    ).toLocal();

    return DateFormat('h a').format(date); // 1 PM, 8 AM
  }

  double convertTemperature(double celsius) {
    if (isCelsius) return celsius;
    return (celsius * 9 / 5) + 32;
  }

  String getTemperatureUnit() {
    return isCelsius ? '°C' : '°F';
  }

  double temp(double c) => isCelsius ? c : (c * 9 / 5) + 32;
  String tempUnit() => isCelsius ? '°C' : '°F';

  double wind(double ms) {
    switch (windUnit) {
      case WindUnit.ms:
        return ms;
      case WindUnit.kmh:
        return ms * 3.6;
      case WindUnit.mph:
        return ms * 2.23694;
      case WindUnit.knots:
        return ms * 1.94384;
    }
  }

  String windUnitLabel() {
    switch (windUnit) {
      case WindUnit.ms:
        return 'm/s';
      case WindUnit.kmh:
        return 'km/h';
      case WindUnit.mph:
        return 'mph';
      case WindUnit.knots:
        return 'knots';
    }
  }

  double pressureConv(double hpa) {
    switch (pressureUnit) {
      case PressureUnit.hpa:
        return hpa;
      case PressureUnit.mmhg:
        return hpa * 0.75006;
      case PressureUnit.atm:
        return hpa / 1013.25;
    }
  }

  String pressureUnitLabel() {
    switch (pressureUnit) {
      case PressureUnit.hpa:
        return 'hPa';
      case PressureUnit.mmhg:
        return 'mmHg';
      case PressureUnit.atm:
        return 'atm';
    }
  }

  double visibilityConv(double meters) {
    final km = meters / 1000;
    return visibilityUnit == VisibilityUnit.km ? km : km * 0.621371;
  }

  String visibilityUnitLabel() =>
      visibilityUnit == VisibilityUnit.km ? 'km' : 'miles';

  String aqicategory(int? aqi) {
    if (aqi == null) return "Unknown";
    if (aqi >= 0 && aqi <= 50) {
      return "Good";
    } else if (aqi >= 51 && aqi <= 100) {
      return "Moderate";
    } else if (aqi >= 101 && aqi <= 150) {
      return "Unhealthy (Sensitive)";
    } else if (aqi >= 151 && aqi <= 200) {
      return "Unhealthy";
    } else if (aqi >= 201 && aqi <= 300) {
      return "Very Unhealthy";
    } else if (aqi > 300) {
      return "Hazardous";
    } else {
      return "Unknown";
    }
  }

  Color getAqiColor(int? aqi) {
    if (aqi == null) return Colors.grey;
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow.shade600;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Color(0xFFD32F2F);
    if (aqi <= 300) return Colors.purple;
    return Colors.brown;
  }

  String getWeatherSymbol(String? weather) {
    switch (weather?.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
      case 'drizzle':
        return '🌧️';
      case 'snow':
        return '❄️';
      case 'thunderstorm':
        return '⛈️';
      case 'mist':
      case 'fog':
      case 'haze':
        return '🌫️';
      default:
        return '☁️';
    }
  }

  String aqiHealthTip(int? aqi) {
    if (aqi == null) return "Data unavailable";

    if (aqi >= 0 && aqi <= 50) {
      return "Air quality is good. Enjoy outdoor activities.";
    } else if (aqi >= 51 && aqi <= 100) {
      return "Sensitive individuals should reduce prolonged outdoor exertion.";
    } else if (aqi >= 101 && aqi <= 150) {
      return "Children, elderly, and asthmatics should limit outdoor activity.";
    } else if (aqi >= 151 && aqi <= 200) {
      return "Avoid outdoor exercise. Wear a mask if going outside.";
    } else if (aqi >= 201 && aqi <= 300) {
      return "Stay indoors. Outdoor activity strongly discouraged.";
    } else if (aqi > 300) {
      return "Health emergency. Remain indoors with windows closed.";
    } else {
      return "Data unavailable";
    }
  }

  String getLottieForWeather(String? weather) {
    switch (weather?.toLowerCase()) {
      case 'clear':
        return 'assets/animations/little sun.json';
      case 'clouds':
        return 'assets/animations/Clouds.json';
      case 'rain':
      case 'drizzle':
        return 'assets/animations/rainy icon.json';
      case 'snow':
        return 'assets/animations/Weather-snow.json';
      case 'thunderstorm':
      case 'tornado':
      case 'squall':
        return 'assets/animations/Thunderstorm.json';
      case 'mist':
      case 'haze':
      case 'fog':
      case 'smoke':
      case 'dust':
      case 'dusty':
        return 'assets/animations/Foggy.json';
      default:
        return 'assets/animations/little sun.json';
    }
  }

  String getBackgroundForWeather(String? weather) {
    switch (weather?.toLowerCase()) {
      case 'clear':
        return 'assets/animations/sunny.jpg';
      case 'clouds':
        return 'assets/animations/cloudy.jpg';
      case 'snow':
        return 'assets/animations/snow.jpg';
      default:
        return 'assets/animations/cloudy.jpg';
    }
  }

  bool useWhiteForeground(Color? backgroundColor) {
    if (backgroundColor == null) return true;
    return backgroundColor.computeLuminance() < 0.5;
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.black12, width: 0.4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isWeatherBackground ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }

  bool isWeatherBackground = false;

  void showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, modalSetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text(
                'Settings',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // 🌡 Temperature
              SwitchListTile(
                title: const Text('Temperature Unit'),
                subtitle: Text(isCelsius ? 'Celsius (°C)' : 'Fahrenheit (°F)'),
                value: isCelsius,
                onChanged: (value) {
                  modalSetState(() => isCelsius = value);
                  setState(() {});
                },
              ),

              const Divider(),

              // 🌬 Wind Speed Units
              const Text('Wind Speed Unit',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              ...WindUnit.values.map(
                (unit) => RadioListTile<WindUnit>(
                  title: Text(unit.name.toUpperCase()),
                  value: unit,
                  groupValue: windUnit,
                  onChanged: (val) {
                    modalSetState(() => windUnit = val!);
                    setState(() {});
                  },
                ),
              ),

              const Divider(),

              // 👁 Visibility Units
              const Text('Visibility Unit',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              ...VisibilityUnit.values.map(
                (unit) => RadioListTile<VisibilityUnit>(
                  title: Text(unit.name.toUpperCase()),
                  value: unit,
                  groupValue: visibilityUnit,
                  onChanged: (val) {
                    modalSetState(() => visibilityUnit = val!);
                    setState(() {});
                  },
                ),
              ),

              const Divider(),

              // ⚙ Pressure Units
              const Text('Pressure Unit',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              ...PressureUnit.values.map(
                (unit) => RadioListTile<PressureUnit>(
                  title: Text(unit.name.toUpperCase()),
                  value: unit,
                  groupValue: pressureUnit,
                  onChanged: (val) {
                    modalSetState(() => pressureUnit = val!);
                    setState(() {});
                  },
                ),
              ),

              const Divider(),

              // 🎨 Background
              SwitchListTile(
                title: const Text('Background Style'),
                subtitle: Text(
                  isWeatherBackground
                      ? 'Solid dark background'
                      : 'Weather-based background',
                ),
                value: isWeatherBackground,
                onChanged: (value) {
                  modalSetState(() => isWeatherBackground = value);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: isWeatherBackground
            ? BoxDecoration(
                color: Color(0xFF090B20),
              )
            : BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(getBackgroundForWeather(weatherMain)),
                  fit: BoxFit.cover,
                ),
              ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: RefreshIndicator(
            //pull down to refresh
            onRefresh: () => fetchWeather(),
            color: Colors.redAccent,
            child: SingleChildScrollView(
              //scrollable
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 30),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      SizedBox(width: 100),
                      Container(
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.my_location),
                              onPressed: useCurrentLocation,
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings, size: 30),
                              onPressed: () {
                                showSettingsModal(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 30, color: Colors.red),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          cityName ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 30,
                            fontFamily: 'Times New Roman',
                            fontWeight: FontWeight.w900,
                            color: isWeatherBackground
                                ? Colors.white
                                : Colors.blueGrey.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 40),
                    child: Text(
                      '$country',
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'Times New Roman',
                        color:
                            isWeatherBackground ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    height: 360,
                    // width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          offset: Offset(-5, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(top: 60), // 🔥 key line
                            child: Lottie.asset(
                              getLottieForWeather(weatherMain),
                              height: 260,
                              width: 260,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: Text(
                            '${temperature != null ? convertTemperature(temperature!).toStringAsFixed(1) : 'N/A'}${getTemperatureUnit()}',
                            style: TextStyle(
                              fontSize: 50,
                              fontFamily: 'Times New Roman',
                              color: isWeatherBackground
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 70,
                          left: 30,
                          child: Text(
                            weatherMain.toString(),
                            style: TextStyle(
                              fontSize: 25,
                              fontFamily: 'Times New Roman',
                              color: isWeatherBackground
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (hourlyForecast != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Next 24 Hours",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isWeatherBackground
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        Icon(
                          Icons.schedule,
                          color: isWeatherBackground
                              ? Colors.white.withOpacity(0.6)
                              : Colors.black.withOpacity(0.4),
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 14,
                      ),
                      child: SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: hourlyForecast!.take(8).length,
                          itemBuilder: (context, index) {
                            final item = hourlyForecast![index];
                            final time = formatHourlyTime(item['dt']);
                            final temp =
                                convertTemperature((item['main']['temp'] as num).toDouble())
                                    .toStringAsFixed(0);
                            final weatherMain = item['weather'][0]['main'];
                            final humidity = (item['main']['humidity'] as num).toInt();

                            return Container(
                              width: 88,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withOpacity(0.25),
                                    Colors.white.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    time,
                                    style: TextStyle(
                                      color: isWeatherBackground
                                          ? Colors.white.withOpacity(0.9)
                                          : Colors.black87,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  Text(
                                    getWeatherSymbol(weatherMain),
                                    style: const TextStyle(fontSize: 36),
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        "$temp${getTemperatureUnit()}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: isWeatherBackground
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        "$humidity%",
                                        style: TextStyle(
                                          color: isWeatherBackground
                                              ? Colors.white.withOpacity(0.7)
                                              : Colors.black54,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.black26,
                            //width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.device_thermostat,
                                color: isWeatherBackground
                                    ? Colors.white
                                    : Colors.black,
                                size: 40),
                            SizedBox(height: 10),
                            Text(
                              'Feels Like\n${feelsLike != null ? convertTemperature(feelsLike!).toStringAsFixed(1) : 'N/A'}${getTemperatureUnit()}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isWeatherBackground
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.black26,
                            //width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.water_drop,
                                color: isWeatherBackground
                                    ? Colors.white
                                    : Colors.black,
                                size: 40),
                            SizedBox(height: 10),
                            Text(
                              'Humidity\n${humidity?.toStringAsFixed(1)}%',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isWeatherBackground
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.black26,
                            // width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.air,
                                color: isWeatherBackground
                                    ? Colors.white
                                    : Colors.black,
                                size: 40),
                            SizedBox(height: 10),
                            Text(
                              'Wind Speed\n${windSpeed != null ? wind(windSpeed!).toStringAsFixed(1) : 'N/A'} ${windUnitLabel()}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isWeatherBackground
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.black26,
                            //width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.visibility,
                                color: isWeatherBackground
                                    ? Colors.white
                                    : Colors.black,
                                size: 40),
                            SizedBox(height: 10),
                            Text(
                              'Visibility\n${visibility != null ? visibilityConv(visibility!).toStringAsFixed(1) : 'N/A'} ${visibilityUnitLabel()}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isWeatherBackground
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.black26,
                            //width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.speed,
                                color: isWeatherBackground
                                    ? Colors.white
                                    : Colors.black,
                                size: 40),
                            SizedBox(height: 10),
                            Text(
                              'Pressure\n${pressure != null ? pressureConv(pressure!).toStringAsFixed(1) : 'N/A'} ${pressureUnitLabel()}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isWeatherBackground
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.black26,
                            //width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.cloud,
                                color: isWeatherBackground
                                    ? Colors.white
                                    : Colors.black,
                                size: 40),
                            SizedBox(height: 10),
                            Text(
                              'Cloudiness\n${cloudiness?.toStringAsFixed(1)}%',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isWeatherBackground
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 25),
                  // aqi container - compact, professional styling
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: isWeatherBackground
                          ? const LinearGradient(
                              colors: [Color(0xFF071022), Color(0xFF0B1630)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.14),
                                Colors.white.withOpacity(0.06)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Air quality',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isWeatherBackground
                                        ? Colors.white.withOpacity(0.95)
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  aqicategory(aqi),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: isWeatherBackground
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: 220,
                                  child: Text(
                                    aqiHealthTip(aqi),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.4,
                                      color: isWeatherBackground
                                          ? Colors.white.withOpacity(0.9)
                                          : Colors.black87,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // AQI badge (pill)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: getAqiColor(aqi),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: getAqiColor(aqi).withOpacity(0.28),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    aqi != null ? aqi.toString() : 'N/A',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color:
                                          useWhiteForeground(getAqiColor(aqi))
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'AQI',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          useWhiteForeground(getAqiColor(aqi))
                                              ? Colors.white70
                                              : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Segmented bar with marker
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final total = constraints.maxWidth;
                            final val = (aqi ?? 0).clamp(0, 500).toDouble();
                            final markerX = total * (val / 500);

                            final segThresholds = [50, 50, 50, 50, 100, 200];
                            final segColors = [
                              Colors.green,
                              Colors.yellow.shade600,
                              Colors.orange,
                              const Color(0xFFD32F2F),
                              Colors.purple,
                              Colors.brown,
                            ];

                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Row(
                                  children: List.generate(
                                    segThresholds.length,
                                    (i) => Expanded(
                                      flex: segThresholds[i],
                                      child: Container(
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: segColors[i],
                                          borderRadius: i == 0
                                              ? const BorderRadius.only(
                                                  topLeft: Radius.circular(8),
                                                  bottomLeft:
                                                      Radius.circular(8))
                                              : i == segThresholds.length - 1
                                                  ? const BorderRadius.only(
                                                      topRight:
                                                          Radius.circular(8),
                                                      bottomRight:
                                                          Radius.circular(8))
                                                  : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // marker
                                Positioned(
                                  left: (markerX - 6).clamp(0.0, total - 12),
                                  top: -6,
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.25),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 10),

                        // Compact legend
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            _legendDot(Colors.green, 'Good'),
                            _legendDot(Colors.yellow.shade600, 'Moderate'),
                            _legendDot(Colors.orange, 'Unhealthy SG'),
                            _legendDot(const Color(0xFFD32F2F), 'Unhealthy'),
                            _legendDot(Colors.purple, 'Very Unhealthy'),
                            _legendDot(Colors.brown, 'Hazardous'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (dailyForecast != null) ...[
                    const SizedBox(height: 15),
                    // Forecast Container
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 25,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: dailyForecast!.length,
                          separatorBuilder: (context, index) => Divider(
                            color: Colors.white.withOpacity(0.08),
                            height: 14,
                            thickness: 1,
                          ),
                          itemBuilder: (context, index) {
                            final day = dailyForecast![index];

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Day name - improved styling
                                  SizedBox(
                                    width: 85,
                                    child: Text(
                                      day['day'],
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                        color: isWeatherBackground
                                            ? Colors.white.withOpacity(0.95)
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  // Weather Icon - in container
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      getWeatherSymbol(day['weather']),
                                      style: const TextStyle(
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                  // Temperature range - clearly organized
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "Max: ${convertTemperature(day['max']).toStringAsFixed(0)}${getTemperatureUnit()}",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isWeatherBackground
                                              ? Colors.white.withOpacity(0.9)
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        "Min: ${convertTemperature(day['min']).toStringAsFixed(0)}${getTemperatureUnit()}",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: isWeatherBackground
                                              ? Colors.white.withOpacity(0.7)
                                              : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Weather data may not be 100% accurate and depends on third-party APIs.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isWeatherBackground
                            ? Colors.white.withOpacity(0.8)
                            : Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
