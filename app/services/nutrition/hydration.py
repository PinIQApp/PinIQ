from __future__ import annotations

from app.models.nutrition import NutritionPlanRequest, PracticeWindow, TrainingPhase


def build_hydration_plan(payload: NutritionPlanRequest, water_oz: int) -> dict:
    practice_bonus = 20 if payload.practice_window != PracticeWindow.NONE else 0
    total_target = water_oz + practice_bonus
    practice_before = 16 if payload.practice_window != PracticeWindow.NONE else 0
    practice_during = 12 if payload.practice_window != PracticeWindow.NONE else 0
    practice_after = 20 if payload.practice_window != PracticeWindow.NONE else 0
    electrolytes = payload.training_phase in {TrainingPhase.INSEASON, TrainingPhase.TOURNAMENT_WEEK} or payload.matches_this_week > 0

    return {
        "daily_target_oz": total_target,
        "daily_water_oz_target": total_target,
        "baseline_schedule": {
            "morning": round(total_target * 0.3),
            "midday": round(total_target * 0.3),
            "afternoon_evening": round(total_target * 0.4),
        },
        "practice": {
            "before_oz": practice_before,
            "during_oz": practice_during,
            "after_oz": practice_after,
        },
        "before_practice_oz": practice_before,
        "during_practice_oz": practice_during,
        "post_practice_oz": practice_after,
        "electrolytes": electrolytes,
        "electrolyte_note": "Include an electrolyte beverage during and after practice to support sweat losses."
            if electrolytes
            else "No extra electrolyte beverage is needed for this plan unless symptoms appear.",
    }
