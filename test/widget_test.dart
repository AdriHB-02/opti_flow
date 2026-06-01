import 'package:flutter_test/flutter_test.dart';

import 'package:opti_flow/main.dart';

void main() {
  testWidgets('App renders OptiFlow title', (WidgetTester tester) async {
    await tester.pumpWidget(const OptiFlowApp());
    await tester.pumpAndSettle();

    expect(find.text('OptiFlow - Login'), findsOneWidget);
  });
}
