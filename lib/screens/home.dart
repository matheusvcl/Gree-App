import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../state.dart';
import '../widgets.dart';
import '../services/remote.dart';

/* ---------- borda em onda (card ligado) ---------- */
class WaveBorder extends StatefulWidget {
  final Widget child;
  final BorderRadius radius;
  final Color color;
  const WaveBorder({super.key, required this.child, required this.radius, this.color = const Color(0xFF4EA8FF)});

  @override
  State<WaveBorder> createState() => _WaveBorderState();
}

class _WaveBorderState extends State<WaveBorder> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => CustomPaint(
        painter: _WavePainter(angle: _c.value * 2 * pi, radius: widget.radius, color: widget.color),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _WavePainter extends CustomPainter {
  final double angle;
  final BorderRadius radius;
  final Color color;
  _WavePainter({required this.angle, required this.radius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndCorners(Offset.zero & size,
        topLeft: radius.topLeft, topRight: radius.topRight, bottomLeft: radius.bottomLeft, bottomRight: radius.bottomRight);
    final shader = SweepGradient(
      startAngle: 0,
      endAngle: 2 * pi,
      transform: GradientRotation(angle),
      colors: [
        color.withValues(alpha: 0),
        color.withValues(alpha: .95),
        color.withValues(alpha: .22),
        color.withValues(alpha: 0),
        color.withValues(alpha: .6),
        color.withValues(alpha: 0),
      ],
      stops: const [0, .16, .38, .58, .82, 1],
    ).createShader(Offset.zero & size);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..shader = shader;
    canvas.drawRRect(rrect.deflate(1), paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.angle != angle;
}

/* ---------- card de aparelho ---------- */
class DeviceCard extends StatelessWidget {
  final AppState st;
  final Device d;
  final VoidCallback onOpen;
  final VoidCallback onPower;
  const DeviceCard({super.key, required this.st, required this.d, required this.onOpen, required this.onPower});

  IconData get _modeIcon => switch (d.mode) {
        'cool' => Icons.ac_unit_rounded,
        'heat' => Icons.whatshot_rounded,
        'dry' => Icons.water_drop_rounded,
        'fan' => Icons.air_rounded,
        _ => Icons.brightness_auto_rounded,
      };

  String get _modeLabel => switch (d.mode) {
        'cool' => 'Resfriar',
        'heat' => 'Aquecer',
        'dry' => 'Desumidificar',
        'fan' => 'Ventilar',
        _ => 'Automático',
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette();
    final c = modeAccent(d.mode);
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: d.on ? c.withValues(alpha: .62) : p.line),
        boxShadow: d.on ? [BoxShadow(color: c.withValues(alpha: .12), blurRadius: 22)] : null,
      ),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(15)),
          child: Icon(_modeIcon, size: 21, color: d.on ? c : p.dim),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.name, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: p.text)),
            const SizedBox(height: 3),
            Text('${d.room} · ${d.on ? "${st.tempDisp(d.temp)}°${st.unit}" : "Desligado"}',
                style: TextStyle(fontSize: 12.5, color: p.dim)),
            const SizedBox(height: 2),
            Text('$_modeLabel · ${['Silencioso', 'Baixa', 'Média', 'Alta', 'Turbo'][d.fan]}',
                style: TextStyle(fontSize: 11, color: p.dimmer)),
          ]),
        ),
        GestureDetector(
          onTap: onPower,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: d.on ? c : p.surface2,
              shape: BoxShape.circle,
              border: Border.all(color: d.on ? c : p.line),
            ),
            child: Icon(Icons.power_settings_new_rounded,
                size: 20, color: d.on ? Colors.white : p.dim),
          ),
        ),
      ]),
    );
    return GestureDetector(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: d.on
            ? WaveBorder(radius: BorderRadius.circular(22), color: c, child: card)
            : card,
      ),
    );
  }
}

/* ---------- tela inicial ---------- */
class HomeScreen extends StatelessWidget {
  final AppState st;
  const HomeScreen({super.key, required this.st});

