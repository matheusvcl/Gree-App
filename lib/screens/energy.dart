import 'package:flutter/material.dart';
import '../theme.dart';
import '../state.dart';
import '../widgets.dart';

/* Energia: números calculados do estado real dos aparelhos (ligado, modo,
   temperatura, vento) — mudam ao vivo quando você controla o ar. */
class EnergyScreen extends StatelessWidget {
  final AppState st;
  const EnergyScreen({super.key, required this.st});

  /* estimativa diária de consumo de um aparelho (kWh) */
  double devKwh(Device d) {
    if (!d.on) return 0;
    final base = {'cool': 1.1, 'heat': 1.3, 'auto': 0.9, 'dry': 0.8, 'fan': 0.5}[d.mode] ?? 1.0;
    final tempFactor = 1 + (24 - d.temp).abs() * 0.06;
    final fanFactor = 1 + d.fan * 0.08;
    return base * tempFactor * fanFactor;
  }

  /* histórico estável dos últimos dias + hoje ao vivo */
  double dayKwh(DateTime day, double todayTotal) {
    final today = DateTime.now();
    final diff = DateTime(today.year, today.month, today.day)
        .difference(DateTime(day.year, day.month, day.day))
        .inDays;
    if (diff == 0) return todayTotal;
    final seed = ((day.day * 37 + day.month * 11) % 100) / 100; // 0..1 estável
    return todayTotal * (0.62 + seed * 0.72);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette();
    String money(num kwh) => 'R\$ ${(kwh * st.tariff).toStringAsFixed(2).replaceAll('.', ',')}';
    String kwh1(num v) => v.toStringAsFixed(1).replaceAll('.', ',');

    final devs = st.devices.where((d) => st.locRooms().contains(d.room)).toList();
    final today = devs.fold<double>(0, (a, d) => a + devKwh(d));
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final weekTotal = days.fold<double>(0, (a, d) => a + dayKwh(d, today));
    final maxDay = days.map((d) => dayKwh(d, today)).fold<double>(0.001, (a, b) => a > b ? a : b);
    final dayNames = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 140), children: [
      const SectionTitle('Consumo'),
      Row(children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            decoration: BoxDecoration(
                color: p.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: p.line)),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
              Text(money(today),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: p.text)),
              const SizedBox(height: 4),
              Text('Hoje · ${kwh1(today)} kWh',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: p.dim)),
            ]),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            decoration: BoxDecoration(
                color: p.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: p.line)),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
              Text(money(weekTotal),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: p.text)),
              const SizedBox(height: 4),
              Text('Esta semana · ${kwh1(weekTotal)} kWh',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: p.dim)),
            ]),
          ),
        ),
      ]),
      const SectionTitle('Últimos 7 dias (kWh)'),
      AppCard(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
        child: SizedBox(
          height: 190,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final d in days)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(
                        height: 120,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: dayKwh(d, today) / maxDay),
                          duration: const Duration(milliseconds: 550),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, child) => Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: v.clamp(.06, 1),
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
                      const SizedBox(height: 6),
                      Text(kwh1(dayKwh(d, today)),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: p.text)),
                      Text('${dayNames[d.weekday - 1]} ${d.day}',
                          style: TextStyle(fontSize: 9.5, color: p.dim)),
                    ]),
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
          if (devs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('Nenhum aparelho neste local', style: TextStyle(fontSize: 12.5, color: p.dim)),
            )
          else
            for (final d in devs)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.text)),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: today > 0 ? devKwh(d) / today : 0),
                          duration: const Duration(milliseconds: 550),
                          builder: (_, v, child) => LinearProgressIndicator(
                            value: v.clamp(0, 1),
                            minHeight: 5,
                            backgroundColor: p.surface2,
                            valueColor: AlwaysStoppedAnimation(d.on ? AppColors.accent : p.dimmer),
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${(today > 0 ? devKwh(d) / today * 100 : 0).round()}%',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.text)),
                    Text('${kwh1(devKwh(d))} kWh', style: TextStyle(fontSize: 10.5, color: p.dim)),
                  ]),
                ]),
              ),
        ]),
      ),
    ]);
  }
}
