from __future__ import annotations

from app.models.nutrition import NutritionPlanRequest
from app.services.nutrition.provider_base import NutritionProvider


class MockNutritionProvider(NutritionProvider):
    def create_plan(self, payload: NutritionPlanRequest, plan_summary: dict) -> dict | None:
        if not payload.include_provider_plan:
            return {"provider": "mock", "requested": False, "status": "skipped"}

        return {
            "provider": "mock",
            "requested": True,
            "status": "ready",
            "external_plan_id": f"mock-{payload.athlete_id or 'athlete'}",
            "summary": {
                "calories": plan_summary["calories"],
                "meals_per_day": payload.meals_per_day,
                "notes": "Mock provider response generated locally.",
            },
        }
