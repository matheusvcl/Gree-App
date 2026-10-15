import 'package:flutter/material.dart';
import '../theme.dart';
import '../state.dart';
import '../widgets.dart';
import '../updater.dart';
import '../avatars.dart';
import '../services/remote.dart';

/* ================= avatar ================= */
class UserAvatar extends StatelessWidget {
  final String avatar;
  final double size;
  const UserAvatar({super.key, required this.avatar, this.size = 46});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'assets/avatars/$avatar.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(color: Color(0xFF5B7FA6), shape: BoxShape.circle),
          child: Icon(Icons.person_rounded, size: size * .6, color: const Color(0xFF2B2D42)),
        ),
      ),
    );
  }
}

/* ================= perfil ================= */
class ProfileScreen extends StatelessWidget {
  final AppState st;
  const ProfileScreen({super.key, required this.st});

  @override
  Widget build(BuildContext context) {
    final p = context.palette();
    final me = st.users.isNotEmpty ? st.users.first : null;

    return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 140), children: [
      Row(children: [
        UserAvatar(avatar: me?.avatar ?? 'p1', size: 56),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(me?.name ?? 'Usuário', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: p.text)),
            const SizedBox(height: 2),
            Text('${st.loc.name} · ${st.devices.length} aparelhos', style: TextStyle(fontSize: 13, color: p.dim)),
          ]),
        ),
      ]),
      const SectionTitle('Conta'),
      _row(context, Icons.person_outline_rounded, 'Editar perfil', 'Nome e avatar', () => st.go('editprofile')),
      _row(context, Icons.place_outlined, 'Gerenciar locais', 'Ambientes e cidades', () => st.go('locations')),
      _row(context, Icons.group_outlined, 'Modo família', 'Vários usuários nos mesmos aparelhos', () => st.go('family')),
      const SectionTitle('Preferências'),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Icon(Icons.brightness_6_rounded, size: 19, color: p.text),
          const SizedBox(width: 13),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Aparência', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.text)),
              Text('Tema do aplicativo', style: TextStyle(fontSize: 11, color: p.dim)),
            ]),
          ),
          AppChip(label: 'Claro', on: st.themeMode == 'light', small: true, onTap: () => st.setTheme('light')),
          const SizedBox(width: 8),
          AppChip(label: 'Escuro', on: st.themeMode == 'dark', small: true, onTap: () => st.setTheme('dark')),
        ]),
      ),
      _row(context, Icons.system_update_rounded, 'Atualizações', 'Versão, verificação e o que mudou', () => st.go('updates')),
      _row(context, Icons.apps_rounded, 'Ícones', 'Ícone na tela inicial e no app drawer', () => st.go('icons')),
      _row(context, Icons.notifications_none_rounded, 'Notificações', 'Alertas e avisos', () => st.go('notifications')),
      _row(context, Icons.bolt_outlined, 'Moeda e energia', 'Tarifa e estimativas', () => st.go('energyset')),
      _row(context, Icons.link_rounded, 'Integrações', 'Assistentes e serviços', () => st.go('integrations'),
          last: true),
    ]);
  }

  Widget _row(BuildContext context, IconData icon, String title, String sub, VoidCallback onTap, {bool last = false}) {
    final p = context.palette();
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: last ? Colors.transparent : p.line))),
        child: Row(children: [
          Icon(icon, size: 19, color: p.text),
          const SizedBox(width: 13),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.text)),
              Text(sub, style: TextStyle(fontSize: 11, color: p.dim)),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, size: 18, color: p.dimmer),
        ]),
      ),
    );
  }
}

/* ================= editar perfil ================= */
class EditProfileScreen extends StatelessWidget {
  final AppState st;
  const EditProfileScreen({super.key, required this.st});

  @override
  Widget build(BuildContext context) {
    final p = context.palette();
    final me = st.users.first;
    final name = TextEditingController(text: me.name);

    return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 140), children: [
      const SectionTitle('Nome'),
      TextField(
        controller: name,
        onChanged: (v) => st.profileDraftName = v,
        style: TextStyle(color: p.text, fontSize: 15),
        decoration: InputDecoration(
          filled: true,
          fillColor: p.surface,
          hintText: 'Seu nome',
          hintStyle: TextStyle(color: p.dimmer),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: p.line)),
        ),
      ),
      const SectionTitle('Avatar'),
      for (final g in avatarGroups.entries) ...[
        Text(g.key,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: p.dimmer, letterSpacing: .4)),
        const SizedBox(height: 8),
        Wrap(spacing: 12, runSpacing: 12, children: [
          for (final id in g.value)
            GestureDetector(
              onTap: () {
                me.avatar = id;
                st.go('editprofile');
              },
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: me.avatar == id ? Border.all(color: Colors.white, width: 3) : null,
                ),
                child: UserAvatar(avatar: id, size: 52),
              ),
            ),
        ]),
        const SizedBox(height: 16),
      ],
      const SizedBox(height: 26),
    ]);
  }
}

