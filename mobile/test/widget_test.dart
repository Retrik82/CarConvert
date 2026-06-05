import 'package:carconvert/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App shows splash with logo while bootstrapping', (tester) async {
    await tester.pumpWidget(const RenderWheelsApp());

    expect(find.text('RenderWheels'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    // Bootstrap completes to login or home depending on stored session.
    expect(
      find.text('RenderWheels').evaluate().isNotEmpty ||
          find.text('Login').evaluate().isNotEmpty,
      isTrue,
    );
  });
}
