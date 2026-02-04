import 'package:flutter/material.dart';
import 'backend.dart';
import 'weather_screen.dart'; // make sure this path is correct
import 'package:country_picker/country_picker.dart';


class SelectCity extends StatefulWidget {
  const SelectCity({super.key});

  @override
  State<SelectCity> createState() => _SelectCityState();
}

class _SelectCityState extends State<SelectCity> {
  TextEditingController controller = TextEditingController();

  // 🔹 API-based suggestions
  List<Map<String, dynamic>> suggestions = [];

String formatCity(Map<String, dynamic> place) {
  final city = place['name'];
  final state = place['state'];
  final countryCode = place['country'];

  final countryName =
      Country.tryParse(countryCode)?.name ?? countryCode;

  if (state != null && state.toString().isNotEmpty) {
    return "$city, $state, $countryName";
  }

  return "$city, $countryName";
}


 Future<void> fetchSuggestions(String input) async {
  if (input.isEmpty) {
    setState(() => suggestions = []);
    return;
  }

  final data = await WeatherService().getCitySuggestions(input);

  // ✅ OPTION A: Deduplicate by name + state + country
  final Map<String, Map<String, dynamic>> unique = {};

  for (var city in data) {
    final key =
        "${city['name']}-${city['state']}-${city['country']}";
    unique[key] = city;
  }

  setState(() {
    suggestions = unique.values.toList();
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo, Colors.cyan],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 60),
            Text(
              'Weather Vibe',
              style: TextStyle(
                fontSize: 40,
                fontFamily: 'Italics',
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                color: Colors.yellowAccent.shade400,
                letterSpacing: 5,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.8),
                    offset: const Offset(6, 3),
                    blurRadius: 10,
                  ),
                  Shadow(
                    color: Colors.orangeAccent.withOpacity(0.6),
                    offset: const Offset(-1, -1),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black87,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: controller,
                  onChanged: fetchSuggestions, // 🔥 ONLY CHANGE HERE
                  decoration: InputDecoration(
                    hintText: 'Search city...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      onPressed: () {
                        controller.clear();
                        setState(() {
                          suggestions.clear();
                        });
                      },
                      icon: const Icon(Icons.clear),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
           // 🔹 Uses same ListView UI, different data source
            Expanded(
              child: ListView.builder(
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      formatCity(suggestions[index]),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WeatherScreen(
                            city: suggestions[index]['name'],
                            lat: suggestions[index]['lat'],
                            lon: suggestions[index]['lon'],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
