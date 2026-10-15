import 'package:flutter_test/flutter_test.dart';
import 'package:gree_app/main.dart';
import 'package:gree_app/state.dart';

void main() {
  testWidgets('app renderiza e navega', (WidgetTester tester) async {
    await tester.pumpWidget(GreeApp(st: AppState()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Início'), findsOneWidget);

    // navega para Agenda
    await tester.tap(find.text('Agenda'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('ROTINAS'), findsOneWidget);

    // abre a tela de controle do ar
    await tester.tap(find.text('Início'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Ar da Sala'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Controle'), findsOneWidget);
    expect(find.text('VELOCIDADE DO VENTO'), findsOneWidget);

    // perfil: subscreens renderizam conteúdo
    await tester.tap(find.text('Voltar'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Perfil'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Aparência'), findsOneWidget);
    await tester.tap(find.text('Gerenciar locais'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Locais separam'), findsOneWidget);

    // editor de rotinas abre ao tocar
    await tester.tap(find.text('Voltar'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Agenda'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Acordar'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Editar agendamento'), findsOneWidget);
  });
}
