import 'package:flutter/material.dart';
import 'package:lucide_icons_svg/lucide_icons_svg.dart';

/// Lucide outline icons for bottom navigation — matches web client stroke 1.75.
class NavLucideIcon extends StatelessWidget {
  const NavLucideIcon({
    super.key,
    required this.icon,
    this.selected = false,
  });

  final LucideIcons icon;
  final bool selected;

  static const defaultStroke = 1.75;
  static const selectedStroke = 2.25;

  @override
  Widget build(BuildContext context) {
    return LucideIcon(
      icon,
      size: 24,
      strokeWidth: selected ? selectedStroke : defaultStroke,
    );
  }
}