/* ================= gerenciar locais (arrastar para reordenar) ================= */
class LocationsScreen extends StatefulWidget {
  final AppState st;
  const LocationsScreen({super.key, required this.st});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  int? draggingId;

  @override
  Widget build(BuildContext context) {
    final st = widget.st;
    final p = context.palette();
    final newName = TextEditingController();
    final roomCtrl = <int, TextEditingController>{};

    return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 140), children: [
      Text('Locais separam seus aparelhos por prédio ou endereço. Toque em um local para ativá-lo. Segure e arraste para reordenar — o primeiro vira o ativo.',
          style: TextStyle(fontSize: 12.5, color: p.dim, height: 1.5)),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(
          child: TextField(
            controller: newName,
            style: TextStyle(color: p.text, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'Nome do novo local (ex.: Sítio)',
              hintStyle: TextStyle(color: p.dimmer, fontSize: 13),
              filled: true,
              fillColor: p.surface2,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.line)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            if (newName.text.trim().isEmpty) return;
            st.addPlace(newName.text.trim());
            st.go('locations');
            showToast(context, 'Local adicionado');
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
            child: const Icon(Icons.add_rounded, size: 20, color: Color(0xFF101316)),
          ),
        ),
      ]),
      const SizedBox(height: 16),
      ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        proxyDecorator: (child, index, anim) => Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 30)],
            ),
            child: child,
          ),
        ),
        itemCount: st.locations.length,
        onReorderItem: (oldIdx, newIdx) {
          // o newIndex já vem ajustado para a remoção do item antigo
          final ids = st.locations.map((l) => l.id).toList();
          final id = ids.removeAt(oldIdx);
          ids.insert(newIdx, id);
          st.reorderLocations(ids);
          st.go('locations');
          showToast(context, 'Ordem atualizada · ${st.locations.first.name} ativo');
        },
        itemBuilder: (_, i) {
          final l = st.locations[i];
          final isActive = st.activeLoc == l.id;
          roomCtrl[l.id] ??= TextEditingController();
          return Padding(
            key: ValueKey('loc-${l.id}'),
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: draggingId == l.id ? AppColors.accent : p.line),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Listener(
                    onPointerDown: (_) => setState(() => draggingId = l.id),
                    onPointerUp: (_) => setState(() => draggingId = null),
                    onPointerCancel: (_) => setState(() => draggingId = null),
                    child: ReorderableDragStartListener(
                      index: i,
                      child: AnimatedOpacity(
                        opacity: draggingId == l.id ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(Icons.drag_indicator_rounded, size: 18, color: p.dimmer),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        st.selectLoc(l.id);
                        st.go('locations');
                      },
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(l.name, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: p.text)),
                        Text('${l.rooms.length} ambiente${l.rooms.length > 1 ? 's' : ''} · ${l.rooms.join(', ')}',
                            style: TextStyle(fontSize: 11, color: p.dim)),
                      ]),
                    ),
                  ),
                  if (isActive)
                    Text('Ativo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ok))
                  else
                    GestureDetector(
                      onTap: () async {
                        final ok = await showConfirm(context,
                            title: 'Remover local?',
                            text: '"${l.name}" e seus ambientes serão removidos.',
                            okLabel: 'Remover');
                        if (ok) {
                          st.removePlace(l.id);
                          st.go('locations');
                          showToast(context, 'Local removido');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.line)),
                        child: Icon(Icons.delete_rounded, size: 15, color: AppColors.danger),
                      ),
                    ),
                ]),
                if (l.rooms.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final r in l.rooms)
                      AppChip(
                        label: r,
                        small: true,
                        icon: Icon(Icons.close_rounded, size: 12, color: p.dim),
                        onTap: () {
                          st.removeRoom(l.id, r);
                          st.go('locations');
                        },
                      ),
                  ]),
                ],
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: roomCtrl[l.id],
                      style: TextStyle(color: p.text, fontSize: 12.5),
                      decoration: InputDecoration(
                        hintText: 'Novo ambiente (ex.: Cozinha)',
                        hintStyle: TextStyle(color: p.dimmer, fontSize: 11.5),
                        filled: true,
                        fillColor: p.surface2,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: p.line)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppChip(
                    label: 'Adicionar',
                    white: true,
                    small: true,
                    onTap: () {
                      st.addRoom(l.id, roomCtrl[l.id]?.text ?? '');
                      roomCtrl[l.id]?.clear();
                      st.go('locations');
                    },
                  ),
                ]),
              ]),
            ),
          );
        },
      ),
    ]);
  }
}

