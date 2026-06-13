import 'package:carconvert/core/theme/app_theme_builder.dart';
import 'package:carconvert/screens/login_screen.dart';
import 'package:carconvert/widgets/design_system/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  Future<void> tapButton(WidgetTester tester, String label) async {
    final finder = find.descendant(
      of: find.byType(AppButton),
      matching: find.text(label),
    );
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
  }

  testWidgets('LoginScreen shows validation errors on empty submit', (tester) async {
    await tester.pumpWidget(wrap(LoginScreen(onLoggedIn: () {})));
    await tester.pumpAndSettle();

    await tapButton(tester, 'Sign in');

    expect(find.text('Email or username is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('LoginScreen navigates to register screen', (tester) async {
    await tester.pumpWidget(wrap(LoginScreen(onLoggedIn: () {})));
    await tester.pumpAndSettle();

    await tapButton(tester, 'Create account');
    await tester.pumpAndSettle();

    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Register'), findsOneWidget);
  });

  testWidgets('LoginScreen navigates to forgot password screen', (tester) async {
    await tester.pumpWidget(wrap(LoginScreen(onLoggedIn: () {})));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Forgot password'));
    await tester.tap(find.text('Forgot password'));
    await tester.pumpAndSettle();

    expect(find.text('Send reset link'), findsOneWidget);
  });
}
