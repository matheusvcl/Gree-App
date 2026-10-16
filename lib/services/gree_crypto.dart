import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

/* Protocolo Gree/EWPE (UDP 7000) — camada de crypto + envelope
 * AES-128/ECB com padding PKCS-7, depois Base64 (o campo "pack").
 * Chave genérica usada no scan/bind: igual em todos os aparelhos.
 */
const String kGreeGenericKey = 'a3K8Bx%2r8Y7#xDh';

Uint8List _aesEcb(Uint8List data, Uint8List key, {required bool encrypt}) {
  final cipher = AESEngine()..init(encrypt, KeyParameter(key));
  final out = Uint8List(data.length);
  for (var i = 0; i < data.length; i += 16) {
    cipher.processBlock(data, i, out, i);
  }
  return out;
}

Uint8List _pad(Uint8List data) {
  final n = 16 - (data.length % 16);
  final out = Uint8List(data.length + n)..setAll(0, data);
  for (var i = data.length; i < out.length; i++) {
    out[i] = n;
  }
  return out;
}

Uint8List _unpad(Uint8List data) {
  if (data.isEmpty) return data;
  final n = data.last;
  if (n < 1 || n > 16 || n > data.length) return data;
  return data.sublist(0, data.length - n);
}

/* encripta o payload JSON e devolve o "pack" (base64) */
String greeEncrypt(Map<String, dynamic> payload, String key) {
  final bytes = Uint8List.fromList(utf8.encode(json.encode(payload)));
  return base64.encode(_aesEcb(_pad(bytes), Uint8List.fromList(utf8.encode(key)), encrypt: true));
}

/* descriptografa um "pack" (base64) de volta para o payload JSON */
Map<String, dynamic> greeDecrypt(String pack, String key) {
  final raw = _unpad(_aesEcb(Uint8List.fromList(base64.decode(pack)), Uint8List.fromList(utf8.encode(key)), encrypt: false));
  return json.decode(utf8.decode(raw)) as Map<String, dynamic>;
}

/* envelope externo (JSON em claro) que envolve o pack */
Map<String, dynamic> greeEnvelope({required String t, required String tcid, required Map<String, dynamic> pack, String cid = 'app', String key = kGreeGenericKey, int i = 1}) {
  return {'cid': cid, 'i': i, 'uid': 0, 't': 'pack', 'tcid': tcid, 'pack': greeEncrypt(pack, key)};
}
