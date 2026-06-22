import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/nutrition_models.dart';
import '../../services/browser_link_service.dart';
import '../../services/nutrition_api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/subpage_header.dart';
import '../weights/body_fat_calculator_screen.dart';

class NutritionPlanScreen extends StatefulWidget {
  const NutritionPlanScreen({
    super.key,
    required this.baseUrl,
    this.authToken,
  });

  final String baseUrl;
  final String? authToken;

  @override
  State<NutritionPlanScreen> createState() => _NutritionPlanScreenState();
}

class _NutritionPlanScreenState extends State<NutritionPlanScreen> {
  late final NutritionApiService _api;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Avery Hall');
  final _ageController = TextEditingController(text: '16');
  final _heightController = TextEditingController(text: '64');
  final _weightController = TextEditingController(text: '122');
  final _bodyFatController = TextEditingController(text: '14.2');
  final _targetWeightController = TextEditingController(text: '120');
  final _daysController = TextEditingController(text: '7');
  final _allergiesController = TextEditingController();
  final _dislikesController = TextEditingController(text: 'sardines');
  final _dietTagsController =
      TextEditingController(text: 'high_protein, hydration');
  final _budgetNotesController = TextEditingController(
      text: 'Family needs simple prep and school-night friendly meals.');

  String _sex = 'female';
  String _goal = 'cut';
  String _activityLevel = 'high';
  String _trainingPhase = 'inseason';
  String _practiceWindow = 'afternoon';
  String _mealTemplate = 'family';
  String _budgetLevel = 'medium';
  String _plannerMode = 'safe_cut';
  bool _parentVisible = true;
  bool _includeChecklist = true;

  bool _isLoading = false;
  String? _error;
  NutritionPlanResponseModel? _plan;

