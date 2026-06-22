from __future__ import annotations
from typing import Optional

from enum import Enum
from typing import Literal

from pydantic import BaseModel, Field, field_validator, model_validator


class Goal(str, Enum):
    CUT = "cut"
    MAINTAIN = "maintain"
    BULK = "bulk"


class Sex(str, Enum):
    MALE = "male"
    FEMALE = "female"
    OTHER = "other"


class ActivityLevel(str, Enum):
    LOW = "low"
    MODERATE = "moderate"
    HIGH = "high"
    ELITE = "elite"


class TrainingPhase(str, Enum):
    OFFSEASON = "offseason"
    PRESEASON = "preseason"
    INSEASON = "inseason"
    TOURNAMENT_WEEK = "tournament_week"


class MealTemplate(str, Enum):
    SIMPLE = "simple"
    FAMILY = "family"
    BUDGET = "budget"
    HIGH_PROTEIN = "high_protein"


class PracticeWindow(str, Enum):
    MORNING = "morning"
    AFTERNOON = "afternoon"
    EVENING = "evening"
    NONE = "none"


class NutritionPlanRequest(BaseModel):
    athlete_id: str | None = None
    name: str | None = None
    age: int = Field(..., ge=12, le=19)
    sex: Sex
    height_in: float = Field(..., gt=36, lt=96)
    weight_lbs: float = Field(..., gt=60, lt=400)
    target_weight_lbs: float | None = Field(None, gt=60, lt=400)

    body_fat_percent: float | None = Field(None, ge=3, le=60)
    goal: Goal
    activity_level: ActivityLevel
    training_phase: TrainingPhase = TrainingPhase.INSEASON
    practice_window: PracticeWindow = PracticeWindow.AFTERNOON

    days_to_weigh_in: int | None = Field(None, ge=0, le=90)
    matches_this_week: int = Field(0, ge=0, le=20)

    allergies: list[str] = Field(default_factory=list)
    dislikes: list[str] = Field(default_factory=list)
    excluded_ingredients: list[str] = Field(default_factory=list)
    diet_tags: list[str] = Field(default_factory=list)
    meal_template: MealTemplate = MealTemplate.HIGH_PROTEIN
    meals_per_day: int = Field(4, ge=3, le=6)
    snacks_per_day: int = Field(1, ge=0, le=3)

    budget_level: Literal["low", "medium", "high"] = "medium"
    include_provider_plan: bool = False

    @field_validator("allergies", "dislikes", "excluded_ingredients", "diet_tags")
    @classmethod
    def normalize_lists(cls, value: list[str]) -> list[str]:
        return sorted({item.strip().lower() for item in value if item and item.strip()})

    @model_validator(mode="after")
    def validate_target(self) -> "NutritionPlanRequest":
        if self.goal == Goal.CUT and self.target_weight_lbs is None:
            raise ValueError("target_weight_lbs is required for cut goal")
        if self.target_weight_lbs is not None and self.target_weight_lbs > self.weight_lbs and self.goal == Goal.CUT:
            raise ValueError("target_weight_lbs must be less than or equal to current weight for cut goal")
        return self


class DailyMacros(BaseModel):
    calories: int
    protein_g: int
    carbs_g: int
    fats_g: int
    fiber_g: int
    water_oz: int


class MealItem(BaseModel):
    name: str
    foods: list[str]
    approx_calories: int
    protein_g: int
    carbs_g: int
    fats_g: int
    timing_note: str | None = None


class DailyPlan(BaseModel):
    day_label: str
    meals: list[MealItem]


class GroceryItem(BaseModel):
    item: str
    quantity: str
    category: str


class NutritionWarning(BaseModel):
    code: str
    message: str
    severity: Literal["info", "warning", "high"]


class NutritionPlanResponse(BaseModel):
    athlete_summary: dict
    macros: DailyMacros
    weekly_plan: list[DailyPlan]
    grocery_list: list[GroceryItem]
    hydration_plan: dict
    weigh_in_strategy: dict
    warnings: list[NutritionWarning]
    provider_status: dict | None = None


class CheckInRequest(BaseModel):
    athlete_id: str | None = None
    current_weight_lbs: float = Field(..., gt=60, lt=400)
    previous_weight_lbs: float | None = Field(None, gt=60, lt=400)
    days_to_weigh_in: int | None = Field(None, ge=0, le=30)
    energy_level: Literal["low", "ok", "good"] = "ok"
    soreness_level: int = Field(3, ge=1, le=10)
    hunger_level: int = Field(3, ge=1, le=10)


class CheckInResponse(BaseModel):
    adjustments: dict
    warnings: list[NutritionWarning]
