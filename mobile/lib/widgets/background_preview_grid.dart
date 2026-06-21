import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/design_tokens.dart';
import '../models/background.dart';
import 'background_scene_preview.dart';

/// 16:9 angle grid for comfortable background browsing.
class BackgroundPreviewGrid extends StatelessWidget {
  final BackgroundPreset preset;
  final void Function(String angle)? onAngleTap;

  const BackgroundPreviewGrid({
    super.key,
    required this.preset,
    this.onAngleTap,
  });

  static const angles = [
    'three_quarter_left',
    'three_quarter_right',
    'left',
    'right',
    'front',
    'rear',
    'interior',
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: DesignTokens.spacing12,
        mainAxisSpacing: DesignTokens.spacing12,
        childAspectRatio: 16 / 10,
      ),
      itemCount: angles.length,
      itemBuilder: (context, index) {
        final angle = angles[index];
        final variant = preset.variantByAngle(angle);
        final label = variant?.angleLabel ?? angle.replaceAll('_', ' ');

        return Material(
          color: tokens.surfaceMuted,
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onAngleTap == null ? null : () => onAngleTap!(angle),
            child: Stack(
              fit: StackFit.expand,
              children: [
                BackgroundScenePreview(preset: preset, angle: angle),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
                    ),
                    child: Text(
                      label,
                      style: tokens.textStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> openBackgroundDetailSheet(
  BuildContext context, {
  required BackgroundPreset preset,
  required bool isSelected,
  required VoidCallback onSelect,
}) {
  final s = context.strings;
  final tokens = context.tokens;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.screenPaddingH,
              DesignTokens.spacing16,
              DesignTokens.screenPaddingH,
              DesignTokens.spacing24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: tokens.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.spacing16),
                Text(
                  preset.name,
                  style: tokens.textStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                if (preset.description != null) ...[
                  const SizedBox(height: DesignTokens.spacing8),
                  Text(
                    preset.description!,
                    style: tokens.textStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
                if (preset.generationPrompt != null) ...[
                  const SizedBox(height: DesignTokens.spacing16),
                  Container(
                    padding: const EdgeInsets.all(DesignTokens.spacing12),
                    decoration: BoxDecoration(
                      color: tokens.surfaceMuted,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                      border: Border.all(color: tokens.border.withValues(alpha: 0.6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.backgroundGenerationPrompt,
                          style: tokens.textStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: DesignTokens.spacing8),
                        Text(
                          preset.generationPrompt!,
                          style: tokens.textStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: tokens.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: DesignTokens.spacing16),
                Text(
                  s.backgroundAnglesTitle,
                  style: tokens.textStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: DesignTokens.spacing12),
                BackgroundPreviewGrid(
                  preset: preset,
                  onAngleTap: (angle) => openFullscreenBackgroundAngle(ctx, preset: preset, angle: angle),
                ),
                const SizedBox(height: DesignTokens.spacing24),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onSelect();
                  },
                  child: Text(isSelected ? s.useThisBackground : s.selectBackground),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<void> openFullscreenBackgroundAngle(
  BuildContext context, {
  required BackgroundPreset preset,
  required String angle,
}) {
  final variant = preset.variantByAngle(angle);
  final title = '${preset.name} · ${variant?.angleLabel ?? angle}';

  return Navigator.push(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(ctx),
          ),
        ),
        body: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: BackgroundScenePreview(preset: preset, angle: angle),
            ),
          ),
        ),
      ),
    ),
  );
}
