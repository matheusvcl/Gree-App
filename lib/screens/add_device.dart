import 'package:flutter/material.dart';
import '../theme.dart';
import '../state.dart';
import '../widgets.dart';

/* Cadastro de um novo aparelho: nome, rede Wi-Fi e padrões.
   Os campos alimentam o rascunho no estado; "Adicionar" (barra) confirma. */
class AddDeviceScreen extends StatefulWidget {
  final AppState st;
  const AddDeviceScreen({super.key, required this.st});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  late final TextEditingController name;
  late final TextEditingController room;
  late final TextEditingController ssid;
  late final TextEditingController pass;

  @override
  void initState() {
    super.initState();
    final st = widget.st;
    name = TextEditingController(text: st.newDevName);
    room = TextEditingController(text: st.newDevRoom);
    ssid = TextEditingController(text: st.newDevWifi);
    pass = TextEditingController(text: st.newDevPass);
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
    final p = context.palette();
    return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 140), children: [
      _field(p, 'Nome do aparelho', name, (v) => st.newDevName = v),
      const SizedBox(height: 12),
      _field(p, 'Ambiente (ex.: Sala)', room, (v) => st.newDevRoom = v),
      const SectionTitle('Rede Wi-Fi'),
      _field(p, 'Nome da rede (SSID)', ssid, (v) => st.newDevWifi = v),
      const SizedBox(height: 12),
      _field(p, 'Senha da rede', pass, (v) => st.newDevPass = v, obscure: true),
      const SectionTitle('Padrões'),
      Text('Modo inicial', style: TextStyle(fontSize: 12, color: p.dim)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final e in const {
          'auto': 'Auto',
          'cool': 'Frio',
          'heat': 'Calor',
          'dry': 'Seco',
          'fan': 'Vento',
        }.entries)
          AppChip(label: e.value, on: st.newDevMode == e.key, small: true, onTap: () {
            st.newDevMode = e.key;
            st.touch();
          }),
      ]),
      const SizedBox(height: 16),
      Text('Temperatura inicial', style: TextStyle(fontSize: 12, color: p.dim)),
      const SizedBox(height: 8),
      Row(children: [
        _roundBtn(p, Icons.remove_rounded, () {
          st.newDevTemp = (st.newDevTemp - 1).clamp(st.tempMin, st.tempMax);
          st.touch();
        }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text('${st.newDevTemp}°${st.unit}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: p.text)),
        ),
        _roundBtn(p, Icons.add_rounded, () {
          st.newDevTemp = (st.newDevTemp + 1).clamp(st.tempMin, st.tempMax);
          st.touch();
        }),
      ]),
    ]);
  }

  Widget _field(AppPalette p, String hint, TextEditingController controller, ValueChanged<String> onChange, {bool obscure = false}) {
    return TextField(
      onChanged: onChange,
      obscureText: obscure,
      controller: controller,
      style: TextStyle(color: p.text, fontSize: 14.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: p.dimmer, fontSize: 13),
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: p.line)),
      ),
    );
  }

  Widget _roundBtn(AppPalette p, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: p.surface2, shape: BoxShape.circle, border: Border.all(color: p.line)),
        child: Icon(icon, size: 19, color: p.text),
      ),
    );
  }
}
