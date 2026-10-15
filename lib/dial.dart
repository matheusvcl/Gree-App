import 'dart:math';
import 'package:flutter/material.dart';
import 'theme.dart';

/* Dial 270° — arraste para ajustar, handle encaixa no valor (fim do arco = máximo) */
class TempDial extends StatefulWidget {
  final int temp, min, max;
  final String unit;
  final String sub; // ex.: "Resfriar · Silencioso"
  final String ambient; // ex.: "Ambiente 27°C · Umidade 52%"
  final ValueChanged<int> onChanged;
  const TempDial({
    super.key,
    required this.temp,
    required this.min,
    required this.max,
    required this.unit,
    required this.sub,
    required this.ambient,
    required this.onChanged,
  });

  @override
  State<TempDial> createState() => _TempDialState();
}

class _TempDialState extends State<TempDial> with SingleTickerProviderStateMixin {
  double _frac = 0; // fração visual (snapada no valor)
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220))..value = 1;

  @override
  void initState() {
    super.initState();
    _frac = _fracOf(widget.temp);
  }

  @override
  void didUpdateWidget(TempDial old) {
    super.didUpdateWidget(old);
    if (old.temp != widget.temp) _frac = _fracOf(widget.temp);
  }

  double _fracOf(int t) => ((t - widget.min) / (widget.max - widget.min)).clamp(0, 1);

  void _fromPoint(Offset local, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    double a = atan2(local.dy - c.dy, local.dx - c.dx) * 180 / pi;
    if (a < 0) a += 360;
    if (a < 135) a += 360;
    a = a.clamp(135, 405);
    final frac = (a - 135) / 270;
    final t = (widget.min + frac * (widget.max - widget.min)).round();
    if (t != widget.temp) widget.onChanged(t);
    setState(() => _frac = _fracOf(t));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette();
    return LayoutBuilder(builder: (_, c) {
      final size = Size(c.maxWidth, c.maxWidth);
      return GestureDetector(
        onPanStart: (d) => _fromPoint(d.localPosition, size),
        onPanUpdate: (d) => _fromPoint(d.localPosition, size),
        onPanEnd: (_) => _ctrl.forward(from: 0),
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(alignment: Alignment.center, children: [
            CustomPaint(
              size: size,
              painter: _DialPainter(
                frac: _frac,
                track: p.surface2,
                arc: AppColors.accent,
                handle: Colors.white,
              ),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(color: p.text, fontWeight: FontWeight.w200, height: 1),
                  children: [
                    TextSpan(text: '${widget.temp}', style: const TextStyle(fontSize: 62, fontWeight: FontWeight.w200)),
                    TextSpan(text: '°${widget.unit}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, color: p.dim)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(widget.sub, style: TextStyle(fontSize: 12.5, color: p.dim)),
              const SizedBox(height: 10),
              SizedBox(
                width: 150,
                child: Text(widget.ambient,
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: p.dimmer, height: 1.5)),
              ),
            ]),
          ]),
        ),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}

class _DialPainter extends CustomPainter {
  final double frac;
  final Color track, arc, handle;
  _DialPainter({required this.frac, required this.track, required this.arc, required this.handle});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 16;
    const startDeg = 135.0, sweepDeg = 270.0;
    final start = startDeg * pi / 180;
    final rect = Rect.fromCircle(center: c, radius: r);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(rect, start, sweepDeg * pi / 180, false, trackPaint);

    final end = (startDeg + sweepDeg * frac) * pi / 180;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = arc;
    if (frac > 0.002) {
      canvas.drawArc(rect, start, (end - start), false, arcPaint);
    }

    final hp = Paint()..color = handle;
    final pos = c + Offset(cos(end), sin(end)) * r;
    canvas.drawShadow(Path()..addOval(Rect.fromCircle(center: pos, radius: 13)), Colors.black, 6, false);
    canvas.drawCircle(pos, 13, hp);
    canvas.drawCircle(pos, 13, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = arc);
  }

  @override
  bool shouldRepaint(_DialPainter old) => old.frac != frac || old.arc != arc || old.track != track;
}
