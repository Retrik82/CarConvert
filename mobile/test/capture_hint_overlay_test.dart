import 'package:carconvert/core/l10n/hint_localizer.dart';
import 'package:carconvert/core/l10n/strings_en.dart';
import 'package:carconvert/models/hint_response.dart';
import 'package:carconvert/widgets/capture_hint_bar.dart';
import 'package:carconvert/widgets/capture_hint_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CaptureHintBar shows connection status message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        home: Scaffold(
          body: CaptureHintBar(message: 'Connecting...'),
        ),
      ),
    );

    expect(find.text('Connecting...'), findsOneWidget);
  });

  testWidgets('CaptureHintBar shows perfect framing message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        home: Scaffold(
          body: CaptureHintBar(
            message: 'Perfect framing — shoot now',
            isPerfect: true,
          ),
        ),
      ),
    );

    expect(find.text('Perfect framing — shoot now'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('CaptureHintOverlay renders frame guide painter', (tester) async {
    final hint = HintResponse(
      hint: 'align_car',
      message: 'Center',
      confidence: 0.5,
      scores: HintScores(centering: 0.5, distance: 0.5, angle: 0.5),
      overlay: HintOverlay(arrow: 'left', color: 'yellow'),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 600,
            child: CaptureHintOverlay(hint: hint),
          ),
        ),
      ),
    );

    expect(find.byType(CaptureHintOverlay), findsOneWidget);
  });

  group('HintLocalizer', () {
    final localizer = HintLocalizer(StringsEn());

    test('maps hint types to localized messages', () {
      expect(
        localizer.message(
          hint: HintResponse(
            hint: 'move_left',
            message: 'x',
            confidence: 0.5,
            scores: HintScores(centering: 0, distance: 0, angle: 0),
            overlay: HintOverlay(arrow: 'none', color: 'yellow'),
          ),
          status: '',
        ),
        'Move camera left',
      );
    });

    test('returns point camera when hint is null', () {
      expect(localizer.message(hint: null, status: 'Initializing...'), 'Point the camera at the car');
    });
  });
}
