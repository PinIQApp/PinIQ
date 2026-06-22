from __future__ import annotations

from app.models.nutrition import (
    ActivityLevel,
    DailyMacros,
    Goal,
    NutritionPlanRequest,
    PracticeWindow,
    Sex,
    TrainingPhase,
)


ACTIVITY_MULTIPLIERS = {
    ActivityLevel.LOW: 1.35,
    ActivityLevel.MODERATE: 1.5,
    ActivityLevel.HIGH: 1.7,
    ActivityLevel.ELITE: 1.9,
}

PHASE_CALORIE_ADJUSTMENTS = {
    TrainingPhase.OFFSEASON: 150,
    TrainingPhase.PRESEASON: 100,
    TrainingPhase.INSEASON: 0,
    TrainingPhase.TOURNAMENT_WEEK: -50,
}

SAFE_CALORIE_MINIMUMS = {
    True: 1200,
    False: 1400,
}


def _weight_kg(weight_lbs: float) -> float:
    return weight_lbs * 0.45359237


def _height_cm(height_in: float) -> float:
    return height_in * 2.54


def _goal_energy_modifier(payload: NutritionPlanRequest, base_calories: float) -> float:
    if payload.goal == Goal.CUT:
        target_deficit = 350
        if payload.days_to_weigh_in is not None and payload.days_to_weigh_in <= 7:
            target_deficit += 150
        return max(target_deficit, base_calories * 0.18)

    if payload.goal == Goal.BULK:
        return max(225, base_calories * 0.12)

    return 0.0


def _protein_per_pound(payload: NutritionPlanRequest) -> float:
    if payload.goal == Goal.CUT:
        return 1.4
    if payload.goal == Goal.BULK:
        return 1.1
    return 0.95


def _fat_per_pound(payload: NutritionPlanRequest) -> float:
    if payload.goal == Goal.CUT:
        return 0.28
    if payload.goal == Goal.BULK:
        return 0.30
    return 0.32


def _water_factor(payload: NutritionPlanRequest) -> float:
    if payload.training_phase == TrainingPhase.TOURNAMENT_WEEK:
        return 0.75
    if payload.practice_window != PracticeWindow.NONE:
        return 0.68
    return 0.6


def estimate_daily_macros(payload: NutritionPlanRequest) -> DailyMacros:
    weight_kg = _weight_kg(payload.weight_lbs)
    height_cm = _height_cm(payload.height_in)

    if payload.sex == Sex.FEMALE:
        bmr = 10 * weight_kg + 6.25 * height_cm - 5 * payload.age - 161
    else:
        bmr = 10 * weight_kg + 6.25 * height_cm - 5 * payload.age + 5

    maintenance = bmr * ACTIVITY_MULTIPLIERS[payload.activity_level] + PHASE_CALORIE_ADJUSTMENTS[payload.training_phase]
    energy_modifier = _goal_energy_modifier(payload, maintenance)
    calories = maintenance - energy_modifier if payload.goal == Goal.CUT else maintenance + energy_modifier

    calories = max(calories, SAFE_CALORIE_MINIMUMS[payload.age < 16])

    protein_g = round(payload.weight_lbs * _protein_per_pound(payload))
    fats_g = round(payload.weight_lbs * _fat_per_pound(payload))

    calories_after_protein_fat = calories - protein_g * 4 - fats_g * 9
    carbs_g = max(round(calories_after_protein_fat / 4), 100)
    fiber_g = max(25, round(calories / 1000 * 14))
    water_oz = round(payload.weight_lbs * _water_factor(payload))

    if payload.training_phase == TrainingPhase.TOURNAMENT_WEEK or payload.matches_this_week >= 2:
        water_oz += 12

    if payload.goal == Goal.CUT and payload.days_to_weigh_in is not None and payload.days_to_weigh_in <= 3:
        fiber_g = max(fiber_g, 18)

    return DailyMacros(
        calories=max(int(round(calories)), SAFE_CALORIE_MINIMUMS[payload.age < 16]),
        protein_g=max(protein_g, 110),
        carbs_g=max(carbs_g, 120),
        fats_g=max(fats_g, 40),
        fiber_g=fiber_g,
        water_oz=max(water_oz, 80),
    )
