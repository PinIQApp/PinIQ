import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../models/nutrition_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/section_header.dart';
import '../../widgets/subpage_header.dart';
import '../nutrition/nutrition_plan_screen.dart';
import '../weights/body_fat_calculator_screen.dart';

class NutritionCenterScreen extends StatefulWidget {
  const NutritionCenterScreen({super.key});

  @override
  State<NutritionCenterScreen> createState() => _NutritionCenterScreenState();
}

class _NutritionCenterScreenState extends State<NutritionCenterScreen> {
  String _filter = 'all';
  int _selectedIndex = 0;
  int _selectedProfileIndex = 0;

  static const List<_MealPlanRecord> _plans = [
    _MealPlanRecord(
      athlete: 'Avery Hall',
      phase: 'In season',
      status: 'Needs review',
      target: '120 lbs',
      planName: 'Balanced cut support',
      summary:
          'Hydration and meal timing need a coach check before the weekend.',
      notes: [
        'Weight trend needs a safer hydration reset before travel.',
        'Family summary should spell out recovery meals clearly.',
        'Post-practice fuel window is being missed too often.',
      ],
      nextStep: 'Tighten hydration and review the Friday dinner plan tonight.',
      familyStatus: 'Needs parent clarity',
      compliance: '2 missed check-ins',
    ),
    _MealPlanRecord(
      athlete: 'Maya Slone',
      phase: 'Maintenance',
      status: 'Healthy',
      target: '132 lbs',
      planName: 'Steady maintenance',
      summary:
          'Stable weekly pattern with good compliance and no safety flags.',
      notes: [
        'Current meal rhythm has held for two full weeks.',
        'Hydration compliance is strong throughout the school day.',
        'Safe to share clean parent-facing guidance.',
      ],
      nextStep:
          'Keep maintenance structure and monitor tournament-week breakfast timing.',
      familyStatus: 'Ready to share',
      compliance: 'All check-ins complete',
    ),
    _MealPlanRecord(
      athlete: 'Jocelyn Reed',
      phase: 'Off season',
      status: 'Template ready',
      target: '155 lbs',
      planName: 'Strength build',
      summary: 'Off-season nutrition block is ready to apply and customize.',
      notes: [
        'Good base for strength-heavy training blocks.',
        'Can become a reusable template for the room.',
        'Needs substitutions list before it goes to families.',
      ],
      nextStep:
          'Convert this into a reusable family-friendly template with swaps.',
      familyStatus: 'Template draft',
      compliance: 'Setup stage',
    ),
    _MealPlanRecord(
      athlete: 'Kylie Johnson',
      phase: 'In season',
      status: 'Flagged',
      target: '145 lbs',
      planName: 'Cut safety review',
      summary: 'Unsafe drop pattern detected across recent weigh-ins.',
      notes: [
        'Current drop pace should not continue without staff review.',
        'Body fat threshold needs to be checked again before approval.',
        'Recovery and replacement foods must be simplified for home use.',
      ],
      nextStep:
          'Stop the cut and require physician-aware coach review before any change.',
      familyStatus: 'Hold communication',
      compliance: 'Red flag triggered',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final profiles = appState.nutritionProfiles;
    final reviewCount = _plans
        .where(
            (plan) => plan.status == 'Needs review' || plan.status == 'Flagged')
        .length;
    final readyCount = _plans.where((plan) => plan.status == 'Healthy').length;
    final bodyFatCount =
        profiles.where((profile) => profile.bodyFat != 'Needed').length;
    final visible = _filteredPlans();

    if (_selectedIndex >= visible.length) {
      _selectedIndex = visible.isEmpty ? 0 : visible.length - 1;
    }
    if (_selectedProfileIndex >= profiles.length) {
      _selectedProfileIndex = profiles.isEmpty ? 0 : profiles.length - 1;
    }

    final selectedPlan = visible.isEmpty ? null : visible[_selectedIndex];
    final selectedProfile = _resolveSelectedProfile(profiles, selectedPlan);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1180;

          return Container(
            decoration: const BoxDecoration(
              color: AppColors.bg,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF07111C),
                  AppColors.bg,
                ],
              ),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SubpageHeader(
                  title: 'Nutrition Center',
                  subtitle:
                      'Run safer meal plans, clearer family handoffs, and tighter coach oversight.',
                ),
                const SizedBox(height: AppSpacing.lg),
                _NutritionHeroBar(
                  reviewCount: reviewCount,
                  readyCount: readyCount,
                  bodyFatCount: bodyFatCount,
                  onCreatePlan: () => _openPlanner(appState),
                  onOpenBodyFatCalculator: _openBodyFatCalculator,
                ),
                const SizedBox(height: AppSpacing.xl),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 330,
                        child: _NutritionAthleteRail(
                          profiles: profiles,
                          selectedIndex: _selectedProfileIndex,
                          onSelect: _selectProfile,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          children: [
                            _NutritionCoachWorkspace(
                              plan: selectedPlan,
                              profile: selectedProfile,
                              onCreatePlan: () => _openPlanner(appState),
                              onOpenBodyFatCalculator: _openBodyFatCalculator,
                              onSaveProfile: selectedPlan == null
                                  ? null
                                  : () => _saveProfileFromPlan(
                                      appState, selectedPlan),
                              onDecisionChanged: (decision) {
                                if (selectedPlan == null) return;
                                _applyDecision(
                                  appState: appState,
                                  athlete: selectedPlan.athlete,
                                  decision: decision,
                                );
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _NutritionPlanBoard(
                              filter: _filter,
                              plans: visible,
                              selectedIndex: _selectedIndex,
                              onFilterChanged: (value) => setState(() {
                                _filter = value;
                                _selectedIndex = 0;
                              }),
                              onSelect: _selectPlan,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  _NutritionAthleteRail(
                    profiles: profiles,
                    selectedIndex: _selectedProfileIndex,
                    onSelect: _selectProfile,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _NutritionCoachWorkspace(
                    plan: selectedPlan,
                    profile: selectedProfile,
                    onCreatePlan: () => _openPlanner(appState),
                    onOpenBodyFatCalculator: _openBodyFatCalculator,
                    onSaveProfile: selectedPlan == null
                        ? null
                        : () => _saveProfileFromPlan(appState, selectedPlan),
                    onDecisionChanged: (decision) {
                      if (selectedPlan == null) return;
                      _applyDecision(
                        appState: appState,
                        athlete: selectedPlan.athlete,
                        decision: decision,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _NutritionPlanBoard(
                    filter: _filter,
                    plans: visible,
                    selectedIndex: _selectedIndex,
                    onFilterChanged: (value) => setState(() {
                      _filter = value;
                      _selectedIndex = 0;
                    }),
                    onSelect: _selectPlan,
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'Coach support lane'),
                const SizedBox(height: AppSpacing.md),
                _NutritionSupportStrip(
                  onCreatePlan: () => _openPlanner(appState),
                  onOpenBodyFatCalculator: _openBodyFatCalculator,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }

  List<_MealPlanRecord> _filteredPlans() {
    return _plans.where((plan) {
      return switch (_filter) {
        'review' => plan.status == 'Needs review' || plan.status == 'Flagged',
        'ready' => plan.status == 'Healthy',
        'templates' => plan.status == 'Template ready',
        'season' => plan.phase == 'In season',
        _ => true,
      };
    }).toList();
  }

  NutritionAthleteProfileModel? _resolveSelectedProfile(
    List<NutritionAthleteProfileModel> profiles,
    _MealPlanRecord? selectedPlan,
  ) {
    if (profiles.isEmpty) return null;
    if (selectedPlan != null) {
      for (final profile in profiles) {
        if (profile.athlete == selectedPlan.athlete) {
          return profile;
        }
      }
    }
    return profiles[_selectedProfileIndex.clamp(0, profiles.length - 1)];
  }

  void _selectPlan(int index) {
    final visible = _filteredPlans();
    if (index >= visible.length) return;
    final athlete = visible[index].athlete;

    setState(() {
      _selectedIndex = index;
      final profileIndex =
          context.read<AppState>().nutritionProfiles.indexWhere(
                (profile) => profile.athlete == athlete,
              );
      if (profileIndex != -1) {
        _selectedProfileIndex = profileIndex;
      }
    });
  }

  void _selectProfile(int index) {
    final profiles = context.read<AppState>().nutritionProfiles;
    if (index >= profiles.length) return;
    final athlete = profiles[index].athlete;
    final visible = _filteredPlans();
    final planIndex = visible.indexWhere((plan) => plan.athlete == athlete);

    setState(() {
      _selectedProfileIndex = index;
      if (planIndex != -1) {
        _selectedIndex = planIndex;
      }
    });
  }

  void _openPlanner(AppState appState) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NutritionPlanScreen(
          baseUrl: appState.api.baseUrl,
          authToken: appState.token,
        ),
      ),
    );
  }

  Future<void> _openBodyFatCalculator() async {
    await Navigator.of(context).push<double>(
      MaterialPageRoute(
        builder: (_) => const BodyFatCalculatorScreen(
          initialSex: 'female',
          initialWeight: 122,
          initialHeight: 64,
        ),
      ),
    );
  }

  void _applyDecision({
    required AppState appState,
    required String athlete,
    required String decision,
  }) {
    appState.updateNutritionProfileDecision(
      athlete: athlete,
      decision: decision,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$athlete marked as $decision.')),
    );
  }

  void _saveProfileFromPlan(AppState appState, _MealPlanRecord plan) {
    NutritionAthleteProfileModel? existing;
    for (final item in appState.nutritionProfiles) {
      if (item.athlete == plan.athlete) {
        existing = item;
        break;
      }
    }
    appState.saveNutritionProfile(
      NutritionAthleteProfileModel(
        athlete: plan.athlete,
        classWeight: plan.target.replaceAll(' lbs', ''),
        bodyFat: existing?.bodyFat ?? 'Needed',
        hydration: existing?.hydration ?? 'Coach review',
        decision: existing?.decision ??
            (plan.status == 'Healthy' ? 'Approved' : 'Coach review'),
        focus: existing?.focus ?? plan.summary,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${plan.athlete} saved to nutrition profiles.')),
    );
  }
}

class _NutritionHeroBar extends StatelessWidget {
  const _NutritionHeroBar({
    required this.reviewCount,
    required this.readyCount,
    required this.bodyFatCount,
    required this.onCreatePlan,
    required this.onOpenBodyFatCalculator,
  });

  final int reviewCount;
  final int readyCount;
  final int bodyFatCount;
  final VoidCallback onCreatePlan;
  final VoidCallback onOpenBodyFatCalculator;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF111C2D),
            Color(0xFF0C1420),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 980;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _NutritionPill(
                  label: 'Coach nutrition desk', color: Color(0xFF38BDF8)),
              const SizedBox(height: AppSpacing.md),
              Text(
                  'Keep cuts safe. Keep families clear. Keep coaches in control.',
                  style: AppTextStyles.pageTitle.copyWith(fontSize: 30)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'This should feel like one clean workflow: pick the athlete, review risk, adjust the plan, and send a family-ready version without digging through clutter.',
                style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.82)),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ElevatedButton.icon(
                    onPressed: onCreatePlan,
                    icon: const Icon(Icons.add_task_rounded),
                    label: const Text('Build plan'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onOpenBodyFatCalculator,
                    icon: const Icon(Icons.calculate_outlined),
                    label: const Text('Body fat calculator'),
                  ),
                ],
              ),
            ],
          );

          final metrics = Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              SizedBox(
                width: 180,
                child: _NutritionMetric(
                  label: 'Needs review',
                  value: '$reviewCount',
                  note: 'coach decisions pending',
                  color: AppColors.warning,
                ),
              ),
              SizedBox(
                width: 180,
                child: _NutritionMetric(
                  label: 'Ready to share',
                  value: '$readyCount',
                  note: 'safe family handoffs',
                  color: AppColors.success,
                ),
              ),
              SizedBox(
                width: 180,
                child: _NutritionMetric(
                  label: 'Body fat on file',
                  value: '$bodyFatCount',
                  note: 'athletes with fresh checks',
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: AppSpacing.lg),
                metrics,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: copy),
              const SizedBox(width: AppSpacing.xl),
              Expanded(flex: 4, child: metrics),
            ],
          );
        },
      ),
    );
  }
}

