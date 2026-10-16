import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/remote.dart';
import 'services/family_sync.dart';

/* ================= modelos (espelham o mockup) ================= */
class Device {
  String id, name, room, type;
  bool on;
  int temp, fan;
  String mode; // auto cool heat dry fan
  String swing;
  bool locked;
  String wifi; // rede do aparelho
  String wifiPass; // senha da rede (para o provisionamento do módulo)
  String mac; // MAC do módulo Wi-Fi (vinculação LAN)
  String lanKey; // chave exclusiva do aparelho (protocolo Gree)
  String ip; // último IP conhecido
  String fw; // versão do firmware (do scan)
  String model; // número do modelo (ID)
  Device({required this.id, required this.name, required this.room, this.type = 'ar', this.on = false, this.temp = 22, this.fan = 2, this.mode = 'cool', this.swing = 'Fixo', this.locked = false, this.wifi = '', this.wifiPass = '', this.mac = '', this.lanKey = '', this.ip = '', this.fw = '', this.model = ''});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'room': room, 'type': type, 'on': on, 'temp': temp, 'fan': fan, 'mode': mode, 'swing': swing, 'locked': locked, 'wifi': wifi, 'wifiPass': wifiPass, 'mac': mac, 'lanKey': lanKey, 'ip': ip, 'fw': fw, 'model': model};
  factory Device.fromJson(Map<String, dynamic> j) => Device(
      id: j['id'], name: j['name'], room: j['room'], type: j['type'] ?? 'ar',
      on: j['on'] ?? false, temp: j['temp'] ?? 22, fan: j['fan'] ?? 2,
      mode: j['mode'] ?? 'cool', swing: j['swing'] ?? 'Fixo', locked: j['locked'] ?? false,
      wifi: j['wifi'] ?? '', wifiPass: j['wifiPass'] ?? '', mac: j['mac'] ?? '', lanKey: j['lanKey'] ?? '', ip: j['ip'] ?? '',
      fw: j['fw'] ?? '', model: j['model'] ?? '');
}

class Schedule {
  int id;
  String name, cmd, mode;
  int hour, minute, temp;
  List<int> days; // 0=dom .. 6=sab
  bool on;
  Schedule({required this.id, required this.name, this.cmd = 'on', this.mode = 'cool', required this.hour, required this.minute, this.temp = 22, required this.days, this.on = true});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'cmd': cmd, 'mode': mode, 'hour': hour, 'minute': minute, 'temp': temp, 'days': days, 'on': on};
  factory Schedule.fromJson(Map<String, dynamic> j) => Schedule(
      id: j['id'], name: j['name'], cmd: j['cmd'] ?? 'on', mode: j['mode'] ?? 'cool',
      hour: j['hour'] ?? 0, minute: j['minute'] ?? 0, temp: j['temp'] ?? 22,
      days: (j['days'] as List?)?.cast<int>() ?? [1, 2, 3, 4, 5], on: j['on'] ?? true);
}

class Place {
  int id;
  String name;
  List<String> rooms;
  Place({required this.id, required this.name, required this.rooms});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'rooms': rooms};
  factory Place.fromJson(Map<String, dynamic> j) =>
      Place(id: j['id'], name: j['name'], rooms: (j['rooms'] as List?)?.cast<String>() ?? []);
}

class UserPrefs {
  String mode;
  Map<String, int> temps;
  UserPrefs({this.mode = 'cool', Map<String, int>? temps})
      : temps = temps ?? {'auto': 22, 'cool': 22, 'heat': 24, 'dry': 21, 'fan': 23};

  Map<String, dynamic> toJson() => {'mode': mode, 'temps': temps};
  factory UserPrefs.fromJson(Map<String, dynamic> j) => UserPrefs(
      mode: j['mode'] ?? 'cool',
      temps: (j['temps'] as Map?)?.map((k, v) => MapEntry(k as String, v as int)) ??
          {'auto': 22, 'cool': 22, 'heat': 24, 'dry': 21, 'fan': 23});
}

