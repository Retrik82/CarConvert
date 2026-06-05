import 'package:carconvert/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cold start shows splash then login or home', (tester) async {
    await tester.pumpWidget(const RenderWheelsApp());
    expect(find.text('RenderWheels'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 5));

    final onLogin = find.text('Login');
    final onHome = find.text('Take Photo');
    expect(onLogin.evaluate().isNotEmpty || onHome.evaluate().isNotEmpty, isTrue);
  });
}
