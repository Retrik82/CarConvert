import 'package:carconvert/app.dart';
import 'package:carconvert/widgets/design_system/car_hero.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App shows splash with hero while bootstrapping', (tester) async {
    await tester.pumpWidget(const RenderWheelsApp());

    expect(find.byType(CarHero), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
