import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

/* Fontes de dados externas:
   - energia.json (bandeira + tarifas): GitHub (gerado semanalmente pela ANEEL)
   - cidade/estado: Nominatim/OpenStreetMap
   - clima: Open-Meteo (sem chave) */
const _token = String.fromEnvironment('UPDATE_TOKEN');
const _energyUrl =
    'https://api.github.com/repos/matheusvcl/Gree-App/contents/docs/data/energy.json';

Map<String, String> get _ghHeaders => {
      'Accept': 'application/vnd.github.raw',
      'User-Agent': 'GreeApp',
      if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
    };

class GeoPlace {
  final String city, uf;
  final double lat, lon;
  final String countryCode; // ISO (br, us, ...) — decide a unidade secundária
  GeoPlace({required this.city, required this.uf, required this.lat, required this.lon, this.countryCode = 'br'});
}

class WeatherNow {
  final double temp, feels, humidity, wind;
  final int code;
  final bool isDay;
  WeatherNow({required this.temp, required this.feels, required this.humidity, required this.code, this.isDay = true, this.wind = 0});
  static String conditionOf(int code) => WeatherNow(temp: 0, feels: 0, humidity: 0, code: code).condition;

  /* ícone por condição e hora do dia — sol/lua com as variações do clima */
  static IconData iconOf(int code, bool isDay, {double wind = 0}) {
    if (wind >= 45) return Icons.air_rounded; // vento forte
    return switch (code) {
      0 || 1 => isDay ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded,
      2 => isDay ? Icons.wb_cloudy_rounded : Icons.bedtime_rounded,
      3 => Icons.cloud_rounded,
      45 || 48 => Icons.blur_on_rounded, // névoa
      51 || 53 || 55 => Icons.grain_rounded, // garoa
      56 || 57 => Icons.severe_cold_rounded, // garoa congelante (gelo)
      61 || 63 || 65 || 80 || 81 || 82 => Icons.water_drop_rounded, // chuva
      66 || 67 => Icons.severe_cold_rounded, // chuva congelante (gelo)
      71 || 73 || 75 || 77 || 85 || 86 => Icons.snowing, // neve
      95 => Icons.thunderstorm_rounded, // temporal
      96 || 99 => Icons.flash_on_rounded, // tempestade com granizo
      _ => isDay ? Icons.wb_cloudy_rounded : Icons.dark_mode_rounded,
    };
  }

  IconData get icon => iconOf(code, isDay, wind: wind);

  String get condition => switch (code) {
        0 => 'Limpo',
        1 => 'Predominantemente limpo',
        2 => 'Parcialmente nublado',
        3 => 'Nublado',
        45 || 48 => 'Névoa',
        51 || 53 || 55 || 56 || 57 => 'Chuva fraca',
        61 || 63 || 65 || 66 || 67 => 'Chuva',
        71 || 73 || 75 || 77 => 'Neve',
        80 || 81 || 82 => 'Pancadas de chuva',
        85 || 86 => 'Pancadas de neve',
        95 || 96 || 99 => 'Tempestade',
        _ => 'Parcialmente nublado',
      };
}

class EnergyData {
  final String flagName;
  final double flagSurcharge; // R$/kWh
  final Map<String, double> tariffs; // SigAgente -> R$/kWh (TE+TUSD)
  EnergyData({required this.flagName, required this.flagSurcharge, required this.tariffs});
}

