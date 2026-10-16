import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../state.dart';
import '../widgets.dart';
import '../services/gree_lan.dart';

/* Pareamento do ar na rede local: scan (UDP 7000) → bind → salva MAC + chave */
class DevicePairingScreen extends StatefulWidget {
  final AppState st;
  final Device device;
  const DevicePairingScreen({super.key, required this.st, required this.device});

  @override
  State<DevicePairingScreen> createState() => _DevicePairingScreenState();
}

class _DevicePairingScreenState extends State<DevicePairingScreen> {
  bool scanning = false;
  bool binding = false;
  String step = '';
  List<GreeLanDevice> found = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
  }

  Future<void> _scan() async {
    setState(() {
      scanning = true;
      found = [];
      step = 'Procurando ar-condicionados na rede...';
    });
    final list = await GreeLan().scan();
    if (!mounted) return;
    setState(() {
      scanning = false;
      found = list;
      step = list.isEmpty
          ? 'Nenhum aparelho achado. Coloque o ar em modo pareamento e tente de novo.'
          : 'Toque no aparelho para vincular.';
    });
  }

  Future<void> _bind(GreeLanDevice dev) async {
    setState(() {
      binding = true;
      step = 'Vinculando ${dev.name.isNotEmpty ? dev.name : dev.cid}...';
    });
    final key = await GreeLan().bind(dev);
    if (!mounted) return;
    if (key == null) {
      setState(() {
        binding = false;
        step = 'Não foi possível vincular. Coloque o ar em modo pareamento e tente de novo.';
      });
      return;
    }
    final st = widget.st;
    st.patchDev((d) {
      d.mac = dev.cid;
      d.lanKey = key;
      d.ip = dev.address;
      d.fw = dev.ver;
      d.model = dev.model;
      if (d.wifi.isEmpty) d.wifi = 'rede local';
    });
    setState(() {
      binding = false;
      step = 'Vinculado com sucesso! O aparelho já pode ser controlado pela rede.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette();
    final web = !GreeLan.supported;
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          TopBar(title: 'Conectar o ar', center: true, onBack: () => Navigator.pop(context)),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 60), children: [
        if (web)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              'A busca e o pareamento funcionam pelo celular — o navegador não tem acesso à rede local.',
              style: TextStyle(color: AppColors.danger, fontSize: 12.5, height: 1.5),
            ),
          ),
        Text(
          '1. No ar, segure o botão de Wi-Fi (ou Reset) por ~5 segundos até o LED piscar\n'
          '2. O celular precisa estar na mesma rede Wi-Fi do ar\n'
          '3. Toque no aparelho encontrado para vincular',
          style: TextStyle(color: p.dim, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 18),
        if (scanning)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)),
          ),
        for (final d in found)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: binding ? null : () => _bind(d),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: p.line),
                ),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.ac_unit_rounded, size: 20, color: p.text),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d.name.isNotEmpty ? d.name : 'Gree ${d.cid}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.text)),
                      const SizedBox(height: 2),
                      Text('${d.address} · ${d.cid}', style: TextStyle(fontSize: 11, color: p.dim)),
                    ]),
                  ),
                  binding
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
                      : Icon(Icons.link_rounded, color: AppColors.accent, size: 18),
                ]),
              ),
            ),
          ),
        if (!scanning && step.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: Text(step, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: p.dim)),
            ),
          ),
        const SizedBox(height: 18),
        if (!scanning)
          AppChip(label: 'Procurar de novo', ghost: true, small: true, onTap: _scan),
            ]),
          ),
        ]),
      ),
    );
  }
}
