import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'models/weather_model.dart';
import 'providers/weather_provider.dart';

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WeatherProvider(),
      child: MaterialApp(
        title: 'Weather App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: const WeatherScreen(),
      ),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  ThailandProvince _selectedProvince = thailandProvinces[0];
  
  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
    await weatherProvider.fetchWeatherData(
      _selectedProvince.latitude,
      _selectedProvince.longitude,
    );
  }

  bool get _isNight {
    final now = DateTime.now();
    return now.hour < 6 || now.hour > 18;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<WeatherProvider>(
        builder: (context, weatherProvider, child) {
          if (weatherProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (weatherProvider.error != null) {
            return Center(child: Text('Error: ${weatherProvider.error}'));
          }
          if (weatherProvider.weatherData == null) {
            return const Center(child: Text('No weather data available'));
          }
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _isNight
                        ? [
                            const Color(0xFF1A237E),
                            const Color(0xFF303F9F),
                          ]
                        : [
                            const Color(0xFF64B5F6),
                            const Color(0xFF90CAF9),
                          ],
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _buildProvinceSelector(),
                    Expanded(
                      child: _buildWeatherContent(),
                    ),
                    _buildWeatherForecast(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProvinceSelector() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      child: SearchAnchor(
        builder: (BuildContext context, SearchController controller) {
          return SearchBar(
            controller: controller,
            padding: const MaterialStatePropertyAll<EdgeInsets>(
              EdgeInsets.symmetric(horizontal: 16.0),
            ),
            onTap: () {
              controller.openView();
            },
            leading: const Icon(Icons.location_city),
            hintText: 'เลือกจังหวัด',
            backgroundColor: MaterialStatePropertyAll(Colors.white.withOpacity(0.9)),
            surfaceTintColor: const MaterialStatePropertyAll(Colors.white),
            shadowColor: const MaterialStatePropertyAll(Colors.transparent),
            textStyle: MaterialStatePropertyAll(
              TextStyle(
                color: _isNight ? Colors.black87 : Colors.black87,
                fontSize: 16,
              ),
            ),
            trailing: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _selectedProvince.name,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          );
        },
        suggestionsBuilder: (BuildContext context, SearchController controller) {
          return thailandProvinces.map((province) {
            return ListTile(
              title: Text(province.name),
              onTap: () {
                setState(() {
                  _selectedProvince = province;
                });
                controller.closeView(province.name);
                _fetchWeatherData();
              },
            );
          }).toList();
        },
      ),
    );
  }

  Widget _buildWeatherContent() {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, child) {
        final weatherData = weatherProvider.weatherData;
        if (weatherData == null) return const SizedBox.shrink();

        final currentTemp = weatherData.maxTemperatures[0].round();
        final condition = weatherData.getWeatherCondition(0);

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              condition.icon,
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              '$currentTemp°',
              style: const TextStyle(
                fontSize: 72,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                condition.thaiName,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeatherForecast() {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, child) {
        final weatherData = weatherProvider.weatherData;
        if (weatherData == null) return const SizedBox.shrink();

        return Container(
          height: 100,
          margin: const EdgeInsets.all(16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: weatherData.dates.length,
            itemBuilder: (context, index) {
              final date = weatherData.dates[index];
              final maxTemp = weatherData.maxTemperatures[index].round();
              final minTemp = weatherData.minTemperatures[index].round();
              final dayName = DateFormat('E').format(date);
              final condition = weatherData.getWeatherCondition(index);
              
              return Container(
                width: 60,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayName,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      condition.icon,
                      size: 24,
                      color: Colors.white,
                    ),
                    Text(
                      '$maxTemp°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$minTemp°',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}