import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'state.dart';
import 'widgets.dart';
import 'updater.dart';
import 'screens/home.dart';
import 'screens/control.dart';
import 'screens/schedule.dart';
import 'screens/energy.dart';
import 'screens/profile.dart';
import 'screens/updates.dart';
import 'screens/onboarding.dart';
import 'screens/device_manage.dart';
import 'screens/add_device.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  final st = AppState();
  await st.init(); // restaura tela atual e dados (minimizar/reabrir não perde estado)
  runApp(GreeApp(st: st));
}

class GreeApp extends StatefulWidget {
  final AppState st;
  const GreeApp({super.key, required this.st});

  @override
  State<GreeApp> createState() => _GreeAppState();
}

class _GreeAppState extends State<GreeApp> {
  AppState get st => widget.st;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: st,
      builder: (_, __) => MaterialApp(
        title: 'Gree',
        debugShowCheckedModeBanner: false,
        theme: st.themeMode == 'dark' ? AppTheme.dark() : AppTheme.light(),
        home: AppShell(st: st),
      ),
    );
  }
}

const TABS = [
  ('home', 'Início', Icons.home_rounded),
  ('schedule', 'Agenda', Icons.calendar_month_rounded),
  ('energy', 'Energia', Icons.bolt_rounded),
  ('profile', 'Perfil', Icons.person_rounded),
];
const INTERNAL = {
  'control': 'Controle',
  'editprofile': 'Editar perfil',
  'locations': 'Gerenciar locais',
  'family': 'Modo família',
  'notifications': 'Notificações',
  'energyset': 'Moeda e energia',
  'integrations': 'Integrações',
  'icons': 'Ícones',
  'updates': 'Atualizações',
  'devmanage': 'Gerenciar ar',
  'adddevice': 'Novo dispositivo',
};

class AppShell extends StatefulWidget {
  final AppState st;
  const AppShell({super.key, required this.st});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppState get st => widget.st;

  @override
  void initState() {
    super.initState();
    // update automático: ao abrir, avisa se existe versão nova
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final info = await Updater.check();
      if (info != null && mounted) showUpdateDialog(context, info);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette();
    final isTab = TABS.any((t) => t.$1 == st.screen);
    final isInternal = INTERNAL.containsKey(st.screen);

    if (!st.onboarded) return OnboardingScreen(st: st); // primeira abertura

    final Widget body = switch (st.screen) {
      'home' => HomeScreen(st: st),
      'schedule' => ScheduleScreen(st: st),
      'energy' => EnergyScreen(st: st),
      'profile' => ProfileScreen(st: st),
      'control' => ControlScreen(st: st),
      'editprofile' => EditProfileScreen(st: st),
      'locations' => LocationsScreen(st: st),
      'family' => FamilyScreen(st: st),
      'notifications' => NotificationsScreen(st: st),
      'energyset' => EnergySetScreen(st: st),
      'integrations' => IntegrationsScreen(st: st),
      'icons' => IconsScreen(st: st),
      'updates' => UpdatesScreen(st: st),
      'devmanage' => DeviceManageScreen(st: st),
      'adddevice' => AddDeviceScreen(st: st),
      _ => HomeScreen(st: st),
    };

    return PopScope(
      canPop: isTab,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        st.go(st.screen == 'control' ? 'home' : 'profile');
      },
      child: Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          if (isInternal)
            TopBar(
                title: INTERNAL[st.screen]!,
                center: true,
                onBack: () => st.go(st.screen == 'devmanage'
                    ? 'control'
                    : st.screen == 'control' || st.screen == 'adddevice'
                        ? 'home'
                        : 'profile'))
          else if (st.screen == 'schedule')
            const TopBar(title: 'Agendamento', center: true)
          else if (st.screen == 'energy')
            const TopBar(title: 'Energia', center: true)
          else if (st.screen == 'profile')
            const TopBar(title: 'Perfil', center: true)
          else if (st.screen == 'home')
            const TopBar(title: 'Início', center: true)
          else
            const SizedBox(height: 6),
          Expanded(child: body),
        ]),
      ),
      bottomNavigationBar: isTab
          ? Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: p.surface.withValues(alpha: .82),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: p.line),
              ),
              child: Row(children: [
                for (final t in TABS)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => st.go(t.$1),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: st.screen == t.$1 ? p.surface2 : Colors.transparent,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(t.$3, size: 21, color: st.screen == t.$1 ? AppColors.accent : p.dim),
                          const SizedBox(height: 3),
                          Text(t.$2,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: st.screen == t.$1 ? AppColors.accent : p.dim)),
                        ]),
                      ),
                    ),
                  ),
              ]),
            )
          : SafeArea(
              top: false,
              child: ActionBar(
                bare: true,
                actions: switch (st.screen) {
                  'control' => [ActionButton('Voltar', () => st.go('home'), ghost: true)],
                  'locations' => [ActionButton('Voltar', () => st.go('profile'), ghost: true)],
                  'adddevice' => [
                    ActionButton('Cancelar', () => st.go('home'), ghost: true),
                    ActionButton('Adicionar', () {
                      st.commitNewDevice();
                      st.go('home');
                    }, ghost: true),
                  ],
                  'editprofile' => [
                    ActionButton('Salvar', () {
                      st.applyProfileDraft();
                      st.go('profile');
                    }, ghost: true)
                  ],
                  _ => [ActionButton('Concluir', () => st.go('profile'), ghost: true)],
                },
              ),
            ),
    ),
    );
  }
}
