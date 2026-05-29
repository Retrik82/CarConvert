class HintScores {
  final double centering;
  final double distance;
  final double angle;

  HintScores({
    required this.centering,
    required this.distance,
    required this.angle,
  });

  factory HintScores.fromJson(Map<String, dynamic>? json) {
    return HintScores(
      centering: (json?['centering'] as num?)?.toDouble() ?? 0,
      distance: (json?['distance'] as num?)?.toDouble() ?? 0,
      angle: (json?['angle'] as num?)?.toDouble() ?? 0,
    );
  }
}

class HintOverlay {
  final String arrow;
  final String color;

  HintOverlay({required this.arrow, required this.color});

  factory HintOverlay.fromJson(Map<String, dynamic>? json) {
    return HintOverlay(
      arrow: json?['arrow'] as String? ?? 'none',
      color: json?['color'] as String? ?? 'yellow',
    );
  }
}

class HintResponse {
  final String hint;
  final String message;
  final double confidence;
  final HintScores scores;
  final HintOverlay overlay;

  HintResponse({
    required this.hint,
    required this.message,
    required this.confidence,
    required this.scores,
    required this.overlay,
  });

  static double _normalizeConfidence(num? value) {
    if (value == null) return 0.5;
    var confidence = value.toDouble();
    if (confidence > 1.0) confidence /= 100.0;
    return confidence.clamp(0.0, 1.0);
  }

  factory HintResponse.fromJson(Map<String, dynamic> json) {
    return HintResponse(
      hint: json['hint'] as String? ?? 'align_car',
      message: json['message'] as String? ?? 'Наведи камеру',
      confidence: _normalizeConfidence(json['confidence'] as num?),
      scores: HintScores.fromJson(json['scores'] as Map<String, dynamic>?),
      overlay: HintOverlay.fromJson(json['overlay'] as Map<String, dynamic>?),
    );
  }

  bool get isPerfect => hint == 'perfect_frame';
}
