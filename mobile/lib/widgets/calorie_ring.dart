import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Large circular calorie progress ring for the dashboard.
/// Shows "Kcal Left" (goal - consumed) in the center with the arc filled
/// proportionally to consumed/goal. Animates the sweep on value change.
class CalorieRing extends StatelessWidget {
  final int consumed;
  final int goal;
  final double size;
  final double strokeWidth;

  const CalorieRing({
    super.key,
    required this.consumed,
    required this.goal,
    this.size = 220,
    this.strokeWidth = 18,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final safeGoal = goal <= 0 ? 1 : goal;
    final fraction = (consumed / safeGoal).clamp(0.0, 1.0);
    final left = goal - consumed;
    final over = left < 0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: fraction),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(
              fraction: value,
              strokeWidth: strokeWidth,
              // Over budget flips the arc to the coral accent.
              progressColor: over ? AppColors.accent : AppColors.primary,
              trackColor: AppColors.primaryLight.withValues(alpha: 0.5),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    over ? '${left.abs()}' : '$left',
                    style: text.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color:
                          over ? AppColors.accent : AppColors.textPrimary,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    over ? 'Kcal over' : 'Kcal left',
                    style: text.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '$consumed / $goal',
                    style: text.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final double strokeWidth;
  final Color progressColor;
  final Color trackColor;

  _RingPainter({
    required this.fraction,
    required this.strokeWidth,
    required this.progressColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progress = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        colors: [progressColor.withValues(alpha: 0.75), progressColor],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Full track.
    canvas.drawCircle(center, radius, track);

    // Progress arc starting at top (-90°).
    const startAngle = -math.pi / 2;
    final sweep = 2 * math.pi * fraction;
    canvas.drawArc(rect, startAngle, sweep, false, progress);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.fraction != fraction ||
      old.progressColor != progressColor ||
      old.strokeWidth != strokeWidth;
}
