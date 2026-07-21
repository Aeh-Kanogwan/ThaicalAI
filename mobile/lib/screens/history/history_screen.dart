import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../state/weight_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';

/// History: weight tracker line chart + past entries list.
/// [embedded] = true when hosted inside HomeShell (no standalone AppBar back).
class HistoryScreen extends ConsumerWidget {
  final bool embedded;
  const HistoryScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(weightEntriesProvider);

    final body = entriesAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => EmptyState(
        icon: Icons.cloud_off_rounded,
        title: "Couldn't load history",
        message: 'Please try again.',
        action: PrimaryButton(
          label: 'Retry',
          expanded: false,
          onPressed: () => ref.invalidate(weightEntriesProvider),
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return EmptyState(
            icon: Icons.monitor_weight_outlined,
            title: 'No weight logged yet',
            message: 'Log your first weigh-in to see your trend here.',
            action: PrimaryButton(
              label: 'Log weight',
              expanded: false,
              onPressed: () => _promptLogWeight(context, ref),
            ),
          );
        }
        final sorted = [...entries]
          ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
        return ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, 120),
          children: [
            _WeightChartCard(entries: sorted),
            const SizedBox(height: AppSpacing.lg),
            Text('Weigh-ins',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
            ...sorted.reversed.map((e) => _WeightRow(entry: e)),
          ],
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !embedded,
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Log weight',
            onPressed: () => _promptLogWeight(context, ref),
          ),
        ],
      ),
      body: SafeArea(bottom: false, child: body),
    );
  }

  Future<void> _promptLogWeight(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final value = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log weight'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Weight', suffixText: 'kg'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(controller.text);
              Navigator.pop(ctx, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value != null && value > 0) {
      await ref.read(weightActionsProvider).add(value);
    }
  }
}

class _WeightChartCard extends StatelessWidget {
  final List<WeightEntry> entries;
  const _WeightChartCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final weights = entries.map((e) => e.weightKg).toList();
    final minW =
        (weights.reduce((a, b) => a < b ? a : b) - 1).floorToDouble();
    final maxW =
        (weights.reduce((a, b) => a > b ? a : b) + 1).ceilToDouble();
    final latest = entries.last.weightKg;
    final change = entries.length > 1
        ? entries.last.weightKg - entries.first.weightKg
        : 0.0;

    final spots = <FlSpot>[
      for (var i = 0; i < entries.length; i++)
        FlSpot(i.toDouble(), entries[i].weightKg),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current weight',
                        style: text.labelLarge
                            ?.copyWith(color: AppColors.textSecondary)),
                    Text('${latest.toStringAsFixed(1)} kg',
                        style: text.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
                const Spacer(),
                _ChangePill(change: change),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: minW,
                  maxY: maxW,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: AppColors.border,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: ((maxW - minW) / 4).clamp(1.0, 100.0),
                        getTitlesWidget: (v, _) => Text(
                          v.toStringAsFixed(0),
                          style: text.bodySmall
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval:
                            (entries.length / 4).ceilToDouble().clamp(1.0, 100.0),
                        getTitlesWidget: (v, _) {
                          final i = v.round();
                          if (i < 0 || i >= entries.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat('d/M').format(entries[i].loggedAt),
                              style: text.bodySmall
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, __, ___) =>
                            FlDotCirclePainter(
                          radius: 3.5,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: AppColors.primary,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.25),
                            AppColors.primary.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePill extends StatelessWidget {
  final double change;
  const _ChangePill({required this.change});
  @override
  Widget build(BuildContext context) {
    final down = change <= 0;
    final color = down ? AppColors.primary : AppColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(down ? Icons.trending_down_rounded : Icons.trending_up_rounded,
              size: 16, color: color),
          const SizedBox(width: 4),
          Text('${change.abs().toStringAsFixed(1)} kg',
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _WeightRow extends StatelessWidget {
  final WeightEntry entry;
  const _WeightRow({required this.entry});
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: Icon(Icons.monitor_weight_outlined,
              color: AppColors.primaryDark),
        ),
        title: Text('${entry.weightKg.toStringAsFixed(1)} kg',
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        subtitle: Text(DateFormat('EEE, d MMM yyyy').format(entry.loggedAt)),
      ),
    );
  }
}
