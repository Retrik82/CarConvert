import '../../models/background.dart';

/// Offline background presets when the API is unavailable.
class BundledBackgroundCatalog {
  BundledBackgroundCatalog._();

  static const _angles = [
    'three_quarter_left',
    'three_quarter_right',
    'left',
    'right',
    'front',
    'rear',
    'interior',
  ];

  static BackgroundCatalog get catalog => BackgroundCatalog(
        presets: [
          _preset(
            id: 'local-gray-showroom',
            slug: 'gray-showroom',
            name: 'Gray Showroom',
            description: 'Minimalist gray studio with a central podium',
            prompt: 'Minimalist luxury gray automotive showroom studio with soft diffused lighting and a round light-gray podium.',
          ),
          _preset(
            id: 'local-auto-workshop',
            slug: 'auto-workshop',
            name: 'Auto Workshop',
            description: 'Modern professional car service garage',
            prompt: 'Modern professional automotive service garage with bright ceiling workshop lights and a low circular platform.',
          ),
        ],
        custom: const [],
        customBackgroundPriceUsd: 0.5,
      );

  static BackgroundPreset _preset({
    required String id,
    required String slug,
    required String name,
    required String description,
    required String prompt,
  }) {
    return BackgroundPreset(
      id: id,
      slug: slug,
      name: name,
      description: description,
      generationPrompt: prompt,
      variants: _angles
          .map(
            (angle) => BackgroundVariant(
              id: '$id-$angle',
              angle: angle,
            ),
          )
          .toList(),
    );
  }

  static BackgroundPreset? findPresetBySlug(String slug) {
    for (final preset in catalog.presets) {
      if (preset.slug == slug) return preset;
    }
    return null;
  }
}
