import 'package:flutter/material.dart';
import '../theme.dart';
import '../state.dart';
import '../widgets.dart';
import '../avatars.dart';
import '../services/remote.dart';
import 'profile.dart' show UserAvatar;

/* Onboarding de primeira abertura: perfil → ar → localização → família.
   O app nasce limpo; tudo aqui cria o estado inicial.
   O conteúdo fica centralizado no meio da tela. */
class OnboardingScreen extends StatefulWidget {
  final AppState st;
  const OnboardingScreen({super.key, required this.st});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 0;
  String name = '';
  String avatar = 'p1';
  String devName = '';
  String room = '';
  String devWifi = '';
  String devPass = '';
  int temp = 22;
  String mode = 'cool';
  GeoPlace? place;
  bool busy = false;
  bool famOn = false;
  final List<String> famNames = [];

  AppState get st => widget.st;

  @override
  Widget build(BuildContext context) {
    final p = context.palette();
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 5; i++)
                Container(
                  width: 26,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i <= step ? AppColors.accent : p.surface2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
          Expanded(
            child: LayoutBuilder(builder: (_, c) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: c.maxHeight - 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [_body(p)],
                    ),
                  ),
                )),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            child: Row(children: [
              if (step > 0) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => step--),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                          color: p.surface2,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: p.line)),
                      alignment: Alignment.center,
                      child: Text('Voltar',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.text)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (step < 4) {
                      setState(() => step++);
                    } else {
                      st.finishOnboarding(
                        name: name,
                        avatar: avatar,
                        devName: devName,
                        room: room,
                        temp: temp,
                        mode: mode,
                        devWifi: devWifi,
                        devPass: devPass,
                        place: place,
                      );
                      st.famOn = famOn;
                      for (final n in famNames) {
                        st.addUser(n);
                      }
                      st.go('home');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
                    alignment: Alignment.center,
                    child: Text(step < 4 ? 'Continuar' : 'Concluir',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _title(String t, AppPalette p) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: p.text)),
      );

  Widget _sub(String t, AppPalette p) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Text(t, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: p.dim, height: 1.5)),
      );

  Widget _label(String t, AppPalette p) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: p.dim)),
      );

  Widget _body(AppPalette p) {
    switch (step) {
      case 0:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _title('Crie seu perfil', p),
          _sub('É como você aparece no app — dá para mudar depois.', p),
          TextField(
            onChanged: (v) => name = v,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.text, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Seu nome',
              hintStyle: TextStyle(color: p.dimmer),
              filled: true,
              fillColor: p.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: p.line)),
            ),
          ),
          const SizedBox(height: 18),
          _label('Escolha um avatar', p),
          for (final g in avatarGroups.entries) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(g.key,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: p.dimmer, letterSpacing: .4)),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final id in g.value)
                  GestureDetector(
                    onTap: () => setState(() => avatar = id),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: avatar == id ? Border.all(color: Colors.white, width: 3) : null,
                      ),
                      child: UserAvatar(avatar: id, size: 46),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
          ],
        ]);
      case 1:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _title('Configure seu ar', p),
          _sub('Os ajustes iniciais do aparelho que você vai controlar.', p),
          TextField(
            onChanged: (v) => devName = v,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.text, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Nome do aparelho',
              hintStyle: TextStyle(color: p.dimmer, fontSize: 13),
              filled: true,
              fillColor: p.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: p.line)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => room = v,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.text, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Ambiente (ex.: Sala)',
              hintStyle: TextStyle(color: p.dimmer, fontSize: 13),
              filled: true,
              fillColor: p.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: p.line)),
            ),
          ),
          const SizedBox(height: 18),
          _label('Rede Wi-Fi do ar', p),
          InkWell(
            onTap: () => _openWifi(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: p.line),
              ),
              child: Row(children: [
                Icon(Icons.wifi_rounded, size: 18, color: devWifi.isEmpty ? p.dimmer : AppColors.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(devWifi.isEmpty ? 'Configurar rede' : '$devWifi${devPass.isEmpty ? '' : ' · senha salva'}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.text)),
                ),
                Icon(Icons.chevron_right_rounded, size: 18, color: p.dimmer),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Text('O ar precisa estar nesta rede para o app controlar pela rede local.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: p.dim, height: 1.4)),
          const SizedBox(height: 18),
          _label('Modo inicial', p),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in const {
                'auto': 'Auto',
                'cool': 'Frio',
                'heat': 'Calor',
                'dry': 'Seco',
                'fan': 'Vento',
              }.entries)
                AppChip(label: e.value, on: mode == e.key, small: true, onTap: () => setState(() => mode = e.key)),
            ],
          ),
          const SizedBox(height: 18),
          _label('Temperatura inicial', p),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _roundBtn(p, Icons.remove_rounded, () => setState(() => temp = (temp - 1).clamp(16, 30))),
            SizedBox(
              width: 90,
              child: Text('${st.tempDisp(temp)}°${st.unit}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: p.text)),
            ),
            _roundBtn(p, Icons.add_rounded, () => setState(() => temp = (temp + 1).clamp(16, 30))),
          ]),
        ]);
      case 2:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _title('Onde você mora?', p),
          _sub('Com a localização o app traz o clima em tempo real e calcula a tarifa de energia da sua cidade automaticamente.', p),
          if (place != null)
            AppCard(
              child: Row(children: [
                const Icon(Icons.check_circle_rounded, size: 22, color: AppColors.ok),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('${place!.city}/${place!.uf}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.text)),
                ),
              ]),
            )
          else
            GestureDetector(
              onTap: busy
                  ? null
                  : () async {
                      setState(() => busy = true);
                      final pl = await Remote.deviceLocation();
                      setState(() {
                        busy = false;
                        place = pl;
                      });
                      if (pl == null && context.mounted) {
                        showToast(context, 'Sem permissão — você pode definir depois em Moeda e energia');
                      }
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(18)),
                alignment: Alignment.center,
                child: Text(busy ? 'Localizando…' : 'Usar minha localização',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => setState(() => step++),
              child: Text('Agora não', style: TextStyle(fontSize: 12.5, color: p.dim)),
            ),
          ),
        ]);
      case 3:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _title('Modo família', p),
          _sub('Cada pessoa tem o seu app, perfil e temperatura. Ative para compartilhar os mesmos aparelhos.', p),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(children: [
              Expanded(
                child: Text('Ativar modo família',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.text)),
              ),
              AppSwitch(value: famOn, onChanged: (v) => setState(() => famOn = v)),
            ]),
          ),
          if (famOn) ...[
            const SizedBox(height: 14),
            _label('Código de convite', p),
            AppCard(
              child: Row(children: [
                Expanded(
                  child: Text('Os membros entram com este código no app deles',
                      style: TextStyle(fontSize: 11.5, color: p.dim, height: 1.4)),
                ),
                Text(st.familyCode,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.text, letterSpacing: 2)),
              ]),
            ),
            const SizedBox(height: 8),
            InviteQr(code: st.familyCode),
            const SizedBox(height: 8),
            _label('Adicionar agora (opcional)', p),
            for (final n in famNames)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.person_rounded, size: 15, color: AppColors.ok),
                  const SizedBox(width: 8),
                  Text(n, style: TextStyle(fontSize: 12.5, color: p.text)),
                ]),
              ),
            TextField(
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) setState(() => famNames.add(v.trim()));
              },
              textAlign: TextAlign.center,
              style: TextStyle(color: p.text, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Nome e Enter para adicionar',
                hintStyle: TextStyle(color: p.dimmer, fontSize: 12.5),
                filled: true,
                fillColor: p.surface2,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.line)),
              ),
            ),
          ],
        ]);
      default:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _title('Escolha o tema', p),
          _sub('Detectamos o tema do seu celular — pode trocar quando quiser.', p),
          Row(children: [
            Expanded(child: _themeCard(p, dark: false)),
            const SizedBox(width: 12),
            Expanded(child: _themeCard(p, dark: true)),
          ]),
        ]);
    }
  }

  Widget _themeCard(AppPalette p, {required bool dark}) {
    final selected = (st.themeMode == 'dark') == dark;
    final bg = dark ? const Color(0xFF0C0D0F) : const Color(0xFFF3F4F6);
    final surface = dark ? const Color(0xFF151719) : Colors.white;
    final line = dark ? const Color(0xFF262A2E) : const Color(0xFFE3E6EA);
    return GestureDetector(
      onTap: () => st.setTheme(dark ? 'dark' : 'light'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? AppColors.accent : p.line, width: selected ? 2 : 1),
        ),
        child: Column(children: [
          Container(
            height: 110,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: line)),
            padding: const EdgeInsets.all(10),
            child: Column(children: [
              Container(height: 8, decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 6),
              Expanded(
                child: Row(children: [
                  Expanded(child: Container(decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(8)))),
                  const SizedBox(width: 6),
                  Expanded(child: Container(decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(8)))),
                ]),
              ),
              const SizedBox(height: 6),
              Container(height: 16, width: 60, decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(8))),
            ]),
          ),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(dark ? 'Escuro' : 'Claro',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: p.text)),
            if (selected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.accent),
            ],
          ]),
        ]),
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

  Future<void> _openWifi(BuildContext context) async {
    final r = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (_) => WifiSetupScreen(ssid: devWifi, pass: devPass)),
    );
    if (r != null) {
      setState(() {
        devWifi = r['ssid'] ?? '';
        devPass = r['pass'] ?? '';
      });
    }
  }
}

