import 'package:flutter_test/flutter_test.dart';
import 'package:flip_bills/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FlipBillsApp());
    expect(find.byType(FlipBillsApp), findsOneWidget);
  });
}
