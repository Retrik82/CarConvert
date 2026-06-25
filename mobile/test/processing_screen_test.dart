import 'dart:typed_data';

import 'package:carconvert/core/theme/app_theme_builder.dart';
import 'package:carconvert/screens/processing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

Uint8List _testImageBytes() {
  final source = img.Image(width: 400, height: 300);
  img.fill(source, color: img.ColorRgb8(80, 80, 80));
  return Uint8List.fromList(img.encodeJpg(source));
}

void main() {
  testWidgets('ProcessingScreen shows back button and progress UI', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeBuilder.light,
        home: ProcessingScreen(
          imageBytes: _testImageBytes(),
          autoStart: false,
        ),
      ),
    );

    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    expect(find.text('Processing'), findsOneWidget);
    expect(find.text('Uploading image...'), findsOneWidget);
  });
}
