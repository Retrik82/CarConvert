import 'package:carconvert/core/assets/bundled_background_catalog.dart';
import 'package:carconvert/models/background.dart';
import 'package:carconvert/repositories/background_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bundled catalog contains two default presets', () {
    final catalog = BundledBackgroundCatalog.catalog;

    expect(catalog.presets.length, 2);
    expect(catalog.presets.map((p) => p.slug), containsAll(['gray-showroom', 'auto-workshop']));
    expect(catalog.presets.every((p) => p.variants.length == 7), isTrue);
  });

  test('empty remote catalog is filled with bundled presets', () {
    const empty = BackgroundCatalog(
      presets: [],
      custom: [],
      customBackgroundPriceUsd: 0.75,
    );

    final merged = BackgroundRepository.mergeWithDefaultPresets(empty);

    expect(merged.presets.length, 2);
    expect(merged.presets.first.slug, 'gray-showroom');
    expect(merged.custom, isEmpty);
    expect(merged.customBackgroundPriceUsd, 0.75);
  });

  test('remote catalog with presets is unchanged', () {
    const remote = BackgroundCatalog(
      presets: [
        BackgroundPreset(
          id: 'server-1',
          slug: 'gray-showroom',
          name: 'Gray Showroom',
        ),
      ],
      custom: [],
      customBackgroundPriceUsd: 0.5,
    );

    final merged = BackgroundRepository.mergeWithDefaultPresets(remote);

    expect(merged.presets.length, 1);
    expect(merged.presets.first.id, 'server-1');
  });
}
