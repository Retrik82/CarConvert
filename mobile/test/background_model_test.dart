import 'package:carconvert/models/background.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackgroundPreset', () {
    test('variantByAngle returns matching variant', () {
      const preset = BackgroundPreset(
        id: 'p1',
        slug: 'gray-showroom',
        name: 'Gray Showroom',
        variants: [
          BackgroundVariant(id: 'v1', angle: 'front'),
          BackgroundVariant(id: 'v2', angle: 'left'),
        ],
      );

      expect(preset.variantByAngle('left')?.id, 'v2');
      expect(preset.defaultVariant?.angle, 'front');
    });

    test('fromJson parses catalog preset', () {
      final preset = BackgroundPreset.fromJson({
        'id': 'p1',
        'slug': 'auto-workshop',
        'name': 'Auto Workshop',
        'description': 'Garage',
        'preview_url': '/backgrounds/image/v1',
        'variants': [
          {'id': 'v1', 'angle': 'three_quarter_left', 'preview_url': '/backgrounds/image/v1'},
        ],
      });

      expect(preset.slug, 'auto-workshop');
      expect(preset.variants.length, 1);
      expect(preset.defaultVariant?.angle, 'three_quarter_left');
    });
  });

  group('SelectedBackground', () {
    test('previewUrl prefers variant url', () {
      const selected = SelectedBackground(
        preset: BackgroundPreset(
          id: 'p1',
          slug: 'gray-showroom',
          name: 'Gray',
          previewUrl: '/preset.jpg',
          variants: [BackgroundVariant(id: 'v1', angle: 'front', previewUrl: '/variant.jpg')],
        ),
        variant: BackgroundVariant(id: 'v1', angle: 'front', previewUrl: '/variant.jpg'),
      );

      expect(selected.previewUrl, '/variant.jpg');
    });
  });
}
