import 'package:flutter_test/flutter_test.dart';
import 'package:gree_app/services/gree_crypto.dart';

void main() {
  test('AES-128-ECB confere com o openssl (vetor conhecido)', () {
    // gerado com: openssl enc -aes-128-ecb -K 61334b38427825327238593723784468 -nosalt
    const expected = 'F2TbJuBPyruBIJvZ1allpehlk4bvqevljypqCJLauZij9mrs/0p7GUTdWxmNaBUt';
    final pack = greeEncrypt({'mac': '00123456789a', 't': 'bind', 'uid': 0}, kGreeGenericKey);
    expect(pack, expected);
  });

  test('round-trip encrypt/decrypt', () {
    final payload = {'cid': 'abc123', 'i': 7, 't': 'cmd', 'uid': 0, 'opt': ['pow', 'settem'], 'p': [1, 24]};
    final pack = greeEncrypt(payload, 'minha-chave-16ch');
    expect(greeDecrypt(pack, 'minha-chave-16ch'), payload);
  });

  test('envelope tem os campos esperados', () {
    final e = greeEnvelope(t: 'pack', tcid: '00123456789a', pack: {'mac': '00123456789a', 't': 'bind', 'uid': 0});
    expect(e['cid'], 'app');
    expect(e['tcid'], '00123456789a');
    expect(e['t'], 'pack');
    expect(greeDecrypt(e['pack'] as String, kGreeGenericKey)['t'], 'bind');
  });
}
