import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'gree_crypto.dart';

class GreeLanDevice {
  final String cid; // MAC do módulo
  final String name;
  final String ver;
  final String model;
  final String address; // IP
  GreeLanDevice({required this.cid, required this.address, this.name = '', this.ver = '', this.model = ''});
}

class GreeLan {
  static bool get supported => true;

  static const _scan = '{"t":"scan"}';

  Future<RawDatagramSocket> _open() async {
    final s = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    s.broadcastEnabled = true;
    return s;
  }

  Map<String, dynamic>? _decodePack(Uint8List data, String key) {
    try {
      final msg = json.decode(utf8.decode(data)) as Map<String, dynamic>;
      if (msg['pack'] == null) return null;
      return greeDecrypt(msg['pack'] as String, key);
    } catch (_) {
      return null;
    }
  }

  /* varre a rede local por ar-condicionados Gree (UDP 7000) */
  Future<List<GreeLanDevice>> scan({Duration timeout = const Duration(seconds: 5)}) async {
    final socket = await _open();
    final found = <String, GreeLanDevice>{};
    final sub = socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final dg = socket.receive();
      if (dg == null) return;
      final pack = _decodePack(dg.data, kGreeGenericKey);
      if (pack == null) return;
      final cid = ((pack['cid'] ?? pack['mac'] ?? '') as String).trim();
      if (cid.isEmpty) return;
      found[cid] = GreeLanDevice(
        cid: cid,
        address: dg.address.address,
        name: (pack['name'] ?? 'Gree') as String,
        ver: (pack['ver'] ?? '') as String,
        model: (pack['bc'] ?? pack['catalog'] ?? '') as String,
      );
    });
    // UDP é perdedor: repete o scan durante a janela
    Timer.periodic(const Duration(milliseconds: 900), (t) {
      socket.send(utf8.encode(_scan), InternetAddress('255.255.255.255'), 7000);
    });
    socket.send(utf8.encode(_scan), InternetAddress('255.255.255.255'), 7000);
    await Future.delayed(timeout);
    await sub.cancel();
    socket.close();
    return found.values.toList();
  }

  /* vincula o aparelho e devolve a chave exclusiva dele */
  Future<String?> bind(GreeLanDevice dev, {Duration timeout = const Duration(seconds: 5)}) async {
    final socket = await _open();
    final done = Completer<String?>();
    final sub = socket.listen((event) {
      if (event != RawSocketEvent.read || done.isCompleted) return;
      final dg = socket.receive();
      if (dg == null) return;
      final pack = _decodePack(dg.data, kGreeGenericKey);
      if (pack == null) return;
      if (pack['t'] == 'bindok' && pack['key'] != null) {
        done.complete(pack['key'] as String);
      }
    });
    final env = greeEnvelope(t: 'pack', tcid: dev.cid, pack: {'mac': dev.cid, 't': 'bind', 'uid': 0});
    socket.send(utf8.encode(json.encode(env)), InternetAddress(dev.address), 7000);
    final key = await done.future.timeout(timeout, onTimeout: () => null);
    await sub.cancel();
    socket.close();
    return key;
  }

  /* pede o status atual do aparelho */
  Future<Map<String, dynamic>?> status(GreeLanDevice dev, String key) async {
    const cols = ['pow', 'mod', 'settem', 'windspeed', 'air', 'health', 'lights', 'swing', 'turbo', 'lock', 'name'];
    final pack = {'mac': dev.cid, 't': 'dat', 'cols': cols, 'i': 1, 'uid': 0};
    return _request(dev, key, pack);
  }

  /* testa se o aparelho responde */
  Future<bool> ping(GreeLanDevice dev, String key) async => await status(dev, key) != null;

  /* envia comandos: opt lista os campos, p os valores (ex.: opt=[pow,settem], p=[1,24]) */
  Future<bool> command(GreeLanDevice dev, String key, List<String> opt, List<dynamic> p) async {
    final pack = {'cid': dev.cid, 'i': 1, 't': 'cmd', 'uid': 0, 'opt': opt, 'p': p};
    return await _request(dev, key, pack) != null;
  }

  Future<Map<String, dynamic>?> _request(GreeLanDevice dev, String key, Map<String, dynamic> pack, {Duration timeout = const Duration(seconds: 4)}) async {
    final socket = await _open();
    final done = Completer<Map<String, dynamic>?>();
    final sub = socket.listen((event) {
      if (event != RawSocketEvent.read || done.isCompleted) return;
      final dg = socket.receive();
      if (dg == null) return;
      final p = _decodePack(dg.data, key);
      if (p == null) return;
      done.complete(p);
    });
    final env = greeEnvelope(t: 'pack', tcid: dev.cid, pack: pack, key: key);
    socket.send(utf8.encode(json.encode(env)), InternetAddress(dev.address), 7000);
    final res = await done.future.timeout(timeout, onTimeout: () => null);
    await sub.cancel();
    socket.close();
    return res;
  }
}