class FamilyUser {
  int id;
  String name, avatar, role;
  UserPrefs prefs;
  List<String> rooms;
  FamilyUser({required this.id, required this.name, this.avatar = 'p1', this.role = 'user', UserPrefs? prefs, List<String>? rooms})
      : prefs = prefs ?? UserPrefs(),
        rooms = rooms ?? [];

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'avatar': avatar, 'role': role, 'prefs': prefs.toJson(), 'rooms': rooms};
  factory FamilyUser.fromJson(Map<String, dynamic> j) => FamilyUser(
      id: j['id'], name: j['name'], avatar: j['avatar'] ?? 'p1', role: j['role'] ?? 'user',
      prefs: j['prefs'] != null ? UserPrefs.fromJson(j['prefs']) : UserPrefs(),
      rooms: (j['rooms'] as List?)?.cast<String>() ?? []);
}

class AppState extends ChangeNotifier {
  AppState({bool demo = false}) {
    if (demo) {
      onboarded = true;
      locations = [
        Place(id: 1, name: 'Casa', rooms: ['Sala', 'Quarto', 'Escritório']),
        Place(id: 2, name: 'Trabalho', rooms: ['Reunião', 'Suíte']),
      ];
      devices = [
        Device(id: 'sala', name: 'Ar da Sala', room: 'Sala', temp: 22, mode: 'cool', fan: 2),
        Device(id: 'quarto', name: 'Ar do Quarto', room: 'Quarto', temp: 24, mode: 'heat', fan: 1),
        Device(id: 'escritorio', name: 'Ar do Escritório', room: 'Escritório', temp: 20, mode: 'cool', fan: 3, on: true),
        Device(id: 'reuniao', name: 'Ar da Reunião', room: 'Reunião', temp: 23, mode: 'auto', fan: 2),
      ];
      schedules = [
        Schedule(id: 1, name: 'Acordar', cmd: 'on', mode: 'cool', hour: 6, minute: 30, temp: 22, days: [1, 2, 3, 4, 5]),
        Schedule(id: 2, name: 'Sair', cmd: 'off', hour: 8, minute: 30, days: [1, 2, 3, 4, 5]),
        Schedule(id: 3, name: 'Chegar', cmd: 'on', mode: 'auto', hour: 18, minute: 0, temp: 23, days: [1, 2, 3, 4, 5]),
        Schedule(id: 4, name: 'Dormir', cmd: 'on', mode: 'heat', hour: 22, minute: 45, temp: 25, days: [0, 1, 2, 3, 4, 5, 6]),
      ];
      famOn = true;
      users = [
        FamilyUser(id: 1, name: 'Matheus', avatar: 'p1', role: 'admin', rooms: ['Sala', 'Quarto', 'Escritório']),
        FamilyUser(id: 2, name: 'Filha', avatar: 'p3', rooms: ['Quarto']),
      ];
    }
  }

  bool onboarded = false; // false = primeira abertura (onboarding)
  String screen = 'home';
  String themeMode = 'dark'; // dark | light
  String unit = 'C'; // C | F
  String appIcon = 'default'; // default | light | accent | mono
  String? profileDraftName; // rascunho do nome em Editar perfil (a barra salva)
  String familyCodeSaved = ''; // código de convite da família

  /* código de convite (gerado uma vez e lembrado) */
  String get familyCode {
    if (familyCodeSaved.isEmpty) {
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      final r = DateTime.now().millisecondsSinceEpoch;
      familyCodeSaved = List.generate(6, (i) => chars[(r >> (i * 5)) % chars.length]).join();
      _save();
    }
    return familyCodeSaved;
  }

  /* entra em uma família pelo código do convite (busca e sincroniza o registro) */
  Future<bool> joinFamily(String code) async {
    final c = code.trim().toUpperCase();
    if (c.length != 6) return false;
    familyCodeSaved = c;
    famOn = true;
    final remote = await FamilySync.fetch(c);
    if (remote != null) {
      if (remote['users'] is List && (remote['users'] as List).isNotEmpty) {
        users = (remote['users'] as List).map((x) => FamilyUser.fromJson(x)).toList();
      }
      if (remote['locations'] is List && (remote['locations'] as List).isNotEmpty) {
        locations = (remote['locations'] as List).map((x) => Place.fromJson(x)).toList();
        if (locations.isNotEmpty && !locations.any((l) => l.id == activeLoc)) activeLoc = locations.first.id;
      }
      if (remote['devices'] is List && (remote['devices'] as List).isNotEmpty) {
        devices = (remote['devices'] as List).map((x) => Device.fromJson(x)).toList();
      }
    }
    _changed();
    syncFamily();
    return true;
  }

