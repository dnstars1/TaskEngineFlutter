import 'package:flutter_test/flutter_test.dart';

import 'package:taskengineflutter/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TaskEngineApp());
    expect(find.text('TaskEngine'), findsOneWidget);
  });
}
