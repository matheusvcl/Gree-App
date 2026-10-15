import 'package:flutter/material.dart';
import '../theme.dart';
import '../state.dart';
import '../widgets.dart';

const DAY_SHORT = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
const DAY_NAME = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];

String hhmm(Schedule s) => '${s.hour.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')}';
String daysLabel(List<int> days) {
  if (days.length == 7) return 'Todos os dias';
  if (days.toString() == [1, 2, 3, 4, 5].toString()) return 'Seg–Sex';
  if (days.toString() == [0, 6].toString()) return 'Fim de semana';
  return days.map((d) => DAY_SHORT[d]).join(' · ');
}

String schedAction(Schedule s) {
  if (s.cmd == 'off') return 'Desligar';
  final mode = {'auto': 'Auto', 'cool': 'Resfriar', 'heat': 'Aquecer', 'dry': 'Desumidificar', 'fan': 'Ventilar'}[s.mode] ?? 'Auto';
  return 'Ligar · $mode · ${s.temp}°';
}

class ScheduleScreen extends StatefulWidget {
  final AppState st;
  const ScheduleScreen({super.key, required this.st});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final Set<int> sel = {};
  int? menuFor;

  @override
  Widget build(BuildContext context) {
    final st = widget.st;
    final p = context.palette();

    // "Em 24 horas": próximo disparo real considerando os dias
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    final dow = now.weekday % 7; // 0=dom
    final upcoming = <MapEntry<Schedule, List<int>>>[];
    for (final s in st.schedules.where((s) => s.on)) {
      int? best;
      int bestOff = 0;
      for (var off = 0; off < 8; off++) {
        if (!s.days.contains((dow + off) % 7)) continue;
        final diff = off * 1440 + (s.hour * 60 + s.minute - nowMin);
        if (diff >= 0 && (best == null || diff < best)) {
          best = diff;
          bestOff = off;
        }
      }
      if (best != null && best <= 1440) upcoming.add(MapEntry(s, [best, bestOff]));
    }
    upcoming.sort((a, b) => a.value[0].compareTo(b.value[0]));

    return Stack(children: [
      ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 140), children: [
        const SectionTitle('Rotinas'),
        for (final s in st.schedules) _schedRow(context, st, s),
        const SectionTitle('Em 24 horas'),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: upcoming.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Nada nas próximas 24h', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.text)),
                    const SizedBox(height: 3),
                    Text('Crie um agendamento no +', style: TextStyle(fontSize: 11.5, color: p.dim)),
                  ]),
                )
              : Column(children: [
                  for (final u in upcoming.take(3))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${u.value[1] == 0 ? "Hoje" : u.value[1] == 1 ? "Amanhã" : DAY_NAME[(dow + u.value[1]) % 7]}, ${hhmm(u.key)}',
                                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.text)),
                            const SizedBox(height: 2),
                            Text('${u.key.name} · ${schedAction(u.key)}', style: TextStyle(fontSize: 11.5, color: p.dim)),
                          ]),
                        ),
                        Text('em ${u.value[0] ~/ 60}h${(u.value[0] % 60).toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 12.5, color: p.dim)),
                      ]),
                    ),
                ]),
        ),
      ]),
      if (menuFor != null) _schedMenu(context, st),
      Positioned(
        right: 20,
        bottom: 96,
        child: GestureDetector(
          onTap: () => _edit(context, null),
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle, boxShadow: [
              BoxShadow(color: AppColors.accent.withValues(alpha: .35), blurRadius: 18, offset: const Offset(0, 6)),
            ]),
            child: const Icon(Icons.add_rounded, size: 26, color: Colors.white),
          ),
        ),
      ),
    ]);
  }

  /* card com gestos: deslizar direita = editar, esquerda = excluir; long-press = seleção múltipla */
  Widget _schedRow(BuildContext context, AppState st, Schedule s) {
    final p = context.palette();
    final selected = sel.contains(s.id);
    return GestureDetector(
      onTap: () {
        if (menuFor != null) {
          setState(() => selected ? sel.remove(s.id) : sel.add(s.id));
          if (sel.isEmpty) menuFor = null;
        } else {
          _edit(context, s);
        }
      },
      onLongPressStart: (_) {
        setState(() {
          menuFor = s.id;
          sel
            ..clear()
            ..add(s.id);
        });
      },
      child: Dismissible(
        key: ValueKey('sched-${s.id}'),
        dismissThresholds: const {DismissDirection.startToEnd: .35, DismissDirection.endToStart: .35},
        background: _swipeBg(context, icon: Icons.edit_rounded, color: AppColors.accent, align: Alignment.centerLeft),
        secondaryBackground: _swipeBg(context, icon: Icons.delete_rounded, color: AppColors.danger, align: Alignment.centerRight),
        confirmDismiss: (dir) async {
          if (dir == DismissDirection.startToEnd) {
            _edit(context, s);
            return false;
          }
          final ok = await showConfirm(context,
              title: 'Excluir agendamento?',
              text: 'A rotina "${s.name}" será removida permanentemente.',
              okLabel: 'Excluir');
          if (ok) {
            st.deleteSchedules([s.id]);
            showToast(context, 'Agendamento excluído');
          }
          return false;
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentSoft : p.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.accent : p.line),
          ),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(hhmm(s), style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600, color: p.text, letterSpacing: .5)),
              const SizedBox(height: 2),
              Text(daysLabel(s.days), style: TextStyle(fontSize: 10.5, color: p.dim)),
            ]),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (selected) ...[
                    const Icon(Icons.check_rounded, size: 14, color: AppColors.accent),
                    const SizedBox(width: 4),
                  ],
                  Text(s.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.text)),
                ]),
                const SizedBox(height: 2),
                Text(schedAction(s), style: TextStyle(fontSize: 11, color: p.dimmer)),
              ]),
            ),
            AppSwitch(
              value: s.on,
              onChanged: (v) {
                s.on = v;
                st.go('schedule');
              },
            ),
          ]),
        ),
      ),
    );
  }

  Widget _swipeBg(BuildContext context, {required IconData icon, required Color color, required Alignment align}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: .4, end: 1),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutBack,
        builder: (_, v, child) => Transform.scale(scale: v, child: child),
        child: Icon(icon, color: Colors.white, size: 21),
      ),
    );
  }

  /* menu ancorado da seleção múltipla */
  Widget _schedMenu(BuildContext context, AppState st) {
    final p = context.palette();
    return Stack(children: [
      GestureDetector(
        onTap: () => setState(() {
          menuFor = null;
          sel.clear();
        }),
        child: Container(color: Colors.black26),
      ),
      Positioned(
        left: 20,
        right: 20,
        bottom: 96,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.line),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 36)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (sel.length == 1)
              _menuItem(context, Icons.edit_rounded, 'Editar', 'Horário, dias e ação', onTap: () {
                final s = st.schedules.firstWhere((x) => x.id == sel.first);
                setState(() {
                  menuFor = null;
                  sel.clear();
                });
                _edit(context, s);
              }),
            _menuItem(context, Icons.delete_rounded,
                'Excluir ${sel.length > 1 ? "${sel.length} rotinas" : "agendamento"}',
                sel.length > 1 ? 'Remove todas as selecionadas' : 'Remove a rotina', danger: true, onTap: () async {
              final n = sel.length;
              final ok = await showConfirm(context,
                  title: n > 1 ? 'Excluir $n rotinas?' : 'Excluir agendamento?',
                  text: n > 1 ? 'As rotinas selecionadas serão removidas permanentemente.' : 'A rotina será removida permanentemente.',
                  okLabel: 'Excluir');
              if (ok) {
                st.deleteSchedules(sel.toList());
                showToast(context, n > 1 ? '$n rotinas excluídas' : 'Agendamento excluído');
              }
              setState(() {
                menuFor = null;
                sel.clear();
              });
            }),
            _menuItem(context, Icons.close_rounded, 'Cancelar', 'Limpar seleção', onTap: () => setState(() {
              menuFor = null;
              sel.clear();
            })),
          ]),
        ),
      ),
    ]);
  }

  Widget _menuItem(BuildContext context, IconData icon, String title, String sub,
      {bool danger = false, required VoidCallback onTap}) {
    final p = context.palette();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(children: [
          Icon(icon, size: 18, color: danger ? AppColors.danger : p.text),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: danger ? AppColors.danger : p.text)),
              Text(sub, style: TextStyle(fontSize: 11, color: p.dim)),
            ]),
          ),
        ]),
      ),
    );
  }

  /* editor de agendamento (relógio + dias) */
  void _edit(BuildContext context, Schedule? s) {
    final st = widget.st;
    final p = context.palette();
    var hour = s?.hour ?? 6;
    var minute = s?.minute ?? 30;
    var days = {...(s?.days ?? [1, 2, 3, 4, 5])};
    var cmd = s?.cmd ?? 'on';
    var mode = s?.mode ?? 'cool';
    var temp = s?.temp ?? 22;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final hCtrl = FixedExtentScrollController(initialItem: hour);
          final mCtrl = FixedExtentScrollController(initialItem: minute);
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(
                child: Text(s == null ? 'Novo agendamento' : 'Editar agendamento',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.text)),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 130,
                child: Row(children: [
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      controller: hCtrl,
                      itemExtent: 44,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (i) => setLocal(() => hour = i),
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 24,
                        builder: (_, i) => _wheelItem(ctx, i.toString().padLeft(2, '0'), hour == i),
                      ),
                    ),
                  ),
                  Text(':', style: TextStyle(fontSize: 26, color: p.dim)),
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      controller: mCtrl,
                      itemExtent: 44,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (i) => setLocal(() => minute = i),
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 60,
                        builder: (_, i) => _wheelItem(ctx, i.toString().padLeft(2, '0'), minute == i),
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
              Row(children: [
                for (var i = 0; i < 7; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: GestureDetector(
                      onTap: () => setLocal(() => days.contains(i) ? days.remove(i) : days.add(i)),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: days.contains(i) ? p.text : p.surface2,
                          shape: BoxShape.circle,
                          border: Border.all(color: days.contains(i) ? p.text : p.line),
                        ),
                        alignment: Alignment.center,
                        child: Text(DAY_SHORT[i],
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: days.contains(i) ? p.bg : p.dim)),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                AppChip(label: 'Ligar', on: cmd == 'on', small: true, onTap: () => setLocal(() => cmd = 'on')),
                const SizedBox(width: 8),
                AppChip(label: 'Desligar', on: cmd == 'off', small: true, onTap: () => setLocal(() => cmd = 'off')),
                const Spacer(),
                if (cmd == 'on')
                  Row(children: [
                    GestureDetector(
                      onTap: () => setLocal(() => temp = (temp - 1).clamp(st.tempMin, st.tempMax)),
                      child: _roundBtn(ctx, Icons.remove_rounded),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('$temp°${st.unit}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.text)),
                    ),
                    GestureDetector(
                      onTap: () => setLocal(() => temp = (temp + 1).clamp(st.tempMin, st.tempMax)),
                      child: _roundBtn(ctx, Icons.add_rounded),
                    ),
                  ]),
              ]),
              const SizedBox(height: 18),
              Row(children: [
                if (s != null)
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final ok = await showConfirm(context,
                            title: 'Excluir agendamento?',
                            text: 'A rotina "${s.name}" será removida permanentemente.',
                            okLabel: 'Excluir');
                        if (ok) {
                          st.deleteSchedules([s.id]);
                          if (ctx.mounted) Navigator.pop(ctx);
                          showToast(context, 'Agendamento excluído');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(22)),
                        alignment: Alignment.center,
                        child: Text('Excluir agendamento',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.text)),
                      ),
                    ),
                  ),
                if (s != null) const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final id = s?.id ?? (st.schedules.map((x) => x.id).fold(0, (a, b) => a > b ? a : b) + 1);
                      final sched = Schedule(
                          id: id,
                          name: s?.name ?? 'Rotina',
                          cmd: cmd,
                          mode: mode,
                          hour: hour,
                          minute: minute,
                          temp: temp,
                          days: days.toList()..sort());
                      if (s == null) {
                        st.schedules.add(sched);
                      } else {
                        st.patchSched(id, (x) {
                          x
                            ..cmd = cmd
                            ..mode = mode
                            ..hour = hour
                            ..minute = minute
                            ..temp = temp
                            ..days = sched.days;
                        });
                      }
                      st.go('schedule');
                      Navigator.pop(ctx);
                      showToast(context, 'Agendamento salvo');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(22)),
                      alignment: Alignment.center,
                      child: Text(s == null ? 'Criar agendamento' : 'Salvar agendamento',
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ),
              ]),
            ]),
          );
        },
      ),
    );
  }

  Widget _wheelItem(BuildContext ctx, String text, bool active) {
    final p = ctx.palette();
    return Center(
      child: Text(text,
          style: TextStyle(
              fontSize: active ? 30 : 22,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              color: active ? p.text : p.dimmer)),
    );
  }

  Widget _roundBtn(BuildContext ctx, IconData icon) {
    final p = ctx.palette();
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: p.surface2, shape: BoxShape.circle, border: Border.all(color: p.line)),
      child: Icon(icon, size: 17, color: p.text),
    );
  }
}
