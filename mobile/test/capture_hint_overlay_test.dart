import 'package:carconvert/models/hint_response.dart';
import 'package:carconvert/widgets/capture_hint_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CaptureHintOverlay shows connection status when hint is null', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CaptureHintOverlay(
            hint: null,
            status: 'Connecting...',
          ),
        ),
      ),
    );

    expect(find.text('Connecting...'), findsOneWidget);
  });

  testWidgets('CaptureHintOverlay shows perfect framing message', (tester) async {
    final hint = HintResponse(
      hint: 'perfect_frame',
      message: 'Good',
      confidence: 0.95,
      scores: HintScores(centering: 1, distance: 1, angle: 1),
      overlay: HintOverlay(arrow: 'none', color: 'green'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CaptureHintOverlay(hint: hint, status: 'AI active'),
        ),
      ),
    );

    expect(find.text('Perfect framing — take the photo'), findsOneWidget);
  });
}
