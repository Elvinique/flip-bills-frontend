import 'package:flutter_test/flutter_test.dart';
import 'package:flip_bills/main.dart';

void main() {
  testWidgets('Super-App Root Bootstrapper Verification Test', (WidgetTester tester) async {
    await tester.pumpWidget(const ByeByeBillApp());

    expect(find.text('Bye-Bye Bill'), findsOneWidget);
    expect(find.text('One app, one wallet.'), findsOneWidget);
  });
}