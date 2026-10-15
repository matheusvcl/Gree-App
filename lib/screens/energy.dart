import 'package:flutter/material.dart';
import '../theme.dart';
import '../state.dart';
import '../widgets.dart';

class EnergyScreen extends StatelessWidget {
  final AppState st;
  const EnergyScreen({super.key, required this.st});

  @override
  Widget build(BuildContext context) {
    final p = context.palette();
    String money(num kwh) => 'R\$ ${(kwh * st.tariff).toStringAsFixed(2).replaceAll('.', ',')}';
    const pcts = [62, 18, 20, 8];

    return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 140), children: [
      Row(children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: p.line)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(money(4.2), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: p.text)),
              const SizedBox(height: 4),
              Text('Hoje · 4,2 kWh', style: TextStyle(fontSize: 11.5, color: p.dim)),
            ]),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: p.line)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(money(24.8), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: p.text)),
              const SizedBox(height: 4),
              Text('Esta semana · 24,8 kWh', style: TextStyle(fontSize: 11.5, color: p.dim)),
            ]),
          ),
        ),
      ]),
      const SectionTitle('Últimos 7 dias'),
      AppCard(
        child: SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final h in const [42, 55, 38, 61, 48, 72, 58])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: h / 100),
                      duration: const Duration(milliseconds: 550),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, child) => Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: v.clamp(.04, 1),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [AppColors.accent, AppColors.accent.withValues(alpha: .35)]),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      const SectionTitle('Por aparelho'),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(children: [
          for (var i = 0; i < st.devices.length && i < 4; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(st.devices[i].name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.text)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: pcts[i] / 100),
                        duration: const Duration(milliseconds: 550),
                        builder: (_, v, child) => LinearProgressIndicator(
                          value: v,
                          minHeight: 5,
                          backgroundColor: p.surface2,
                          valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${pcts[i]}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.text)),
                  Text('${(24.8 * pcts[i] / 100).toStringAsFixed(1)} kWh', style: TextStyle(fontSize: 10.5, color: p.dim)),
                ]),
              ]),
            ),
        ]),
      ),
    ]);
  }
}
