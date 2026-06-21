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
  final _pageController = PageController();
  int _page = 0;

  static const _pageCount = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (widget.markAsSeenOnFinish) {
      await AppPreferences.instance.setBeginnerGuideSeen(true);
    }
    if (mounted) Navigator.pop(context);
  }

  void _next() {
    if (_page >= _pageCount - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: DesignTokens.durationTheme,
      curve: DesignTokens.curveStandard,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final s = context.strings;

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: Text(s.guideTitle),
        actions: [
          TextButton(onPressed: _finish, child: Text(s.guideSkip)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                _GuidePage(
                  icon: Icons.waving_hand_rounded,
                  title: s.guideStep1Title,
                  body: s.guideStep1Body,
                  child: HeroBeforeAfter(height: 180, afterPresetSlug: 'gray-showroom'),
                ),
                _GuidePage(
                  icon: Icons.wallpaper_outlined,
                  title: s.guideStep2Title,
                  body: s.guideStep2Body,
                ),
                _GuidePage(
                  icon: Icons.camera_alt_outlined,
                  title: s.guideStep3Title,
                  body: s.guideStep3Body,
                ),
                _GuidePage(
                  icon: Icons.auto_fix_high_rounded,
                  title: s.guideStep4Title,
                  body: s.guideStep4Body,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(DesignTokens.screenPaddingH),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pageCount,
                    (i) => AnimatedContainer(
                      duration: DesignTokens.durationTheme,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: i == _page ? tokens.accent : tokens.surfaceMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.spacing16),
                AppButton(
                  label: _page >= _pageCount - 1 ? s.guideFinish : s.guideNext,
                  icon: _page >= _pageCount - 1 ? Icons.check_rounded : Icons.arrow_forward_rounded,
                  onPressed: _next,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidePage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Widget? child;

  const _GuidePage({
    required this.icon,
    required this.title,
    required this.body,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.screenPaddingH),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: tokens.primaryGradient,
              borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
            ),
            child: Icon(icon, color: tokens.onAccent, size: 32),
          ),
          const SizedBox(height: DesignTokens.spacing24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: tokens.textStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.4),
          ),
          const SizedBox(height: DesignTokens.spacing12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: tokens.textStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: tokens.textSecondary,
              height: 1.5,
            ),
          ),
          if (child != null) ...[
            const SizedBox(height: DesignTokens.spacing24),
            child!,
          ],
        ],
      ),
    );
  }
}
