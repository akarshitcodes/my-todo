import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_todo/main.dart';

void main() {
  testWidgets(
    'Todo app builds successfully',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const TodoApp(
          initialThemeMode: ThemeMode.system,
        ),
      );

      await tester.pump();

      expect(
        find.byType(TodoApp),
        findsOneWidget,
      );
    },
  );
}