import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gree_app/main.dart';
import 'package:gree_app/state.dart';
import 'package:gree_app/theme.dart';
import 'package:gree_app/widgets.dart';
import 'package:gree_app/screens/device_about.dart';
import 'package:gree_app/services/remote.dart';

void main() {
  void usePhone(WidgetTester tester) {
    // viewport de celular — senão os toques caem fora da área do teste
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  Future<AppState> pumpApp(WidgetTester tester) async {
    usePhone(tester);
    final st = AppState(demo: true);
    await tester.pumpWidget(GreeApp(st: st));
    await tester.pump(const Duration(milliseconds: 350));
    return st;
  }

  testWidgets('distribuidora: selecionar mostra o nome na hora', (tester) async {
    final st = await pumpApp(tester);
    st.city = 'Rio Branco';
    st.uf = ufDistributors.entries.firstWhere((e) => e.value.isNotEmpty).key;
    st.touch();
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(find.text('Perfil').last);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.scrollUntilVisible(find.text('Moeda e energia'), 300, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Moeda e energia'));
    await tester.pump(const Duration(milliseconds: 350));

    await tester.scrollUntilVisible(find.text('Distribuidora'), 250, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Distribuidora'), findsOneWidget);
    await tester.tap(find.text('Distribuidora'));
    await tester.pump(const Duration(milliseconds: 350));

    // o seletor abre com as opções da UF
    final opcao = ufDistributors[st.uf]!.first;
    expect(find.text(opcao), findsOneWidget, reason: 'o seletor deve abrir com as opções');

    // escolher (estado) faz o nome aparecer na linha — a regressão original
    st.setDistributor(opcao);
    await tester.pump(const Duration(milliseconds: 350));
    expect(st.distributor, opcao);
    // o nome aparece na linha do card (o sheet continua aberto por cima)
    expect(
      find.descendant(of: find.byType(AppCard), matching: find.text(opcao)),
      findsOneWidget,
      reason: 'o nome da distribuidora deve aparecer na linha',
    );
  });

  testWidgets('novo dispositivo: campos criam o aparelho com rede', (tester) async {
    final st = await pumpApp(tester);
    final antes = st.devices.length;
    st.go('adddevice');
    await tester.pump(const Duration(milliseconds: 350));

    await tester.enterText(find.byType(TextField).at(0), 'Ar do escritório');
    await tester.enterText(find.byType(TextField).at(1), 'Escritório');
    await tester.enterText(find.byType(TextField).at(2), 'Casa');
    await tester.enterText(find.byType(TextField).at(3), 'senha123');
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(find.text('Adicionar'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(st.devices.length, antes + 1);
    expect(st.devices.last.name, 'Ar do escritório');
    expect(st.devices.last.wifi, 'Casa');
    expect(st.devices.last.wifiPass, 'senha123');
  });

  testWidgets('controle: mudar modo reflete no aparelho', (tester) async {
    final st = await pumpApp(tester);
    st.go('control');
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(find.text('Calor'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(st.dev.mode, 'heat');

    await tester.tap(find.text('Frio'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(st.dev.mode, 'cool');
  });

  testWidgets('Sobre mostra nome, modelo e rede', (tester) async {
    usePhone(tester);
    final st = AppState(demo: true);
    st.patchDev((d) {
      d.mac = '00123456789a';
      d.ip = '192.168.0.10';
      d.model = 'gree-x1';
      d.fw = 'V1.1.13';
    });
    await tester.pumpWidget(MaterialApp(theme: AppTheme.dark(), home: DeviceAboutScreen(st: st)));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('00123456789a'), findsOneWidget); // MAC
    expect(find.text('192.168.0.10'), findsOneWidget); // IP
    expect(find.text('gree-x1'), findsOneWidget); // modelo
    expect(find.text('V1.1.13'), findsWidgets); // versão/firmware
    expect(find.text(st.dev.name), findsOneWidget); // nome
  });
}
