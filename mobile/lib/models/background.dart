class BackgroundVariant {
  final String id;
  final String angle;
  final String? previewUrl;

  const BackgroundVariant({
    required this.id,
    required this.angle,
    this.previewUrl,
  });

  factory BackgroundVariant.fromJson(Map<String, dynamic> json) {
    return BackgroundVariant(
      id: json['id'] as String,
      angle: json['angle'] as String,
      previewUrl: json['preview_url'] as String?,
    );
  }

  String get angleLabel {
    switch (angle) {
      case 'left':
        return 'Left';
      case 'right':
        return 'Right';
      case 'front':
        return 'Front';
      case 'rear':
        return 'Rear';
      case 'interior':
        return 'Interior';
      case 'three_quarter_left':
        return '3/4 Left';
      case 'three_quarter_right':
        return '3/4 Right';
      default:
        return angle.replaceAll('_', ' ');
    }
  }
}

class BackgroundPreset {
  final String id;
  final String slug;
  final String name;
  final String? description;
  final String? generationPrompt;
  final String? previewUrl;
  final List<BackgroundVariant> variants;
  final bool isCustom;

  const BackgroundPreset({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    this.generationPrompt,
    this.previewUrl,
    this.variants = const [],
    this.isCustom = false,
  });

  factory BackgroundPreset.fromJson(Map<String, dynamic> json) {
    final variantsJson = json['variants'] as List<dynamic>? ?? const [];
    return BackgroundPreset(
      id: json['id'] as String,
      slug: json['slug'] as String? ?? json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      generationPrompt: json['prompt_template'] as String? ?? json['prompt'] as String?,
      previewUrl: json['preview_url'] as String?,
      variants: variantsJson
          .map((item) => BackgroundVariant.fromJson(item as Map<String, dynamic>))
          .toList(),
      isCustom: json['is_custom'] as bool? ?? false,
    );
  }

  BackgroundVariant? variantByAngle(String angle) {
    for (final variant in variants) {
      if (variant.angle == angle) return variant;
    }
    return variants.isNotEmpty ? variants.first : null;
  }

  BackgroundVariant? get defaultVariant =>
      variantByAngle('three_quarter_left') ?? (variants.isNotEmpty ? variants.first : null);
}

class BackgroundCatalog {
  final List<BackgroundPreset> presets;
  final List<BackgroundPreset> custom;
  final double customBackgroundPriceUsd;

  const BackgroundCatalog({
    required this.presets,
    required this.custom,
    required this.customBackgroundPriceUsd,
  });

  factory BackgroundCatalog.fromJson(Map<String, dynamic> json) {
    final presetsJson = _readPresetList(json['presets'] ?? json['shared_presets']);
    final customJson = _readPresetList(json['custom'] ?? json['user_backgrounds']);
    return BackgroundCatalog(
      presets: presetsJson
          .map((item) => BackgroundPreset.fromJson(item as Map<String, dynamic>))
          .toList(),
      custom: customJson
          .map((item) => BackgroundPreset.fromJson(item as Map<String, dynamic>))
          .toList(),
      customBackgroundPriceUsd: _parsePrice(json['custom_background_price_usd']),
    );
  }

  static List<dynamic> _readPresetList(dynamic value) {
    if (value is List<dynamic>) return value;
    return const [];
  }

  static double _parsePrice(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.5;
    return 0.5;
  }

  List<BackgroundPreset> get all => [...presets, ...custom];
}

/// User selects a background type only — angle is detected from the photo at processing time.
class SelectedBackground {
  final BackgroundPreset preset;

  const SelectedBackground({required this.preset});

  String? get presetId => preset.isCustom || preset.id.startsWith('local-') ? null : preset.id;

  String? get presetSlug => preset.isCustom ? null : preset.slug;

  String? get userBackgroundId => preset.isCustom ? preset.id : null;

  String get displayName => preset.name;

  String? get previewUrl => preset.previewUrl ?? preset.defaultVariant?.previewUrl;
}
