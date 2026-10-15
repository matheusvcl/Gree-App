import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'theme.dart';

/* Sistema de update automático via GitHub Releases (repo privado + token de leitura).
   O token entra em tempo de compilação via --dart-define=UPDATE_TOKEN=... (scripts/release.sh).
   Canal: releases/latest do repo matheusvcl/Gree-App; tag no formato v1.0.1+2 (versão+build). */
const _apiLatest = 'https://api.github.com/repos/matheusvcl/Gree-App/releases/latest';
const _token = String.fromEnvironment('UPDATE_TOKEN');

Map<String, String> get _headers => {
      'Accept': 'application/vnd.github+json',
      'User-Agent': 'GreeApp',
      if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
    };

class UpdateInfo {
  final String version;
  final int build;
  final String url; // URL da API do asset (funciona em repo privado com token)
  final String notes;
  UpdateInfo({required this.version, required this.build, required this.url, required this.notes});
  String get label => 'v$version';
}

class Updater {
  /* retorna a atualização disponível, ou null se já está atualizado/sem rede */
  static Future<UpdateInfo?> check() async {
    try {
      final r = await http.get(Uri.parse(_apiLatest), headers: _headers).timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return null;
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      final tag = (j['tag_name'] ?? '') as String;
      final m = RegExp(r'v?(\d+\.\d+\.\d+)(?:\+(\d+))?').firstMatch(tag);
      if (m == null) return null;
      final version = m.group(1)!;
      final build = int.tryParse(m.group(2) ?? '') ?? 0;
      String url = '';
      for (final a in (j['assets'] as List? ?? [])) {
        final name = (a['name'] ?? '') as String;
        if (name.endsWith('.apk')) {
          // URL da API do asset (browser_download_url não baixa de repo privado)
          url = (a['url'] ?? '') as String;
          break;
        }
      }
      if (url.isEmpty) return null;
      final pi = await PackageInfo.fromPlatform();
      final curBuild = int.tryParse(pi.buildNumber) ?? 0;
      final cmp = _cmpVersion(version, pi.version);
      final newer = cmp > 0 || (cmp == 0 && build > curBuild); // versão manda; build só desempata
      if (!newer) return null;
      return UpdateInfo(version: version, build: build, url: url, notes: (j['body'] ?? '') as String);
    } catch (_) {
      return null; // sem rede/token inválido: segue sem avisar
    }
  }

  static int _cmpVersion(String a, String b) {
    final pa = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final pb = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (var i = 0; i < 3; i++) {
      final d = (i < pa.length ? pa[i] : 0).compareTo(i < pb.length ? pb[i] : 0);
      if (d != 0) return d;
    }
    return 0;
  }

  /* baixa o APK com progresso; retorna o arquivo ou null em falha */
  static Future<File?> download(UpdateInfo info, void Function(double, int) onProgress) async {
    final client = http.Client();
    try {
      final req = http.Request('GET', Uri.parse(info.url))
        ..headers.addAll({
          ..._headers,
          'Accept': 'application/octet-stream', // necessário para baixar asset via API
        });
      final resp = await client.send(req);
      if (resp.statusCode != 200) return null;
      final total = resp.contentLength ?? 0;
      final file = File('${Directory.systemTemp.path}/gree-update.apk');
      final sink = file.openWrite();
      var received = 0;
      await for (final chunk in resp.stream) {
        received += chunk.length;
        sink.add(chunk);
        onProgress(total > 0 ? received / total : 0, received);
      }
      await sink.flush();
      await sink.close();
      return file;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  static Future<void> install(File file) => OpenFilex.open(file.path);
}

/* ---------- diálogo de atualização (estilo do app) ---------- */
Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) async {
  final progress = ValueNotifier<double?>(null); // null = não está baixando
  final err = ValueNotifier<String?>(null);
  await showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) {
        final palette = ctx.palette();
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 302,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            decoration: BoxDecoration(
                color: palette.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: palette.line)),
            child: ValueListenableBuilder<double?>(
              valueListenable: progress,
              builder: (_, pct, __) => Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Atualização disponível',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: palette.text)),
                const SizedBox(height: 6),
                Text(info.label,
                    style: TextStyle(fontSize: 11.5, color: palette.dim)),
                if (info.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(info.notes.trim(),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: palette.dim, height: 1.5)),
                ],
                const SizedBox(height: 18),
                if (pct == null)
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: palette.surface2, borderRadius: BorderRadius.circular(16)),
                          alignment: Alignment.center,
                          child: Text('Depois', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: palette.text)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          progress.value = 0;
                          err.value = null;
                          setLocal(() {});
                          final file = await Updater.download(info, (p0, _) => progress.value = p0);
                          if (file != null) {
                            Navigator.pop(ctx);
                            await Updater.install(file);
                          } else {
                            progress.value = null;
                            err.value = 'Falha no download. Toque em "Baixar e instalar" para tentar de novo.';
                            setLocal(() {});
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: const Color(0xFF4EA8FF), borderRadius: BorderRadius.circular(16)),
                          alignment: Alignment.center,
                          child: const Text('Baixar e instalar',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                    ),
                  ])
                else
                  Column(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                          value: pct == 0 ? null : pct, minHeight: 6, backgroundColor: palette.surface2),
                    ),
                    const SizedBox(height: 10),
                    Text(pct >= 1
                        ? 'Abrindo instalador…'
                        : pct == 0
                            ? 'Baixando…'
                            : 'Baixando ${(pct * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 12, color: palette.dim)),
                  ]),
                if (err.value != null) ...[
                  const SizedBox(height: 10),
                  Text(err.value!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11.5, color: const Color(0xFFFF4D4F), height: 1.5)),
                ],
              ]),
            ),
          ),
        );
      },
    ),
  );
  progress.dispose();
  err.dispose();
}
