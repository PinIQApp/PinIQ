from __future__ import annotations

from abc import ABC, abstractmethod

from app.models.nutrition import NutritionPlanRequest


class NutritionProvider(ABC):
    @abstractmethod
    def create_plan(self, payload: NutritionPlanRequest, plan_summary: dict) -> dict | None:
        raise NotImplementedError
