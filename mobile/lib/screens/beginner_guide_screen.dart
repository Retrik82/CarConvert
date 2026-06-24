import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';
import '../core/preferences/app_preferences.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/design_tokens.dart';
import '../widgets/design_system/app_button.dart';
import '../widgets/design_system/hero_before_after.dart';

class BeginnerGuideScreen extends StatefulWidget {
  final bool markAsSeenOnFinish;

  const BeginnerGuideScreen({super.key, this.markAsSeenOnFinish = true});

  static Future<void> open(BuildContext context, {bool markAsSeenOnFinish = false}) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BeginnerGuideScreen(markAsSeenOnFinish: markAsSeenOnFinish),
      ),
    );
  }

  static Future<void> showIfNeeded(BuildContext context) async {
    final seen = await AppPreferences.instance.hasSeenBeginnerGuide();
    if (seen || !context.mounted) return;
    await open(context, markAsSeenOnFinish: true);
  }

  @override
  State<BeginnerGuideScreen> createState() => _BeginnerGuideScreenState();
}

class _BeginnerGuideScreenState extends State<BeginnerGuideScreen> {
  bool _finishing = false;

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    if (widget.markAsSeenOnFinish) {
      await AppPreferences.instance.setBeginnerGuideSeen(true);
    }
    if (mounted) Navigator.pop(context);
    _finishing = false;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final s = context.strings;
    final steps = [
      _GuideStep(
        icon: Icons.waving_hand_rounded,
        title: s.guideStep1Title,
        body: s.guideStep1Body,
        child: const HeroBeforeAfter(height: 180, afterPresetSlug: 'gray-showroom'),
      ),
      _GuideStep(
        icon: Icons.wallpaper_outlined,
        title: s.guideStep2Title,
        body: s.guideStep2Body,
      ),
      _GuideStep(
        icon: Icons.camera_alt_outlined,
        title: s.guideStep3Title,
        body: s.guideStep3Body,
      ),
      _GuideStep(
        icon: Icons.auto_fix_high_rounded,
        title: s.guideStep4Title,
        body: s.guideStep4Body,
      ),
    ];

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: Text(s.guideTitle),
        actions: [
          TextButton(
            onPressed: _finish,
            child: Text(s.guideSkip),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.screenPaddingH,
                  DesignTokens.spacing12,
                  DesignTokens.screenPaddingH,
                  DesignTokens.spacing24,
                ),
                itemCount: steps.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.spacing12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _GuideIntroCard(
                      title: s.guideTitle,
                      subtitle: s.guideStep1Body,
                    );
                  }
                  final step = steps[index - 1];
                  return _GuideStepCard(stepNumber: index, step: step);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.screenPaddingH,
                DesignTokens.spacing8,
                DesignTokens.screenPaddingH,
                DesignTokens.spacing16,
              ),
              child: AppButton(
                label: s.guideFinish,
                icon: Icons.check_rounded,
                onPressed: _finish,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideStep {
  final IconData icon;
  final String title;
  final String body;
  final Widget? child;

  const _GuideStep({
    required this.icon,
    required this.title,
    required this.body,
    this.child,
  });
}

class _GuideIntroCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _GuideIntroCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing16),
      decoration: BoxDecoration(
        gradient: tokens.primaryGradient,
        borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: tokens.textStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: tokens.onAccent,
            ),
          ),
          const SizedBox(height: DesignTokens.spacing8),
          Text(
            subtitle,
            style: tokens.textStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: tokens.onAccent.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStepCard extends StatelessWidget {
  final int stepNumber;
  final _GuideStep step;

  const _GuideStepCard({
    required this.stepNumber,
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
        border: Border.all(color: tokens.border.withValues(alpha: 0.65)),
      ),
      padding: const EdgeInsets.all(DesignTokens.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: tokens.surfaceMuted,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$stepNumber',
                  style: tokens.textStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: tokens.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.spacing8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: tokens.primaryGradient,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                ),
                child: Icon(step.icon, color: tokens.onAccent, size: 20),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing12),
          Text(
            step.title,
            style: tokens.textStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: DesignTokens.spacing8),
          Text(
            step.body,
            style: tokens.textStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: tokens.textSecondary,
              height: 1.45,
            ),
          ),
          if (step.child != null) ...[
            const SizedBox(height: DesignTokens.spacing16),
            step.child!,
          ],
        ],
      ),
    );
  }
}

