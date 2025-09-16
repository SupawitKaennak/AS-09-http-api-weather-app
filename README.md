<img width="254.5" height="533" alt="image" src="https://github.com/user-attachments/assets/ea1d70ab-d07d-4504-af2a-156e7629a8da" />
<img width="254.5" height="533" alt="image" src="https://github.com/user-attachments/assets/5644af6d-0484-4888-ab88-91b0be609b28" />

# Weather App Flutter

เอกสารประกอบการสร้างแอปพลิเคชันแสดงผลสภาพอากาศด้วย Flutter

## สารบัญ
1. [ศึกษาการใช้งาน API](#1-ศึกษาการใช้งาน-api)
2. [การสร้าง Class สำหรับข้อมูล (Data Model)](#2-การสร้าง-class-สำหรับข้อมูล-data-model)
3. [หลักการใช้งาน http และ provider](#3-หลักการใช้งาน-http-และ-provider)
4. [การนำ http และ provider มาใช้งานในแอป](#4-การนำ-http-และ-provider-มาใช้งานในแอป)
5. [ออกแบบหน้าแอปเพื่อแสดงผลข้อมูล](#5-ออกแบบหน้าแอปเพื่อแสดงผลข้อมูล)
6. [อธิบายโค้ดอย่างละเอียด](#6-อธิบายโค้ดอย่างละเอียด)

---

### 1. ศึกษาการใช้งาน API

ในโปรเจกต์นี้ เราจะใช้ API จาก [Open-Meteo](https://open-meteo.com/) ซึ่งเป็น API ฟรีและไม่ต้องใช้ Key.

**ขั้นตอน:**
1.  **ศึกษาเอกสาร API:** ไปที่เว็บไซต์ Open-Meteo และดูเอกสารประกอบ ที่นี่เราจะใช้ Forecast API.
2.  **ทำความเข้าใจ URL และ Parameters:**
    *   **URL ตัวอย่าง:** `https://api.open-meteo.com/v1/forecast?latitude=18.7883&longitude=98.9853&daily=temperature_2m_max,temperature_2m_min,precipitation_sum&timezone=Asia/Bangkok`
    *   **Parameters หลัก:**
        *   `latitude` & `longitude`: พิกัดทางภูมิศาสตร์ของตำแหน่งที่ต้องการ
        *   `daily`: ข้อมูลรายวันที่ต้องการดึงค่า เช่น `temperature_2m_max` (อุณหภูมิสูงสุด), `temperature_2m_min` (อุณหภูมิต่ำสุด), `precipitation_sum` (ปริมาณน้ำฝนรวม)
        *   `timezone`: เขตเวลาเพื่อความถูกต้องของข้อมูล
3.  **วิเคราะห์ข้อมูล JSON ที่ได้รับ:**
    **ตัวอย่าง JSON Response:**
    ```json
    {
      "latitude": 18.79,
      "longitude": 98.99,
      "timezone": "Asia/Bangkok",
      "daily": {
        "time": ["2024-09-16", "2024-09-17"],
        "temperature_2m_max": [32.5, 33.0],
        "temperature_2m_min": [24.1, 24.5],
        "precipitation_sum": [5.3, 2.1]
      }
    }
    ```
    ข้อมูลที่ได้จะเป็นการพยากรณ์ล่วงหน้าหลายวัน ในตัวอย่างนี้เราจะดึงข้อมูลของวันแรกมาใช้งาน.

---

### 2. การสร้าง Class สำหรับข้อมูล (Data Model)

เพื่อจัดการข้อมูล JSON ที่ซับซ้อนให้ง่ายขึ้นใน Dart เราจะสร้าง Class Model (`WeatherModel`) ขึ้นมาเพื่อแปลง JSON เป็น Object.

**ไฟล์: `lib/models/weather_model.dart`**
```dart
class WeatherModel {
  final double maxTemperature;
  final double minTemperature;
  final double precipitationSum;

  WeatherModel({
    required this.maxTemperature,
    required this.minTemperature,
    required this.precipitationSum,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    // API คืนค่าเป็น list ของข้อมูลรายวัน, ในที่นี้เราจะใช้ข้อมูลของวันแรก (index 0)
    return WeatherModel(
      maxTemperature: json['daily']['temperature_2m_max'][0].toDouble(),
      minTemperature: json['daily']['temperature_2m_min'][0].toDouble(),
      precipitationSum: json['daily']['precipitation_sum'][0].toDouble(),
    );
  }
}
```
- **`WeatherModel`**: คลาสที่เก็บข้อมูลสภาพอากาศที่เราสนใจ.
- **`factory WeatherModel.fromJson`**: ทำหน้าที่แปลง `Map<String, dynamic>` (ผลลัพธ์จากการ decode JSON) ให้กลายเป็น `WeatherModel` object.

---

### 3. หลักการใช้งาน http และ provider

ในการสร้างแอปนี้ เราจะใช้ 2 แพ็กเกจหลักคือ:
- **`http`**: สำหรับการยิง HTTP request ไปยัง API Server.
- **`provider`**: สำหรับการจัดการสถานะ (State Management) ของแอป.

**การติดตั้ง:**
เพิ่ม dependency ในไฟล์ `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.1
  provider: ^6.1.2
```
แล้วรัน `flutter pub get` ใน Terminal.

#### หลักการของ `http`
ใช้สำหรับสื่อสารกับ Web services. ในที่นี้คือการส่ง `GET` request ไปยัง Open-Meteo API เพื่อขอข้อมูลสภาพอากาศ.

#### หลักการของ `provider`
เป็นวิธีที่ง่ายในการจัดการ State ของแอป.
- **`ChangeNotifier`**: คลาสที่เราจะสร้าง (เช่น `WeatherProvider`) เพื่อเก็บ State และแจ้งเตือนเมื่อ State เปลี่ยนแปลง.
- **`ChangeNotifierProvider`**: Widget ที่ทำหน้าที่ "Provide" instance ของ `ChangeNotifier` ให้กับ Widget ลูกหลานที่อยู่ภายใต้มัน.
- **`Consumer`**: Widget ที่ "Consume" (รับฟัง) การเปลี่ยนแปลงจาก `ChangeNotifier` และ rebuild UI ส่วนที่ต้องการเมื่อมีการแจ้งเตือน.

---

### 4. การนำ http และ provider มาใช้งานในแอป

เราจะแบ่งโค้ดออกเป็นส่วนต่างๆ เพื่อให้จัดการง่าย:
- **`WeatherService`**: คลาสที่รับผิดชอบการสื่อสารกับ API.
- **`WeatherProvider`**: คลาสที่จัดการ State และตรรกะของแอป.

#### WeatherService (`lib/services/weather_service.dart`)
คลาสนี้จะใช้ `http` เพื่อดึงข้อมูลและแปลงเป็น `WeatherModel`.
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  static const BASE_URL = 'https://api.open-meteo.com/v1/forecast';

  Future<WeatherModel> getWeather(double latitude, double longitude) async {
    final response = await http.get(Uri.parse(
        '$BASE_URL?latitude=$latitude&longitude=$longitude&daily=temperature_2m_max,temperature_2m_min,precipitation_sum&timezone=Asia%2FBangkok'));

    if (response.statusCode == 200) {
      return WeatherModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load weather data');
    }
  }
}
```

#### WeatherProvider (`lib/providers/weather_provider.dart`)
คลาสนี้จะใช้ `WeatherService` เพื่อดึงข้อมูล, เก็บสถานะของข้อมูลสภาพอากาศ, และแจ้งเตือน Widget ที่เกี่ยวข้อง.
```dart
import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  WeatherModel? _weather;
  final WeatherService _weatherService;
  bool _isLoading = false;
  String? _errorMessage;

  WeatherProvider(this._weatherService);

  WeatherModel? get weather => _weather;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchWeather(double latitude, double longitude) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _weather = await _weatherService.getWeather(latitude, longitude);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```
- **`notifyListeners()`**: เมธอดสำคัญที่เรียกใช้เพื่อแจ้งให้ `Consumer` ทราบว่า State มีการเปลี่ยนแปลงและต้อง rebuild UI.

---

### 5. ออกแบบหน้าแอปเพื่อแสดงผลข้อมูล

หน้าแอปจะแสดงข้อมูลพยากรณ์อากาศสำหรับพิกัดที่กำหนด (เช่น เชียงใหม่).
1.  **อุณหภูมิสูงสุด (Max Temperature)**
2.  **อุณหภูมิต่ำสุด (Min Temperature)**
3.  **ปริมาณน้ำฝน (Precipitation)**
4.  **สถานะ Loading และ Error**

เราจะใช้ `ChangeNotifierProvider` ที่ Widget แม่สุดของแอป (`main.dart`) และใช้ `Consumer<WeatherProvider>` ใน Widget ที่ต้องการแสดงผลข้อมูล.

**ไฟล์: `lib/main.dart` (ส่วนของ UI)**
```dart
// ... (ส่วนของ imports และ main())

class WeatherPage extends StatefulWidget {
  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  @override
  void initState() {
    super.initState();
    // เรียก fetchWeather เมื่อหน้าจอถูกสร้างขึ้นครั้งแรก
    // ใช้พิกัดของเชียงใหม่ตามตัวอย่าง API
    Provider.of<WeatherProvider>(context, listen: false).fetchWeather(18.7883, 98.9853);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Weather Forecast')),
      body: Center(
        child: Consumer<WeatherProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return CircularProgressIndicator();
            }
            if (provider.errorMessage != null) {
              return Text(provider.errorMessage!);
            }
            if (provider.weather == null) {
              return Text('No weather data available.');
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Chiang Mai Forecast', style: TextStyle(fontSize: 32)),
                SizedBox(height: 20),
                Text('Max Temp: ${provider.weather!.maxTemperature.round()}°C', style: TextStyle(fontSize: 24)),
                Text('Min Temp: ${provider.weather!.minTemperature.round()}°C', style: TextStyle(fontSize: 24)),
                Text('Precipitation: ${provider.weather!.precipitationSum} mm', style: TextStyle(fontSize: 24)),
              ],
            );
          },
        ),
      ),
    );
  }
}
```
- `Consumer<WeatherProvider>` จะ rebuild เฉพาะส่วนที่อยู่ภายใน `builder` function ทำให้มีประสิทธิภาพดีกว่าการ rebuild ทั้งหน้า.

---

### 6. อธิบายโค้ดอย่างละเอียด

#### `main.dart`
- **`main()`**: จุดเริ่มต้นของแอป. เราจะห่อ `MaterialApp` ด้วย `ChangeNotifierProvider` เพื่อให้ `WeatherProvider` สามารถถูกเรียกใช้ได้จากทุกที่ในแอป.
- **`WeatherPage`**: ถูกเปลี่ยนเป็น `StatefulWidget` เพื่อใช้ `initState` ในการดึงข้อมูลสภาพอากาศครั้งแรกเมื่อแอปเริ่มทำงาน.
- **`Provider.of<WeatherProvider>(context, listen: false).fetchWeather(...)`**: ถูกเรียกใน `initState` เพื่อเริ่มการดึงข้อมูล. `listen: false` เป็นสิ่งจำเป็นเมื่อเรียก Provider ใน `initState`.

#### `weather_model.dart`
- ถูกปรับเปลี่ยนให้ตรงกับโครงสร้าง JSON ของ Open-Meteo API โดยจะเก็บค่า `maxTemperature`, `minTemperature`, และ `precipitationSum`.

#### `weather_service.dart`
- `BASE_URL` ถูกเปลี่ยนเป็นของ Open-Meteo.
- เมธอด `getWeather` รับ `latitude` และ `longitude` แทน `cityName`.
- ไม่มีการใช้ `apiKey` เนื่องจาก Open-Meteo ไม่ต้องการ.

#### `weather_provider.dart`
- เมธอด `fetchWeather` ถูกปรับให้รับ `latitude` และ `longitude` เพื่อส่งต่อไปยัง `WeatherService`.

---
