import 'package:flutter_test/flutter_test.dart';
import 'package:esenyas/main.dart';

void main() {
  testWidgets('App renders launch screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ESenyasApp());
    expect(find.text('e-Senyas'), findsOneWidget);
    expect(find.text('Start Translation'), findsOneWidget);
  });
}
