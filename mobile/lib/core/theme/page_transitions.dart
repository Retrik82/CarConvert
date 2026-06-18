import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Shared fade + slide page transitions (200–300 ms).
abstract final class AppPageTransitions {
  static Route<T> fadeSlide<T>({
    required Widget page,
    Offset beginOffset = const Offset(0, 0.03),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: DesignTokens.durationNormal,
      reverseTransitionDuration: DesignTokens.durationFast,
      transitionsBuilder: (_, animation, __, child) {
        return _buildFadeSlide(animation, child, beginOffset);
      },
    );
  }

  static Route<T> fade<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: DesignTokens.durationFast,
      reverseTransitionDuration: DesignTokens.durationFast,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: DesignTokens.curveStandard),
          child: child,
        );
      },
    );
  }

  static Widget _buildFadeSlide(Animation<double> animation, Widget child, Offset beginOffset) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: DesignTokens.curveEmphasized,
      reverseCurve: DesignTokens.curveStandard,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}

/// Applied globally via [ThemeData.pageTransitionsTheme] for [MaterialPageRoute].
class FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return AppPageTransitions._buildFadeSlide(animation, child, const Offset(0, 0.03));
  }
}
