import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gree_app/services/remote.dart';

void main() {
  group('Ícone do clima por condição e hora', () {
    test('dia: sol, sol com nuvem, chuva, vento, gelo, neve, temporal, tempestade', () {
      expect(WeatherNow.iconOf(0, true), Icons.wb_sunny_rounded);
      expect(WeatherNow.iconOf(1, true), Icons.wb_sunny_rounded);
      expect(WeatherNow.iconOf(2, true), Icons.wb_cloudy_rounded);
      expect(WeatherNow.iconOf(3, true), Icons.cloud_rounded);
      expect(WeatherNow.iconOf(61, true), Icons.water_drop_rounded);
      expect(WeatherNow.iconOf(80, true), Icons.water_drop_rounded);
      expect(WeatherNow.iconOf(66, true), Icons.severe_cold_rounded);
      expect(WeatherNow.iconOf(71, true), Icons.snowing);
      expect(WeatherNow.iconOf(95, true), Icons.thunderstorm_rounded);
      expect(WeatherNow.iconOf(99, true), Icons.flash_on_rounded);
      expect(WeatherNow.iconOf(45, true), Icons.blur_on_rounded);
      expect(WeatherNow.iconOf(51, true), Icons.grain_rounded);
    });

    test('noite: lua e as variações', () {
      expect(WeatherNow.iconOf(0, false), Icons.dark_mode_rounded);
      expect(WeatherNow.iconOf(2, false), Icons.bedtime_rounded);
      expect(WeatherNow.iconOf(61, false), Icons.water_drop_rounded); // lua com chuva
      expect(WeatherNow.iconOf(71, false), Icons.snowing); // lua com neve
      expect(WeatherNow.iconOf(95, false), Icons.thunderstorm_rounded); // lua com temporal
    });

    test('vento forte sobrepõe o código', () {
      expect(WeatherNow.iconOf(0, true, wind: 50), Icons.air_rounded);
      expect(WeatherNow.iconOf(0, true, wind: 20), Icons.wb_sunny_rounded);
    });
  });
}