  /* envia o registro da família para o Worker */
  void syncFamily() {
    if (familyCodeSaved.isEmpty || !famOn) return;
    FamilySync.push(familyCodeSaved, {
      'code': familyCodeSaved,
      'updated': DateTime.now().millisecondsSinceEpoch,
      'users': users.map((u) => u.toJson()).toList(),
      'locations': locations.map((l) => l.toJson()).toList(),
      'devices': devices.map((d) => d.toJson()).toList(),
    });
  }
  int activeLoc = 1;
  String room = 'Todos';
  String? selected;
  bool locMenu = false;

  List<Place> locations = [];
  List<Device> devices = [];
  List<Schedule> schedules = [];
  bool famOn = true;
  List<FamilyUser> users = [];

  // notificações / energia
  bool notifPush = true, notifEnergy = true, notifAlerts = false;
  double tariff = 0.92;

  // localização / clima (detectados ou escolhidos pelo usuário)
  String city = '', uf = '';
  double? lat, lon;
  String distributor = '';
  double baseTariff = 0; // R$/kWh (TE+TUSD) da ANEEL
  String flagName = '';
  double flagSurcharge = 0; // R$/kWh
  double? weatherTemp, weatherFeels, weatherHumidity;
  int? weatherCode;
  bool weatherIsDay = true;
  double weatherWind = 0;
  int weatherAt = 0;

