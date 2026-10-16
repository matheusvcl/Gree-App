import 'dart:convert';
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
  GeoPlace({required this.city, required this.uf, required this.lat, required this.lon});
}

class WeatherNow {
  final double temp, feels, humidity;
  final int code;
  WeatherNow({required this.temp, required this.feels, required this.humidity, required this.code});
  static String conditionOf(int code) => WeatherNow(temp: 0, feels: 0, humidity: 0, code: code).condition;
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
      return GeoPlace(city: city, uf: ufFromState(state), lat: lat, lon: lon);
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
              '&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code'))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return null;
      final c = ((jsonDecode(utf8.decode(r.bodyBytes)) as Map)['current'] ?? {}) as Map;
      return WeatherNow(
        temp: (c['temperature_2m'] as num?)?.toDouble() ?? 0,
        feels: (c['apparent_temperature'] as num?)?.toDouble() ?? 0,
        humidity: (c['relative_humidity_2m'] as num?)?.toDouble() ?? 0,
        code: (c['weather_code'] as num?)?.toInt() ?? 2,
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
