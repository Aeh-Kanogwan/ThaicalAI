import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../router.dart';
import '../../state/auth_state.dart';
import '../../state/daily_log_state.dart';
import '../../state/quota_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';

/// Daily Dashboard: calorie ring + macros + meal timeline.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final auth = ref.watch(authControllerProvider);
    final dayAsync = ref.watch(dailyLogProvider);
    final goal = auth.dailyGoal ?? DailyGoal.demo;
    final greeting = _greeting();
    final name = auth.user?.name ?? '';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ref.invalidate(dailyLogProvider),
          child: dayAsync.when(
            loading: () => const _DashboardLoading(),
            error: (e, _) => ListView(
              children: [
                const SizedBox(height: 120),
                EmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: "Couldn't load today",
                  message: 'Pull down to retry.',
                  action: PrimaryButton(
                    label: 'Retry',
                    expanded: false,
                    onPressed: () => ref.invalidate(dailyLogProvider),
                  ),
                ),
              ],
            ),
            data: (day) {
              final s = day.summary;
              final grouped = day.groupedByMeal();
              final target = s.target > 0 ? s.target : goal.calories;

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md, AppSpacing.md, 120),
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(greeting,
                                style: text.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary)),
                            Text(
                              name.isEmpty ? 'Today' : name,
                              style: text.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      const _QuotaChip(),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Calorie ring
                  Center(
                    child: CalorieRing(
                      consumed: s.calories,
                      goal: target,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Macros
                  Row(
                    children: [
                      Expanded(
                        child: MacroCard(
                          label: 'Protein',
                          consumedG: s.protein,
                          targetG: goal.proteinG,
                          color: AppColors.protein,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: MacroCard(
                          label: 'Carbs',
                          consumedG: s.carbs,
                          targetG: goal.carbsG,
                          color: AppColors.carbs,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: MacroCard(
                          label: 'Fat',
                          consumedG: s.fat,
                          targetG: goal.fatG,
                          color: AppColors.fat,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Text('Today’s meals',
                      style:
                          text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.sm),

                  if (day.logs.isEmpty)
                    _EmptyMeals(onScan: () => context.push(Routes.scanner))
                  else
                    ...MealType.values.map((type) {
                      final logs = grouped[type]!;
                      if (logs.isEmpty) return const SizedBox.shrink();
                      return _MealSection(type: type, logs: logs);
                    }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning ☀️';
    if (h < 17) return 'Good afternoon 🌤️';
    return 'Good evening 🌙';
  }
}

class _QuotaChip extends ConsumerWidget {
  const _QuotaChip();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotaAsync = ref.watch(quotaProvider);
    return quotaAsync.maybeWhen(
      data: (q) => GestureDetector(
        onTap: () {
          if (q.isExhausted) context.push(Routes.paywall);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome,
                  size: 14, color: AppColors.primaryDark),
              const SizedBox(width: 4),
              Text('${q.remaining} scans',
                  style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ],
          ),
        ),
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _MealSection extends ConsumerWidget {
  final MealType type;
  final List<MealLog> logs;
  const _MealSection({required this.type, required this.logs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final total = logs.fold<int>(0, (a, b) => a + b.calories);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(type.label,
                    style: text.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('$total kcal',
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textMuted)),
              ],
            ),
            const Divider(),
            ...logs.map(
              (log) => MealTile(
                log: log,
                onDelete: () =>
                    ref.read(logActionsProvider).deleteLog(log.id),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMeals extends StatelessWidget {
  final VoidCallback onScan;
  const _EmptyMeals({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: EmptyState(
          icon: Icons.ramen_dining_rounded,
          title: 'No meals logged yet',
          message: 'Tap the scan button to add your first meal of the day.',
          action: PrimaryButton(
            label: 'Scan a meal',
            icon: Icons.center_focus_strong_rounded,
            expanded: false,
            onPressed: onScan,
          ),
        ),
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}