/* ================= modo família ================= */
class FamilyScreen extends StatelessWidget {
  final AppState st;
  const FamilyScreen({super.key, required this.st});

  @override
  Widget build(BuildContext context) {
    final p = context.palette();
    final newName = TextEditingController();

    return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 140), children: [
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Ativar modo família', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.text)),
              Text('Restringe os ambientes de acordo com cada usuário',
                  style: TextStyle(fontSize: 11, color: p.dim)),
            ]),
          ),
          AppSwitch(
            value: st.famOn,
            onChanged: (v) async {
              if (v) {
                st.famOn = true;
                st.go('family');
              } else {
                final ok = await showConfirm(context,
                    title: 'Desativar o modo família?',
                    text: 'A família e os ar-condicionados dos outros usuários serão desvinculados e o app volta a ser de usuário único.',
                    okLabel: 'Desativar');
                if (ok) {
                  st.disableFamily();
                  st.go('family');
                  showToast(context, 'Modo família desativado — usuário único');
                }
              }
            },
          ),
        ]),
      ),
      if (st.famOn) ...[
        const SizedBox(height: 8),
        Text('Cada usuário guarda um apelido, avatar e as temperaturas próprias por modo.',
            style: TextStyle(fontSize: 12, color: p.dim, height: 1.5)),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(
          child: TextField(
            controller: newName,
            style: TextStyle(color: p.text, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'Nome do usuário (ex.: Filha)',
              hintStyle: TextStyle(color: p.dimmer, fontSize: 13),
              filled: true,
              fillColor: p.surface2,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.line)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            st.addUser(newName.text);
            st.go('family');
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
            child: const Icon(Icons.add_rounded, size: 20, color: Color(0xFF101316)),
          ),
        ),
      ]),
      SectionTitle('Usuários (${st.users.length})'),
      for (final u in st.users)
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              UserAvatar(avatar: u.avatar, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(u.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.text)),
                  Text(u.role == 'admin' ? 'Administrador' : 'Ambientes: ${u.rooms.join(', ')}',
                      style: TextStyle(fontSize: 11, color: p.dim)),
                ]),
              ),
              if (u.role != 'admin')
                GestureDetector(
                  onTap: () async {
                    final ok = await showConfirm(context,
                        title: 'Excluir usuário?',
                        text: '${u.name} será removido e seus aparelhos desvinculados.',
                        okLabel: 'Excluir');
                    if (ok) {
                      st.removeUser(u.id);
                      st.go('family');
                      showToast(context, 'Usuário excluído');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: p.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.line)),
                    child: Icon(Icons.delete_rounded, size: 15, color: AppColors.danger),
                  ),
                ),
            ]),
            const SizedBox(height: 12),
            Text('Ar individual · cada modo com a própria temperatura',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: p.dimmer, letterSpacing: .3)),
            const SizedBox(height: 8),
            Wrap(spacing: 7, runSpacing: 7, children: [
              for (final e in const {
                'auto': 'Auto',
                'cool': 'Resfriar',
                'heat': 'Aquecer',
                'dry': 'Desumidificar',
                'fan': 'Ventilar',
              }.entries)
                AppChip(
                  label: '${e.value} ${u.prefs.temps[e.key] ?? 22}°${st.unit}',
                  on: u.prefs.mode == e.key,
                  small: true,
                  onTap: () {
                    u.prefs.mode = e.key;
                    st.go('family');
                  },
                ),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Código de convite', style: TextStyle(fontSize: 12, color: p.dim)),
                const SizedBox(height: 2),
                Text(st.familyCode,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.text, letterSpacing: 2)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        InviteQr(code: st.familyCode),
        const SizedBox(height: 8),
        TextField(
          onSubmitted: (v) async {
            if (await st.joinFamily(v)) {
              showToast(context, 'Você entrou na família');
            } else {
              showToast(context, 'Código inválido — são 6 caracteres');
            }
            st.go('family');
          },
          style: TextStyle(color: p.text, fontSize: 13.5),
          decoration: InputDecoration(
            hintText: 'Entrar em uma família com o código',
            hintStyle: TextStyle(color: p.dimmer, fontSize: 12.5),
            prefixIcon: Icon(Icons.login_rounded, size: 16, color: p.dim),
            filled: true,
            fillColor: p.surface2,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.line)),
          ),
        ),
      ],
    ]);
  }
}