  /* ---------- persistência (volta à tela certa ao reabrir) ---------- */
  SharedPreferences? _prefs;
  Timer? _weatherTimer;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs!.getString('gree_state');
      if (raw != null) {
        _fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } else {
        // primeira instalação: segue o tema do sistema (a pessoa ajusta no onboarding)
        themeMode = ui.PlatformDispatcher.instance.platformBrightness == ui.Brightness.dark ? 'dark' : 'light';
      }
    } catch (_) {
      // estado corrompido? segue com os padrões
    }
    // dados antigos gravavam em °F quando a unidade era F — agora tudo vive em °C
    if (unit == 'F') {
      for (final d in devices) {
        if (d.temp > 40) d.temp = ((d.temp - 32) * 5 / 9).round().clamp(16, 30);
      }
      for (final s in schedules) {
        if (s.temp > 40) s.temp = ((s.temp - 32) * 5 / 9).round();
      }
    }
    // clima em tempo real: atualiza sozinho de 10 em 10 minutos
    refreshWeather();
    _weatherTimer?.cancel();
    _weatherTimer = Timer.periodic(const Duration(minutes: 10), (_) => refreshWeather());
  }

  void _changed() {
    _save();
    notifyListeners();
  }

  void _save() {
    final p = _prefs;
    if (p == null) return;
    p.setString('gree_state', jsonEncode(_toJson()));
  }

  Map<String, dynamic> _toJson() => {
        'onboarded': onboarded,
        'familyCode': familyCodeSaved,
        'screen': screen,
        'themeMode': themeMode,
        'unit': unit,
        'appIcon': appIcon,
        'activeLoc': activeLoc,
        'room': room,
        'selected': selected,
        'famOn': famOn,
        'notifPush': notifPush,
        'notifEnergy': notifEnergy,
        'notifAlerts': notifAlerts,
        'tariff': tariff,
        'city': city,
        'uf': uf,
        'lat': lat,
        'lon': lon,
        'distributor': distributor,
        'baseTariff': baseTariff,
        'flagName': flagName,
        'flagSurcharge': flagSurcharge,
        'weatherTemp': weatherTemp,
        'weatherFeels': weatherFeels,
        'weatherHumidity': weatherHumidity,
        'weatherCode': weatherCode,
        'weatherAt': weatherAt,
        'locations': locations.map((l) => l.toJson()).toList(),
        'devices': devices.map((d) => d.toJson()).toList(),
        'schedules': schedules.map((s) => s.toJson()).toList(),
        'users': users.map((u) => u.toJson()).toList(),
      };

  void _fromJson(Map<String, dynamic> j) {
    // instalação limpa: dados de versões antigas (sem o campo de onboarding)
    // são descartados — atualizações futuras sempre têm o campo e preservam tudo
    if (!j.containsKey('onboarded')) return;
    onboarded = j['onboarded'] ?? false;
    familyCodeSaved = j['familyCode'] ?? '';
    screen = j['screen'] ?? 'home';
    themeMode = j['themeMode'] ?? 'dark';
    unit = j['unit'] ?? 'C';
    appIcon = j['appIcon'] ?? 'default';
    activeLoc = j['activeLoc'] ?? 1;
    room = j['room'] ?? 'Todos';
    selected = j['selected'];
    famOn = j['famOn'] ?? true;
    notifPush = j['notifPush'] ?? true;
    notifEnergy = j['notifEnergy'] ?? true;
    notifAlerts = j['notifAlerts'] ?? false;
    tariff = (j['tariff'] as num?)?.toDouble() ?? 0.92;
    city = j['city'] ?? '';
    uf = j['uf'] ?? '';
    lat = (j['lat'] as num?)?.toDouble();
    lon = (j['lon'] as num?)?.toDouble();
    distributor = j['distributor'] ?? '';
    baseTariff = (j['baseTariff'] as num?)?.toDouble() ?? 0;
    flagName = j['flagName'] ?? '';
    flagSurcharge = (j['flagSurcharge'] as num?)?.toDouble() ?? 0;
    weatherTemp = (j['weatherTemp'] as num?)?.toDouble();
    weatherFeels = (j['weatherFeels'] as num?)?.toDouble();
    weatherHumidity = (j['weatherHumidity'] as num?)?.toDouble();
    weatherCode = j['weatherCode'];
    weatherAt = j['weatherAt'] ?? 0;
    if (j['locations'] != null) locations = (j['locations'] as List).map((x) => Place.fromJson(x)).toList();
    if (j['devices'] != null) devices = (j['devices'] as List).map((x) => Device.fromJson(x)).toList();
    if (j['schedules'] != null) schedules = (j['schedules'] as List).map((x) => Schedule.fromJson(x)).toList();
    if (j['users'] != null) users = (j['users'] as List).map((x) => FamilyUser.fromJson(x)).toList();
    if (locations.isNotEmpty && !locations.any((l) => l.id == activeLoc)) activeLoc = locations.first.id;
    if (screen == 'control' && (selected == null || !devices.any((d) => d.id == selected))) screen = 'home';
    if (screen == 'schededit') screen = 'schedule';
  }

  /* ---------- seletores ---------- */
  Place get loc => locations.firstWhere((l) => l.id == activeLoc, orElse: () => locations.first);
  Device get dev {
    if (devices.isEmpty) devices.add(Device(id: 'dev-1', name: 'Ar', room: 'Sala'));
    return devices.firstWhere((d) => d.id == selected, orElse: () => devices.first);
  }

  List<String> locRooms() => loc.rooms;

  /* ---------- mutações ---------- */
  void go(String s) {
    screen = s;
    locMenu = false;
    _changed();
  }

  /* atualiza a tela atual sem navegar (para os controles refletirem na hora) */
  void touch() => _changed();

  void setTheme(String mode) {
    themeMode = mode;
    _changed();
  }

  void applyProfileDraft() {
    final n = profileDraftName?.trim();
    if (n != null && n.isNotEmpty && users.isNotEmpty) users.first.name = n;
    profileDraftName = null;
    _changed();
  }

  static const _iconChannel = MethodChannel('gree/icon');

  Future<void> setAppIcon(String name) async {
    appIcon = name;
    _changed();
    try {
      await _iconChannel.invokeMethod('set', {'name': name});
    } catch (_) {
      // em testes/desktop o canal não existe; a escolha fica salva mesmo assim
    }
  }

  void toggleTheme() => setTheme(themeMode == 'dark' ? 'light' : 'dark');

  void setUnit(String u) {
    if (u == unit) return;
    unit = u;
    _changed();
  }

  void toggleUnit() => setUnit(unit == 'C' ? 'F' : 'C');

  /* ---------- unidades de temperatura ----------
   * os valores ficam SEMPRE em °C (o ar só entende °C no protocolo);
   * a conversão acontece só na exibição e na entrada da pessoa.
   */
  double tempToDisplay(num c) => unit == 'F' ? c * 9 / 5 + 32 : c.toDouble();
  int tempDisp(num c) => tempToDisplay(c).round();

  /* a outra unidade, para não se perder (ex.: viajando) */
  String tempAlt(num c) => unit == 'F' ? '${c.round()}°C' : '${(c * 9 / 5 + 32).round()}°F';

  double tempFromDisplay(num v) => unit == 'F' ? (v - 32) * 5 / 9 : v.toDouble();

  int get tempMin => unit == 'C' ? 16 : 61;
  int get tempMax => unit == 'C' ? 30 : 86;

  void setTemp(int v) {
    // v vem na unidade de exibição; guarda em °C (16–30 é o que o ar aceita)
    dev.temp = tempFromDisplay(v).round().clamp(16, 30);
    _changed();
  }

  void patchDev(void Function(Device) fn) {
    fn(dev);
    _changed();
  }

  void patchSched(int id, void Function(Schedule) fn) {
    final i = schedules.indexWhere((s) => s.id == id);
    if (i >= 0) {
      fn(schedules[i]);
      _changed();
    }
  }

  void deleteSchedules(List<int> ids) {
    schedules.removeWhere((s) => ids.contains(s.id));
    _changed();
  }

  void selectLoc(int id) {
    activeLoc = id;
    locMenu = false;
    _changed();
  }

  void reorderLocations(List<int> order) {
    locations.sort((a, b) => order.indexOf(a.id).compareTo(order.indexOf(b.id)));
    activeLoc = locations.first.id;
    _changed();
  }

  void addPlace(String name) {
    if (name.trim().isEmpty) return;
    locations.add(Place(id: DateTime.now().millisecondsSinceEpoch % 100000, name: name.trim(), rooms: []));
    _changed();
    syncFamily();
  }

  void removePlace(int id) {
    locations.removeWhere((l) => l.id == id);
    if (locations.isNotEmpty && !locations.any((l) => l.id == activeLoc)) activeLoc = locations.first.id;
    _changed();
    syncFamily();
  }

  void addRoom(int locId, String room) {
    if (room.trim().isEmpty) return;
    final i = locations.indexWhere((l) => l.id == locId);
    if (i >= 0) {
      locations[i].rooms.add(room.trim());
      _changed();
      syncFamily();
    }
  }

  void removeRoom(int locId, String room) {
    final i = locations.indexWhere((l) => l.id == locId);
    if (i >= 0) {
      locations[i].rooms.remove(room);
      _changed();
      syncFamily();
    }
  }

  void addUser(String name) {
    if (name.trim().isEmpty) return;
    final ids = users.map((u) => u.id).toList()..sort();
    users.add(FamilyUser(id: (ids.isEmpty ? 0 : ids.last) + 1, name: name.trim(), avatar: 'p2'));
    _changed();
    syncFamily();
  }

  void removeUser(int id) {
    users.removeWhere((u) => u.id == id);
    _changed();
    syncFamily();
  }

  void disableFamily() {
    famOn = false;
    if (users.isNotEmpty) users = [users.first];
    _changed();
    syncFamily();
  }

  void setNotif(String key, bool v) {
    if (key == 'push') notifPush = v;
    if (key == 'energy') notifEnergy = v;
    if (key == 'alerts') notifAlerts = v;
    _changed();
  }

  void setTariff(double v) {
    tariff = double.parse(v.clamp(0.1, 9).toStringAsFixed(2));
    _changed();
  }

  /* ---------- localização, tarifa e clima (automático) ---------- */
  /* rascunho do novo aparelho (a tela de cadastro preenche; a barra confirma) */
  String newDevName = 'Ar-condicionado';
  String newDevRoom = '';
  String newDevWifi = '';
  String newDevPass = '';
  String newDevMode = 'cool';
  int newDevTemp = 22;

  void resetNewDeviceDraft() {
    newDevName = '';
    newDevRoom = '';
    newDevWifi = '';
    newDevPass = '';
    newDevMode = 'cool';
    newDevTemp = 22;
    _changed();
  }

  void commitNewDevice() {
    final name = newDevName.trim().isEmpty ? 'Ar-condicionado' : newDevName.trim();
    final room = newDevRoom.trim().isEmpty ? 'Sala' : newDevRoom.trim();
    if (!locRooms().contains(room) && locations.isNotEmpty) {
      locations.firstWhere((l) => l.id == activeLoc, orElse: () => locations.first).rooms.add(room);
    }
    devices.add(Device(
      id: 'dev-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      room: room,
      wifi: newDevWifi.trim(),
      wifiPass: newDevPass.trim(),
      mode: newDevMode,
      temp: newDevTemp,
    ));
    _changed();
    syncFamily();
  }

  void removeDevice(String id) {
    devices.removeWhere((d) => d.id == id);
    if (selected == id) selected = null;
    _changed();
    syncFamily();
  }

  /* conclui o onboarding: app limpo + usuário/ar/local criados */
  void finishOnboarding({
    required String name,
    required String avatar,
    required String devName,
    required String room,
    required int temp,
    required String mode,
    String devWifi = '',
    String devPass = '',
    GeoPlace? place,
  }) {
    final r = room.trim().isEmpty ? 'Sala' : room.trim();
    users = [FamilyUser(id: 1, name: name.trim().isEmpty ? 'Usuário' : name.trim(), avatar: avatar, role: 'admin', rooms: [r])];
    locations = [Place(id: 1, name: 'Casa', rooms: [r])];
    devices = [Device(id: 'dev-1', name: devName.trim().isEmpty ? 'Ar-condicionado' : devName.trim(), room: r, temp: temp, mode: mode, wifi: devWifi.trim(), wifiPass: devPass.trim())];
    schedules = [];
    activeLoc = 1;
    selected = 'dev-1';
    screen = 'home';
    famOn = false;
    onboarded = true;
    _changed();
    if (place != null) {
      applyPlace(place);
    }
  }

  Future<void> applyPlace(GeoPlace place) async {
    city = place.city;
    uf = place.uf;
    lat = place.lat;
    lon = place.lon;
    _changed();
    await resolveEnergy();
    await refreshWeather();
  }

  Future<void> resolveEnergy() async {
    final data = await Remote.energyData();
    if (data == null) {
      _changed(); // mesmo sem dados, a escolha do usuário vale e a tela atualiza
      return;
    }
    flagName = data.flagName;
    flagSurcharge = data.flagSurcharge;
    // distribuidora: a salva, senão a primeira compatível com a UF
    final options = ufDistributors[uf] ?? [];
    if (distributor.isEmpty || !data.tariffs.containsKey(distributor)) {
      distributor = options.firstWhere((o) => data.tariffs.containsKey(o), orElse: () => distributor);
    }
    final base = data.tariffs[distributor];
    if (base != null) {
      baseTariff = base;
      tariff = double.parse((base + flagSurcharge).toStringAsFixed(3));
    }
    _changed();
  }

  /* escolha manual da distribuidora (o nome aparece na hora) */
  void setDistributor(String d) {
    distributor = d;
    _changed();
    resolveEnergy();
  }

  Future<void> refreshWeather() async {
    if (lat == null || lon == null) return;
    final w = await Remote.weather(lat!, lon!);
    if (w == null) return;
    weatherTemp = w.temp;
    weatherFeels = w.feels;
    weatherHumidity = w.humidity;
    weatherCode = w.code;
    weatherIsDay = w.isDay;
    weatherWind = w.wind;
    weatherAt = DateTime.now().millisecondsSinceEpoch;
    _changed();
  }
}
