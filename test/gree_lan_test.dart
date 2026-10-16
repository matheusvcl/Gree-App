import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gree_app/services/gree_crypto.dart';
import 'package:gree_app/services/gree_lan.dart';

/* Dispositivo Gree falso na porta 7000 para testar o protocolo de verdade. */
void main() {
  const cid = '00123456789a';
  const devKey = '1234567890abcdef';
  late RawDatagramSocket server;

  setUp(() async {
    server = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 7000);
  });

  tearDown(() => server.close());

  void serve(void Function(Map<String, dynamic> pack, Datagram dg) handler, {String key = kGreeGenericKey}) {
    server.listen((event) {
      if (event != RawSocketEvent.read) return;
      final dg = server.receive();
      if (dg == null) return;
      try {
        final msg = json.decode(utf8.decode(dg.data)) as Map<String, dynamic>;
        final pack = greeDecrypt(msg['pack'] as String, key);
        handler(pack, dg);
      } catch (_) {}
    });
  }

  void reply(Map<String, dynamic> envelope, Datagram dg) {
    server.send(utf8.encode(json.encode(envelope)), dg.address, dg.port);
  }

  test('bind: recebe a chave exclusiva do aparelho', () async {
    serve((pack, dg) {
      expect(pack['t'], 'bind');
      expect(pack['mac'], cid);
      reply({
        'cid': cid, 'i': 1, 'uid': 0, 't': 'pack', 'tcid': '',
        'pack': greeEncrypt({'t': 'bindok', 'mac': cid, 'key': devKey}, kGreeGenericKey),
      }, dg);
    });
    final key = await GreeLan().bind(GreeLanDevice(cid: cid, address: '127.0.0.1'), timeout: const Duration(seconds: 2));
    expect(key, devKey);
  });

  test('bind: timeout devolve null', () async {
    // servidor não responde
    final key = await GreeLan().bind(GreeLanDevice(cid: cid, address: '127.0.0.1'), timeout: const Duration(milliseconds: 400));
    expect(key, null);
  });

  test('status: retorna o mapa do aparelho', () async {
    serve((pack, dg) {
      expect(pack['t'], 'dat');
      reply({
        'cid': cid, 'i': 1, 'uid': 0, 't': 'pack', 'tcid': cid,
        'pack': greeEncrypt({
          't': 'dat', 'mac': cid, 'cols': ['pow', 'mod', 'settem'], 'dat': [1, 1, 24],
        }, devKey),
      }, dg);
    }, key: devKey);
    final res = await GreeLan().status(GreeLanDevice(cid: cid, address: '127.0.0.1'), devKey);
    expect(res, isNotNull);
    expect(res!['t'], 'dat');
    expect(res['dat'], [1, 1, 24]);
  });

  test('command: envia opt/p e confirma resposta', () async {
    serve((pack, dg) {
      expect(pack['t'], 'cmd');
      expect(pack['opt'], ['pow', 'settem']);
      expect(pack['p'], [1, 22]);
      reply({
        'cid': cid, 'i': 1, 'uid': 0, 't': 'pack', 'tcid': cid,
        'pack': greeEncrypt({'t': 'res', 'opt': ['pow', 'settem'], 'p': [1, 22]}, devKey),
      }, dg);
    }, key: devKey);
    final ok = await GreeLan().command(GreeLanDevice(cid: cid, address: '127.0.0.1'), devKey, ['pow', 'settem'], [1, 22]);
    expect(ok, true);
  });

  test('ping: false quando o aparelho não responde', () async {
    final ok = await GreeLan().ping(GreeLanDevice(cid: cid, address: '127.0.0.1'), devKey);
    expect(ok, false);
  });
}
