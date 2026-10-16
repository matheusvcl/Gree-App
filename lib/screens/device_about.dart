import 'package:flutter/material.dart';
import '../theme.dart';
import '../state.dart';
import '../widgets.dart';

/* Sobre o aparelho: identidade, firmware e endereço de rede */
class DeviceAboutScreen extends StatelessWidget {
  final AppState st;
  const DeviceAboutScreen({super.key, required this.st});

  @override
  Widget build(BuildContext context) {
    final p = context.palette();
    final d = st.dev;
    final linked = d.mac.isNotEmpty || d.ip.isNotEmpty;

    Widget row(String label, String value, {bool mono = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(children: [
            Expanded(child: Text(label, style: TextStyle(fontSize: 12.5, color: p.dim))),
            const SizedBox(width: 12),
            Flexible(
              child: Text(value.isEmpty ? '—' : value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: value.isEmpty ? p.dimmer : p.text,
                      fontFamily: mono ? 'monospace' : null)),
            ),
          ]),
        );

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          TopBar(title: 'Sobre', center: true, onBack: () => Navigator.pop(context)),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 60), children: [
              const SectionTitle('Aparelho'),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(children: [
                  row('Nome', d.name),
                  row('Ambiente', d.room),
                  row('Modelo (ID)', d.model),
                  row('Versão', d.fw),
                  row('Firmware', d.fw),
                ]),
              ),
              const SectionTitle('Rede'),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(children: [
                  row('Rede Wi-Fi', d.wifi),
                  row('Endereço IP', d.ip, mono: true),
                  row('MAC', d.mac, mono: true),
                ]),
              ),
              if (!linked)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Center(
                    child: Text(
                      'Conecte o ar em "Gerenciar ar → Conectar o ar"\npara preencher os dados de rede e firmware.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: p.dim, height: 1.5),
                    ),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}
