from __future__ import annotations

import json
from urllib import error, request

from app.core.config import settings
from app.models.nutrition import NutritionPlanRequest
from app.services.nutrition.provider_base import NutritionProvider


class FitChefNutritionProvider(NutritionProvider):
    def create_plan(self, payload: NutritionPlanRequest, plan_summary: dict) -> dict | None:
        if not payload.include_provider_plan:
            return {"provider": "fitchef", "requested": False, "status": "skipped"}

        if not settings.fitchef_api_base or not settings.fitchef_api_key:
            return {
                "provider": "fitchef",
                "requested": True,
                "status": "unconfigured",
                "message": "FitChef provider is not configured.",
            }

        provider_payload = {
            "athlete_id": payload.athlete_id,
            "name": payload.name,
            "goal": payload.goal.value,
            "diet_tags": payload.diet_tags,
            "allergies": payload.allergies,
            "excluded_ingredients": payload.excluded_ingredients,
            "targets": plan_summary,
        }
        body = json.dumps(provider_payload).encode("utf-8")
        api_request = request.Request(
            url=f"{settings.fitchef_api_base.rstrip('/')}/plans",
            data=body,
            method="POST",
            headers={
                "Authorization": f"Bearer {settings.fitchef_api_key}",
                "Content-Type": "application/json",
            },
        )

        try:
            with request.urlopen(api_request, timeout=8) as response:
                response_payload = json.loads(response.read().decode("utf-8"))
            return {
                "provider": "fitchef",
                "requested": True,
                "status": "ready",
                "response": response_payload,
            }
        except error.HTTPError as exc:
            return {
                "provider": "fitchef",
                "requested": True,
                "status": "error",
                "message": f"FitChef HTTP error: {exc.code}",
            }
        except error.URLError as exc:
            return {
                "provider": "fitchef",
                "requested": True,
                "status": "error",
                "message": f"FitChef connection error: {exc.reason}",
            }
