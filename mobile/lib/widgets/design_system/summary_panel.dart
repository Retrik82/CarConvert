import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/design_tokens.dart';

class StickyBottomCta extends StatelessWidget {
  final Widget child;
  final bool showGradient;

  const StickyBottomCta({
    super.key,
    required this.child,
    this.showGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.screenPaddingH,
        DesignTokens.spacing16,
        DesignTokens.screenPaddingH,
        bottom + DesignTokens.spacing16,
      ),
      decoration: BoxDecoration(
        gradient: showGradient
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  tokens.background.withValues(alpha: 0),
                  tokens.background.withValues(alpha: 0.92),
                  tokens.background,
                ],
                stops: const [0, 0.35, 1],
              )
            : null,
        color: showGradient ? null : tokens.background,
      ),
      child: child,
    );
  }
}

class SummaryPanel extends StatelessWidget {
  final String title;
  final List<SummaryRow> rows;

  const SummaryPanel({
    super.key,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing24),
      decoration: tokens.cardDecoration(elevated: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: tokens.textStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: DesignTokens.spacing16),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.spacing12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (row.leading != null) ...[
                    row.leading!,
                    const SizedBox(width: DesignTokens.spacing12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.label,
                          style: tokens.textStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: tokens.textSecondary,
                          ),
                        ),
                        Text(
                          row.value,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: tokens.textStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryRow {
  final String label;
  final String value;
  final Widget? leading;

  const SummaryRow({required this.label, required this.value, this.leading});
}

class SegmentedControl<T> extends StatelessWidget {
  final List<SegmentItem<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  const SegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
        border: Border.all(color: tokens.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: segments.map((seg) {
          final active = seg.value == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(seg.value),
              child: AnimatedContainer(
                duration: DesignTokens.durationNormal,
                curve: DesignTokens.curveStandard,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? tokens.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusButton - 4),
                  boxShadow: active && !tokens.isDark
                      ? [
                          BoxShadow(
                            color: tokens.shadow.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  seg.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: tokens.textStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? tokens.textPrimary : tokens.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class SegmentItem<T> {
  final T value;
  final String label;

  const SegmentItem({required this.value, required this.label});
}
