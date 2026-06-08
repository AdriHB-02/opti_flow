import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Flutter framework smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: const Text('test'))),
    );
    expect(find.text('test'), findsOneWidget);
  });
}
