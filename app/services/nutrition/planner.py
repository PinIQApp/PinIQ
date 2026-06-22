from __future__ import annotations

from app.models.nutrition import DailyMacros, DailyPlan, MealItem, MealTemplate, NutritionPlanRequest, PracticeWindow


MEAL_LIBRARY: dict[MealTemplate, list[dict]] = {
    MealTemplate.SIMPLE: [
        {
            "name": "Breakfast",
            "foods": ["Greek yogurt", "mixed berries", "granola"],
            "bias": 0.22,
            "protein": 0.22,
            "carbs": 0.24,
            "fats": 0.18,
        },
        {
            "name": "Lunch",
            "foods": ["Turkey sandwich", "carrot sticks", "apple"],
            "bias": 0.28,
            "protein": 0.28,
            "carbs": 0.26,
            "fats": 0.24,
        },
        {
            "name": "Snack",
            "foods": ["Protein shake", "banana"],
            "bias": 0.10,
            "protein": 0.18,
            "carbs": 0.12,
            "fats": 0.08,
        },
        {
            "name": "Dinner",
            "foods": ["Chicken rice bowl", "broccoli"],
            "bias": 0.40,
            "protein": 0.32,
            "carbs": 0.38,
            "fats": 0.34,
        },
    ],
    MealTemplate.FAMILY: [
        {
            "name": "Breakfast",
            "foods": ["Egg scramble", "whole grain toast", "fruit"],
            "bias": 0.21,
            "protein": 0.22,
            "carbs": 0.22,
            "fats": 0.22,
        },
        {
            "name": "Lunch",
            "foods": ["Chicken wraps", "yogurt"],
            "bias": 0.27,
            "protein": 0.26,
            "carbs": 0.24,
            "fats": 0.22,
        },
        {
            "name": "Snack",
            "foods": ["String cheese", "pretzels"],
            "bias": 0.10,
            "protein": 0.13,
            "carbs": 0.12,
            "fats": 0.09,
        },
        {
            "name": "Dinner",
            "foods": ["Lean taco bowls", "black beans", "salad"],
            "bias": 0.42,
            "protein": 0.39,
            "carbs": 0.42,
            "fats": 0.47,
        },
    ],
    MealTemplate.BUDGET: [
        {
            "name": "Breakfast",
            "foods": ["Oatmeal", "peanut butter", "banana"],
            "bias": 0.20,
            "protein": 0.17,
            "carbs": 0.22,
            "fats": 0.20,
        },
        {
            "name": "Lunch",
            "foods": ["Rice", "beans", "ground turkey"],
            "bias": 0.30,
            "protein": 0.30,
            "carbs": 0.30,
            "fats": 0.26,
        },
        {
            "name": "Snack",
            "foods": ["Cottage cheese", "apple"],
            "bias": 0.08,
            "protein": 0.14,
            "carbs": 0.10,
            "fats": 0.07,
        },
        {
            "name": "Dinner",
            "foods": ["Pasta", "meat sauce", "green beans"],
            "bias": 0.42,
            "protein": 0.39,
            "carbs": 0.38,
            "fats": 0.47,
        },
    ],
    MealTemplate.HIGH_PROTEIN: [
        {
            "name": "Breakfast",
            "foods": ["Egg whites", "oatmeal", "berries"],
            "bias": 0.22,
            "protein": 0.24,
            "carbs": 0.22,
            "fats": 0.16,
        },
        {
            "name": "Lunch",
            "foods": ["Grilled chicken", "rice", "steamed vegetables"],
            "bias": 0.28,
            "protein": 0.29,
            "carbs": 0.26,
            "fats": 0.23,
        },
        {
            "name": "Snack",
            "foods": ["Greek yogurt", "protein bar"],
            "bias": 0.10,
            "protein": 0.17,
            "carbs": 0.11,
            "fats": 0.08,
        },
        {
            "name": "Dinner",
            "foods": ["Salmon", "sweet potato", "asparagus"],
            "bias": 0.40,
            "protein": 0.30,
            "carbs": 0.33,
            "fats": 0.33,
        },
    ],
}

DAY_LABELS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]


def _timing_note(name: str, practice_window: PracticeWindow) -> str | None:
    if practice_window == PracticeWindow.NONE:
        return None
    lowered = name.lower()
    if lowered == "snack":
        return f"Use this as a pre-{practice_window.value} snack 60-90 minutes before training."
    if lowered == "dinner" and practice_window in {PracticeWindow.AFTERNOON, PracticeWindow.EVENING}:
        return "Prioritize carbs and protein after practice for recovery."
    if lowered == "breakfast" and practice_window == PracticeWindow.MORNING:
        return "Keep this meal easy to digest before training and add recovery carbs after."
    return None


def _normalize_food(food: str) -> str:
    cleaned = food.strip().lower()
    if cleaned.endswith("s") and "grass" not in cleaned:
        return cleaned.rstrip("s")
    return cleaned


def _filtered_foods(payload: NutritionPlanRequest, foods: list[str]) -> list[str]:
    excluded = {item.strip().lower() for item in payload.allergies + payload.dislikes + payload.excluded_ingredients}
    filtered = [food for food in foods if all(excluded_item not in food.lower() for excluded_item in excluded)]
    return filtered or ["Custom meal based on athlete restrictions"]


def _apply_budget_alternatives(food: str, budget_level: str) -> str:
    if budget_level == "low":
        return {
            "greek yogurt": "plain yogurt",
            "salmon": "canned tuna",
            "chicken": "rotisserie chicken",
            "sweet potato": "white potato",
            "protein bar": "peanut butter",
            "quinoa": "brown rice",
        }.get(food.lower(), food)
    return food


def build_weekly_plan(payload: NutritionPlanRequest, macros: DailyMacros) -> list[DailyPlan]:
    templates = MEAL_LIBRARY[payload.meal_template]
    meals = templates[: payload.meals_per_day]

    snack_count = max(payload.snacks_per_day, 1 if any(meal["name"] == "Snack" for meal in meals) else 0)
    if snack_count > 1 and len(meals) < payload.meals_per_day + 1:
        meals.insert(-1, templates[2])

    weekly_plan: list[DailyPlan] = []
    for index, day_label in enumerate(DAY_LABELS):
        day_meals: list[MealItem] = []
        calorie_shift = -75 if index in {5, 6} and payload.matches_this_week == 0 else 0

        for meal in meals:
            base_foods = [_apply_budget_alternatives(food, payload.budget_level) for food in meal["foods"]]
            foods = _filtered_foods(payload, base_foods)
            approx_calories = round(macros.calories * meal["bias"]) + calorie_shift
            day_meals.append(
                MealItem(
                    name=meal["name"],
                    foods=foods,
                    approx_calories=max(approx_calories, 180),
                    protein_g=max(round(macros.protein_g * meal["protein"]), 12),
                    carbs_g=max(round(macros.carbs_g * meal["carbs"]), 15),
                    fats_g=max(round(macros.fats_g * meal["fats"]), 5),
                    timing_note=_timing_note(meal["name"], payload.practice_window),
                )
            )

        weekly_plan.append(DailyPlan(day_label=day_label, meals=day_meals))

    return weekly_plan
