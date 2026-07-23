import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firelens/main.dart';

void main() {
  testWidgets('App renders MainScreen widget smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FirestoreClientApp(),
      ),
    );
    expect(find.byType(FirestoreClientApp), findsOneWidget);
  });
}
