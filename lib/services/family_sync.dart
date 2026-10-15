import 'dart:convert';
import 'package:http/http.dart' as http;

/* Sync da família via Cloudflare Worker (worker/ — gree-family).
   O código da família é a chave; cada app guarda/sincroniza membros,
   locais e aparelhos. O controle dos ar-condicionados continua direto
   na rede local — o cloud só guarda o registro da família. */
const familySyncUrl = 'https://gree-family.matheusvicolli.workers.dev';

class FamilySync {
  static Future<Map<String, dynamic>?> fetch(String code) async {
    try {
      final r = await http
          .get(Uri.parse('$familySyncUrl/family/${code.toUpperCase()}'))
          .timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) return null;
      final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      return j.isEmpty ? null : j;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> push(String code, Map<String, dynamic> record) async {
    try {
      final r = await http
          .post(
            Uri.parse('$familySyncUrl/family/${code.toUpperCase()}'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode(record),
          )
          .timeout(const Duration(seconds: 8));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