/* tela de rede do ar (faz parte do step "Configure seu ar", sem criar step novo) */
class WifiSetupScreen extends StatefulWidget {
  final String ssid, pass;
  const WifiSetupScreen({super.key, this.ssid = '', this.pass = ''});

  @override
  State<WifiSetupScreen> createState() => _WifiSetupScreenState();
}

class _WifiSetupScreenState extends State<WifiSetupScreen> {
  late final TextEditingController ssid;
  late final TextEditingController pass;

  @override
  void initState() {
    super.initState();
    ssid = TextEditingController(text: widget.ssid);
    pass = TextEditingController(text: widget.pass);
  }

  @override
  void dispose() {
    ssid.dispose();
    pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette();
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          TopBar(title: 'Rede Wi-Fi do ar', center: true, onBack: () => Navigator.pop(context)),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 60), children: [
              Text(
                'Informe a rede em que o ar vai ficar conectado. O app controla o aparelho pela rede local.',
                style: TextStyle(color: p.dim, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: ssid,
                style: TextStyle(color: p.text, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Nome da rede (SSID)',
                  hintStyle: TextStyle(color: p.dimmer, fontSize: 13),
                  filled: true,
                  fillColor: p.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: p.line)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pass,
                obscureText: true,
                style: TextStyle(color: p.text, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Senha da rede',
                  hintStyle: TextStyle(color: p.dimmer, fontSize: 13),
                  filled: true,
                  fillColor: p.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: p.line)),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: AppChip(
                  label: 'Salvar rede',
                  on: true,
                  onTap: () => Navigator.pop(context, {'ssid': ssid.text.trim(), 'pass': pass.text}),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
