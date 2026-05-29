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

  factory HintResponse.fromJson(Map<String, dynamic> json) {
    return HintResponse(
      hint: json['hint'] as String? ?? 'align_car',
      message: json['message'] as String? ?? 'Наведи камеру',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      scores: HintScores.fromJson(json['scores'] as Map<String, dynamic>?),
      overlay: HintOverlay.fromJson(json['overlay'] as Map<String, dynamic>?),
    );
  }

  bool get isPerfect => hint == 'perfect_frame';
}
