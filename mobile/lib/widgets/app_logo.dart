import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double iconSize;
  final double titleSize;
  final bool showTagline;

  const AppLogo({
    super.key,
    this.iconSize = 72,
    this.titleSize = 32,
    this.showTagline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.directions_car_filled_rounded, size: iconSize, color: AppTheme.textPrimary),
        const SizedBox(height: AppTheme.spacingElement),
        Text(
          'RenderWheels',
          textAlign: TextAlign.center,
          style: AppTheme.textStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 8),
          Text(
            'AI car rendering studio',
            textAlign: TextAlign.center,
            style: AppTheme.textStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
