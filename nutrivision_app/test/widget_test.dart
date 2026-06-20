import 'package:flutter_test/flutter_test.dart';
import 'package:nutrivision_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App builds smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: NutriVisionApp(initialRoute: '/'),
      ),
    );
    expect(find.byType(NutriVisionApp), findsOneWidget);
  });
}
