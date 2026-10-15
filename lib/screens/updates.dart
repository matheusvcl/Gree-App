import 'package:flutter/material.dart';
import '../theme.dart';
import '../state.dart';
import '../widgets.dart';
import '../updater.dart';
import '../version.dart';

/* Atualizações: versão instalada, verificação manual e o histórico do app
   (docs/changelog/CHANGELOG.md embutido como asset). */
class UpdatesScreen extends StatefulWidget {
  final AppState st;
  const UpdatesScreen({super.key, required this.st});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  String version = '—';
  List<_ChangeSection> sections = [];
  bool checking = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await DefaultAssetBundle.of(context).loadString('docs/changelog/CHANGELOG.md');
    if (!mounted) return;
    setState(() {
      version = kAppVersion;
      sections = _parse(raw);
    });
  }

  static List<_ChangeSection> _parse(String raw) {
    final out = <_ChangeSection>[];
    _ChangeSection? cur;
    for (final line in raw.split('\n')) {
      if (line.startsWith('## ')) {
        cur = _ChangeSection(line.substring(3).trim());
        out.add(cur);
      } else if (cur != null && line.startsWith('### ')) {
        cur.blocks.add(_Block(line.substring(4).trim(), []));
      } else if (cur != null && line.trim().startsWith('- ')) {
        if (cur.blocks.isEmpty) cur.blocks.add(_Block('', []));
        cur.blocks.last.items.add(line.trim().substring(2));
      }
    }
    return out;
  }

  Future<void> _check() async {
    setState(() => checking = true);
    final info = await Updater.check();
    if (!mounted) return;
    setState(() => checking = false);
    if (info == null) {
      showToast(context, 'Você está na última versão');
    } else {
      showUpdateDialog(context, info);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette();
    return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 140), children: [
      AppCard(
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.system_update_rounded, size: 20, color: AppColors.accent),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Versão instalada: v$version',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.text)),
              const SizedBox(height: 2),
              Text('Atualização automática ativa', style: TextStyle(fontSize: 11, color: p.dim)),
            ]),
          ),
          AppChip(
            label: checking ? 'Verificando…' : 'Verificar',
            on: true,
            small: true,
            onTap: checking ? null : _check,
          ),
        ]),
      ),
      const SectionTitle('O que mudou'),
      for (final s in sections)
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: p.text)),
            const SizedBox(height: 10),
            for (final b in s.blocks) ...[
              if (b.subtitle.isNotEmpty) ...[
                Text(b.subtitle,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: p.dim, letterSpacing: .4)),
                const SizedBox(height: 6),
              ],
              for (final item in b.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: 8),
                      child: Container(width: 5, height: 5, decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                    ),
                    Expanded(
                      child: Text(item, style: TextStyle(fontSize: 12, color: p.dim, height: 1.5)),
                    ),
                  ]),
                ),
              const SizedBox(height: 4),
            ],
          ]),
        ),
    ]);
  }
}

class _ChangeSection {
  final String title;
  final List<_Block> blocks = [];
  _ChangeSection(this.title);
}

class _Block {
  final String subtitle;
  final List<String> items;
  _Block(this.subtitle, this.items);
}