/* ================= notificações / energia / integrações ================= */
class NotificationsScreen extends StatelessWidget {
  final AppState st;
  const NotificationsScreen({super.key, required this.st});

  @override
  Widget build(BuildContext context) {
    final p = context.palette();
    Widget row(String title, String sub, bool v, ValueChanged<bool> fn) => AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.text)),
                Text(sub, style: TextStyle(fontSize: 11, color: p.dim)),
              ]),
            ),
            AppSwitch(value: v, onChanged: fn),
          ]),
        );
    return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 140), children: [
      row('Notificações push', 'Alertas gerais do app', st.notifPush, (v) {
        st.notifPush = v;
        st.go('notifications');
      }),
      row('Alertas de energia', 'Avisa quando o consumo passar do padrão', st.notifEnergy, (v) {
        st.notifEnergy = v;
        st.go('notifications');
      }),
      row('Novidades', 'Novos recursos e melhorias', st.notifAlerts, (v) {
        st.notifAlerts = v;
        st.go('notifications');
      }),
    ]);
  }
}

class EnergySetScreen extends StatefulWidget {
  final AppState st;
  const EnergySetScreen({super.key, required this.st});

  @override
  State<EnergySetScreen> createState() => _EnergySetScreenState();
}

class _EnergySetScreenState extends State<EnergySetScreen> {
  List<GeoPlace> results = [];
  bool busy = false;

  @override
  Widget build(BuildContext context) {
    final st = widget.st;
    final p = context.palette();
    final flagColor = switch (st.flagName) {
      'Amarela' => AppColors.warn,
      'Vermelha Patamar 1' || 'Vermelha P1' => AppColors.danger,
      'Vermelha Patamar 2' || 'Vermelha P2' => AppColors.danger,
      _ => AppColors.ok,
    };
    String money3(double v) => 'R\$ ${v.toStringAsFixed(3).replaceAll('.', ',')}';

    return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 140), children: [
      const SectionTitle('Localização'),
      AppCard(
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.location_on_outlined, size: 20, color: AppColors.accent),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(st.city.isEmpty ? 'Sem local definido' : '${st.city}/${st.uf}',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.text)),
              const SizedBox(height: 2),
              Text('Detecta a distribuidora e a tarifa da sua cidade',
                  style: TextStyle(fontSize: 11, color: p.dim)),
            ]),
          ),
          AppChip(
            label: busy ? 'Buscando…' : 'Usar localização',
            on: true,
            small: true,
            onTap: busy
                ? null
                : () async {
                    setState(() => busy = true);
                    final place = await Remote.deviceLocation();
                    setState(() => busy = false);
                    if (place != null) {
                      await st.applyPlace(place);
                      if (context.mounted) showToast(context, 'Local detectado: ${place.city}/${place.uf}');
                    } else if (context.mounted) {
                      showToast(context, 'Localização negada — busque a cidade abaixo');
                    }
                  },
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: TextField(
          onSubmitted: (q) async {
            final r = await Remote.searchPlaces(q);
            setState(() => results = r);
          },
          style: TextStyle(color: p.text, fontSize: 13.5),
          decoration: InputDecoration(
            hintText: 'Buscar cidade (ex.: Niterói)',
            hintStyle: TextStyle(color: p.dimmer, fontSize: 13),
            prefixIcon: Icon(Icons.search_rounded, size: 18, color: p.dim),
            filled: true,
            fillColor: p.surface2,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.line)),
          ),
        ),
      ),
      for (final r in results)
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: InkWell(
            onTap: () async {
              await st.applyPlace(r);
              setState(() => results = []);
              if (context.mounted) showToast(context, 'Local definido: ${r.city}/${r.uf}');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                const Icon(Icons.place_outlined, size: 17, color: AppColors.accent),
                const SizedBox(width: 10),
                Expanded(
                    child: Text('${r.city}/${r.uf}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.text))),
                Icon(Icons.chevron_right_rounded, size: 16, color: p.dimmer),
              ]),
            ),
          ),
        ),
      const SectionTitle('Energia'),
      AppCard(
        child: Column(children: [
          if (ufDistributors[st.uf]?.isNotEmpty ?? false)
            Row(children: [
              Expanded(
                child: Text('Distribuidora', style: TextStyle(fontSize: 12, color: p.dim)),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: st.distributor.isNotEmpty ? st.distributor : null,
                  dropdownColor: p.surface,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: p.text),
                  items: [
                    for (final d in ufDistributors[st.uf] ?? [])
                      DropdownMenuItem(value: d, child: Text(d, style: TextStyle(fontSize: 12, color: p.text))),
                  ],
                  onChanged: (v) async {
                    if (v == null) return;
                    st.distributor = v;
                    await st.resolveEnergy();
                  },
                ),
              ),
            ]),
          _row('Tarifa base (TE+TUSD)', st.baseTariff > 0 ? '${money3(st.baseTariff)}/kWh' : '—'),
          _row('Bandeira do mês',
              st.flagName.isEmpty ? '—' : '${st.flagName} · +${money3(st.flagSurcharge)}/kWh', dot: flagColor),
          const Divider(height: 20),
          Row(children: [
            Expanded(
              child: Text('Tarifa total estimada',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: p.dim)),
            ),
            Text('${money3(st.tariff)}/kWh',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.text)),
          ]),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Calculado automaticamente pela ANEEL · atualizado em ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}',
                style: TextStyle(fontSize: 10, color: p.dimmer)),
          ),
        ]),
      ),
      const SectionTitle('Estimativa'),
      Row(children: [
        Expanded(
          child: AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('R\$ ${(4.2 * st.tariff).toStringAsFixed(2).replaceAll('.', ',')}',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.text)),
              const SizedBox(height: 3),
              Text('Hoje · 4,2 kWh', style: TextStyle(fontSize: 11, color: p.dim)),
            ]),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('R\$ ${(24.8 * st.tariff).toStringAsFixed(2).replaceAll('.', ',')}',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.text)),
              const SizedBox(height: 3),
              Text('Esta semana', style: TextStyle(fontSize: 11, color: p.dim)),
            ]),
          ),
        ),
      ]),
    ]);
  }

  Widget _row(String label, String value, {Color? dot}) {
    final p = context.palette();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        if (dot != null) ...[
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 8),
        ],
        Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: p.dim))),
        Text(value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: p.text)),
      ]),
    );
  }
}

