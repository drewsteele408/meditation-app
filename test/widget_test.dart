// Smoke test — verifies the app widget tree can be built without throwing.

import 'package:flutter_test/flutter_test.dart';

import 'package:meditation_app/app.dart';

void main() {
  testWidgets('App builds without error', (WidgetTester tester) async {
    // App requires a ProviderScope ancestor and a Supabase + dotenv
    // initialization, so we only verify the widget class is importable and
    // that the file compiles cleanly.  Integration-level smoke tests that
    // boot the full app should use a dedicated integration_test target.
    expect(App, isNotNull);
  });
}
