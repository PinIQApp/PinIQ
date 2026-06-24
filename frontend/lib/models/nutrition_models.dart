class NutritionMacros {
  const NutritionMacros({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
    required this.fiberG,
    required this.waterOz,
  });

  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatsG;
  final int fiberG;
  final int waterOz;

  factory NutritionMacros.fromJson(Map<String, dynamic> json) {
    return NutritionMacros(
      calories: json['calories'] ?? 0,
      proteinG: json['protein_g'] ?? 0,
      carbsG: json['carbs_g'] ?? 0,
      fatsG: json['fats_g'] ?? 0,
      fiberG: json['fiber_g'] ?? 0,
      waterOz: json['water_oz'] ?? 0,
    );
  }
}

class NutritionMeal {
  const NutritionMeal({
    required this.name,
    required this.foods,
    required this.approxCalories,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
    this.timingNote,
  });

  final String name;
  final List<String> foods;
  final int approxCalories;
  final int proteinG;
  final int carbsG;
  final int fatsG;
  final String? timingNote;

  factory NutritionMeal.fromJson(Map<String, dynamic> json) {
    return NutritionMeal(
      name: json['name'] ?? '',
      foods: (json['foods'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      approxCalories: json['approx_calories'] ?? 0,
      proteinG: json['protein_g'] ?? 0,
      carbsG: json['carbs_g'] ?? 0,
      fatsG: json['fats_g'] ?? 0,
      timingNote: json['timing_note'],
    );
  }
}

class NutritionDayPlan {
  const NutritionDayPlan({
    required this.dayLabel,
    required this.meals,
  });

  final String dayLabel;
  final List<NutritionMeal> meals;

  factory NutritionDayPlan.fromJson(Map<String, dynamic> json) {
    return NutritionDayPlan(
      dayLabel: json['day_label'] ?? '',
      meals: (json['meals'] as List<dynamic>? ?? [])
          .map(
              (item) => NutritionMeal.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class GroceryItemModel {
  const GroceryItemModel({
    required this.item,
    required this.quantity,
    required this.category,
    this.estimatedUnitPrice,
    this.estimatedTotalPrice,
    this.priceSource,
    this.servingSizeNote,
    this.shoppingQuery,
    this.shoppingUrl,
  });

  final String item;
  final String quantity;
  final String category;
  final double? estimatedUnitPrice;
  final double? estimatedTotalPrice;
  final String? priceSource;
  final String? servingSizeNote;
  final String? shoppingQuery;
  final String? shoppingUrl;

  factory GroceryItemModel.fromJson(Map<String, dynamic> json) {
    return GroceryItemModel(
      item: json['item'] ?? '',
      quantity: json['quantity'] ?? '',
      category: json['category'] ?? '',
      estimatedUnitPrice: (json['estimated_unit_price'] as num?)?.toDouble(),
      estimatedTotalPrice: (json['estimated_total_price'] as num?)?.toDouble(),
      priceSource: json['price_source'],
      servingSizeNote: json['serving_size_note'],
      shoppingQuery: json['shopping_query'],
      shoppingUrl: json['shopping_url'],
    );
  }
}

class NutritionWarningModel {
  const NutritionWarningModel({
    required this.code,
    required this.message,
    required this.severity,
  });

  final String code;
  final String message;
  final String severity;

  factory NutritionWarningModel.fromJson(Map<String, dynamic> json) {
    return NutritionWarningModel(
      code: json['code'] ?? '',
      message: json['message'] ?? '',
      severity: json['severity'] ?? 'info',
    );
  }
}

class NutritionPlanResponseModel {
  const NutritionPlanResponseModel({
    required this.athleteSummary,
    required this.macros,
    required this.weeklyPlan,
    required this.groceryList,
    required this.hydrationPlan,
    required this.weighInStrategy,
    required this.warnings,
    this.providerStatus,
  });

  final Map<String, dynamic> athleteSummary;
  final NutritionMacros macros;
  final List<NutritionDayPlan> weeklyPlan;
  final List<GroceryItemModel> groceryList;
  final Map<String, dynamic> hydrationPlan;
  final Map<String, dynamic> weighInStrategy;
  final List<NutritionWarningModel> warnings;
  final Map<String, dynamic>? providerStatus;

  factory NutritionPlanResponseModel.fromJson(Map<String, dynamic> json) {
    return NutritionPlanResponseModel(
      athleteSummary: Map<String, dynamic>.from(json['athlete_summary'] ?? {}),
      macros: NutritionMacros.fromJson(
          Map<String, dynamic>.from(json['macros'] ?? {})),
      weeklyPlan: (json['weekly_plan'] as List<dynamic>? ?? [])
          .map((item) =>
              NutritionDayPlan.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      groceryList: (json['grocery_list'] as List<dynamic>? ?? [])
          .map((item) =>
              GroceryItemModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      hydrationPlan: Map<String, dynamic>.from(json['hydration_plan'] ?? {}),
      weighInStrategy:
          Map<String, dynamic>.from(json['weigh_in_strategy'] ?? {}),
      warnings: (json['warnings'] as List<dynamic>? ?? [])
          .map((item) =>
              NutritionWarningModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      providerStatus: json['provider_status'] == null
          ? null
          : Map<String, dynamic>.from(json['provider_status']),
    );
  }
}

class NutritionAthleteProfileModel {
  const NutritionAthleteProfileModel({
    required this.athlete,
    required this.classWeight,
    required this.bodyFat,
    required this.hydration,
    required this.decision,
    required this.focus,
  });

  final String athlete;
  final String classWeight;
  final String bodyFat;
  final String hydration;
  final String decision;
  final String focus;

  NutritionAthleteProfileModel copyWith({
    String? athlete,
    String? classWeight,
    String? bodyFat,
    String? hydration,
    String? decision,
    String? focus,
  }) {
    return NutritionAthleteProfileModel(
      athlete: athlete ?? this.athlete,
      classWeight: classWeight ?? this.classWeight,
      bodyFat: bodyFat ?? this.bodyFat,
      hydration: hydration ?? this.hydration,
      decision: decision ?? this.decision,
      focus: focus ?? this.focus,
    );
  }
}

List<NutritionAthleteProfileModel> seedNutritionAthleteProfiles() {
  return const [
    NutritionAthleteProfileModel(
      athlete: 'Avery Hall',
      classWeight: '120',
      bodyFat: '14.2%',
      hydration: 'Behind',
      decision: 'Coach review',
      focus:
          'Tighten hydration and post-practice recovery before weekend travel.',
    ),
    NutritionAthleteProfileModel(
      athlete: 'Maya Slone',
      classWeight: '132',
      bodyFat: '18.6%',
      hydration: 'On target',
      decision: 'Approved',
      focus: 'Stable maintenance pattern with a clean family handoff.',
    ),
    NutritionAthleteProfileModel(
      athlete: 'Kylie Johnson',
      classWeight: '145',
      bodyFat: '12.8%',
      hydration: 'At risk',
      decision: 'Blocked',
      focus:
          'Unsafe cut pattern needs staff intervention before the plan continues.',
    ),
  ];
}