class IntegrationsScreen extends StatelessWidget {
  final AppState st;
  const IntegrationsScreen({super.key, required this.st});

  @override
  Widget build(BuildContext context) {
    final p = context.palette();
    return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 140), children: [
      Text('Conecte assistentes e serviços para controlar seus aparelhos por voz.',
          style: TextStyle(fontSize: 12.5, color: p.dim, height: 1.5)),
      const SizedBox(height: 12),
      for (final e in const [
        ('Google Home', Icons.g_mobiledata_rounded, 'Conectado'),
        ('Amazon Alexa', Icons.podcasts_rounded, 'Conectar'),
        ('Apple HomeKit', Icons.home_outlined, 'Em breve'),
      ])
        AppCard(
          child: Row(children: [
            Icon(e.$2, size: 26, color: p.text),
            const SizedBox(width: 13),
            Expanded(
              child: Text(e.$1, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.text)),
            ),
            AppChip(label: e.$3, on: e.$3 == 'Conectado', small: true, onTap: () {
              showToast(context, '${e.$1}: ${e.$3.toLowerCase()}');
            }),
          ]),
        ),
    ]);
  }
}

/* ================= seleção de ícone do app ================= */
class IconsScreen extends StatelessWidget {
  final AppState st;
  const IconsScreen({super.key, required this.st});

  static const variants = [
    ('default', 'Escuro', 'assets/icon/preview-default.png', false),
    ('light', 'Claro', 'assets/icon/preview-light.png', false),
    ('accent', 'Azul', 'assets/icon/preview-accent.png', false),
    ('mono', 'Mono', 'assets/icon/preview-mono.png', true),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette();
    return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 140), children: [
      Text('Escolha o ícone exibido na tela inicial e na lista de aplicativos. A troca é imediata.',
          style: TextStyle(fontSize: 12.5, color: p.dim, height: 1.5)),
      const SizedBox(height: 16),
      Wrap(spacing: 14, runSpacing: 14, children: [
        for (final v in variants)
          GestureDetector(
            onTap: () async {
              await st.setAppIcon(v.$1);
              if (context.mounted) showToast(context, 'Ícone atualizado: ${v.$2}');
            },
            child: Container(
              width: 104,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: st.appIcon == v.$1 ? AppColors.accent : p.line,
                    width: st.appIcon == v.$1 ? 2 : 1),
              ),
              child: Column(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: v.$4 ? const Color(0xFF0C0D0F) : null,
                    child: Image.asset(v.$3, width: 60, height: 60, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 8),
                Text(v.$2, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: p.text)),
                const SizedBox(height: 4),
                Icon(st.appIcon == v.$1 ? Icons.check_circle_rounded : Icons.circle_outlined,
                    size: 15, color: st.appIcon == v.$1 ? AppColors.accent : p.dimmer),
              ]),
            ),
          ),
      ]),
    ]);
  }
}