class _NutritionAthleteRail extends StatelessWidget {
  const _NutritionAthleteRail({
    required this.profiles,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<NutritionAthleteProfileModel> profiles;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Athletes',
              style: AppTextStyles.cardTitle.copyWith(fontSize: 22)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Select an athlete first. Everything else should get easier from there.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.lg),
          ...List.generate(profiles.length, (index) {
            final profile = profiles[index];
            final selected = index == selectedIndex;
            final accent = switch (profile.decision) {
              'Approved' => AppColors.success,
              'Blocked' => AppColors.danger,
              _ => AppColors.warning,
            };
            return Padding(
              padding: EdgeInsets.only(
                  bottom: index == profiles.length - 1 ? 0 : AppSpacing.sm),
              child: InkWell(
                onTap: () => onSelect(index),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.surfaceElevated
                        : AppColors.surface.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected
                          ? accent.withValues(alpha: 0.45)
                          : AppColors.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Text(profile.athlete,
                                  style: AppTextStyles.bodyStrong)),
                          _NutritionPill(
                              label: profile.decision, color: accent),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text('${profile.classWeight} lbs • ${profile.bodyFat}',
                          style: AppTextStyles.caption),
                      const SizedBox(height: AppSpacing.sm),
                      Text(profile.focus, style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _NutritionCoachWorkspace extends StatelessWidget {
  const _NutritionCoachWorkspace({
    required this.plan,
    required this.profile,
    required this.onCreatePlan,
    required this.onOpenBodyFatCalculator,
    required this.onSaveProfile,
    required this.onDecisionChanged,
  });

  final _MealPlanRecord? plan;
  final NutritionAthleteProfileModel? profile;
  final VoidCallback onCreatePlan;
  final VoidCallback onOpenBodyFatCalculator;
  final VoidCallback? onSaveProfile;
  final ValueChanged<String> onDecisionChanged;

  @override
  Widget build(BuildContext context) {
    if (plan == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
            'Select an athlete or nutrition plan to open the coach workspace.',
            style: AppTextStyles.body),
      );
    }

    final effectiveProfile = profile ??
        NutritionAthleteProfileModel(
          athlete: plan!.athlete,
          classWeight: plan!.target.replaceAll(' lbs', ''),
          bodyFat: 'Needed',
          hydration: 'Coach review',
          decision: plan!.status == 'Healthy' ? 'Approved' : 'Coach review',
          focus: plan!.summary,
        );

    final decisionColor = switch (effectiveProfile.decision) {
      'Approved' => AppColors.success,
      'Blocked' => AppColors.danger,
      _ => AppColors.warning,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan!.athlete, style: AppTextStyles.sectionTitle),
                    const SizedBox(height: AppSpacing.xxs),
                    Text('${plan!.planName} • ${plan!.target} • ${plan!.phase}',
                        style: AppTextStyles.body),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _NutritionPill(
                            label: effectiveProfile.decision,
                            color: decisionColor),
                        _NutritionPill(
                            label: plan!.familyStatus,
                            color: const Color(0xFF14B8A6)),
                        _NutritionPill(
                            label: plan!.compliance,
                            color: const Color(0xFF8B5CF6)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Today', style: AppTextStyles.caption),
                    const SizedBox(height: AppSpacing.xs),
                    Text(plan!.nextStep,
                        style: AppTextStyles.bodyStrong
                            .copyWith(color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(plan!.summary,
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ElevatedButton.icon(
                onPressed: () => onDecisionChanged('Approved'),
                icon: const Icon(Icons.verified_rounded),
                label: const Text('Approve'),
              ),
              OutlinedButton.icon(
                onPressed: () => onDecisionChanged('Coach review'),
                icon: const Icon(Icons.pause_circle_outline_rounded),
                label: const Text('Hold'),
              ),
              OutlinedButton.icon(
                onPressed: () => onDecisionChanged('Blocked'),
                icon: const Icon(Icons.block_rounded),
                label: const Text('Block'),
              ),
              if (onSaveProfile != null)
                OutlinedButton.icon(
                  onPressed: onSaveProfile,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save athlete'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 860;
              final children = [
                _WorkspaceCard(
                  title: 'Body fat + hydration',
                  icon: Icons.monitor_weight_outlined,
                  body:
                      'Current check: ${effectiveProfile.bodyFat}. Hydration status: ${effectiveProfile.hydration}.',
                ),
                _WorkspaceCard(
                  title: 'Family handoff',
                  icon: Icons.family_restroom_outlined,
                  body:
                      'Home message status: ${plan!.familyStatus}. Use replacements and simple meal wording before sharing.',
                ),
                _WorkspaceCard(
                  title: 'Coach notes',
                  icon: Icons.fact_check_outlined,
                  body: plan!.notes.first,
                ),
              ];

              if (stacked) {
                return Column(
                  children: [
                    for (var i = 0; i < children.length; i++) ...[
                      children[i],
                      if (i != children.length - 1)
                        const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    Expanded(child: children[i]),
                    if (i != children.length - 1)
                      const SizedBox(width: AppSpacing.md),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ElevatedButton.icon(
                onPressed: onCreatePlan,
                icon: const Icon(Icons.auto_fix_high_rounded),
                label: const Text('Open planner'),
              ),
              OutlinedButton.icon(
                onPressed: onOpenBodyFatCalculator,
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('Run body fat check'),
              ),
              OutlinedButton.icon(
                onPressed: onCreatePlan,
                icon: const Icon(Icons.share_outlined),
                label: const Text('Build family summary'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NutritionPlanBoard extends StatelessWidget {
  const _NutritionPlanBoard({
    required this.filter,
    required this.plans,
    required this.selectedIndex,
    required this.onFilterChanged,
    required this.onSelect,
  });

  final String filter;
  final List<_MealPlanRecord> plans;
  final int selectedIndex;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Plan queue',
              style: AppTextStyles.cardTitle.copyWith(fontSize: 22)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Use the queue for quick triage. Open the workspace above to make the decision.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final chip in const [
                  ('all', 'All'),
                  ('review', 'Review'),
                  ('ready', 'Ready'),
                  ('templates', 'Templates'),
                  ('season', 'In season'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: ChoiceChip(
                      label: Text(chip.$2),
                      selected: filter == chip.$1,
                      onSelected: (_) => onFilterChanged(chip.$1),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (plans.isEmpty)
            const _NutritionEmptyState()
          else
            ...List.generate(plans.length, (index) {
              final plan = plans[index];
              return Padding(
                padding: EdgeInsets.only(
                    bottom: index == plans.length - 1 ? 0 : AppSpacing.sm),
                child: _PlanRow(
                  plan: plan,
                  selected: index == selectedIndex,
                  onTap: () => onSelect(index),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _NutritionSupportStrip extends StatelessWidget {
  const _NutritionSupportStrip({
    required this.onCreatePlan,
    required this.onOpenBodyFatCalculator,
  });

  final VoidCallback onCreatePlan;
  final VoidCallback onOpenBodyFatCalculator;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980 ? 3 : 1;
        final cards = [
          _SupportCard(
            title: 'Body fat guardrails',
            body:
                'Keep the calculator one click away and tie low body-fat calls to coach review instead of guesswork.',
            actionLabel: 'Open calculator',
            onTap: onOpenBodyFatCalculator,
            accent: const Color(0xFF8B5CF6),
            icon: Icons.calculate_outlined,
          ),
          _SupportCard(
            title: 'Family-ready plans',
            body:
                'Every athlete plan should turn into a cleaner home version with replacements and tournament-week meals.',
            actionLabel: 'Open planner',
            onTap: onCreatePlan,
            accent: const Color(0xFF14B8A6),
            icon: Icons.family_restroom_outlined,
          ),
          _SupportCard(
            title: 'Safety first',
            body:
                'Use holds and blocks fast when the cut is too aggressive, hydration is slipping, or physician clearance matters.',
            actionLabel: 'Review athlete',
            onTap: onCreatePlan,
            accent: AppColors.warning,
            icon: Icons.health_and_safety_outlined,
          ),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: columns == 1 ? 2.2 : 1.35,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onTap,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onTap;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTextStyles.bodyStrong),
          const SizedBox(height: AppSpacing.sm),
          Text(body, style: AppTextStyles.body),
          const Spacer(),
          OutlinedButton(onPressed: onTap, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _WorkspaceCard extends StatelessWidget {
  const _WorkspaceCard({
    required this.title,
    required this.icon,
    required this.body,
  });

  final String title;
  final IconData icon;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF38BDF8)),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: AppTextStyles.bodyStrong),
          const SizedBox(height: AppSpacing.xs),
          Text(body, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final _MealPlanRecord plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = switch (plan.status) {
      'Flagged' => AppColors.danger,
      'Needs review' => AppColors.warning,
      'Healthy' => AppColors.success,
      _ => const Color(0xFF38BDF8),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.surfaceElevated
              : AppColors.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color:
                  selected ? accent.withValues(alpha: 0.45) : AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text(plan.athlete,
                              style: AppTextStyles.bodyStrong)),
                      _NutritionPill(label: plan.status, color: accent),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text('${plan.planName} • ${plan.target} • ${plan.phase}',
                      style: AppTextStyles.caption),
                  const SizedBox(height: AppSpacing.sm),
                  Text(plan.nextStep, style: AppTextStyles.body),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _NutritionMetric extends StatelessWidget {
  const _NutritionMetric({
    required this.label,
    required this.value,
    required this.note,
    required this.color,
  });

  final String label;
  final String value;
  final String note;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTextStyles.cardTitle.copyWith(color: color)),
          const SizedBox(height: AppSpacing.xxs),
          Text(note, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _NutritionPill extends StatelessWidget {
  const _NutritionPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      ),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary)),
    );
  }
}

class _NutritionEmptyState extends StatelessWidget {
  const _NutritionEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text('No nutrition plans match this filter right now.',
          style: AppTextStyles.body),
    );
  }
}

class _MealPlanRecord {
  const _MealPlanRecord({
    required this.athlete,
    required this.phase,
    required this.status,
    required this.target,
    required this.planName,
    required this.summary,
    required this.notes,
    required this.nextStep,
    required this.familyStatus,
    required this.compliance,
  });

  final String athlete;
  final String phase;
  final String status;
  final String target;
  final String planName;
  final String summary;
  final List<String> notes;
  final String nextStep;
  final String familyStatus;
  final String compliance;
}
