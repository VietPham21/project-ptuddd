import 'package:flutter_test/flutter_test.dart';
import 'package:nutritrack_ai/app.dart';
import 'package:nutritrack_ai/core/di/injection_container.dart' as di;

void main() {
  testWidgets('NutriTrack AI App smoke test', (WidgetTester tester) async {
    await di.initDependencies();
    await tester.pumpWidget(const NutriTrackApp());
    expect(find.byType(NutriTrackApp), findsOneWidget);
    // Tua qua thời gian 2 giây của Splash Screen và đợi ổn định
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
