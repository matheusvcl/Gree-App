import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gree_app/main.dart';
import 'package:gree_app/state.dart';

void main() {
  testWidgets('onboarding cria perfil, ar e família', (WidgetTester tester) async {
    await tester.pumpWidget(GreeApp(st: AppState()));
    await tester.pump(const Duration(milliseconds: 300));

    // passo 1: perfil
    expect(find.text('Crie seu perfil'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Ana');
    await tester.tap(find.text('Continuar'));
    await tester.pump(const Duration(milliseconds: 200));

    // passo 2: configurar o ar
    expect(find.text('Configure seu ar'), findsOneWidget);
    await tester.tap(find.text('Frio'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Continuar'));
    await tester.pump(const Duration(milliseconds: 200));

    // passo 3: localização (pula)
    expect(find.text('Onde você mora?'), findsOneWidget);
    await tester.tap(find.text('Agora não'));
    await tester.pump(const Duration(milliseconds: 200));

    // passo 4: família
    expect(find.text('Modo família'), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await tester.pump(const Duration(milliseconds: 200));

    // passo 5: aparência (tema)
    expect(find.text('Escolha o tema'), findsOneWidget);
    await tester.tap(find.text('Concluir'));
    await tester.pump(const Duration(milliseconds: 300));

    // app na home com o estado criado
    expect(find.text('Início'), findsNWidgets(2));
    expect(find.textContaining('Ar-condicionado'), findsWidgets);
  });
}
