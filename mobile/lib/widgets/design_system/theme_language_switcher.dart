import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme_builder.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/design_tokens.dart';

class ThemeSwitcher extends StatelessWidget {
  final AppSettingsController controller;

  const ThemeSwitcher({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final s = context.strings;
    final isDark = controller.isDarkModeExplicit ||
        (controller.themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Semantics(
      button: true,
      label: s.theme,
      child: GestureDetector(
        onTap: controller.toggleTheme,
        child: AnimatedContainer(
          duration: DesignTokens.durationTheme,
          curve: DesignTokens.curveStandard,
          width: 56,
          height: 32,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: tokens.surfaceMuted,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tokens.border.withValues(alpha: 0.6)),
          ),
          child: AnimatedAlign(
            duration: DesignTokens.durationTheme,
            curve: DesignTokens.curveEmphasized,
            alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
            child: AnimatedContainer(
              duration: DesignTokens.durationTheme,
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isDark ? tokens.textPrimary : tokens.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: tokens.shadow.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isDark ? Icons.nightlight_round : Icons.wb_sunny_outlined,
                size: 14,
                color: isDark ? tokens.onAccent : tokens.onAccent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LanguageSwitcher extends StatelessWidget {
  final AppSettingsController controller;

  const LanguageSwitcher({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final current = AppLanguage.fromLocale(controller.locale);

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
                        fontWeight: lang == current ? FontWeight.w500 : FontWeight.w400,
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
          color: tokens.surfaceMuted,
          borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
          border: Border.all(color: tokens.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language_rounded, size: 18, color: tokens.textSecondary),
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

  const PremiumTopBar({
    super.key,
    required this.settings,
    this.trailing,
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
          LanguageSwitcher(controller: settings),
          const Spacer(),
          ThemeSwitcher(controller: settings),
          if (trailing != null) ...[
            const SizedBox(width: DesignTokens.spacing8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
