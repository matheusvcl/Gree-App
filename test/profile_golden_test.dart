import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gree_app/main.dart';
import 'package:gree_app/state.dart';

void main() {
  testWidgets('golden editar perfil claro', (WidgetTester tester) async {
    final st = AppState(demo: true);
    st.setTheme('light');
    await tester.pumpWidget(GreeApp(st: st));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Perfil').last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Editar perfil'));
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/editprofile-light.png'));
  });
}