  @override
  void initState() {
    super.initState();
    _api = NutritionApiService(
      baseUrl: widget.baseUrl,
      authToken: widget.authToken,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _bodyFatController.dispose();
    _targetWeightController.dispose();
    _daysController.dispose();
    _allergiesController.dispose();
    _dislikesController.dispose();
    _dietTagsController.dispose();
    _budgetNotesController.dispose();
    super.dispose();
  }

  double get _currentWeight =>
      double.tryParse(_weightController.text.trim()) ?? 0;
  double get _targetWeight => _goal == 'cut'
      ? (double.tryParse(_targetWeightController.text.trim()) ?? _currentWeight)
      : _currentWeight;
  int get _daysToWeighIn => int.tryParse(_daysController.text.trim()) ?? 0;
  double get _weightDelta => (_currentWeight - _targetWeight).clamp(0, 999);
  double get _weeklyLossRate {
    if (_daysToWeighIn <= 0) return _weightDelta;
    return _weightDelta / (_daysToWeighIn / 7);
  }

  int get _riskScore {
    var score = 18;
    if (_goal == 'cut') {
      score += (_weightDelta * 7).round();
      if (_daysToWeighIn <= 7) score += 18;
      if (_daysToWeighIn <= 3) score += 12;
      if (_weeklyLossRate > 1.5) score += 24;
      if (_weeklyLossRate > 2.0) score += 14;
    }
    if (_plannerMode == 'tournament_week') score += 10;
    if (_plannerMode == 'two_day_recovery') score += 12;
    if (_activityLevel == 'elite') score += 8;
    if (_splitList(_allergiesController.text).isNotEmpty) score += 4;
    return score.clamp(8, 96);
  }

  String get _riskLabel {
    if (_riskScore >= 75) return 'High risk';
    if (_riskScore >= 46) return 'Needs review';
    return 'On track';
  }

  Color get _riskColor {
    if (_riskScore >= 75) return AppColors.danger;
    if (_riskScore >= 46) return AppColors.warning;
    return AppColors.success;
  }

  Future<void> _generatePlan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _api.createPlan(
        payload: {
          'athlete_id': 'preview-athlete',
          'name': _nameController.text.trim(),
          'age': int.parse(_ageController.text.trim()),
          'sex': _sex,
          'height_in': double.parse(_heightController.text.trim()),
          'weight_lbs': double.parse(_weightController.text.trim()),
          'target_weight_lbs': _goal == 'cut'
              ? double.parse(_targetWeightController.text.trim())
              : null,
          'body_fat_percent': double.tryParse(_bodyFatController.text.trim()),
          'goal': _goal,
          'activity_level': _activityLevel,
          'training_phase': _trainingPhase,
          'practice_window': _practiceWindow,
          'days_to_weigh_in': int.parse(_daysController.text.trim()),
          'matches_this_week': _plannerMode == 'tournament_week' ? 3 : 2,
          'allergies': _splitList(_allergiesController.text),
          'dislikes': _splitList(_dislikesController.text),
          'excluded_ingredients': const <String>[],
          'diet_tags': [
            ..._splitList(_dietTagsController.text),
            _plannerMode,
          ],
          'meal_template': _mealTemplate,
          'meals_per_day': _plannerMode == 'two_day_recovery' ? 5 : 4,
          'snacks_per_day': _plannerMode == 'growth' ? 2 : 1,
          'budget_level': _budgetLevel,
          'include_provider_plan': false,
        },
      );

      if (!mounted) return;
      setState(() => _plan = result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<String> _splitList(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    final safetyItems = _buildSafetyItems(plan);
    final coachActions = _buildCoachActions(plan);
    final athleteChecklist = _buildAthleteChecklist(plan);
    final parentSummary = _buildParentSummary(plan);
    final familyStoreItems = _buildFamilyStoreItems(plan);
    final replacementIdeas = _buildReplacementIdeas(plan);
    final tournamentDayPlan = _buildTournamentDayPlan(plan);
    final refuelPlan = _buildPostWeighInRefuel(plan);
    final hydrationTimeline = _buildHydrationTimeline(plan);
    final groceryEstimate = _estimateWeeklyGroceryTotal(plan);
    final weighInMode = _weighInModeLabel(_daysToWeighIn);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SubpageHeader(
            title: 'Nutrition Planner',
            subtitle:
                'Elite wrestling nutrition should feel coach-controlled, safety-aware, and clear enough for families to actually follow.',
          ),
          const SizedBox(height: AppSpacing.lg),
          _PlannerHero(
            plannerMode: _plannerMode,
            riskLabel: _riskLabel,
            riskColor: _riskColor,
            riskScore: _riskScore,
            weightDelta: _weightDelta,
            daysToWeighIn: _daysToWeighIn,
            weeklyLossRate: _weeklyLossRate,
          ),
          const SizedBox(height: AppSpacing.lg),
          _ModeBar(
            value: _plannerMode,
            onChanged: (value) => setState(() => _plannerMode = value),
          ),
          const SizedBox(height: AppSpacing.lg),
          _PlannerDecisionStrip(
            bodyFatText: _bodyFatController.text.trim(),
            riskLabel: _riskLabel,
            riskColor: _riskColor,
            weeklyLossRate: _weeklyLossRate,
            daysToWeighIn: _daysToWeighIn,
          ),
          const SizedBox(height: AppSpacing.lg),
          _PlanReadinessRow(
            plannerMode: _plannerMode,
            parentVisible: _parentVisible,
            includeChecklist: _includeChecklist,
            bodyFatText: _bodyFatController.text.trim(),
            budgetLevel: _budgetLevel,
          ),
          const SizedBox(height: AppSpacing.lg),
          _PlannerSnapshotRow(
            athleteName: _nameController.text.trim().isEmpty
                ? 'Athlete not set'
                : _nameController.text.trim(),
            goal: _goal,
            trainingPhase: _trainingPhase,
            currentWeight: _currentWeight,
            targetWeight: _targetWeight,
            daysToWeighIn: _daysToWeighIn,
            parentVisible: _parentVisible,
            includeChecklist: _includeChecklist,
          ),
          const SizedBox(height: AppSpacing.xl),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1180;
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _PlannerFormCard(
                        formKey: _formKey,
                        nameController: _nameController,
                        ageController: _ageController,
                        heightController: _heightController,
                        weightController: _weightController,
                        bodyFatController: _bodyFatController,
                        targetWeightController: _targetWeightController,
                        daysController: _daysController,
                        allergiesController: _allergiesController,
                        dislikesController: _dislikesController,
                        dietTagsController: _dietTagsController,
                        budgetNotesController: _budgetNotesController,
                        sex: _sex,
                        goal: _goal,
                        activityLevel: _activityLevel,
                        trainingPhase: _trainingPhase,
                        practiceWindow: _practiceWindow,
                        mealTemplate: _mealTemplate,
                        budgetLevel: _budgetLevel,
                        parentVisible: _parentVisible,
                        includeChecklist: _includeChecklist,
                        isLoading: _isLoading,
                        onGenerate: _generatePlan,
                        onOpenBodyFatCalculator: _openBodyFatCalculator,
                        onParentVisibleChanged: (value) =>
                            setState(() => _parentVisible = value),
                        onIncludeChecklistChanged: (value) =>
                            setState(() => _includeChecklist = value),
                        onSexChanged: (value) => setState(() => _sex = value!),
                        onGoalChanged: (value) =>
                            setState(() => _goal = value!),
                        onActivityLevelChanged: (value) =>
                            setState(() => _activityLevel = value!),
                        onTrainingPhaseChanged: (value) =>
                            setState(() => _trainingPhase = value!),
                        onPracticeWindowChanged: (value) =>
                            setState(() => _practiceWindow = value!),
                        onMealTemplateChanged: (value) =>
                            setState(() => _mealTemplate = value!),
                        onBudgetLevelChanged: (value) =>
                            setState(() => _budgetLevel = value!),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _SafetyScoreCard(
                            riskScore: _riskScore,
                            riskLabel: _riskLabel,
                            riskColor: _riskColor,
                            items: safetyItems,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _ActionPanel(
                            title: 'Coach next actions',
                            icon: Icons.fact_check_outlined,
                            color: const Color(0xFF38BDF8),
                            items: coachActions,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _ActionPanel(
                            title: 'Athlete checklist',
                            icon: Icons.checklist_rounded,
                            color: const Color(0xFF14B8A6),
                            items: athleteChecklist,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  _PlannerFormCard(
                    formKey: _formKey,
                    nameController: _nameController,
                    ageController: _ageController,
                    heightController: _heightController,
                    weightController: _weightController,
                    bodyFatController: _bodyFatController,
                    targetWeightController: _targetWeightController,
                    daysController: _daysController,
                    allergiesController: _allergiesController,
                    dislikesController: _dislikesController,
                    dietTagsController: _dietTagsController,
                    budgetNotesController: _budgetNotesController,
                    sex: _sex,
                    goal: _goal,
                    activityLevel: _activityLevel,
                    trainingPhase: _trainingPhase,
                    practiceWindow: _practiceWindow,
                    mealTemplate: _mealTemplate,
                    budgetLevel: _budgetLevel,
                    parentVisible: _parentVisible,
                    includeChecklist: _includeChecklist,
                    isLoading: _isLoading,
                    onGenerate: _generatePlan,
                    onOpenBodyFatCalculator: _openBodyFatCalculator,
                    onParentVisibleChanged: (value) =>
                        setState(() => _parentVisible = value),
                    onIncludeChecklistChanged: (value) =>
                        setState(() => _includeChecklist = value),
                    onSexChanged: (value) => setState(() => _sex = value!),
                    onGoalChanged: (value) => setState(() => _goal = value!),
                    onActivityLevelChanged: (value) =>
                        setState(() => _activityLevel = value!),
                    onTrainingPhaseChanged: (value) =>
                        setState(() => _trainingPhase = value!),
                    onPracticeWindowChanged: (value) =>
                        setState(() => _practiceWindow = value!),
                    onMealTemplateChanged: (value) =>
                        setState(() => _mealTemplate = value!),
                    onBudgetLevelChanged: (value) =>
                        setState(() => _budgetLevel = value!),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SafetyScoreCard(
                    riskScore: _riskScore,
                    riskLabel: _riskLabel,
                    riskColor: _riskColor,
                    items: safetyItems,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_error != null) _MessageCard(message: _error!, isError: true),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (plan != null) ...[
            _OutputHeader(
              mode: _plannerMode,
              plan: plan,
              parentVisible: _parentVisible,
            ),
            const SizedBox(height: AppSpacing.lg),
            _PremiumMetricRow(
              macros: plan.macros,
              hydrationPlan: plan.hydrationPlan,
              warnings: plan.warnings.length,
            ),
            const SizedBox(height: AppSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1120;
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: _WeekPlanCard(plan: plan)),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            _HydrationCard(
                              plan: plan,
                              timeline: hydrationTimeline,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _WarningsCard(plan: plan),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    _WeekPlanCard(plan: plan),
                    const SizedBox(height: AppSpacing.lg),
                    _HydrationCard(
                      plan: plan,
                      timeline: hydrationTimeline,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _WarningsCard(plan: plan),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1120;
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _ParentSummaryCard(
                          items: parentSummary,
                          onOpenHandoff: () => _openParentHandoff(
                            plan: plan,
                            parentSummary: parentSummary,
                            familyStoreItems: familyStoreItems,
                            replacementIdeas: replacementIdeas,
                            tournamentDayPlan: tournamentDayPlan,
                            refuelPlan: refuelPlan,
                            hydrationTimeline: hydrationTimeline,
                            weeklyEstimate: groceryEstimate,
                            weighInMode: weighInMode,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          children: [
                            _FamilySupportCard(
                              storeItems: familyStoreItems,
                              replacementIdeas: replacementIdeas,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _TournamentDayCard(
                              items: tournamentDayPlan,
                              title: 'Tournament day plan',
                              icon: Icons.flag_circle_outlined,
                              color: const Color(0xFF38BDF8),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _TournamentDayCard(
                              items: refuelPlan,
                              title: 'Post weigh-in refuel',
                              icon: Icons.bolt_rounded,
                              color: const Color(0xFF14B8A6),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _GroceryCard(
                              plan: plan,
                              weeklyEstimate: groceryEstimate,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    _ParentSummaryCard(
                      items: parentSummary,
                      onOpenHandoff: () => _openParentHandoff(
                        plan: plan,
                        parentSummary: parentSummary,
                        familyStoreItems: familyStoreItems,
                        replacementIdeas: replacementIdeas,
                        tournamentDayPlan: tournamentDayPlan,
                        refuelPlan: refuelPlan,
                        hydrationTimeline: hydrationTimeline,
                        weeklyEstimate: groceryEstimate,
                        weighInMode: weighInMode,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _FamilySupportCard(
                      storeItems: familyStoreItems,
                      replacementIdeas: replacementIdeas,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _TournamentDayCard(
                      items: tournamentDayPlan,
                      title: 'Tournament day plan',
                      icon: Icons.flag_circle_outlined,
                      color: const Color(0xFF38BDF8),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _TournamentDayCard(
                      items: refuelPlan,
                      title: 'Post weigh-in refuel',
                      icon: Icons.bolt_rounded,
                      color: const Color(0xFF14B8A6),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _GroceryCard(
                      plan: plan,
                      weeklyEstimate: groceryEstimate,
                    ),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  List<String> _buildSafetyItems(NutritionPlanResponseModel? plan) {
    final items = <String>[
      'Weight class delta is ${_weightDelta.toStringAsFixed(1)} lbs over $_daysToWeighIn days.',
      if (_bodyFatController.text.trim().isNotEmpty)
        'Body fat estimate is ${_bodyFatController.text.trim()}% and should stay above the safe minimum for the current cut.',
      if (_weeklyLossRate > 1.5)
        'Projected weekly cut rate is ${_weeklyLossRate.toStringAsFixed(1)} lbs per week and should be coach-reviewed.',
      if (_plannerMode == 'tournament_week')
        'Tournament-week mode keeps fuel timing tighter before first whistle.',
      if (_splitList(_allergiesController.text).isNotEmpty)
        'Allergy list is active and should be reflected in every family-facing meal swap.',
    ];
    if (plan != null) {
      items.addAll(
        plan.warnings.take(2).map((warning) => warning.message),
      );
    }
    return items.take(4).toList();
  }

  List<String> _buildCoachActions(NutritionPlanResponseModel? plan) {
    final base = <String>[
      'Approve or override the plan before the next weigh-in if the athlete stays in cut mode.',
      'Review hydration and recovery window with the athlete after practice.',
      'Confirm parent-visible meal prep notes are simple enough for school nights.',
    ];
    if (plan?.warnings.isNotEmpty == true) {
      base.insert(0,
          'Resolve ${plan!.warnings.length} nutrition warning(s) before locking this week.');
    }
    return base;
  }

  List<String> _buildAthleteChecklist(NutritionPlanResponseModel? plan) {
    final waterTarget =
        plan?.hydrationPlan['daily_water_oz_target']?.toString() ?? '--';
    return [
      'Hit $waterTarget oz of water before the end of the day.',
      'Eat the first recovery meal within 45 minutes after practice.',
      if (_includeChecklist) 'Log morning weight and energy before school.',
      'Use a planned snack instead of guessing when hunger spikes late.',
    ];
  }

  List<String> _buildParentSummary(NutritionPlanResponseModel? plan) {
    final note = _budgetNotesController.text.trim();
    return [
      'Prep two easy repeat meals for the week so compliance stays high.',
      'Keep hydration options visible before and after practice.',
      if (note.isNotEmpty) note,
      if (_parentVisible)
        'Share grocery list and meal swaps with the family before tournament travel.',
    ];
  }

  List<String> _buildFamilyStoreItems(NutritionPlanResponseModel? plan) {
    final items = <String>[
      'Water bottles and electrolyte packets for practice and travel',
      'Greek yogurt, oats, fruit, and easy protein snacks',
      'Meal-prep containers for school-night portions',
    ];
    if (plan != null && _plannerMode == 'tournament_week') {
      items.add(
          'Tournament-week refuel items like bagels, bananas, and quick carbs');
    }
    if (_goal == 'cut') {
      items.add(
          'Simple scale-ready breakfast options to avoid last-minute guessing');
    }
    return items;
  }

  List<String> _buildReplacementIdeas(NutritionPlanResponseModel? plan) {
    final foods = <String>{
      for (final day in plan?.weeklyPlan ?? const <NutritionDayPlan>[])
        for (final meal in day.meals)
          for (final food in meal.foods) food.toLowerCase(),
    };
    final replacements = <String>[];
    if (foods.any((food) => food.contains('chicken'))) {
      replacements.add(
          'Swap chicken with turkey, lean beef, or tuna packs when needed.');
    }
    if (foods.any((food) => food.contains('rice'))) {
      replacements.add(
          'Swap rice with potatoes, wraps, or pasta when travel changes the plan.');
    }
    if (foods.any((food) => food.contains('egg'))) {
      replacements.add(
          'Swap eggs with Greek yogurt, cottage cheese, or a protein shake.');
    }
    if (replacements.isEmpty) {
      replacements.addAll([
        'Swap a missed meal with a simple protein + carb combo instead of skipping it.',
        'Use shelf-stable snacks on travel days so the plan does not fall apart.',
      ]);
    }
    return replacements.take(4).toList();
  }

  List<String> _buildTournamentDayPlan(NutritionPlanResponseModel? plan) {
    final sameDay = _isSameDayWeighIn(_daysToWeighIn);
    final items = <String>[
      if (sameDay)
        'Same-day weigh-in plan: keep the first meal light, familiar, and easy to digest before stepping on the scale.'
      else
        'Night-before weigh-in plan: start the morning with a steady breakfast instead of chasing food late.',
      'Keep a fast carb + hydration option packed for warm-up and bracket delays.',
      'Use the family support kit to stay on plan between matches.',
      if (sameDay)
        'Wait until after weigh-ins to push the bigger carb refill so the athlete feels sharp instead of heavy.'
      else
        'Use the morning to top off energy, not to scramble for last-minute food choices.',
    ];
    if (_plannerMode == 'tournament_week' || _daysToWeighIn <= 2) {
      items.insert(1,
          'Treat today like a tournament day: simple foods, no heavy meals, no experiments.');
    }
    if (_goal == 'cut') {
      items.add(
          'Do not celebrate making weight with a huge meal; refuel in steps so the athlete feels sharp.');
    }
    if (plan?.hydrationPlan['electrolyte_note'] != null) {
      items.add(plan!.hydrationPlan['electrolyte_note'].toString());
    }
    return items.take(6).toList();
  }

  List<String> _buildPostWeighInRefuel(NutritionPlanResponseModel? plan) {
    final items = <String>[
      'Refuel right away with fluid, easy carbs, and a small protein source.',
      'Use simple foods the athlete already tolerates well before matches.',
      'Bring a second small refuel option for the middle of the tournament day.',
    ];
    if (_goal == 'cut') {
      items.add(
          'Build back up in layers instead of jumping straight to heavy greasy food.');
    }
    if (plan?.weeklyPlan.isNotEmpty == true) {
      final mealName = plan!.weeklyPlan.first.meals.isNotEmpty
          ? plan.weeklyPlan.first.meals.first.name
          : null;
      if (mealName != null) {
        items.add(
            'Use "$mealName" style foods as the first refuel model when possible.');
      }
    }
    return items.take(5).toList();
  }

  List<String> _buildHydrationTimeline(NutritionPlanResponseModel? plan) {
    final target = '${plan?.hydrationPlan['daily_water_oz_target'] ?? '--'} oz';
    final practice = '${plan?.hydrationPlan['during_practice_oz'] ?? '--'} oz';
    final post = '${plan?.hydrationPlan['post_practice_oz'] ?? '--'} oz';
    final sameDay = _isSameDayWeighIn(_daysToWeighIn);

    return [
      'Morning: start the day with fluids early so the athlete is not trying to catch up late.',
      'School day: keep water moving steadily toward the $target target instead of chugging at once.',
      'Practice block: plan around about $practice during training when allowed.',
      'After practice: recover with about $post and keep the refill simple.',
      if (sameDay)
        'Tournament morning: stay controlled before weigh-ins, then rebuild fluids in steps right after.'
      else
        'Night-before weigh-in: finish the evening on plan so the athlete wakes up ready to fuel, not recover from dehydration.',
    ];
  }

  Future<void> _openBodyFatCalculator() async {
    final result = await Navigator.of(context).push<double>(
      MaterialPageRoute(
        builder: (_) => BodyFatCalculatorScreen(
          initialSex: _sex,
          initialWeight: _currentWeight,
          initialHeight: double.tryParse(_heightController.text.trim()),
          initialAge: int.tryParse(_ageController.text.trim()),
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _bodyFatController.text = result.toStringAsFixed(1));
  }

  Future<void> _openParentHandoff({
    required NutritionPlanResponseModel plan,
    required List<String> parentSummary,
    required List<String> familyStoreItems,
    required List<String> replacementIdeas,
    required List<String> tournamentDayPlan,
    required List<String> refuelPlan,
    required List<String> hydrationTimeline,
    required double weeklyEstimate,
    required String weighInMode,
  }) async {
    final handoffText = [
      'Pin IQ Parent Handoff',
      _nameController.text.trim(),
      '',
      'Weigh-in mode: $weighInMode',
      'Weekly grocery estimate: ~\$${weeklyEstimate.toStringAsFixed(2)}',
      '',
      'Summary',
      ...parentSummary.map((item) => '- $item'),
      '',
      'Store list',
      ...familyStoreItems.map((item) => '- $item'),
      '',
      'Replacement ideas',
      ...replacementIdeas.map((item) => '- $item'),
      '',
      'Tournament day',
      ...tournamentDayPlan.map((item) => '- $item'),
      '',
      'Post weigh-in refuel',
      ...refuelPlan.map((item) => '- $item'),
      '',
      'Hydration timeline',
      ...hydrationTimeline.map((item) => '- $item'),
      '',
      'Hydration target: ${plan.hydrationPlan['daily_water_oz_target'] ?? '--'} oz',
    ].join('\n');

    final messenger = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      builder: (context) => _ParentHandoffDialog(
        athleteName: _nameController.text.trim(),
        parentSummary: parentSummary,
        familyStoreItems: familyStoreItems,
        replacementIdeas: replacementIdeas,
        tournamentDayPlan: tournamentDayPlan,
        refuelPlan: refuelPlan,
        hydrationTimeline: hydrationTimeline,
        hydrationTarget:
            '${plan.hydrationPlan['daily_water_oz_target'] ?? '--'} oz',
        weeklyEstimate: weeklyEstimate,
        weighInMode: weighInMode,
        onCopy: () async {
          await Clipboard.setData(ClipboardData(text: handoffText));
          if (!context.mounted) return;
          Navigator.of(context).pop();
          messenger.showSnackBar(
            const SnackBar(content: Text('Parent handoff copied.')),
          );
        },
      ),
    );
  }

  bool _isSameDayWeighIn(int daysToWeighIn) => daysToWeighIn <= 0;
}

class _PlannerDecisionStrip extends StatelessWidget {
  const _PlannerDecisionStrip({
    required this.bodyFatText,
    required this.riskLabel,
    required this.riskColor,
    required this.weeklyLossRate,
    required this.daysToWeighIn,
  });

  final String bodyFatText;
  final String riskLabel;
  final Color riskColor;
  final double weeklyLossRate;
  final int daysToWeighIn;

  @override
  Widget build(BuildContext context) {
    final items = [
      _DecisionPoint(
        title: 'Body fat input',
        value: bodyFatText.isEmpty ? 'Needed' : '$bodyFatText%',
        note: bodyFatText.isEmpty
            ? 'Use the calculator before approving a harder cut.'
            : 'Body composition should set the safe floor for this plan.',
        color: const Color(0xFF8B5CF6),
      ),
      _DecisionPoint(
        title: 'Projected rate',
        value: '${weeklyLossRate.toStringAsFixed(1)} lbs/week',
        note:
            'Anything aggressive should trigger a coach check before the plan goes live.',
        color: riskColor,
      ),
      _DecisionPoint(
        title: 'Decision window',
        value: '$daysToWeighIn days',
        note:
            'Shorter timelines change whether you fuel, hold, recover, or shut the cut down.',
        color: const Color(0xFF38BDF8),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980 ? 3 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: columns == 1 ? 2.4 : 1.35,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) =>
              _DecisionPointCard(item: items[index], riskLabel: riskLabel),
        );
      },
    );
  }
}

class _PlanReadinessRow extends StatelessWidget {
  const _PlanReadinessRow({
    required this.plannerMode,
    required this.parentVisible,
    required this.includeChecklist,
    required this.bodyFatText,
    required this.budgetLevel,
  });

  final String plannerMode;
  final bool parentVisible;
  final bool includeChecklist;
  final String bodyFatText;
  final String budgetLevel;

  @override
  Widget build(BuildContext context) {
    final items = [
      _ReadinessItem(
        title: 'Plan mode',
        value: _modeLabel(plannerMode),
        note:
            'The planner should match the calendar, not just the goal weight.',
        color: const Color(0xFF38BDF8),
      ),
      _ReadinessItem(
        title: 'Family handoff',
        value: parentVisible ? 'Enabled' : 'Coach only',
        note: parentVisible
            ? 'Parent-safe outputs will be generated with the plan.'
            : 'Keep this draft internal until the plan is ready to share.',
        color:
            parentVisible ? const Color(0xFF14B8A6) : AppColors.textSecondary,
      ),
      _ReadinessItem(
        title: 'Checklist',
        value: includeChecklist ? 'Active' : 'Off',
        note: includeChecklist
            ? 'Athlete gets a day-to-day compliance checklist.'
            : 'No athlete checklist will be attached to this plan yet.',
        color: includeChecklist
            ? const Color(0xFF8B5CF6)
            : AppColors.textSecondary,
      ),
      _ReadinessItem(
        title: 'Body fat context',
        value: bodyFatText.isEmpty ? 'Needed' : '$bodyFatText%',
        note: bodyFatText.isEmpty
            ? 'Use the calculator before approving a harder cut.'
            : 'Body fat estimate is ready to inform the safe floor.',
        color: bodyFatText.isEmpty ? AppColors.warning : AppColors.success,
      ),
      _ReadinessItem(
        title: 'Budget fit',
        value: budgetLevel.toUpperCase(),
        note:
            'Family reality matters if the plan is supposed to stick after school and travel.',
        color: const Color(0xFFF59E0B),
      ),
    ];

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: items.map((item) => _ReadinessCard(item: item)).toList(),
    );
  }
}

class _ReadinessItem {
  const _ReadinessItem({
    required this.title,
    required this.value,
    required this.note,
    required this.color,
  });

  final String title;
  final String value;
  final String note;
  final Color color;
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({required this.item});

  final _ReadinessItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.sm),
            Text(item.value,
                style: AppTextStyles.bodyStrong.copyWith(color: item.color)),
            const SizedBox(height: AppSpacing.xs),
            Text(item.note,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _DecisionPoint {
  const _DecisionPoint({
    required this.title,
    required this.value,
    required this.note,
    required this.color,
  });

  final String title;
  final String value;
  final String note;
  final Color color;
}

class _DecisionPointCard extends StatelessWidget {
  const _DecisionPointCard({required this.item, required this.riskLabel});

  final _DecisionPoint item;
  final String riskLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.sm),
          Text(item.value,
              style: AppTextStyles.cardTitle.copyWith(color: item.color)),
          const SizedBox(height: AppSpacing.xs),
          Text(item.note, style: AppTextStyles.body),
          if (item.title == 'Projected rate') ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Current planner state: $riskLabel',
                style: AppTextStyles.caption.copyWith(color: item.color)),
          ],
        ],
      ),
    );
  }
}

class _PlannerHero extends StatelessWidget {
  const _PlannerHero({
    required this.plannerMode,
    required this.riskLabel,
    required this.riskColor,
    required this.riskScore,
    required this.weightDelta,
    required this.daysToWeighIn,
    required this.weeklyLossRate,
  });

  final String plannerMode;
  final String riskLabel;
  final Color riskColor;
  final int riskScore;
  final double weightDelta;
  final int daysToWeighIn;
  final double weeklyLossRate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
                riskColor.withValues(alpha: 0.20), AppColors.surfaceElevated),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 980;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Pill(
                  label: _modeTitle(plannerMode),
                  color: const Color(0xFF38BDF8)),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Coach-safe nutrition planning for the real wrestling calendar.',
                style: AppTextStyles.pageTitle.copyWith(fontSize: 36),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'This planner should help a coach decide whether to fuel, hold, recover, or shut a cut down before it becomes risky.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.84),
                  fontSize: 16,
                ),
              ),
            ],
          );

          final scoreCard = Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Safety score', style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$riskScore',
                        style: AppTextStyles.pageTitle.copyWith(fontSize: 42)),
                    const SizedBox(width: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _Pill(label: riskLabel, color: riskColor),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _HeroMetric(
                    label: 'Weight delta',
                    value: '${weightDelta.toStringAsFixed(1)} lbs'),
                _HeroMetric(label: 'Weigh-in', value: '$daysToWeighIn days'),
                _HeroMetric(
                    label: 'Projected rate',
                    value: '${weeklyLossRate.toStringAsFixed(1)} lbs/week'),
              ],
            ),
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: AppSpacing.lg),
                scoreCard,
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 6, child: copy),
              const SizedBox(width: AppSpacing.xl),
              Expanded(flex: 4, child: scoreCard),
            ],
          );
        },
      ),
    );
  }
}

