import 'package:flutter_test/flutter_test.dart';

import 'package:carconvert/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CarConvertApp());
    expect(find.text('CarConvert'), findsOneWidget);
  });
}
