import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme_builder.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/design_tokens.dart';
import '../app_logo.dart';

enum LanguageSwitcherStyle { standard, onPhoto }

class LanguageSwitcher extends StatelessWidget {
  final AppSettingsController controller;
  final LanguageSwitcherStyle style;

  const LanguageSwitcher({
    super.key,
    required this.controller,
    this.style = LanguageSwitcherStyle.standard,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final current = AppLanguage.fromLocale(controller.locale);
    final onPhoto = style == LanguageSwitcherStyle.onPhoto;

    return PopupMenuButton<AppLanguage>(
      tooltip: context.strings.language,
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusChip)),
      color: tokens.surface,
      onSelected: (lang) => controller.setLocale(lang.locale),
      itemBuilder: (_) => AppLanguage.values
          .map(
            (lang) => PopupMenuItem(
              value: lang,
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      lang.label,
                      style: tokens.textStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: lang == current ? tokens.accent : tokens.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lang.fullName,
                      style: tokens.textStyle(
                        fontSize: 14,
                        fontWeight: lang == current ? FontWeight.w600 : FontWeight.w400,
                        color: lang == current ? tokens.textPrimary : tokens.textSecondary,
                      ),
                    ),
                  ),
                  if (lang == current)
                    Icon(Icons.check_rounded, size: 18, color: tokens.accent),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: onPhoto
              ? Colors.white.withValues(alpha: 0.88)
              : tokens.surfaceMuted,
          borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
          border: Border.all(
            color: onPhoto
                ? Colors.white.withValues(alpha: 0.9)
                : tokens.border.withValues(alpha: 0.6),
          ),
          boxShadow: onPhoto
              ? [
                  BoxShadow(
                    color: DesignTokens.textDark.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language_rounded, size: 18, color: tokens.accent),
            const SizedBox(width: 6),
            Text(
              current.label,
              style: tokens.textStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class PremiumTopBar extends StatelessWidget {
  final AppSettingsController settings;
  final Widget? trailing;
  final bool showBrand;

  const PremiumTopBar({
    super.key,
    required this.settings,
    this.trailing,
    this.showBrand = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.screenPaddingH,
        vertical: DesignTokens.spacing8,
      ),
      child: Row(
        children: [
          if (showBrand)
            const Expanded(
              child: AppLogo(iconSize: 36, titleSize: 20, showTagline: false, centered: false),
            )
          else
            LanguageSwitcher(controller: settings),
          if (!showBrand) const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class FeatureHighlightRow extends StatelessWidget {
  final List<FeatureHighlight> features;

  const FeatureHighlightRow({super.key, required this.features});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: features
          .map(
            (f) => Expanded(
              child: _FeatureItem(feature: f),
            ),
          )
          .toList(),
    );
  }
}

class FeatureHighlight {
  final IconData icon;
  final String title;
  final String subtitle;

  const FeatureHighlight({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _FeatureItem extends StatelessWidget {
  final FeatureHighlight feature;

  const _FeatureItem({required this.feature});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing4),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tokens.accentMuted.withValues(alpha: tokens.isDark ? 0.3 : 1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
            ),
            child: ShaderMask(
              shaderCallback: (bounds) => tokens.primaryGradient.createShader(bounds),
              child: Icon(feature.icon, size: 22, color: Colors.white),
            ),
          ),
          const SizedBox(height: DesignTokens.spacing8),
          Text(
            feature.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: tokens.textStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            feature.subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: tokens.textStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
