from app.core.config import settings
from app.models.nutrition import (
    ActivityLevel,
    CheckInRequest,
    Goal,
    NutritionPlanRequest,
    PracticeWindow,
    Sex,
    TrainingPhase,
)
from app.services.nutrition.service import NutritionService


service = NutritionService()


def test_create_plan_cut_includes_health_warnings():
    payload = NutritionPlanRequest(
        athlete_id="athlete-1",
        name="Test Athlete",
        age=16,
        sex=Sex.MALE,
        height_in=70,
        weight_lbs=190,
        target_weight_lbs=180,
        body_fat_percent=12,
        goal=Goal.CUT,
        activity_level=ActivityLevel.HIGH,
        training_phase=TrainingPhase.INSEASON,
        practice_window=PracticeWindow.AFTERNOON,
        days_to_weigh_in=5,
        matches_this_week=1,
        allergies=["peanut"],
        dislikes=["salmon"],
        excluded_ingredients=["protein bar"],
        diet_tags=["high_protein"],
        meal_template="high_protein",
        meals_per_day=4,
        snacks_per_day=1,
        budget_level="medium",
        include_provider_plan=False,
    )

    plan = service.create_plan(payload)

    assert 2000 <= plan.macros.calories <= 2800
    assert plan.macros.protein_g >= 150
    assert plan.macros.water_oz >= 80
    assert any(w.code == "aggressive_cut" for w in plan.warnings)
    assert plan.provider_status["requested"] is False
    assert len(plan.weekly_plan) == 7
    assert any("Snack" in meal.name for day in plan.weekly_plan for meal in day.meals)


def test_steady_cut_pace_is_not_high_risk_with_normal_body_fat():
    payload = NutritionPlanRequest(
        athlete_id="athlete-steady",
        name="Steady Athlete",
        age=17,
        sex=Sex.MALE,
        height_in=70,
        weight_lbs=190,
        target_weight_lbs=176,
        body_fat_percent=13,
        goal=Goal.CUT,
        activity_level=ActivityLevel.HIGH,
        training_phase=TrainingPhase.INSEASON,
        practice_window=PracticeWindow.AFTERNOON,
        days_to_weigh_in=90,
        matches_this_week=1,
    )

    plan = service.create_plan(payload)

    assert any(w.code == "steady_cut_pace" for w in plan.warnings)
    assert not any(w.severity == "high" for w in plan.warnings)


def test_steady_cut_pace_is_high_risk_with_low_body_fat():
    payload = NutritionPlanRequest(
        athlete_id="athlete-lean",
        name="Lean Athlete",
        age=17,
        sex=Sex.MALE,
        height_in=70,
        weight_lbs=190,
        target_weight_lbs=176,
        body_fat_percent=7,
        goal=Goal.CUT,
        activity_level=ActivityLevel.HIGH,
        training_phase=TrainingPhase.INSEASON,
        practice_window=PracticeWindow.AFTERNOON,
        days_to_weigh_in=90,
        matches_this_week=1,
    )

    plan = service.create_plan(payload)

    assert any(w.code == "low_body_fat_cut" and w.severity == "high" for w in plan.warnings)


def test_create_plan_family_budget_and_exclusions():
    payload = NutritionPlanRequest(
        athlete_id="athlete-2",
        name="Budget Athlete",
        age=17,
        sex=Sex.MALE,
        height_in=72,
        weight_lbs=170,
        target_weight_lbs=None,
        body_fat_percent=15,
        goal=Goal.MAINTAIN,
        activity_level=ActivityLevel.MODERATE,
        training_phase=TrainingPhase.PRESEASON,
        practice_window=PracticeWindow.MORNING,
        days_to_weigh_in=None,
        matches_this_week=0,
        allergies=["dairy"],
        dislikes=["banana"],
        excluded_ingredients=["rice"],
        diet_tags=["budget"],
        meal_template="budget",
        meals_per_day=4,
        snacks_per_day=2,
        budget_level="low",
        include_provider_plan=True,
    )

    plan = service.create_plan(payload)

    assert plan.macros.calories >= 1600
    assert plan.provider_status["provider"] == "mock"
    assert plan.provider_status["requested"] is True
    assert all("rice" not in food.lower() for day in plan.weekly_plan for meal in day.meals for food in meal.foods)
    assert plan.grocery_list
    assert all(item.estimated_total_price is not None for item in plan.grocery_list)
    assert all(item.price_source == "Walmart planning estimate" for item in plan.grocery_list)
    assert all(item.serving_size_note for item in plan.grocery_list)
    assert all(item.shopping_url and "walmart.com/search" in item.shopping_url for item in plan.grocery_list)


def test_check_in_response_adjusts_for_low_energy_and_soreness():
    payload = CheckInRequest(
        athlete_id="athlete-3",
        current_weight_lbs=172,
        previous_weight_lbs=175,
        days_to_weigh_in=4,
        energy_level="low",
        soreness_level=8,
        hunger_level=6,
    )

    response = service.check_in(payload)

    assert response.adjustments["calorie_adjustment"] >= 200
    assert response.adjustments["hydration_adjustment_oz"] >= 16
    assert any("recovery" in note.lower() or "rehydrate" in note.lower() for note in response.adjustments["notes"])
    assert any(w.code == "fast_drop" for w in response.warnings)
