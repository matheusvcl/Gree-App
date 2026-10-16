import 'package:flutter/material.dart';
import '../theme.dart';
import '../state.dart';
import '../widgets.dart';
import '../dial.dart';

const MODES = {
  'auto': ('Automático', Icons.brightness_auto_rounded),
  'cool': ('Resfriar', Icons.ac_unit_rounded),
  'heat': ('Aquecer', Icons.whatshot_rounded),
  'dry': ('Desumidificar', Icons.water_drop_rounded),
  'fan': ('Ventilar', Icons.air_rounded),
};
const MODES_SHORT = {
  'auto': 'Auto',
  'cool': 'Frio',
  'heat': 'Calor',
  'dry': 'Seco',
  'fan': 'Vento',
};
const FANS = ['Silencioso', 'Baixa', 'Média', 'Alta', 'Turbo'];
const SWINGS = ['Fixo', 'Vertical', 'Horizontal', 'Ambos'];

class ControlScreen extends StatelessWidget {
  final AppState st;
  const ControlScreen({super.key, required this.st});

  @override
  Widget build(BuildContext context) {
    final p = context.palette();
    final d = st.dev;
    final (modeLabel, modeIcon) = MODES[d.mode] ?? MODES['cool']!;
    final c = modeAccent(d.mode);
    final cs = modeSoft(d.mode);

    return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 140), children: [
      const SizedBox(height: 26),
      Center(
        child: Text(d.name, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.text)),
      ),
      const SizedBox(height: 18),
      SizedBox(
        height: 250,
        child: TempDial(
          temp: d.temp,
          min: st.tempMin,
          max: st.tempMax,
          unit: st.unit,
          color: c,
          sub: '$modeLabel · ${FANS[d.fan]}',
          ambient: 'Ambiente 27°${st.unit} · Umidade 52%',
          onChanged: (t) {
            d.temp = t;
            st.touch();
          },
        ),
      ),
      const SectionTitle('Modo'),
      Row(children: [
        for (final e in MODES.entries)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  d.mode = e.key;
                  st.touch();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: d.mode == e.key ? cs : p.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: d.mode == e.key ? c : p.line),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(e.value.$2, size: 17, color: d.mode == e.key ? c : p.dim),
                    const SizedBox(height: 4),
                    Text(MODES_SHORT[e.key] ?? e.value.$1,
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: d.mode == e.key ? c : p.dim)),
                  ]),
                ),
              ),
            ),
          ),
      ]),
      const SectionTitle('Velocidade do vento'),
      Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          for (var i = 0; i < FANS.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  d.fan = i;
                  st.touch();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: d.fan == i ? p.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: d.fan == i ? Border.all(color: p.line) : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(FANS[i],
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: d.fan == i ? p.text : p.dim)),
                ),
              ),
            ),
        ]),
      ),
      const SectionTitle('Oscilação'),
      Row(children: [
        for (final s in SWINGS)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AppChip(label: s, on: d.swing == s, small: true, onTap: () {
              d.swing = s;
              st.touch();
            }),
          ),
      ]),
      const SectionTitle('Gerenciar'),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
          onTap: () => st.go('devmanage'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.settings_rounded, size: 18, color: p.text),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Gerenciar este ar',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.text)),
                  Text('Configurar, trocar rede e redefinir de fábrica',
                      style: TextStyle(fontSize: 11, color: p.dim)),
                ]),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: p.dimmer),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 18),
      Center(
        child: Text(d.on ? 'Ligado · ajuste em tempo real' : 'Desligado · toque em ligar na tela inicial',
            style: TextStyle(fontSize: 11.5, color: p.dimmer)),
      ),
    ]);
  }
}
