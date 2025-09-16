import 'package:flutter/material.dart';

class WeatherData {
  final List<double> maxTemperatures;
  final List<double> minTemperatures;
  final List<double> precipitationSums;
  final List<DateTime> dates;

  WeatherData({
    required this.maxTemperatures,
    required this.minTemperatures,
    required this.precipitationSums,
    required this.dates,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final daily = json['daily'];
    
    return WeatherData(
      maxTemperatures: List<double>.from(daily['temperature_2m_max']),
      minTemperatures: List<double>.from(daily['temperature_2m_min']),
      precipitationSums: List<double>.from(daily['precipitation_sum']),
      dates: List<DateTime>.from(
        daily['time'].map((date) => DateTime.parse(date)),
      ),
    );
  }

  WeatherCondition getWeatherCondition(int index) {
    final precipitation = precipitationSums[index];
    final maxTemp = maxTemperatures[index];

    if (precipitation > 10) {
      return WeatherCondition.thunder;
    } else if (precipitation > 5) {
      return WeatherCondition.rainy;
    } else if (maxTemp > 32) {
      return WeatherCondition.sunny;
    } else {
      return WeatherCondition.clear;
    }
  }
}

enum WeatherCondition {
  sunny(Icons.wb_sunny_outlined),
  clear(Icons.cloud_outlined),
  rainy(Icons.cloudy_snowing),
  thunder(Icons.flash_on);

  final IconData icon;
  const WeatherCondition(this.icon);

  String get thaiName {
    switch (this) {
      case WeatherCondition.sunny:
        return 'แดดจัด';
      case WeatherCondition.clear:
        return 'ท้องฟ้าแจ่มใส';
      case WeatherCondition.rainy:
        return 'ฝนตก';
      case WeatherCondition.thunder:
        return 'ฟ้าร้อง';
    }
  }
}

class ThailandProvince {
  final String name;
  final double latitude;
  final double longitude;

  const ThailandProvince({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

final List<ThailandProvince> thailandProvinces = [
  // จังหวัดยอดนิยม
  ThailandProvince(
    name: 'กรุงเทพมหานคร',
    latitude: 13.7563,
    longitude: 100.5018,
  ),
  ThailandProvince(
    name: 'เชียงใหม่',
    latitude: 18.7883,
    longitude: 98.9853,
  ),
  ThailandProvince(
    name: 'ภูเก็ต',
    latitude: 7.8804,
    longitude: 98.3923,
  ),
  // ภาคเหนือ
  ThailandProvince(
    name: 'เชียงราย',
    latitude: 19.9105,
    longitude: 99.8406,
  ),
  ThailandProvince(
    name: 'พิษณุโลก',
    latitude: 16.8211,
    longitude: 100.2659,
  ),
  ThailandProvince(
    name: 'แม่ฮ่องสอน',
    latitude: 19.2995,
    longitude: 97.9684,
  ),
  ThailandProvince(
    name: 'น่าน',
    latitude: 18.7756,
    longitude: 100.7728,
  ),
  // ภาคกลาง
  ThailandProvince(
    name: 'นนทบุรี',
    latitude: 13.8622,
    longitude: 100.5142,
  ),
  ThailandProvince(
    name: 'ปทุมธานี',
    latitude: 14.0208,
    longitude: 100.5255,
  ),
  ThailandProvince(
    name: 'พระนครศรีอยุธยา',
    latitude: 14.3692,
    longitude: 100.5876,
  ),
  // ภาคตะวันออก
  ThailandProvince(
    name: 'ชลบุรี',
    latitude: 13.3611,
    longitude: 100.9847,
  ),
  ThailandProvince(
    name: 'ระยอง',
    latitude: 12.6833,
    longitude: 101.2367,
  ),
  ThailandProvince(
    name: 'จันทบุรี',
    latitude: 12.6112,
    longitude: 102.1035,
  ),
  // ภาคตะวันออกเฉียงเหนือ
  ThailandProvince(
    name: 'ขอนแก่น',
    latitude: 16.4419,
    longitude: 102.8360,
  ),
  ThailandProvince(
    name: 'นครราชสีมา',
    latitude: 14.9799,
    longitude: 102.0978,
  ),
  ThailandProvince(
    name: 'อุดรธานี',
    latitude: 17.4066,
    longitude: 102.7872,
  ),
  ThailandProvince(
    name: 'อุบลราชธานี',
    latitude: 15.2400,
    longitude: 104.8474,
  ),
  // ภาคใต้
  ThailandProvince(
    name: 'สงขลา',
    latitude: 7.1927,
    longitude: 100.5945,
  ),
  ThailandProvince(
    name: 'สุราษฎร์ธานี',
    latitude: 9.1382,
    longitude: 99.3418,
  ),
  ThailandProvince(
    name: 'กระบี่',
    latitude: 8.0863,
    longitude: 98.9063,
  )
];
