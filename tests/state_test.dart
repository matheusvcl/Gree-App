import 'package:flutter_test/flutter_test.dart';
import 'package:gree_app/state.dart';
import 'package:gree_app/services/remote.dart';

void main() {
  unitTests();
  fahrenheitLocationTests();
  group('Serialização', () {
    test('Device faz round-trip completo (incluindo LAN e rede)', () {
      final d = Device(
        id: 'dev-1', name: 'Ar', room: 'Sala', wifi: 'Casa', wifiPass: 'segredo',
        mac: '00123456789a', lanKey: '1234567890abcdef', ip: '192.168.0.10',
        fw: 'V1.1.13', model: 'gree-catalog', temp: 24, mode: 'heat', fan: 3, swing: 'Auto', locked: true,
      );
      final back = Device.fromJson(d.toJson());
      expect(back.id, 'dev-1');
      expect(back.wifi, 'Casa');
      expect(back.wifiPass, 'segredo');
      expect(back.mac, '00123456789a');
      expect(back.lanKey, '1234567890abcdef');
      expect(back.ip, '192.168.0.10');
      expect(back.fw, 'V1.1.13');
      expect(back.model, 'gree-catalog');
      expect(back.temp, 24);
      expect(back.mode, 'heat');
      expect(back.locked, true);
    });

    test('Schedule faz round-trip', () {
      final s = Schedule(id: 7, name: 'Dormir', cmd: 'off', hour: 23, minute: 45, days: [1, 3, 5], temp: 26, mode: 'dry', on: false);
      final back = Schedule.fromJson(s.toJson());
      expect(back.id, 7);
      expect(back.cmd, 'off');
      expect(back.hour, 23);
      expect(back.minute, 45);
      expect(back.days, [1, 3, 5]);
      expect(back.on, false);
    });
  });

  group('AppState', () {
    test('finishOnboarding cria o estado inicial com rede', () {
      final st = AppState();
      st.finishOnboarding(name: 'Matheus', avatar: 'p1', devName: 'Quarto', room: 'Quarto', temp: 21, mode: 'cool', devWifi: 'Casa', devPass: '123');
      expect(st.onboarded, true);
      expect(st.users.length, 1);
      expect(st.users.first.name, 'Matheus');
      expect(st.locations.length, 1);
      expect(st.devices.length, 1);
      expect(st.devices.first.name, 'Quarto');
      expect(st.devices.first.wifi, 'Casa');
      expect(st.devices.first.wifiPass, '123');
    });

    test('commitNewDevice adiciona aparelho com rede e cria a sala', () {
      final st = AppState(demo: true);
      final antes = st.devices.length;
      st.newDevName = 'Escritório';
      st.newDevRoom = 'Escritório';
      st.newDevWifi = 'Trabalho';
      st.newDevPass = 'senha';
      st.commitNewDevice();
      expect(st.devices.length, antes + 1);
      final d = st.devices.last;
      expect(d.name, 'Escritório');
      expect(d.wifi, 'Trabalho');
      expect(d.wifiPass, 'senha');
      expect(st.locRooms(), contains('Escritório'));
    });

    test('removeDevice remove o aparelho', () {
      final st = AppState(demo: true);
      final id = st.devices.first.id;
      st.removeDevice(id);
      expect(st.devices.where((d) => d.id == id), isEmpty);
    });

    test('patchDev e setTemp refletem no aparelho', () {
      final st = AppState(demo: true);
      st.setTemp(27);
      expect(st.dev.temp, 27);
      st.patchDev((d) => d.mode = 'heat');
      expect(st.dev.mode, 'heat');
    });

    test('patchSched e deleteSchedules', () {
      final st = AppState(demo: true);
      st.schedules.add(Schedule(id: 99, name: 'Teste', hour: 6, minute: 0, days: [1]));
      st.patchSched(99, (s) => s.name = 'Renomeada');
      expect(st.schedules.firstWhere((s) => s.id == 99).name, 'Renomeada');
      st.deleteSchedules([99]);
      expect(st.schedules.where((s) => s.id == 99), isEmpty);
    });

    test('locais: add, remove, reordenar e selecionar', () {
      final st = AppState(demo: true);
      st.addPlace('Sítio de teste');
      expect(st.locations.any((l) => l.name == 'Sítio de teste'), true);
      final novo = st.locations.firstWhere((l) => l.name == 'Sítio de teste');
      st.selectLoc(novo.id);
      expect(st.activeLoc, novo.id);
      st.reorderLocations(st.locations.reversed.map((l) => l.id).toList());
      expect(st.locations.first.id, novo.id);
      st.removePlace(novo.id);
      expect(st.locations.any((l) => l.name == 'Sítio de teste'), false);
    });

    test('salas: add e remove', () {
      final st = AppState(demo: true);
      st.addRoom(st.activeLoc, 'Varanda');
      expect(st.locRooms(), contains('Varanda'));
      st.removeRoom(st.activeLoc, 'Varanda');
      expect(st.locRooms(), isNot(contains('Varanda')));
    });

    test('família: addUser, removeUser e disableFamily', () {
      final st = AppState(demo: true);
      st.addUser('Ana');
      expect(st.users.any((u) => u.name == 'Ana'), true);
      final ana = st.users.firstWhere((u) => u.name == 'Ana');
      st.removeUser(ana.id);
      expect(st.users.any((u) => u.name == 'Ana'), false);
      st.disableFamily();
      expect(st.users.length, 1);
    });

    test('setDistributor salva o nome na hora', () {
      final st = AppState(demo: true);
      st.setDistributor('ENEL SP');
      expect(st.distributor, 'ENEL SP');
    });

    test('tema e unidade alternam', () {
      final st = AppState(demo: true);
      st.setTheme('light');
      expect(st.themeMode, 'light');
      st.toggleTheme();
      expect(st.themeMode, 'dark');
      final antes = st.unit;
      st.toggleUnit();
      expect(st.unit, isNot(antes));
    });

    test('go e touch notificam os ouvintes', () {
      final st = AppState(demo: true);
      var notificacoes = 0;
      st.addListener(() => notificacoes++);
      st.go('home');
      st.touch();
      expect(notificacoes, 2);
      expect(st.screen, 'home');
    });
  });
}

