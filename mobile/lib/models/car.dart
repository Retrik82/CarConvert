class RenderResult {
  final String id;
  final String jobId;
  final String? name;
  final String? originalPath;
  final String? renderedPath;
  final DateTime createdAt;
  final double? qualityScore;

  RenderResult({
    required this.id,
    required this.jobId,
    this.name,
    this.originalPath,
    this.renderedPath,
    required this.createdAt,
    this.qualityScore,
  });

  String displayName(String fallback) => (name != null && name!.trim().isNotEmpty) ? name!.trim() : fallback;

  factory RenderResult.fromJson(Map<String, dynamic> json) {
    return RenderResult(
      id: json['id'] as String,
      jobId: json['job_id'] as String,
      name: json['name'] as String?,
      originalPath: json['original_path'] as String?,
      renderedPath: json['rendered_path'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      qualityScore: json['quality_score'] != null
          ? (json['quality_score'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'job_id': jobId,
        'name': name,
        'original_path': originalPath,
        'rendered_path': renderedPath,
        'created_at': createdAt.toIso8601String(),
        'quality_score': qualityScore,
      };

  RenderResult copyWith({
    String? name,
    String? originalPath,
    String? renderedPath,
  }) {
    return RenderResult(
      id: id,
      jobId: jobId,
      name: name ?? this.name,
      originalPath: originalPath ?? this.originalPath,
      renderedPath: renderedPath ?? this.renderedPath,
      createdAt: createdAt,
      qualityScore: qualityScore,
    );
  }
}

class Car {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<RenderResult> renders;

  Car({
    required this.id,
    required this.name,
    required this.createdAt,
    this.renders = const [],
  });

  RenderResult? get lastRender => renders.isNotEmpty ? renders.last : null;

  String? get lastRenderPreview => lastRender?.renderedPath ?? lastRender?.originalPath;

  factory Car.fromJson(Map<String, dynamic> json) {
    final rendersJson = json['renders'] as List<dynamic>? ?? [];
    return Car(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'My Car',
      createdAt: DateTime.parse(json['created_at'] as String),
      renders: rendersJson
          .map((e) => RenderResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'created_at': createdAt.toIso8601String(),
        'renders': renders.map((r) => r.toJson()).toList(),
      };

  Car copyWith({
    String? name,
    List<RenderResult>? renders,
  }) {
    return Car(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      renders: renders ?? this.renders,
    );
  }
}
