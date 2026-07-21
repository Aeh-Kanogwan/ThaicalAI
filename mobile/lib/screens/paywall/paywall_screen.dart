import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';

enum _Plan { monthly, yearly }

/// Premium subscription paywall.
/// Payment is Phase 2 (RevenueCat / IAP) — CTA is a TODO stub showing a snackbar.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  _Plan _plan = _Plan.yearly; // default to Best Value

  void _startTrial() {
    // TODO(phase2): integrate In-App Purchase via RevenueCat and call a
    // backend endpoint to upgrade tier -> "vip". For now, stub with a snackbar.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Payments arrive in Phase 2 (RevenueCat). This is a preview.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => context.pop(),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: const Icon(Icons.workspace_premium_rounded,
                          color: Colors.white, size: 44),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Go unlimited with VIP',
                      textAlign: TextAlign.center,
                      style: text.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Keep the streak going without limits.',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  const _ValueTrigger(
                    icon: Icons.auto_awesome,
                    title: 'Unlimited AI scans',
                    subtitle: 'Up to 10 scans/day — no more counting',
                  ),
                  const _ValueTrigger(
                    icon: Icons.monitor_heart_outlined,
                    title: 'Detailed sodium insights',
                    subtitle: 'Vital for Thai cuisine & healthy eating',
                  ),
                  const _ValueTrigger(
                    icon: Icons.sync_rounded,
                    title: 'Health app sync',
                    subtitle: 'Apple Health & Google Fit / Health Connect',
                  ),
                  const _ValueTrigger(
                    icon: Icons.block_flipped,
                    title: 'Ad-free experience',
                    subtitle: 'Focus on your goals, distraction-free',
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  _PlanCard(
                    selected: _plan == _Plan.yearly,
                    onTap: () => setState(() => _plan = _Plan.yearly),
                    title: 'Yearly',
                    price: '฿${AppConfig.yearlyPriceThb}',
                    period: '/year',
                    subtitle:
                        'Just ฿${(AppConfig.yearlyPriceThb / 12).round()}/mo · save 25%',
                    badge: 'BEST VALUE',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _PlanCard(
                    selected: _plan == _Plan.monthly,
                    onTap: () => setState(() => _plan = _Plan.monthly),
                    title: 'Monthly',
                    price: '฿${AppConfig.monthlyPriceThb}',
                    period: '/month',
                    subtitle: 'Flexible, cancel anytime',
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  PrimaryButton(
                    label:
                        'Start ${AppConfig.freeTrialDays}-day free trial',
                    icon: Icons.lock_open_rounded,
                    onPressed: _startTrial,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _plan == _Plan.yearly
                        ? 'Then ฿${AppConfig.yearlyPriceThb}/year. Cancel anytime.'
                        : 'Then ฿${AppConfig.monthlyPriceThb}/month. Cancel anytime.',
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueTrigger extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _ValueTrigger({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: text.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(subtitle,
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String price;
  final String period;
  final String subtitle;
  final String? badge;

  const _PlanCard({
    required this.selected,
    required this.onTap,
    required this.title,
    required this.price,
    required this.period,
    required this.subtitle,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight.withValues(alpha: 0.4)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: text.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      if (badge != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(badge!,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ],
                  ),
                  Text(subtitle,
                      style: text.bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(price,
                    style: text.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                Text(period,
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
