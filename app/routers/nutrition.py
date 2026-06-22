from __future__ import annotations

from fastapi import APIRouter, Depends

from app.models.nutrition import CheckInRequest, CheckInResponse, NutritionPlanRequest, NutritionPlanResponse
from app.routers.deps import get_current_user
from app.services.nutrition import NutritionService


router = APIRouter(prefix="/nutrition", tags=["nutrition"])
service = NutritionService()


@router.post("/plan", response_model=NutritionPlanResponse)
def create_nutrition_plan(
    payload: NutritionPlanRequest,
    current_user=Depends(get_current_user),
):
    return service.create_plan(payload)


@router.post("/check-in", response_model=CheckInResponse)
def nutrition_check_in(
    payload: CheckInRequest,
    current_user=Depends(get_current_user),
):
    return service.check_in(payload)
