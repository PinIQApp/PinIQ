from __future__ import annotations

from app.core.config import settings
from app.models.nutrition import CheckInRequest, CheckInResponse, NutritionPlanRequest, NutritionPlanResponse
from app.services.nutrition.engine import estimate_daily_macros
from app.services.nutrition.grocery import build_grocery_list
from app.services.nutrition.hydration import build_hydration_plan
from app.services.nutrition.planner import build_weekly_plan
from app.services.nutrition.provider_fitchef import FitChefNutritionProvider
from app.services.nutrition.provider_mock import MockNutritionProvider
from app.services.nutrition.safety import (
    build_checkin_response,
    build_plan_warnings,
    build_weigh_in_strategy,
)


class NutritionService:
    def __init__(self) -> None:
        self.provider = (
            FitChefNutritionProvider() if settings.nutrition_provider.lower() == "fitchef" else MockNutritionProvider()
        )

    def create_plan(self, payload: NutritionPlanRequest) -> NutritionPlanResponse:
        macros = estimate_daily_macros(payload)
        weekly_plan = build_weekly_plan(payload, macros)
        grocery_list = build_grocery_list(weekly_plan)
        hydration_plan = build_hydration_plan(payload, macros.water_oz)
        weigh_in_strategy = build_weigh_in_strategy(payload)
        warnings = build_plan_warnings(payload)

        provider_status = self.provider.create_plan(
            payload,
            {
                "calories": macros.calories,
                "protein_g": macros.protein_g,
                "carbs_g": macros.carbs_g,
                "fats_g": macros.fats_g,
            },
        )

        return NutritionPlanResponse(
            athlete_summary={
                "athlete_id": payload.athlete_id,
                "name": payload.name,
                "age": payload.age,
                "goal": payload.goal.value,
                "current_weight_lbs": payload.weight_lbs,
                "target_weight_lbs": payload.target_weight_lbs,
                "training_phase": payload.training_phase.value,
            },
            macros=macros,
            weekly_plan=weekly_plan,
            grocery_list=grocery_list,
            hydration_plan=hydration_plan,
            weigh_in_strategy=weigh_in_strategy,
            warnings=warnings,
            provider_status=provider_status,
        )

    def check_in(self, payload: CheckInRequest) -> CheckInResponse:
        adjustments, warnings = build_checkin_response(payload)
        return CheckInResponse(adjustments=adjustments, warnings=warnings)
