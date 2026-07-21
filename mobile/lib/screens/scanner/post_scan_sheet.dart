import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';

/// Serving size multipliers applied to the matched food's per-serving macros.
enum ServingSize {
  small,
  regular,
  large;

  double get factor {
    switch (this) {
      case ServingSize.small:
        return 0.7;
      case ServingSize.regular:
        return 1.0;
      case ServingSize.large:
        return 1.5;
    }
  }

  String get label {
    switch (this) {
      case ServingSize.small:
        return 'Small';
      case ServingSize.regular:
        return 'Regular';
      case ServingSize.large:
        return 'Large';
    }
  }
}

typedef AddToLog = Future<void> Function(CreateLogRequest req);

/// Post-Scan modal: matched results + confidence, serving selector,
/// macro summary, and "Add to log".
class PostScanSheet extends StatefulWidget {
  final ScanResult result;
  final AddToLog onAddToLog;

  const PostScanSheet({
    super.key,
    required this.result,
    required this.onAddToLog,
  });

  @override
  State<PostScanSheet> createState() => _PostScanSheetState();
}

class _PostScanSheetState extends State<PostScanSheet> {
  ServingSize _serving = ServingSize.regular;
  MealType _mealType = _defaultMeal();
  bool _submitting = false;

  static MealType _defaultMeal() {
    final h = DateTime.now().hour;
    if (h < 11) return MealType.breakfast;
    if (h < 15) return MealType.lunch;
    if (h < 21) return MealType.dinner;
    return MealType.snack;
  }

  List<ScanItem> get _matched =>
      widget.result.items.where((i) => i.isMatched).toList();

  int get _calories => _matched.fold<int>(
      0, (a, i) => a + (i.matchedFood!.calories * _serving.factor).round());
  double get _protein => _matched.fold<double>(
      0, (a, i) => a + i.matchedFood!.protein * _serving.factor);
  double get _carbs => _matched.fold<double>(
      0, (a, i) => a + i.matchedFood!.carbs * _serving.factor);
  double get _fat => _matched.fold<double>(
      0, (a, i) => a + i.matchedFood!.fat * _serving.factor);
  double get _sodium => _matched.fold<double>(
      0, (a, i) => a + (i.matchedFood!.sodium ?? 0) * _serving.factor);
  double get _grams =>
      _matched.fold<double>(0, (a, i) => a + i.grams * _serving.factor);

  Future<void> _add() async {
    if (_matched.isEmpty) return;
    setState(() => _submitting = true);
    // Combine matched items into one log entry (name = primary dish).
    final primary = _matched.first.matchedFood!;
    final name = _matched.length == 1
        ? primary.displayName
        : '${primary.displayName} +${_matched.length - 1}';
    final req = CreateLogRequest(
      foodId: _matched.length == 1 ? primary.id : null,
      customName: _matched.length == 1 ? null : name,
      mealType: _mealType,
      grams: double.parse(_grams.toStringAsFixed(1)),
      calories: _calories,
      protein: double.parse(_protein.toStringAsFixed(1)),
      carbs: double.parse(_carbs.toStringAsFixed(1)),
      fat: double.parse(_fat.toStringAsFixed(1)),
      sodium: double.parse(_sodium.toStringAsFixed(1)),
      scanId: widget.result.scanId,
    );
    try {
      await widget.onAddToLog(req);
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.sheet,
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Match found',
                            style: text.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const Spacer(),
                        _ConfidencePill(pct: widget.result.confidencePct),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (_matched.isEmpty)
                      const _NoMatch()
                    else
                      ...widget.result.items
                          .map((item) => _ItemRow(item: item)),

                    const SizedBox(height: AppSpacing.lg),

                    // Serving selector.
                    Text('Serving size',
                        style: text.labelLarge
                            ?.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedButton<ServingSize>(
                      segments: ServingSize.values
                          .map((s) => ButtonSegment(
                              value: s, label: Text(s.label)))
                          .toList(),
                      selected: {_serving},
                      onSelectionChanged: (s) =>
                          setState(() => _serving = s.first),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Meal type.
                    Text('Meal',
                        style: text.labelLarge
                            ?.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: MealType.values.map((m) {
                        final selected = _mealType == m;
                        return ChoiceChip(
                          label: Text(m.label),
                          selected: selected,
                          onSelected: (_) => setState(() => _mealType = m),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Macro summary.
                    _MacroSummary(
                      calories: _calories,
                      protein: _protein,
                      carbs: _carbs,
                      fat: _fat,
                      sodium: _sodium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
              // Sticky footer CTA.
              Container(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.md + MediaQuery.of(context).padding.bottom,
                ),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: PrimaryButton(
                  label: 'Add to log · $_calories kcal',
                  icon: Icons.add_rounded,
                  loading: _submitting,
                  onPressed: _matched.isEmpty ? null : _add,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ItemRow extends StatelessWidget {
  final ScanItem item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final matched = item.matchedFood;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: matched != null
                    ? AppColors.primaryLight
                    : AppColors.accentSoft,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                matched != null ? Icons.restaurant : Icons.help_outline,
                color: matched != null
                    ? AppColors.primaryDark
                    : AppColors.accent,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(matched?.displayName ?? item.label,
                      style: text.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    matched != null
                        ? '${item.estimatedPortion ?? matched.servingSize} · ${item.grams.round()} g'
                        : 'No match — search manually',
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            _ConfidencePill(pct: item.confidencePct, small: true),
          ],
        ),
      ),
    );
  }
}

class _ConfidencePill extends StatelessWidget {
  final int pct;
  final bool small;
  const _ConfidencePill({required this.pct, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 8 : 10, vertical: small ? 3 : 5),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$pct% match',
        style: TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w700,
          fontSize: small ? 11 : 12,
        ),
      ),
    );
  }
}

class _MacroSummary extends StatelessWidget {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sodium;

  const _MacroSummary({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.sodium,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total calories',
                    style: text.titleSmall
                        ?.copyWith(color: AppColors.textSecondary)),
                Text('$calories kcal',
                    style: text.titleMedium?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w800)),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _macro('Protein', protein, AppColors.protein),
                _macro('Carbs', carbs, AppColors.carbs),
                _macro('Fat', fat, AppColors.fat),
                _macro('Sodium', sodium, AppColors.water, unit: 'mg'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _macro(String label, double v, Color color, {String unit = 'g'}) {
    return Column(
      children: [
        Text('${v.round()}$unit',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: color, fontSize: 15)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}

class _NoMatch extends StatelessWidget {
  const _NoMatch();
  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.search_off_rounded,
      title: 'No confident match',
      message:
          "We couldn't confidently match this dish. Try searching manually or re-scan with better lighting.",
    );
  }
}
