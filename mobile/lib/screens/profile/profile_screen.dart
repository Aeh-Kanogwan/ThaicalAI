import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../router.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';

/// Profile: user info, goal, tier badge, upgrade + logout.
class ProfileScreen extends ConsumerWidget {
  final bool embedded;
  const ProfileScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final profile = auth.profile;
    final goal = auth.dailyGoal;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !embedded,
        title: const Text('Profile'),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, 120),
          children: [
            // Header card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        (user?.name.isNotEmpty ?? false)
                            ? user!.name[0].toUpperCase()
                            : '?',
                        style: text.titleLarge?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.name ?? 'Guest',
                              style: text.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          Text(user?.email ?? '',
                              style: text.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    _TierBadge(tier: user?.tier ?? UserTier.free),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            if (goal != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daily target',
                          style: text.labelLarge
                              ?.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text('${goal.calories} kcal',
                          style: text.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const Divider(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _stat('Protein', '${goal.proteinG.round()}g',
                              AppColors.protein),
                          _stat('Carbs', '${goal.carbsG.round()}g',
                              AppColors.carbs),
                          _stat('Fat', '${goal.fatG.round()}g',
                              AppColors.fat),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            if (profile != null)
              Card(
                child: Column(
                  children: [
                    _infoRow('Goal', profile.goal.label),
                    const Divider(height: 1),
                    _infoRow('Activity', profile.activityLevel.label),
                    const Divider(height: 1),
                    _infoRow('Sex', profile.sex.label),
                    const Divider(height: 1),
                    _infoRow('Age', '${profile.age} yrs'),
                    const Divider(height: 1),
                    _infoRow('Height', '${profile.heightCm.round()} cm'),
                    const Divider(height: 1),
                    _infoRow('Weight', '${profile.weightKg.round()} kg'),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),

            OutlinedButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit profile & goals'),
              onPressed: () => context.push(Routes.profileSetup),
            ),
            const SizedBox(height: AppSpacing.sm),

            if ((user?.tier ?? UserTier.free) == UserTier.free)
              ElevatedButton.icon(
                icon: const Icon(Icons.workspace_premium_rounded),
                label: const Text('Upgrade to VIP'),
                onPressed: () => context.push(Routes.paywall),
              ),
            const SizedBox(height: AppSpacing.sm),

            TextButton.icon(
              icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
              label: const Text('Log out',
                  style: TextStyle(color: AppColors.danger)),
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go(Routes.welcome);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) => Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: color, fontSize: 16)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
        ],
      );

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary)),
            Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _TierBadge extends StatelessWidget {
  final UserTier tier;
  const _TierBadge({required this.tier});
  @override
  Widget build(BuildContext context) {
    final vip = tier.isVip;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: vip
            ? const LinearGradient(
                colors: [AppColors.accent, Color(0xFFFF9A76)])
            : null,
        color: vip ? null : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            vip ? Icons.workspace_premium_rounded : Icons.person_outline,
            size: 14,
            color: vip ? Colors.white : AppColors.primaryDark,
          ),
          const SizedBox(width: 4),
          Text(
            vip ? 'VIP' : 'Free',
            style: TextStyle(
              color: vip ? Colors.white : AppColors.primaryDark,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