  @override
  Widget build(BuildContext context) {
    final p = context.palette();
    final rooms = ['Todos', ...st.locRooms()];
    final inLoc = st.devices.where((d) => st.locRooms().contains(d.room)).toList();
    final list = inLoc.where((d) => st.room == 'Todos' || d.room == st.room).toList();
    final onCount = inLoc.where((d) => d.on).length;

    return Stack(children: [
      ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 170), children: [
        // seletor de local
        Center(
          child: GestureDetector(
            onTap: () {
              // um local só: vai direto para Gerenciar locais; dois ou mais: abre o seletor
              if (st.locations.length > 1) {
                _openLocMenu(context);
              } else {
                st.go('locations');
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                color: p.surface2,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: p.line),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.location_on_outlined, size: 15, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(st.loc.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.text)),
                if (st.locations.length > 1) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 17, color: p.dim),
                ],
              ]),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // clima
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: p.line),
          ),
          child: st.weatherTemp != null
              ? Row(children: [
                  Icon(WeatherNow.iconOf(st.weatherCode ?? 2, st.weatherIsDay, wind: st.weatherWind),
                      size: 34, color: AppColors.warn),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${st.tempDisp(st.weatherTemp!)}°${st.unit}${st.usesFahrenheit ? ' · ${st.tempAlt(st.weatherTemp!)}' : ''} · ${WeatherNow.conditionOf(st.weatherCode ?? 2)}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.text)),
                      const SizedBox(height: 3),
                      Text('Umidade ${st.weatherHumidity!.round()}% · Sensação ${st.tempDisp(st.weatherFeels!)}°${st.unit}',
                          style: TextStyle(fontSize: 11.5, color: p.dim)),
                    ]),
                  ),
                  if (st.city.isNotEmpty)
                    Text('${st.city}/${st.uf}', style: TextStyle(fontSize: 11, color: p.dimmer)),
                ])
              : GestureDetector(
                  onTap: () => st.go('energyset'),
                  child: Row(children: [
                    const Icon(Icons.location_on_outlined, size: 24, color: AppColors.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Definir localização',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.text)),
                        const SizedBox(height: 2),
                        Text('Clima e tarifa de energia automáticos',
                            style: TextStyle(fontSize: 11, color: p.dim)),
                      ]),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 18, color: p.dimmer),
                  ]),
                ),
        ),
        SectionTitleAction('${rooms.contains(st.room) ? st.room : "Todos"} · $onCount de ${inLoc.length} ligados',
            label: 'Novo dispositivo', onTap: () => _addDevice(context)),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final r in rooms)
            AppChip(label: r, on: st.room == r, small: true, onTap: () {
              st.room = r;
              st.touch();
            }),
        ]),
        const SizedBox(height: 12),
        for (final d in list)
          DeviceCard(
            st: st,
            d: d,
            onOpen: () {
              st.selected = d.id;
              st.go('control');
            },
            onPower: () {
              d.on = !d.on;
              st.touch();
            },
          ),
      ]),
    ]);
  }

  void _openLocMenu(BuildContext context) {
    final p = context.palette();
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(width: 42, height: 4, decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(2))),
          for (final l in st.locations)
            ListTile(
              onTap: () {
                st.selectLoc(l.id);
                st.touch();
                Navigator.pop(context);
              },
              leading: Icon(st.activeLoc == l.id ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: st.activeLoc == l.id ? AppColors.accent : p.dim, size: 20),
              title: Text(l.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.text)),
              subtitle: Text('${l.rooms.length} ambientes · ${l.rooms.join(', ')}',
                  style: TextStyle(fontSize: 11.5, color: p.dim)),
            ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                st.go('locations');
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: p.surface2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.line),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.settings_rounded, size: 17, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text('Gerenciar locais',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.text)),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _addDevice(BuildContext context) {
    st.resetNewDeviceDraft();
    st.go('adddevice');
  }
}
