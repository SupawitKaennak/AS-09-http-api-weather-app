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

ในโปรเจกต์นี้ เราจะใช้ API จาก [OpenWeatherMap](https://openweathermap.org/api) เพื่อดึงข้อมูลสภาพอากาศ.

**ขั้นตอน:**
1.  **สมัครสมาชิกและรับ API Key:** ไปที่เว็บไซต์ OpenWeatherMap และสร้างบัญชีเพื่อรับ API Key ส่วนตัว.
2.  **ศึกษาเอกสาร API:** อ่านเอกสารเพื่อทำความเข้าใจวิธีการเรียกใช้งาน Endpoint ต่างๆ. สำหรับโปรเจกต์นี้ เราจะใช้ Current Weather Data API.
    *   **URL ตัวอย่าง:** `https://api.openweathermap.org/data/2.5/weather?q={city name}&appid={API key}&units=metric`
3.  **วิเคราะห์ข้อมูล JSON ที่ได้รับ:** เมื่อทดลองเรียก API (เช่น ผ่านเบราว์เซอร์หรือ Postman) เราจะได้รับข้อมูลในรูปแบบ JSON.

    **ตัวอย่าง JSON Response:**
    ```json
    {
      "weather": [
        {
          "main": "Clouds",
          "description": "overcast clouds"
        }
      ],
      "main": {
        "temp": 25.3,
        "feels_like": 25.1,
        "humidity": 54
      },
      "name": "Bangkok"
    }
    ```
    จากข้อมูลนี้ เราจะสนใจดึงค่า `name` (ชื่อเมือง), `main.temp` (อุณหภูมิ), และ `weather[0].main` (สภาพอากาศหลัก).

---

### 2. การสร้าง Class สำหรับข้อมูล (Data Model)

เพื่อจัดการข้อมูล JSON ที่ซับซ้อนให้ง่ายขึ้นใน Dart เราจะสร้าง Class Model (`WeatherModel`) ขึ้นมาเพื่อแปลง JSON เป็น Object.

**ไฟล์: `lib/models/weather_model.dart`**
```dart
class WeatherModel {
  final String cityName;
  final double temperature;
  final String mainCondition;

  WeatherModel({
    required this.cityName,
    required this.temperature,
    required this.mainCondition,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      cityName: json['name'],
      temperature: json['main']['temp'].toDouble(),
      mainCondition: json['weather'][0]['main'],
    );
  }
}
```
- **`WeatherModel`**: คลาสที่เก็บข้อมูลสภาพอากาศที่จำเป็น
- **`factory WeatherModel.fromJson`**: เป็น Factory Constructor ที่ทำหน้าที่แปลง `Map<String, dynamic>` (ผลลัพธ์จากการ decode JSON) ให้กลายเป็น `WeatherModel` object.

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
ใช้สำหรับสื่อสารกับ Web services. ในที่นี้คือการส่ง `GET` request ไปยัง OpenWeatherMap API เพื่อขอข้อมูลสภาพอากาศ.

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
  static const BASE_URL = 'http://api.openweathermap.org/data/2.5/weather';
  final String apiKey;

  WeatherService(this.apiKey);

  Future<WeatherModel> getWeather(String cityName) async {
    final response = await http.get(Uri.parse('$BASE_URL?q=$cityName&appid=$apiKey&units=metric'));

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

  Future<void> fetchWeather(String cityName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _weather = await _weatherService.getWeather(cityName);
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

หน้าแอปจะประกอบด้วย:
1.  **ชื่อเมือง (City Name)**
2.  **อุณหภูมิ (Temperature)**
3.  **สภาพอากาศ (Main Condition)**
4.  **ช่องสำหรับค้นหาเมือง (TextField)** - (เพิ่มเติม)
5.  **สถานะ Loading และ Error**

เราจะใช้ `ChangeNotifierProvider` ที่ Widget แม่สุดของแอป (`main.dart`) และใช้ `Consumer<WeatherProvider>` ใน Widget ที่ต้องการแสดงผลข้อมูล.

**ไฟล์: `lib/main.dart` (ส่วนของ UI)**
```dart
// ... (ส่วนของ imports และ main())

class WeatherPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Weather App')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Search Bar (Optional)
            // ...

            Consumer<WeatherProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return CircularProgressIndicator();
                }
                if (provider.errorMessage != null) {
                  return Text(provider.errorMessage!);
                }
                if (provider.weather == null) {
                  return Text('Search for a city to see the weather.');
                }
                return Column(
                  children: [
                    Text(provider.weather!.cityName, style: TextStyle(fontSize: 32)),
                    Text('${provider.weather!.temperature.round()}°C', style: TextStyle(fontSize: 48)),
                    Text(provider.weather!.mainCondition, style: TextStyle(fontSize: 24)),
                  ],
                );
              },
            ),
          ],
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
- **`WeatherPage`**: หน้าหลักของแอปที่แสดง UI.
- **`Provider.of<WeatherProvider>(context, listen: false).fetchWeather(...)`**: วิธีการเรียกใช้เมธอดใน Provider. `listen: false` หมายความว่า Widget นี้ไม่ต้อง rebuild เมื่อ `notifyListeners()` ถูกเรียก (เหมาะสำหรับการเรียก action).

#### `weather_model.dart`
- ตามที่อธิบายในหัวข้อที่ 2, ทำหน้าที่เป็น "พิมพ์เขียว" ของข้อมูล.

#### `weather_service.dart`
- แยกส่วนการติดต่อกับ API ออกมาโดยเฉพาะ ทำให้โค้ดสะอาดและง่ายต่อการทดสอบ.
- จัดการกับการเรียก `http.get` และตรวจสอบ `statusCode` เพื่อให้แน่ใจว่าการเรียกสำเร็จ.

#### `weather_provider.dart`
- เป็นหัวใจของ State Management.
- เก็บสถานะต่างๆ (`_weather`, `_isLoading`, `_errorMessage`).
- มีเมธอด `fetchWeather` ที่เป็น Business Logic หลัก: จัดการการโหลด, ดักจับข้อผิดพลาด, และอัปเดต State.

---




