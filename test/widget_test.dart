import 'package:flutter_test/flutter_test.dart';
import 'package:decision_tracker/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('Counter increment smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: DecisionTrackerApp()));

    // Verify that our app starts. (Change this to match your UI)
    expect(find.text('今日の振り返り'), findsOneWidget);
  });
}