void unitTests() {
  group('Unidades de temperatura', () {
    test('conversões C↔F', () {
      final st = AppState(demo: true);
      st.setUnit('C');
      expect(st.tempDisp(22), 22);
      expect(st.tempAlt(22), '72°F');
      st.setUnit('F');
      expect(st.tempDisp(22), 72);
      expect(st.tempAlt(22), '22°C');
      expect(st.tempFromDisplay(72).round(), 22);
    });

    test('setTemp converte para °C e respeita os limites do ar', () {
      final st = AppState(demo: true);
      st.setUnit('F');
      st.setTemp(75); // 23,9°C
      expect(st.dev.temp, 24);
      st.setTemp(200); // fora da faixa → trava no máximo do ar
      expect(st.dev.temp, 30);
      st.setUnit('C');
      st.setTemp(10);
      expect(st.dev.temp, 16);
    });

    test('trocar unidade não mexe nos valores salvos', () {
      final st = AppState(demo: true);
      st.patchDev((d) => d.temp = 22);
      st.toggleUnit();
      st.toggleUnit();
      expect(st.dev.temp, 22);
      expect(st.unit, 'C');
    });
  });
}

void fahrenheitLocationTests() {
  group('Fahrenheit só em países que usam', () {
    test('regra por país', () {
      final st = AppState(demo: true);
      st.countryCode = 'br';
      expect(st.usesFahrenheit, false);
      st.countryCode = 'us';
      expect(st.usesFahrenheit, true);
      st.countryCode = 'BS'; // maiúsculas também contam
      expect(st.usesFahrenheit, true);
      st.countryCode = 'pt';
      expect(st.usesFahrenheit, false);
    });

    test('applyPlace detecta o país', () async {
      final st = AppState(demo: true);
      await st.applyPlace(GeoPlace(city: 'Miami', uf: '', lat: 25.7, lon: -80.2, countryCode: 'us'));
      expect(st.usesFahrenheit, true);
      await st.applyPlace(GeoPlace(city: 'São Paulo', uf: 'SP', lat: -23.5, lon: -46.6, countryCode: 'br'));
      expect(st.usesFahrenheit, false);
    });
  });
}
