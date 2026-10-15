import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/* ================= modelos (espelham o mockup) ================= */
class Device {
  String id, name, room, type;
  bool on;
  int temp, fan;
  String mode; // auto cool heat dry fan
  String swing;
  bool locked;
  Device({required this.id, required this.name, required this.room, this.type = 'ar', this.on = false, this.temp = 22, this.fan = 2, this.mode = 'cool', this.swing = 'Fixo', this.locked = false});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'room': room, 'type': type, 'on': on, 'temp': temp, 'fan': fan, 'mode': mode, 'swing': swing, 'locked': locked};
  factory Device.fromJson(Map<String, dynamic> j) => Device(
      id: j['id'], name: j['name'], room: j['room'], type: j['type'] ?? 'ar',
      on: j['on'] ?? false, temp: j['temp'] ?? 22, fan: j['fan'] ?? 2,
      mode: j['mode'] ?? 'cool', swing: j['swing'] ?? 'Fixo', locked: j['locked'] ?? false);
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
  String screen = 'home';
  String themeMode = 'dark'; // dark | light
  String unit = 'C'; // C | F
  int activeLoc = 1;
  String room = 'Todos';
  String? selected;
  bool locMenu = false;

  List<Place> locations = [
    Place(id: 1, name: 'Casa', rooms: ['Sala', 'Quarto', 'Escritório']),
    Place(id: 2, name: 'Trabalho', rooms: ['Reunião', 'Suíte']),
  ];

  List<Device> devices = [
    Device(id: 'sala', name: 'Ar da Sala', room: 'Sala', temp: 22, mode: 'cool', fan: 2),
    Device(id: 'quarto', name: 'Ar do Quarto', room: 'Quarto', temp: 24, mode: 'heat', fan: 1),
    Device(id: 'escritorio', name: 'Ar do Escritório', room: 'Escritório', temp: 20, mode: 'cool', fan: 3, on: true),
    Device(id: 'reuniao', name: 'Ar da Reunião', room: 'Reunião', temp: 23, mode: 'auto', fan: 2),
  ];

  List<Schedule> schedules = [
    Schedule(id: 1, name: 'Acordar', cmd: 'on', mode: 'cool', hour: 6, minute: 30, temp: 22, days: [1, 2, 3, 4, 5]),
    Schedule(id: 2, name: 'Sair', cmd: 'off', hour: 8, minute: 30, days: [1, 2, 3, 4, 5]),
    Schedule(id: 3, name: 'Chegar', cmd: 'on', mode: 'auto', hour: 18, minute: 0, temp: 23, days: [1, 2, 3, 4, 5]),
    Schedule(id: 4, name: 'Dormir', cmd: 'on', mode: 'heat', hour: 22, minute: 45, temp: 25, days: [0, 1, 2, 3, 4, 5, 6]),
  ];

  bool famOn = true;
  List<FamilyUser> users = [
    FamilyUser(id: 1, name: 'Matheus', avatar: 'p1', role: 'admin', rooms: ['Sala', 'Quarto', 'Escritório']),
    FamilyUser(id: 2, name: 'Filha', avatar: 'p3', rooms: ['Quarto']),
  ];

  // notificações / energia
  bool notifPush = true, notifEnergy = true, notifAlerts = false;
  double tariff = 0.92;

  /* ---------- persistência (volta à tela certa ao reabrir) ---------- */
  SharedPreferences? _prefs;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs!.getString('gree_state');
      if (raw != null) _fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // estado corrompido? segue com os padrões
    }
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
        'screen': screen,
        'themeMode': themeMode,
        'unit': unit,
        'activeLoc': activeLoc,
        'room': room,
        'selected': selected,
        'famOn': famOn,
        'notifPush': notifPush,
        'notifEnergy': notifEnergy,
        'notifAlerts': notifAlerts,
        'tariff': tariff,
        'locations': locations.map((l) => l.toJson()).toList(),
        'devices': devices.map((d) => d.toJson()).toList(),
        'schedules': schedules.map((s) => s.toJson()).toList(),
        'users': users.map((u) => u.toJson()).toList(),
      };

  void _fromJson(Map<String, dynamic> j) {
    screen = j['screen'] ?? 'home';
    themeMode = j['themeMode'] ?? 'dark';
    unit = j['unit'] ?? 'C';
    activeLoc = j['activeLoc'] ?? 1;
    room = j['room'] ?? 'Todos';
    selected = j['selected'];
    famOn = j['famOn'] ?? true;
    notifPush = j['notifPush'] ?? true;
    notifEnergy = j['notifEnergy'] ?? true;
    notifAlerts = j['notifAlerts'] ?? false;
    tariff = (j['tariff'] as num?)?.toDouble() ?? 0.92;
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

  void setTheme(String mode) {
    themeMode = mode;
    _changed();
  }

  void toggleTheme() => setTheme(themeMode == 'dark' ? 'light' : 'dark');

  void toggleUnit() {
    final toF = unit == 'C';
    if (toF) {
      for (final d in devices) {
        d.temp = (d.temp * 9 / 5 + 32).round();
      }
      for (final s in schedules) {
        if (s.temp > 0) s.temp = (s.temp * 9 / 5 + 32).round();
      }
      unit = 'F';
    } else {
      for (final d in devices) {
        d.temp = ((d.temp - 32) * 5 / 9).round();
      }
      for (final s in schedules) {
        if (s.temp > 0) s.temp = ((s.temp - 32) * 5 / 9).round();
      }
      unit = 'C';
    }
    _changed();
  }

  int get tempMin => unit == 'C' ? 16 : 61;
  int get tempMax => unit == 'C' ? 30 : 86;

  void setTemp(int v) {
    dev.temp = v.clamp(tempMin, tempMax);
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
  }

  void removePlace(int id) {
    locations.removeWhere((l) => l.id == id);
    if (locations.isNotEmpty && !locations.any((l) => l.id == activeLoc)) activeLoc = locations.first.id;
    _changed();
  }

  void addRoom(int locId, String room) {
    if (room.trim().isEmpty) return;
    final i = locations.indexWhere((l) => l.id == locId);
    if (i >= 0) {
      locations[i].rooms.add(room.trim());
      _changed();
    }
  }

  void removeRoom(int locId, String room) {
    final i = locations.indexWhere((l) => l.id == locId);
    if (i >= 0) {
      locations[i].rooms.remove(room);
      _changed();
    }
  }

  void addUser(String name) {
    if (name.trim().isEmpty) return;
    final ids = users.map((u) => u.id).toList()..sort();
    users.add(FamilyUser(id: (ids.isEmpty ? 0 : ids.last) + 1, name: name.trim(), avatar: 'p2'));
    _changed();
  }

  void removeUser(int id) {
    users.removeWhere((u) => u.id == id);
    _changed();
  }

  void disableFamily() {
    famOn = false;
    if (users.isNotEmpty) users = [users.first];
    _changed();
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
}
