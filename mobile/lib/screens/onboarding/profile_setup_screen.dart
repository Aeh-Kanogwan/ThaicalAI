import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_exception.dart';
import '../../models/models.dart';
import '../../router.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';

/// Profile setup form → PUT /me/profile → shows computed daily target.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  Sex _sex = Sex.female;
  final _age = TextEditingController(text: '28');
  final _height = TextEditingController(text: '165');
  final _weight = TextEditingController(text: '60');
  ActivityLevel _activity = ActivityLevel.moderate;
  Goal _goal = Goal.maintain;

  bool _loading = false;
  String? _error;
  DailyGoal? _computed;

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final profile = Profile(
      sex: _sex,
      age: int.tryParse(_age.text) ?? 0,
      heightCm: double.tryParse(_height.text) ?? 0,
      weightKg: double.tryParse(_weight.text) ?? 0,
      activityLevel: _activity,
      goal: _goal,
    );
    try {
      final goal =
          await ref.read(authControllerProvider.notifier).saveProfile(profile);
      setState(() => _computed = goal);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not save your profile. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_computed != null) {
      return _ResultView(goal: _computed!);
    }

    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('About you')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "We'll compute your daily calorie target from this.",
                  style:
                      text.bodyLarge?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),

                _Label('Sex'),
                SegmentedButton<Sex>(
                  segments: const [
                    ButtonSegment(value: Sex.female, label: Text('Female')),
                    ButtonSegment(value: Sex.male, label: Text('Male')),
                  ],
                  selected: {_sex},
                  onSelectionChanged: (s) => setState(() => _sex = s.first),
                ),
                const SizedBox(height: AppSpacing.md),

                Row(
                  children: [
                    Expanded(
                      child: _NumberField(
                        controller: _age,
                        label: 'Age',
                        suffix: 'yrs',
                        min: 10,
                        max: 100,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _NumberField(
                        controller: _height,
                        label: 'Height',
                        suffix: 'cm',
                        min: 100,
                        max: 250,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _NumberField(
                        controller: _weight,
                        label: 'Weight',
                        suffix: 'kg',
                        min: 25,
                        max: 300,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                _Label('Activity level'),
                DropdownButtonFormField<ActivityLevel>(
                  value: _activity,
                  isExpanded: true,
                  items: ActivityLevel.values
                      .map((a) => DropdownMenuItem(
                            value: a,
                            child: Text('${a.label} · ${a.description}',
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _activity = v ?? _activity),
                ),
                const SizedBox(height: AppSpacing.md),

                _Label('Goal'),
                SegmentedButton<Goal>(
                  segments: const [
                    ButtonSegment(value: Goal.lose, label: Text('Lose')),
                    ButtonSegment(
                        value: Goal.maintain, label: Text('Maintain')),
                    ButtonSegment(value: Goal.gain, label: Text('Gain')),
                  ],
                  selected: {_goal},
                  onSelectionChanged: (s) => setState(() => _goal = s.first),
                ),

                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(_error!,
                      style: text.bodySmall
                          ?.copyWith(color: AppColors.danger)),
                ],
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: 'Compute my target',
                  icon: Icons.calculate_outlined,
                  loading: _loading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: AppColors.textSecondary),
        ),
      );
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final double min;
  final double max;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.min,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, suffixText: suffix),
      validator: (v) {
        final n = double.tryParse(v ?? '');
        if (n == null) return 'Required';
        if (n < min || n > max) return '$min–${max.round()}';
        return null;
      },
    );
  }
}

/// Post-submit screen showing the server-computed daily goal.
class _ResultView extends ConsumerWidget {
  final DailyGoal goal;
  const _ResultView({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.check_circle_rounded,
                  size: 64, color: AppColors.primary),
              const SizedBox(height: AppSpacing.md),
              Text('Your daily target',
                  style:
                      text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${goal.calories}',
                style: text.displayMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                ),
              ),
              Text('kcal / day',
                  style: text.bodyLarge
                      ?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _macro('Protein', goal.proteinG, AppColors.protein),
                      _macro('Carbs', goal.carbsG, AppColors.carbs),
                      _macro('Fat', goal.fatG, AppColors.fat),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'BMR ${goal.bmr.round()} · TDEE ${goal.tdee.round()} kcal',
                style: text.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
              const Spacer(),
              PrimaryButton(
                label: "Let's start tracking",
                icon: Icons.arrow_forward_rounded,
                onPressed: () => context.go(Routes.dashboard),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _macro(String label, double g, Color color) => Column(
        children: [
          Text('${g.round()}g',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: color, fontSize: 18)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
        ],
      );
}
