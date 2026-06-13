import 'package:flutter_test/flutter_test.dart';
import 'package:electronic_app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ElectronicApp());
    expect(find.text('측정'), findsOneWidget);
  });
}
