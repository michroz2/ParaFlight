import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:paraflight/main.dart';

void main() {
  testWidgets('Smoke test for ParaFlightApp', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: ParaFlightApp()));

    // Verify that our title is present.
    expect(find.text('ParaFlight'), findsOneWidget);
  });
}
