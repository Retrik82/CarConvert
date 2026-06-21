import 'package:carconvert/core/theme/app_theme_builder.dart';
import 'package:carconvert/screens/backgrounds_screen.dart';
import 'package:carconvert/widgets/design_system/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppThemeBuilder.light,
      locale: const Locale('en'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    );
  }

  testWidgets('BackgroundsScreen shows bundled preset cards', (tester) async {
    await tester.pumpWidget(wrap(const BackgroundsScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Gray Showroom'), findsOneWidget);
    expect(find.text('Auto Workshop'), findsOneWidget);
    expect(find.text('Shared backgrounds'), findsOneWidget);
    expect(find.text('Select background'), findsNWidgets(2));
  });

  testWidgets('BackgroundsScreen opens angle detail sheet', (tester) async {
    await tester.pumpWidget(wrap(const BackgroundsScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    final previewButton = find.descendant(
      of: find.byType(AppButton),
      matching: find.text('Tap to view details'),
    );
    await tester.ensureVisible(previewButton.first);
    await tester.tap(previewButton.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('All camera angles'), findsOneWidget);
  });
}