String _modeLabel(String value) {
  return switch (value) {
    'safe_cut' => 'Safe cut',
    'maintenance' => 'Maintenance',
    'tournament_week' => 'Tournament week',
    'two_day_recovery' => 'Two-day recovery',
    'growth' => 'Growth',
    'travel' => 'Travel',
    _ => value,
  };
}

class _ModeBar extends StatelessWidget {
  const _ModeBar({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const modes = [
      ('safe_cut', 'Safe cut'),
      ('maintenance', 'Maintenance'),
      ('tournament_week', 'Tournament week'),
      ('two_day_recovery', 'Two-day recovery'),
      ('growth', 'Growth'),
      ('travel', 'Travel'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final mode in modes)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: ChoiceChip(
                label: Text(mode.$2),
                selected: value == mode.$1,
                onSelected: (_) => onChanged(mode.$1),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlannerFormCard extends StatelessWidget {
  const _PlannerFormCard({
    required this.formKey,
    required this.nameController,
    required this.ageController,
    required this.heightController,
    required this.weightController,
    required this.bodyFatController,
    required this.targetWeightController,
    required this.daysController,
    required this.allergiesController,
    required this.dislikesController,
    required this.dietTagsController,
    required this.budgetNotesController,
    required this.sex,
    required this.goal,
    required this.activityLevel,
    required this.trainingPhase,
    required this.practiceWindow,
    required this.mealTemplate,
    required this.budgetLevel,
    required this.parentVisible,
    required this.includeChecklist,
    required this.isLoading,
    required this.onGenerate,
    required this.onOpenBodyFatCalculator,
    required this.onParentVisibleChanged,
    required this.onIncludeChecklistChanged,
    required this.onSexChanged,
    required this.onGoalChanged,
    required this.onActivityLevelChanged,
    required this.onTrainingPhaseChanged,
    required this.onPracticeWindowChanged,
    required this.onMealTemplateChanged,
    required this.onBudgetLevelChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController ageController;
  final TextEditingController heightController;
  final TextEditingController weightController;
  final TextEditingController bodyFatController;
  final TextEditingController targetWeightController;
  final TextEditingController daysController;
  final TextEditingController allergiesController;
  final TextEditingController dislikesController;
  final TextEditingController dietTagsController;
  final TextEditingController budgetNotesController;
  final String sex;
  final String goal;
  final String activityLevel;
  final String trainingPhase;
  final String practiceWindow;
  final String mealTemplate;
  final String budgetLevel;
  final bool parentVisible;
  final bool includeChecklist;
  final bool isLoading;
  final VoidCallback onGenerate;
  final VoidCallback onOpenBodyFatCalculator;
  final ValueChanged<bool> onParentVisibleChanged;
  final ValueChanged<bool> onIncludeChecklistChanged;
  final ValueChanged<String?> onSexChanged;
  final ValueChanged<String?> onGoalChanged;
  final ValueChanged<String?> onActivityLevelChanged;
  final ValueChanged<String?> onTrainingPhaseChanged;
  final ValueChanged<String?> onPracticeWindowChanged;
  final ValueChanged<String?> onMealTemplateChanged;
  final ValueChanged<String?> onBudgetLevelChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Athlete context',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 28)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Elite nutrition planning starts with the full situation: cut pressure, practice load, family reality, and what the coach is actually asking the athlete to do.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.lg),
            const _FormSectionHeader(
              title: 'Athlete profile',
              subtitle: 'Who is this plan for right now?',
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                _TextInput(controller: nameController, label: 'Athlete name'),
                _TextInput(
                    controller: ageController,
                    label: 'Age',
                    isNumber: true,
                    width: 160),
                _SelectInput(
                  label: 'Sex',
                  value: sex,
                  items: const ['male', 'female', 'other'],
                  onChanged: onSexChanged,
                  width: 180,
                ),
                _TextInput(
                    controller: heightController,
                    label: 'Height (in)',
                    isNumber: true,
                    width: 180),
                _TextInput(
                    controller: weightController,
                    label: 'Current weight',
                    isNumber: true,
                    width: 200),
                _TextInput(
                    controller: bodyFatController,
                    label: 'Body fat %',
                    isNumber: true,
                    width: 180),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const _FormSectionHeader(
              title: 'Decision setup',
              subtitle: 'What is the coach asking the athlete to do?',
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                _SelectInput(
                  label: 'Goal',
                  value: goal,
                  items: const ['cut', 'maintain', 'bulk'],
                  onChanged: onGoalChanged,
                ),
                if (goal == 'cut')
                  _TextInput(
                      controller: targetWeightController,
                      label: 'Target class weight',
                      isNumber: true,
                      width: 220),
                _TextInput(
                    controller: daysController,
                    label: 'Days to weigh-in',
                    isNumber: true,
                    width: 220),
                _SelectInput(
                  label: 'Activity',
                  value: activityLevel,
                  items: const ['low', 'moderate', 'high', 'elite'],
                  onChanged: onActivityLevelChanged,
                ),
                _SelectInput(
                  label: 'Training phase',
                  value: trainingPhase,
                  items: const [
                    'offseason',
                    'preseason',
                    'inseason',
                    'tournament_week'
                  ],
                  onChanged: onTrainingPhaseChanged,
                ),
                _SelectInput(
                  label: 'Practice window',
                  value: practiceWindow,
                  items: const ['morning', 'afternoon', 'evening', 'none'],
                  onChanged: onPracticeWindowChanged,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const _FormSectionHeader(
              title: 'Food + family reality',
              subtitle:
                  'Make the plan realistic enough to follow after school and on travel days.',
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                _SelectInput(
                  label: 'Meal template',
                  value: mealTemplate,
                  items: const ['budget', 'high_protein', 'family', 'simple'],
                  onChanged: onMealTemplateChanged,
                ),
                _SelectInput(
                  label: 'Budget',
                  value: budgetLevel,
                  items: const ['low', 'medium', 'high'],
                  onChanged: onBudgetLevelChanged,
                  width: 180,
                ),
                _TextInput(
                    controller: allergiesController,
                    label: 'Allergies (comma separated)',
                    width: 420),
                _TextInput(
                    controller: dislikesController,
                    label: 'Dislikes (comma separated)',
                    width: 420),
                _TextInput(
                    controller: dietTagsController,
                    label: 'Diet tags (comma separated)',
                    width: 420),
                _TextInput(
                  controller: budgetNotesController,
                  label: 'Family / prep notes',
                  width: 640,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onOpenBodyFatCalculator,
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Open body fat calculator'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated.withValues(alpha: 0.68),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.sm,
                children: [
                  _ToggleLine(
                    title: 'Parent-visible version',
                    subtitle:
                        'Generate family-facing prep guidance and grocery language.',
                    value: parentVisible,
                    onChanged: onParentVisibleChanged,
                  ),
                  _ToggleLine(
                    title: 'Athlete checklist',
                    subtitle:
                        'Include a simple day-to-day compliance checklist.',
                    value: includeChecklist,
                    onChanged: onIncludeChecklistChanged,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: isLoading ? null : onGenerate,
              icon: const Icon(Icons.restaurant_menu_rounded),
              label: Text(isLoading
                  ? 'Generating premium plan...'
                  : 'Generate premium plan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlannerSnapshotRow extends StatelessWidget {
  const _PlannerSnapshotRow({
    required this.athleteName,
    required this.goal,
    required this.trainingPhase,
    required this.currentWeight,
    required this.targetWeight,
    required this.daysToWeighIn,
    required this.parentVisible,
    required this.includeChecklist,
  });

  final String athleteName;
  final String goal;
  final String trainingPhase;
  final double currentWeight;
  final double targetWeight;
  final int daysToWeighIn;
  final bool parentVisible;
  final bool includeChecklist;

  @override
  Widget build(BuildContext context) {
    final items = [
      _SnapshotItem('Athlete', athleteName),
      _SnapshotItem('Goal', goal.toUpperCase()),
      _SnapshotItem('Phase', trainingPhase.replaceAll('_', ' ')),
      _SnapshotItem('Current', '${currentWeight.toStringAsFixed(1)} lbs'),
      _SnapshotItem('Target', '${targetWeight.toStringAsFixed(1)} lbs'),
      _SnapshotItem('Weigh-in', '$daysToWeighIn days'),
      _SnapshotItem('Family', parentVisible ? 'Visible' : 'Coach only'),
      _SnapshotItem('Checklist', includeChecklist ? 'On' : 'Off'),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: items.map((item) => _SnapshotChip(item: item)).toList(),
    );
  }
}

class _SnapshotItem {
  const _SnapshotItem(this.label, this.value);
  final String label;
  final String value;
}

class _SnapshotChip extends StatelessWidget {
  const _SnapshotChip({required this.item});

  final _SnapshotItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(16),
      ),
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          children: [
            TextSpan(text: '${item.label}: '),
            TextSpan(
              text: item.value,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormSectionHeader extends StatelessWidget {
  const _FormSectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.cardTitle),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          subtitle,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _SafetyScoreCard extends StatelessWidget {
  const _SafetyScoreCard({
    required this.riskScore,
    required this.riskLabel,
    required this.riskColor,
    required this.items,
  });

  final int riskScore;
  final String riskLabel;
  final Color riskColor;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
              Text('Safety center', style: AppTextStyles.cardTitle),
              const Spacer(),
              _Pill(label: riskLabel, color: riskColor),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('$riskScore',
              style: AppTextStyles.pageTitle.copyWith(fontSize: 46)),
          const SizedBox(height: AppSpacing.xs),
          Text(
              'This score helps a coach decide whether to hold, adjust, or block the cut.',
              style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.md),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, size: 18, color: riskColor),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(item, style: AppTextStyles.body)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
              Icon(icon, color: color),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: AppTextStyles.cardTitle),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 8),
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(item, style: AppTextStyles.body)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutputHeader extends StatelessWidget {
  const _OutputHeader({
    required this.mode,
    required this.plan,
    required this.parentVisible,
  });

  final String mode;
  final NutritionPlanResponseModel plan;
  final bool parentVisible;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _Pill(
                        label: _modeTitle(mode),
                        color: const Color(0xFF38BDF8)),
                    if (parentVisible)
                      _Pill(
                          label: 'Parent visible',
                          color: const Color(0xFFF59E0B)),
                    if ((plan.providerStatus?.isNotEmpty ?? false))
                      _Pill(
                          label: 'Provider connected',
                          color: AppColors.success),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Generated weekly nutrition system',
                    style: AppTextStyles.sectionTitle.copyWith(fontSize: 30)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'This output is organized so coaches can approve it quickly and families can actually use it.',
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumMetricRow extends StatelessWidget {
  const _PremiumMetricRow({
    required this.macros,
    required this.hydrationPlan,
    required this.warnings,
  });

  final NutritionMacros macros;
  final Map<String, dynamic> hydrationPlan;
  final int warnings;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        _MetricCard(
            label: 'Calories',
            value: macros.calories.toString(),
            note: 'daily target'),
        _MetricCard(
            label: 'Protein',
            value: '${macros.proteinG}g',
            note: 'muscle support'),
        _MetricCard(
            label: 'Hydration',
            value: '${hydrationPlan['daily_water_oz_target'] ?? '--'} oz',
            note: 'daily water'),
        _MetricCard(
            label: 'Warnings', value: '$warnings', note: 'active flags'),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.note,
  });

  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTextStyles.pageTitle.copyWith(fontSize: 32)),
          const SizedBox(height: AppSpacing.xs),
          Text(note, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.label,
    this.isNumber = false,
    this.width = 280,
  });

  final TextEditingController controller;
  final String label;
  final bool isNumber;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : null,
        validator: (value) =>
            (value == null || value.trim().isEmpty) ? 'Required' : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _SelectInput extends StatelessWidget {
  const _SelectInput({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.width = 280,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label),
        items: items
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item.replaceAll('_', ' ')),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ToggleLine extends StatelessWidget {
  const _ToggleLine({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Switch(value: value, onChanged: onChanged),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyStrong),
                const SizedBox(height: AppSpacing.xxs),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.caption)),
          Text(value, style: AppTextStyles.bodyStrong),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
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
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.message,
    this.isError = false,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: (isError ? AppColors.danger : AppColors.success)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(message,
          style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
    );
  }
}

class _HydrationCard extends StatelessWidget {
  const _HydrationCard({
    required this.plan,
    required this.timeline,
  });

  final NutritionPlanResponseModel plan;
  final List<String> timeline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hydration strategy', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.md),
          _HydrationLine(
              label: 'Daily target',
              value:
                  '${plan.hydrationPlan['daily_water_oz_target'] ?? '--'} oz'),
          _HydrationLine(
              label: 'During practice',
              value: '${plan.hydrationPlan['during_practice_oz'] ?? '--'} oz'),
          _HydrationLine(
              label: 'Post practice',
              value: '${plan.hydrationPlan['post_practice_oz'] ?? '--'} oz'),
          const SizedBox(height: AppSpacing.md),
          Text(
            plan.hydrationPlan['electrolyte_note']?.toString() ??
                'No extra electrolyte note.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Hydration timeline', style: AppTextStyles.bodyStrong),
          const SizedBox(height: AppSpacing.sm),
          ...timeline.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.water_drop_outlined,
                      size: 18, color: Color(0xFF38BDF8)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(item, style: AppTextStyles.body)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HydrationLine extends StatelessWidget {
  const _HydrationLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.caption)),
          Text(value, style: AppTextStyles.bodyStrong),
        ],
      ),
    );
  }
}

class _WarningsCard extends StatelessWidget {
  const _WarningsCard({required this.plan});

  final NutritionPlanResponseModel plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Coach warnings', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.md),
          if (plan.warnings.isEmpty)
            Text('No warnings for this plan.', style: AppTextStyles.body)
          else
            ...plan.warnings.map(
              (warning) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: (warning.severity == 'high'
                            ? AppColors.danger
                            : AppColors.warning)
                        .withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: warning.severity == 'high'
                            ? AppColors.danger
                            : AppColors.warning,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(warning.code, style: AppTextStyles.bodyStrong),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(warning.message, style: AppTextStyles.body),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ParentSummaryCard extends StatelessWidget {
  const _ParentSummaryCard({
    required this.items,
    required this.onOpenHandoff,
  });

  final List<String> items;
  final VoidCallback onOpenHandoff;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
              const Icon(Icons.family_restroom_outlined,
                  color: Color(0xFFF59E0B)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Parent handoff summary',
                    style: AppTextStyles.sectionTitle),
              ),
              OutlinedButton.icon(
                onPressed: onOpenHandoff,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open shareable handoff'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'This is the short version a family needs before school nights, travel, and tournament week start moving fast.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.md),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      size: 18, color: Color(0xFF14B8A6)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(item, style: AppTextStyles.body)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentHandoffDialog extends StatelessWidget {
  const _ParentHandoffDialog({
    required this.athleteName,
    required this.parentSummary,
    required this.familyStoreItems,
    required this.replacementIdeas,
    required this.tournamentDayPlan,
    required this.refuelPlan,
    required this.hydrationTimeline,
    required this.hydrationTarget,
    required this.weeklyEstimate,
    required this.weighInMode,
    required this.onCopy,
  });

  final String athleteName;
  final List<String> parentSummary;
  final List<String> familyStoreItems;
  final List<String> replacementIdeas;
  final List<String> tournamentDayPlan;
  final List<String> refuelPlan;
  final List<String> hydrationTimeline;
  final String hydrationTarget;
  final double weeklyEstimate;
  final String weighInMode;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 920),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(32),
        ),
        child: SingleChildScrollView(
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
                        Text(
                          athleteName.isEmpty
                              ? 'Parent nutrition handoff'
                              : '$athleteName parent handoff',
                          style: AppTextStyles.pageTitle.copyWith(fontSize: 34),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Built for the family to shop, prep, swap meals, and handle tournament day without guessing.',
                          style: AppTextStyles.body,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _Pill(
                      label: 'Hydration target: $hydrationTarget',
                      color: const Color(0xFF38BDF8)),
                  _Pill(
                      label: 'Weigh-in: $weighInMode',
                      color: const Color(0xFF8B5CF6)),
                  _Pill(
                      label:
                          'Weekly est: \$${weeklyEstimate.toStringAsFixed(2)}',
                      color: const Color(0xFF14B8A6)),
                  const _Pill(label: 'Family-ready', color: Color(0xFFF59E0B)),
                  const _Pill(
                      label: 'Tournament support', color: Color(0xFF14B8A6)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 860;
                  final summaryColumn = Column(
                    children: [
                      _HandoffSection(
                        title: 'What matters most',
                        icon: Icons.fact_check_outlined,
                        color: const Color(0xFFF59E0B),
                        items: parentSummary,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _HandoffSection(
                        title: 'Store list',
                        icon: Icons.shopping_bag_outlined,
                        color: const Color(0xFF38BDF8),
                        items: familyStoreItems,
                      ),
                    ],
                  );
                  final actionColumn = Column(
                    children: [
                      _HandoffSection(
                        title: 'Easy replacements',
                        icon: Icons.swap_horiz_rounded,
                        color: const Color(0xFF8B5CF6),
                        items: replacementIdeas,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _HandoffSection(
                        title: 'Tournament day',
                        icon: Icons.flag_circle_outlined,
                        color: const Color(0xFF14B8A6),
                        items: tournamentDayPlan,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _HandoffSection(
                        title: 'Post weigh-in refuel',
                        icon: Icons.bolt_rounded,
                        color: const Color(0xFFF97316),
                        items: refuelPlan,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _HandoffSection(
                        title: 'Hydration timeline',
                        icon: Icons.water_drop_outlined,
                        color: const Color(0xFF38BDF8),
                        items: hydrationTimeline,
                      ),
                    ],
                  );

                  if (stacked) {
                    return Column(
                      children: [
                        summaryColumn,
                        const SizedBox(height: AppSpacing.lg),
                        actionColumn,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: summaryColumn),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(child: actionColumn),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: onCopy,
                    icon: const Icon(Icons.copy_all_rounded),
                    label: const Text('Copy handoff'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HandoffSection extends StatelessWidget {
  const _HandoffSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(title, style: AppTextStyles.cardTitle)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(item, style: AppTextStyles.body)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekPlanCard extends StatelessWidget {
  const _WeekPlanCard({required this.plan});

  final NutritionPlanResponseModel plan;

  @override
  Widget build(BuildContext context) {
    final totalDays = plan.weeklyPlan.length;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly meal system', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Meals are grouped by day so a coach can scan timing and a parent can see what to prep.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.md),
          ...plan.weeklyPlan.map(
            (day) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(day.dayLabel, style: AppTextStyles.cardTitle),
                    if (totalDays > 0) ...[
                      const SizedBox(height: AppSpacing.xs),
                      _Pill(
                        label:
                            'T-${(totalDays - (plan.weeklyPlan.indexOf(day) + 1)).clamp(0, totalDays)}',
                        color: const Color(0xFF38BDF8),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    ...day.meals.map(
                      (meal) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                      child: Text(meal.name,
                                          style: AppTextStyles.bodyStrong)),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${meal.approxCalories} cal',
                                          style: AppTextStyles.caption),
                                      Text(
                                        '~${_estimateMealCost(meal).toStringAsFixed(2)} Walmart est.',
                                        style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(meal.foods.join(', '),
                                  style: AppTextStyles.body),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '${meal.proteinG}p • ${meal.carbsG}c • ${meal.fatsG}f',
                                style: AppTextStyles.caption,
                              ),
                              if ((meal.timingNote ?? '').isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(meal.timingNote!,
                                    style: AppTextStyles.caption),
                              ],
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Family replacement: keep a similar protein + carb option ready if this meal falls apart.',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilySupportCard extends StatelessWidget {
  const _FamilySupportCard({
    required this.storeItems,
    required this.replacementIdeas,
  });

  final List<String> storeItems;
  final List<String> replacementIdeas;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Family support kit', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Everything the family needs from the store, plus simple replacements so the plan still works on busy days.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Store list', style: AppTextStyles.bodyStrong),
          const SizedBox(height: AppSpacing.sm),
          ...storeItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shopping_bag_outlined,
                      size: 18, color: Color(0xFF38BDF8)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(item, style: AppTextStyles.body)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Replacement ideas', style: AppTextStyles.bodyStrong),
          const SizedBox(height: AppSpacing.sm),
          ...replacementIdeas.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.swap_horiz_rounded,
                      size: 18, color: Color(0xFFF59E0B)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(item, style: AppTextStyles.body)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TournamentDayCard extends StatelessWidget {
  const _TournamentDayCard({
    required this.items,
    required this.title,
    required this.icon,
    required this.color,
  });

  final List<String> items;
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
              Icon(icon, color: color),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: AppTextStyles.sectionTitle),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(item, style: AppTextStyles.body)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroceryCard extends StatelessWidget {
  const _GroceryCard({
    required this.plan,
    required this.weeklyEstimate,
  });

  final NutritionPlanResponseModel plan;
  final double weeklyEstimate;

  @override
  Widget build(BuildContext context) {
    final groceryText = _walmartGroceryText(plan);
    return Container(
      width: double.infinity,
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
              Expanded(
                  child:
                      Text('Grocery list', style: AppTextStyles.sectionTitle)),
              _Pill(
                label: 'Weekly est. \$${weeklyEstimate.toStringAsFixed(2)}',
                color: const Color(0xFF14B8A6),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Built to hand off to a parent or team meal-prep lead without extra cleanup.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.md),
          ...plan.groceryList.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                      child: Text(item.item, style: AppTextStyles.bodyStrong)),
                  const SizedBox(width: AppSpacing.md),
                  Text(item.quantity, style: AppTextStyles.body),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    '~${_estimateGroceryItemCost(item).toStringAsFixed(2)}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(item.category, style: AppTextStyles.caption),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Walmart-style cost estimates are approximate and meant for planning, not live checkout pricing.',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ElevatedButton.icon(
                onPressed: () => _openWalmartSearch(context, plan),
                icon: const Icon(Icons.shopping_cart_outlined),
                label: const Text('Open Walmart search'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: groceryText));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Grocery list copied.')),
                  );
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy grocery list'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Walmart does not expose a public consumer checkout-cart upload here, so the beta handoff opens a shopping search and copies the list for fast cart building.',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

String _walmartGroceryText(NutritionPlanResponseModel plan) {
  return [
    'Pin IQ grocery list',
    ...plan.groceryList.map((item) => '- ${item.item}: ${item.quantity}'),
  ].join('\n');
}

Future<void> _openWalmartSearch(
  BuildContext context,
  NutritionPlanResponseModel plan,
) async {
  final terms = plan.groceryList
      .take(8)
      .map((item) => item.item)
      .join(' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final encoded = Uri.encodeComponent(
      terms.isEmpty ? 'wrestling meal prep groceries' : terms);
  final opened =
      await openBrowserLink('https://www.walmart.com/search?q=$encoded');
  if (!context.mounted) return;
  if (!opened) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open Walmart search.')),
    );
  }
}

double _estimateMealCost(NutritionMeal meal) {
  if (meal.foods.isEmpty) return 0;
  final total = meal.foods.fold<double>(
    0,
    (sum, food) => sum + _estimateFoodUnitCost(food),
  );
  return total.clamp(0, 50);
}

double _estimateGroceryItemCost(GroceryItemModel item) {
  final base = _estimateFoodUnitCost(item.item);
  final multiplier = _servingCount(item.quantity).toDouble();
  return (base * multiplier).clamp(0, 80);
}

int _servingCount(String quantity) {
  final match = RegExp(r'\d+').firstMatch(quantity);
  if (match == null) return 1;
  return int.tryParse(match.group(0) ?? '')?.clamp(1, 21) ?? 1;
}

double _estimateWeeklyGroceryTotal(NutritionPlanResponseModel? plan) {
  if (plan == null) return 0;
  final total = plan.groceryList.fold<double>(
    0,
    (sum, item) => sum + _estimateGroceryItemCost(item),
  );
  return total.clamp(0, 500);
}

double _estimateFoodUnitCost(String food) {
  final value = food.toLowerCase();
  if (value.contains('salmon')) return 2.95;
  if (value.contains('chicken wrap')) return 1.85;
  if (value.contains('chicken')) return 1.75;
  if (value.contains('taco bowl')) return 2.35;
  if (value.contains('ground turkey') || value.contains('turkey')) return 1.65;
  if (value.contains('beef')) return 1.95;
  if (value.contains('tuna')) return 1.05;
  if (value.contains('egg')) return 0.45;
  if (value.contains('greek yogurt')) return 0.85;
  if (value.contains('yogurt')) return 0.65;
  if (value.contains('string cheese')) return 0.35;
  if (value.contains('cottage cheese')) return 0.75;
  if (value.contains('oat')) return 0.30;
  if (value.contains('granola')) return 0.55;
  if (value.contains('toast')) return 0.25;
  if (value.contains('bagel')) return 0.65;
  if (value.contains('banana')) return 0.30;
  if (value.contains('apple')) return 0.70;
  if (value.contains('berry')) return 0.95;
  if (value.contains('fruit')) return 0.70;
  if (value.contains('rice')) return 0.25;
  if (value.contains('black bean') || value.contains('bean')) return 0.28;
  if (value.contains('potato')) return 0.45;
  if (value.contains('pasta')) return 0.35;
  if (value.contains('green bean') ||
      value.contains('broccoli') ||
      value.contains('asparagus')) {
    return 0.70;
  }
  if (value.contains('salad')) return 0.85;
  if (value.contains('wrap')) return 0.55;
  if (value.contains('pretzel')) return 0.25;
  if (value.contains('peanut butter')) return 0.18;
  if (value.contains('protein shake')) return 1.65;
  if (value.contains('protein')) return 1.45;
  if (value.contains('electrolyte')) return 0.85;
  if (value.contains('water')) return 0.35;
  if (value.contains('snack')) return 1.25;
  return 0.95;
}

String _weighInModeLabel(int daysToWeighIn) {
  if (daysToWeighIn <= 0) return 'Same day';
  if (daysToWeighIn == 1) return 'Night before';
  return 'Advance prep';
}

String _modeTitle(String mode) {
  return switch (mode) {
    'safe_cut' => 'Safe cut',
    'maintenance' => 'Maintenance',
    'tournament_week' => 'Tournament week',
    'two_day_recovery' => 'Two-day recovery',
    'growth' => 'Growth mode',
    'travel' => 'Travel mode',
    _ => 'Planner mode',
  };
}
