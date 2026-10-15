import 'package:flutter/material.dart';
import '../theme.dart';
import '../state.dart';
import '../widgets.dart';

/* Gestão individual do aparelho: configuração, rede Wi-Fi e reset de fábrica.
   Os botões já estão ligados ao estado — quando o protocolo real entrar,
   cada ação vira o comando correspondente para o ar. */
class DeviceManageScreen extends StatefulWidget {
  final AppState st;
  const DeviceManageScreen({super.key, required this.st});

  @override
  State<DeviceManageScreen> createState() => _DeviceManageScreenState();
}

class _DeviceManageScreenState extends State<DeviceManageScreen> {
  late TextEditingController name;
  late TextEditingController room;
  final ssid = TextEditingController();
  final pass = TextEditingController();
  bool connecting = false;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.st.dev.name);
    room = TextEditingController(text: widget.st.dev.room);
    ssid.text = widget.st.dev.wifi;
  }

  @override
  void dispose() {
    name.dispose();
    room.dispose();
    ssid.dispose();
    pass.dispose();
    super.dispose();
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
      const SectionTitle('Rede Wi-Fi'),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.wifi_rounded, size: 18, color: d.wifi.isEmpty ? p.dimmer : AppColors.accent),
            const SizedBox(width: 10),
            Text(d.wifi.isEmpty ? 'Nenhuma rede conectada' : d.wifi,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.text)),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: ssid,
            style: TextStyle(color: p.text, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Nome da rede (SSID)',
              hintStyle: TextStyle(color: p.dimmer, fontSize: 12.5),
              filled: true,
              fillColor: p.surface2,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.line)),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: pass,
            obscureText: true,
            style: TextStyle(color: p.text, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Senha da rede',
              hintStyle: TextStyle(color: p.dimmer, fontSize: 12.5),
              filled: true,
              fillColor: p.surface2,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.line)),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: AppChip(
              label: connecting ? 'Conectando…' : 'Conectar',
              on: true,
              small: true,
              onTap: connecting
                  ? null
                  : () async {
                      if (ssid.text.trim().isEmpty) {
                        showToast(context, 'Informe o nome da rede');
                        return;
                      }
                      setState(() => connecting = true);
                      await Future.delayed(const Duration(milliseconds: 900));
                      if (!mounted) return;
                      st.patchDev((x) => x.wifi = ssid.text.trim());
                      setState(() => connecting = false);
                      showToast(context, 'Ar conectado a ${ssid.text.trim()}');
                    },
            ),
          ),
        ]),
      ),
      const SectionTitle('Manutenção'),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
          onTap: () async {
            final ok = await showConfirm(context,
                title: 'Redefinir de fábrica?',
                text: 'O ${d.name} volta às configurações originais: nome, temperatura, modo e rede. Você vai precisar configurar de novo.',
                okLabel: 'Redefinir');
            if (!ok) return;
            st.patchDev((x) {
              x
                ..name = 'Ar-condicionado'
                ..temp = 22
                ..mode = 'cool'
                ..fan = 2
                ..swing = 'Fixo'
                ..wifi = ''
                ..on = false;
            });
            if (context.mounted) showToast(context, 'Aparelho redefinido de fábrica');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(children: [
              const Icon(Icons.restart_alt_rounded, size: 19, color: AppColors.danger),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Redefinir de fábrica',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.danger)),
                  Text('Volta às configurações originais do aparelho',
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
