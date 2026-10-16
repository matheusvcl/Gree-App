import 'package:flutter/material.dart';
import '../theme.dart';
import '../state.dart';
import '../widgets.dart';
import '../services/gree_lan.dart';
import 'device_pairing.dart';
import 'device_about.dart';

/* Gestão individual do aparelho: identidade, conexão LAN (vincular, testar,
   trocar rede) e reset. As ações falam com o protocolo Gree de verdade. */
class DeviceManageScreen extends StatefulWidget {
  final AppState st;
  const DeviceManageScreen({super.key, required this.st});

  @override
  State<DeviceManageScreen> createState() => _DeviceManageScreenState();
}

class _DeviceManageScreenState extends State<DeviceManageScreen> {
  late TextEditingController name;
  late TextEditingController room;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.st.dev.name);
    room = TextEditingController(text: widget.st.dev.room);
  }

  @override
  void dispose() {
    name.dispose();
    room.dispose();
    super.dispose();
  }

  Widget _connRow(AppPalette p, {required IconData icon, required String title, required String sub, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(children: [
          Icon(icon, size: 19, color: p.text),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.text)),
              Text(sub, style: TextStyle(fontSize: 11, color: p.dim)),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, size: 18, color: p.dimmer),
        ]),
      ),
    );
  }

  Future<void> _testConnection(BuildContext context) async {
    final st = widget.st;
    final d = st.dev;
    if (d.mac.isEmpty || d.lanKey.isEmpty || d.ip.isEmpty) {
      showToast(context, 'Vincule o aparelho primeiro em "Conectar o ar"');
      return;
    }
    showToast(context, 'Testando conexão com o ar…');
    final ok = await GreeLan().ping(GreeLanDevice(cid: d.mac, address: d.ip), d.lanKey);
    if (!context.mounted) return;
    showToast(context, ok ? 'Ar respondendo na rede' : 'Sem resposta — o IP pode ter mudado; use Re-vincular');
  }

  void _wifiGuide(BuildContext context) {
    final st = widget.st;
    final p = context.palette();
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Trocar a rede Wi-Fi do ar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.text)),
            const SizedBox(height: 12),
            Text(
              '1. Segure o botão Wi-Fi/Reset do ar por ~5 segundos até o LED piscar\n'
              '2. Configure a nova rede no módulo (o app oficial Gree+ faz esse passo de provisionamento)\n'
              '3. Com o ar já na nova rede, volte aqui e refaça o pareamento',
              style: TextStyle(fontSize: 13, color: p.dim, height: 1.6),
            ),
            const SizedBox(height: 16),
            AppChip(
              label: 'Re-vincular agora',
              on: true,
              small: true,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => DevicePairingScreen(st: st, device: st.dev)));
              },
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.st;
    final d = st.dev;
    final p = context.palette();

    return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 140), children: [
      AppCard(
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(15)),
            child: Icon(Icons.ac_unit_rounded, size: 21, color: AppColors.accent),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.text)),
              const SizedBox(height: 2),
              Text('${d.room} · ${d.wifi.isEmpty ? 'sem rede' : d.wifi}',
                  style: TextStyle(fontSize: 11.5, color: p.dim)),
            ]),
          ),
        ]),
      ),
      const SectionTitle('Configuração'),
      AppCard(
        child: Column(children: [
          TextField(
            controller: name,
            style: TextStyle(color: p.text, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Nome do aparelho',
              labelStyle: TextStyle(color: p.dim, fontSize: 12),
              filled: true,
              fillColor: p.surface2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.line)),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: room,
            style: TextStyle(color: p.text, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Ambiente',
              labelStyle: TextStyle(color: p.dim, fontSize: 12),
              filled: true,
              fillColor: p.surface2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.line)),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: AppChip(
              label: 'Salvar',
              ghost: true,
              small: true,
              onTap: () {
                st.patchDev((x) {
                  if (name.text.trim().isNotEmpty) x.name = name.text.trim();
                  if (room.text.trim().isNotEmpty) x.room = room.text.trim();
                });
                showToast(context, 'Configuração salva');
              },
            ),
          ),
        ]),
      ),
      const SectionTitle('Conexão'),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(children: [
              Icon(d.mac.isEmpty ? Icons.link_off_rounded : Icons.link_rounded,
                  size: 19, color: d.mac.isEmpty ? p.dimmer : AppColors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.mac.isEmpty ? 'Não vinculado' : 'Vinculado pela rede local',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.text)),
                  Text(d.mac.isEmpty ? 'Conecte o ar para controlar pela rede' : '${d.mac} · ${d.ip}',
                      style: TextStyle(fontSize: 11, color: p.dim)),
                ]),
              ),
            ]),
          ),
          _connRow(
            p,
            icon: d.mac.isEmpty ? Icons.settings_remote_rounded : Icons.sync_rounded,
            title: d.mac.isEmpty ? 'Conectar o ar' : 'Re-vincular',
            sub: d.mac.isEmpty ? 'Procurar o aparelho na rede e vincular' : 'Refazer o pareamento (ex.: IP mudou)',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DevicePairingScreen(st: st, device: d))),
          ),
          _connRow(
            p,
            icon: Icons.wifi_tethering_rounded,
            title: 'Testar conexão',
            sub: 'Ver se o ar responde na rede',
            onTap: () => _testConnection(context),
          ),
          _connRow(
            p,
            icon: Icons.wifi_find_rounded,
            title: 'Trocar rede Wi-Fi',
            sub: 'Guiar a troca de roteador/rede do aparelho',
            onTap: () => _wifiGuide(context),
          ),
        ]),
      ),
      const SectionTitle('Sobre'),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: _connRow(
          p,
          icon: Icons.info_outline_rounded,
          title: 'Sobre o aparelho',
          sub: 'Modelo, firmware e endereço de rede',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DeviceAboutScreen(st: st))),
        ),
      ),
      const SectionTitle('Manutenção'),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
          onTap: () async {
            final ok = await showConfirm(context,
                title: 'Resetar o aparelho?',
                text: 'O ${d.name} volta às configurações originais e é desvinculado do app.\n\n'
                    'No ar: segure o botão Reset por ~10 segundos até o LED apagar, para o módulo voltar ao padrão de fábrica.',
                okLabel: 'Resetar');
            if (!ok) return;
            st.patchDev((x) {
              x
                ..name = 'Ar-condicionado'
                ..temp = 22
                ..mode = 'cool'
                ..fan = 2
                ..swing = 'Fixo'
                ..wifi = ''
                ..mac = ''
                ..lanKey = ''
                ..ip = ''
                ..on = false;
            });
            if (context.mounted) showToast(context, 'Aparelho resetado e desvinculado');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(children: [
              const Icon(Icons.restart_alt_rounded, size: 19, color: AppColors.danger),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Resetar o aparelho',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.danger)),
                  Text('Volta ao padrão de fábrica e desvincula do app',
                      style: TextStyle(fontSize: 11, color: p.dim)),
                ]),
              ),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 8),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
          onTap: () async {
            final ok = await showConfirm(context,
                title: 'Excluir este ar?',
                text: '${d.name} será removido do app e da família. Os agendamentos dele também saem.',
                okLabel: 'Excluir');
            if (!ok) return;
            st.removeDevice(d.id);
            if (context.mounted) {
              st.go('home');
              showToast(context, 'Aparelho excluído');
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(children: [
              const Icon(Icons.delete_rounded, size: 19, color: AppColors.danger),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Excluir este ar',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.danger)),
                  Text('Remove o aparelho do app e da família',
                      style: TextStyle(fontSize: 11, color: p.dim)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }
}
