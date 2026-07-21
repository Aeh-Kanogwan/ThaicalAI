import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// "AI Scans Left Today" pill shown on the scanner and dashboard.
class ScanQuotaBadge extends StatelessWidget {
  final Quota quota;
  final bool compact;

  const ScanQuotaBadge({
    super.key,
    required this.quota,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final exhausted = quota.isExhausted;
    final fg = exhausted ? AppColors.accent : Colors.white;
    final bg = exhausted
        ? AppColors.accentSoft
        : Colors.black.withValues(alpha: 0.45);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? 6 : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: exhausted
              ? AppColors.accent.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            exhausted ? Icons.lock_outline : Icons.auto_awesome,
            size: compact ? 14 : 16,
            color: exhausted ? AppColors.accent : Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            exhausted
                ? 'No scans left'
                : '${quota.remaining} AI scans left'
                    '${quota.tier.isVip ? ' today' : ''}',
            style: text.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
