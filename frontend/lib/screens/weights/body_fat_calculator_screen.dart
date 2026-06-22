import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/subpage_header.dart';

class BodyFatCalculatorScreen extends StatefulWidget {
  const BodyFatCalculatorScreen({
    super.key,
    this.initialSex = 'female',
    this.initialWeight,
    this.initialHeight,
    this.initialAge,
  });

  final String initialSex;
  final double? initialWeight;
  final double? initialHeight;
  final int? initialAge;

  @override
  State<BodyFatCalculatorScreen> createState() => _BodyFatCalculatorScreenState();
}

class _BodyFatCalculatorScreenState extends State<BodyFatCalculatorScreen> {
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _ageController;
  final _neckController = TextEditingController();
  final _backController = TextEditingController();
  final _stomachController = TextEditingController();

  late String _sex;

  @override
  void initState() {
    super.initState();
    _sex = widget.initialSex;
    _weightController = TextEditingController(
      text: widget.initialWeight == null ? '' : widget.initialWeight!.toStringAsFixed(1),
    );
    _heightController = TextEditingController(
      text: widget.initialHeight == null ? '' : widget.initialHeight!.toStringAsFixed(1),
    );
    _ageController = TextEditingController(
      text: widget.initialAge == null ? '' : widget.initialAge!.toString(),
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _neckController.dispose();
    _backController.dispose();
    _stomachController.dispose();
    super.dispose();
  }

  int? get _age => int.tryParse(_ageController.text.trim());
  double? get _weight => double.tryParse(_weightController.text.trim());
  double? get _neck => double.tryParse(_neckController.text.trim());
  double? get _back => double.tryParse(_backController.text.trim());
  double? get _stomach => double.tryParse(_stomachController.text.trim());

  bool get _canCalculate {
    if (_age == null || _weight == null || _neck == null || _back == null || _stomach == null) return false;
    return true;
  }

  double? get _bodyFatPercentage {
    if (!_canCalculate) return null;
    final age = _age!.toDouble();
    final sum = _neck! + _back! + _stomach!;
    if (sum <= 0) return null;

    final bodyDensity = _sex == 'female'
        ? 1.0994921 - (0.0009929 * sum) + (0.0000023 * math.pow(sum, 2)) - (0.0001392 * age)
        : 1.10938 - (0.0008267 * sum) + (0.0000016 * math.pow(sum, 2)) - (0.0002574 * age);
    if (bodyDensity <= 0) return null;

    return (495 / bodyDensity) - 450;
  }

  double? get _leanMass {
    final bodyFat = _bodyFatPercentage;
    final weight = _weight;
    if (bodyFat == null || weight == null) return null;
    return weight * (1 - (bodyFat / 100));
  }

  double? get _minimumSafeWeight {
    final leanMass = _leanMass;
    if (leanMass == null) return null;
    final minimumBodyFat = _sex == 'female' ? 18 : 7;
    return leanMass / (1 - (minimumBodyFat / 100));
  }

  String get _statusLabel {
    final bf = _bodyFatPercentage;
    if (bf == null) return 'Need measurements';
    if ((_sex == 'male' && bf < 7) || (_sex == 'female' && bf < 18)) return 'Physician clearance required';
    if (bf <= (_sex == 'male' ? 14 : 20)) return 'Competition ready';
    if (bf <= (_sex == 'male' ? 18 : 26)) return 'Train and monitor';
    return 'Needs review';
  }

  Color get _statusColor {
    switch (_statusLabel) {
      case 'Competition ready':
        return AppColors.success;
      case 'Train and monitor':
        return AppColors.warning;
      case 'Physician clearance required':
      case 'Needs review':
        return AppColors.danger;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bodyFat = _bodyFatPercentage;
    final minimumSafeWeight = _minimumSafeWeight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SubpageHeader(
            title: 'Body Fat Calculator',
            subtitle: 'Estimate body fat %, lean mass, and a safer minimum wrestling weight using a 3-site skinfold check.',
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Skinfold calculator', style: AppTextStyles.sectionTitle),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Enter skinfold measurements in millimeters. Use the same pinch style each time so staff can compare trend lines cleanly.',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    _SelectField(
                      label: 'Sex',
                      value: _sex,
                      items: const ['male', 'female'],
                      onChanged: (value) => setState(() => _sex = value!),
                    ),
                    _NumberField(controller: _ageController, label: 'Age', onChanged: () => setState(() {})),
                    _NumberField(controller: _weightController, label: 'Weight (lbs)', onChanged: () => setState(() {})),
                    _NumberField(controller: _heightController, label: 'Height (in, optional)', onChanged: () => setState(() {})),
                    _NumberField(controller: _neckController, label: 'Neck skinfold (mm)', onChanged: () => setState(() {})),
                    _NumberField(controller: _backController, label: 'Back skinfold (mm)', onChanged: () => setState(() {})),
                    _NumberField(controller: _stomachController, label: 'Stomach skinfold (mm)', onChanged: () => setState(() {})),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    ElevatedButton.icon(
                      onPressed: bodyFat == null
                          ? null
                          : () => Navigator.of(context).pop(bodyFat),
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Use this percentage'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        _neckController.clear();
                        _backController.clear();
                        _stomachController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('Clear skinfolds'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _ResultCard(
                label: 'Body fat %',
                value: bodyFat == null ? '--' : '${bodyFat.toStringAsFixed(1)}%',
                note: 'estimated from 3-site skinfolds',
                accent: _statusColor,
              ),
              _ResultCard(
                label: 'Lean mass',
                value: _leanMass == null ? '--' : '${_leanMass!.toStringAsFixed(1)} lbs',
                note: 'non-fat mass estimate',
                accent: const Color(0xFF38BDF8),
              ),
              _ResultCard(
                label: 'Minimum safe weight',
                value: minimumSafeWeight == null ? '--' : '${minimumSafeWeight.toStringAsFixed(1)} lbs',
                note: _sex == 'female' ? 'based on 18% body fat floor' : 'based on 7% body fat floor',
                accent: const Color(0xFFF59E0B),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Coach read', style: AppTextStyles.cardTitle),
                    const Spacer(),
                    _StatusPill(label: _statusLabel, color: _statusColor),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ..._notes(bodyFat, minimumSafeWeight).map(
                  (note) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(note, style: AppTextStyles.body)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _notes(double? bodyFat, double? minimumSafeWeight) {
    if (bodyFat == null || minimumSafeWeight == null) {
      return const [
        'Add age, weight, and the neck, back, and stomach skinfolds to estimate body fat.',
        'Once calculated, you can push the result back into the weight planner or nutrition planner.',
      ];
    }

    return [
      'Estimated body fat is ${bodyFat.toStringAsFixed(1)}%. Treat this as a field estimate, not a lab result.',
      'Estimated minimum safe wrestling weight is ${minimumSafeWeight.toStringAsFixed(1)} lbs.',
      if ((_sex == 'male' && bodyFat < 7) || (_sex == 'female' && bodyFat < 18))
        'This athlete is under the allowed body fat floor and needs physician clearance before continuing.'
      else
        'Use the body fat floor to decide the lowest class staff should even consider.',
      if ((_weight ?? 0) < minimumSafeWeight)
        'Current weight is already below the model’s safe floor and needs staff review plus physician clearance.'
      else
        'Do not set a target class below the minimum safe weight. If the athlete drops under the floor, require physician clearance.',
    ];
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
        onChanged: (_) => onChanged(),
      ),
    );
  }
}

class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label),
        items: items
            .map((item) => DropdownMenuItem<String>(value: item, child: Text(item)))
            .toList(),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.label,
    required this.value,
    required this.note,
    required this.accent,
  });

  final String label;
  final String value;
  final String note;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusPill(label: label, color: accent),
          const SizedBox(height: AppSpacing.md),
          Text(value, style: AppTextStyles.pageTitle.copyWith(fontSize: 30)),
          const SizedBox(height: AppSpacing.xs),
          Text(note, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
