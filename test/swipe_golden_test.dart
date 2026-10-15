import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gree_app/main.dart';
import 'package:gree_app/state.dart';
import 'package:gree_app/widgets/swipe_card.dart';

void main() {
  testWidgets('golden do swipe', (WidgetTester tester) async {
    await tester.pumpWidget(GreeApp(st: AppState(demo: true)));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Agenda').last);
    await tester.pump(const Duration(milliseconds: 300));

    final card = find.byType(SwipeCard).first;

    // editar: arrasta para a direita, captura e volta sem disparar a ação
    var gesture = await tester.startGesture(tester.getCenter(card));
    for (var i = 1; i <= 5; i++) {
      await gesture.moveBy(const Offset(14, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
    await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/swipe-edit.png'));
    await gesture.moveBy(const Offset(-72, 0));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));

    // excluir: arrasta para a esquerda (o quadrado deve ter o mesmo espaço)
    gesture = await tester.startGesture(tester.getCenter(card));
    for (var i = 1; i <= 5; i++) {
      await gesture.moveBy(const Offset(-14, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.byIcon(Icons.delete_rounded), findsOneWidget);
    await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/swipe-delete.png'));
    await gesture.moveBy(const Offset(72, 0));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));
  });
}
