import 'package:flutter_test/flutter_test.dart';
import 'package:sports_app/main.dart';

void main() {
  testWidgets('App has a Start Tests button', (WidgetTester tester) async {
    await tester.pumpWidget(const SportsApp());

    expect(find.text('Start Tests'), findsOneWidget);
  });
}