class Remote {
  /* ---------- energia (bandeira + tarifas) ---------- */
  static Future<EnergyData?> energyData() async {
    try {
      final r = await http.get(Uri.parse(_energyUrl), headers: _ghHeaders).timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return null;
      final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      final flag = j['flag'] as Map<String, dynamic>;
      return EnergyData(
        flagName: (flag['name'] ?? 'Verde') as String,
        flagSurcharge: (flag['surcharge_per_kwh'] as num?)?.toDouble() ?? 0,
        tariffs: (j['tariffs'] as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble())),
      );
    } catch (_) {
      return null;
    }
  }

  /* ---------- localização ---------- */
  static Future<GeoPlace?> reverse(double lat, double lon) async {
    try {
      final r = await http
          .get(Uri.parse(
              'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&zoom=10&addressdetails=1'))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return null;
      final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      final a = (j['address'] ?? {}) as Map<String, dynamic>;
      final city = (a['city'] ?? a['town'] ?? a['village'] ?? a['municipality'] ?? j['name'] ?? '') as String;
      final state = (a['state'] ?? '') as String;
      return GeoPlace(city: city, uf: ufFromState(state), lat: lat, lon: lon, countryCode: (a['country_code'] ?? '') as String);
    } catch (_) {
      return null;
    }
  }

  static Future<List<GeoPlace>> searchPlaces(String q) async {
    try {
      final r = await http
          .get(Uri.parse(
              'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(q)}&format=json&countrycodes=br&addressdetails=1&limit=6'))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return [];
      final list = jsonDecode(utf8.decode(r.bodyBytes)) as List;
      return [
        for (final e in list)
          GeoPlace(
            city: ((e['address'] ?? {})['city'] ??
                (e['address'] ?? {})['town'] ??
                e['name'] ??
                '') as String,
            uf: ufFromState(((e['address'] ?? {})['state'] ?? '') as String),
            lat: double.tryParse('${e['lat']}') ?? 0,
            lon: double.tryParse('${e['lon']}') ?? 0,
            countryCode: (((e['address'] ?? {})['country_code'] ?? 'br') as String).toLowerCase(),
          ),
      ];
    } catch (_) {
      return [];
    }
  }

  static Future<GeoPlace?> deviceLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return null;
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.low));
      return await reverse(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  /* ---------- clima ---------- */
  static Future<WeatherNow?> weather(double lat, double lon) async {
    try {
      final r = await http
          .get(Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
              '&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,is_day,wind_speed_10m'))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return null;
      final c = ((jsonDecode(utf8.decode(r.bodyBytes)) as Map)['current'] ?? {}) as Map;
      return WeatherNow(
        temp: (c['temperature_2m'] as num?)?.toDouble() ?? 0,
        feels: (c['apparent_temperature'] as num?)?.toDouble() ?? 0,
        humidity: (c['relative_humidity_2m'] as num?)?.toDouble() ?? 0,
        code: (c['weather_code'] as num?)?.toInt() ?? 2,
        isDay: (c['is_day'] as num?)?.toInt() == 1,
        wind: (c['wind_speed_10m'] as num?)?.toDouble() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
}

/* nome do estado -> UF */
String ufFromState(String state) {
  const map = {
    'Acre': 'AC', 'Alagoas': 'AL', 'Amapá': 'AP', 'Amazonas': 'AM', 'Bahia': 'BA',
    'Ceará': 'CE', 'Distrito Federal': 'DF', 'Espírito Santo': 'ES', 'Goiás': 'GO',
    'Maranhão': 'MA', 'Mato Grosso': 'MT', 'Mato Grosso do Sul': 'MS', 'Minas Gerais': 'MG',
    'Pará': 'PA', 'Paraíba': 'PB', 'Paraná': 'PR', 'Pernambuco': 'PE', 'Piauí': 'PI',
    'Rio de Janeiro': 'RJ', 'Rio Grande do Norte': 'RN', 'Rio Grande do Sul': 'RS',
    'Rondônia': 'RO', 'Roraima': 'RR', 'Santa Catarina': 'SC', 'São Paulo': 'SP',
    'Sergipe': 'SE', 'Tocantins': 'TO',
  };
  for (final e in map.entries) {
    if (state.toLowerCase().contains(e.key.toLowerCase())) return e.value;
  }
  final upper = state.trim().toUpperCase();
  return map.containsValue(upper) ? upper : '';
}

/* distribuidoras principais por UF (nomes oficiais ANEEL) */
const ufDistributors = <String, List<String>>{
  'AC': ['ELETROCAR'], 'AL': ['EQUATORIAL AL'], 'AM': ['Âmbar Amazonas'], 'AP': ['CEA'],
  'BA': ['COELBA', 'SULGIPE'], 'CE': ['ENEL CE'], 'DF': ['Neoenergia Brasília'],
  'ES': ['EDP ES'], 'GO': ['EQUATORIAL GO'], 'MA': ['EQUATORIAL MA'], 'MG': ['CEMIG-D'],
  'MS': ['EMS'], 'MT': ['EMT'], 'PA': ['EQUATORIAL PA'], 'PB': ['EPB'], 'PE': ['Neoenergia PE'],
  'PI': ['EQUATORIAL PI'], 'PR': ['COPEL-DIS'], 'RJ': ['ENEL RJ', 'LIGHT SESA'],
  'RN': ['COSERN'], 'RO': ['ERO'], 'RR': ['ÂMBAR ENERGIA RR'],
  'RS': ['RGE', 'CEEE-D', 'CERSUL'], 'SC': ['CELESC'], 'SE': ['SULGIPE'],
  'SP': ['ELETROPAULO', 'CPFL-PAULISTA', 'CPFL Santa Cruz', 'ELEKTRO', 'CHESP'],
};
