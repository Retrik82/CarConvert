import 'dart:typed_data';

import 'package:carconvert/screens/processing_screen.dart';
import 'package:carconvert/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ProcessingScreen shows back button and progress UI', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: ProcessingScreen(
          imageBytes: Uint8List.fromList([1, 2, 3]),
          autoStart: false,
        ),
      ),
    );

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.text('Processing'), findsOneWidget);
    expect(find.text('Rendering your car...'), findsOneWidget);
  });
}
