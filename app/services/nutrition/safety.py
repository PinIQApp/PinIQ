from __future__ import annotations

from app.core.config import settings
from app.models.nutrition import CheckInRequest, Goal, NutritionPlanRequest, NutritionWarning


def _weekly_loss_rate(payload: NutritionPlanRequest, pounds_to_lose: float) -> float | None:
    if payload.days_to_weigh_in is None or payload.days_to_weigh_in <= 0:
        return None
    return pounds_to_lose / max(payload.days_to_weigh_in / 7, 1)


def _low_body_fat_cut(payload: NutritionPlanRequest) -> bool:
    if payload.body_fat_percent is None:
        return False
    if payload.sex.value == "female":
        return payload.body_fat_percent < 14
    return payload.body_fat_percent < 8


def build_plan_warnings(payload: NutritionPlanRequest) -> list[NutritionWarning]:
    warnings: list[NutritionWarning] = []

    if payload.goal == Goal.CUT and payload.target_weight_lbs is not None:
        pounds_to_lose = payload.weight_lbs - payload.target_weight_lbs
        weekly_rate = _weekly_loss_rate(payload, pounds_to_lose)
        low_body_fat = _low_body_fat_cut(payload)
        if pounds_to_lose >= 8:
            severity = "warning"
            if low_body_fat or weekly_rate is None or weekly_rate > 1.5:
                severity = "high" if settings.enable_strict_wrestler_safety else "warning"
            elif weekly_rate <= 1.25:
                severity = "info"
            warnings.append(
                NutritionWarning(
                    code="aggressive_cut",
                    severity=severity,
                    message=(
                        "Requested cut should be monitored with body-fat, hydration, and performance checks."
                        if severity != "high"
                        else "Requested cut is aggressive for a youth athlete and should be supervised by a qualified professional."
                    ),
                )
            )
        if weekly_rate is not None:
            if weekly_rate > 1.5:
                warnings.append(
                    NutritionWarning(
                        code="rapid_weight_loss",
                        severity="high",
                        message="Planned rate of loss exceeds conservative wrestling guidance. Slow the cut and prioritize performance.",
                    )
                )
            elif weekly_rate <= 1.25 and not low_body_fat:
                warnings.append(
                    NutritionWarning(
                        code="steady_cut_pace",
                        severity="info",
                        message="Planned loss is near 1 lb/week. Continue monitoring hydration, energy, and body composition.",
                    )
                )

        if low_body_fat:
            warnings.append(
                NutritionWarning(
                    code="low_body_fat_cut",
                    severity="high",
                    message="Reported body-fat percentage is low for an additional cut. Require staff and medical review before reducing weight.",
                )
            )

    if payload.days_to_weigh_in is not None and payload.days_to_weigh_in <= 3:
        warnings.append(
            NutritionWarning(
                code="short_weigh_in_window",
                severity="warning",
                message="Avoid crash cutting in the final 72 hours. Emphasize hydration, low-residue meals, and recovery.",
            )
        )

    if payload.age < 14 and payload.goal == Goal.CUT:
        warnings.append(
            NutritionWarning(
                code="younger_athlete_cut",
                severity="high",
                message="Weight-loss plans for younger athletes should be reviewed closely by guardians and medical staff.",
            )
        )

    if payload.matches_this_week >= 3:
        warnings.append(
            NutritionWarning(
                code="high_competition_load",
                severity="info",
                message="Competition load is elevated this week; recovery carbs, fluids, and sleep should be prioritized.",
            )
        )

    return warnings


def build_weigh_in_strategy(payload: NutritionPlanRequest) -> dict:
    aggressive = payload.days_to_weigh_in is not None and payload.days_to_weigh_in <= 3
    return {
        "focus": "performance_preservation" if aggressive else "steady_progress",
        "recommendations": [
            "Keep protein intake consistent across the day.",
            "Reduce restaurant and high-sodium meals during the final 48 hours before weigh-in.",
            "Use easy-to-digest carbs after practice to restore glycogen.",
            "Do not use sauna suits, severe dehydration, or prolonged fasting.",
        ],
        "final_24h": "Use low-fiber, familiar meals and maintain steady fluid intake." if aggressive else "Maintain normal fueling and check morning body weight trends only.",
    }


def build_checkin_response(payload: CheckInRequest) -> tuple[dict, list[NutritionWarning]]:
    warnings: list[NutritionWarning] = []
    adjustments = {
        "calorie_adjustment": 0,
        "carb_adjustment_g": 0,
        "hydration_adjustment_oz": 0,
        "notes": [],
    }

    if payload.previous_weight_lbs is not None:
        delta = payload.current_weight_lbs - payload.previous_weight_lbs
        if delta <= -2.5:
            warnings.append(
                NutritionWarning(
                    code="fast_drop",
                    severity="high",
                    message="Weight is dropping quickly; increase fueling and hydration, and reassess training load.",
                )
            )
            adjustments["calorie_adjustment"] += 200
            adjustments["hydration_adjustment_oz"] += 24
            adjustments["notes"].append("Add an extra snack and rehydrate aggressively.")
        elif delta >= 1.5 and payload.days_to_weigh_in is not None and payload.days_to_weigh_in <= 7:
            warnings.append(
                NutritionWarning(
                    code="off_track_for_weigh_in",
                    severity="warning",
                    message="Current trend may miss the upcoming weigh-in target without earlier consistency.",
                )
            )
            adjustments["calorie_adjustment"] -= 100
            adjustments["carb_adjustment_g"] -= 20
            adjustments["notes"].append("Tighten liquid calories and late-night snacking.")

    if payload.energy_level == "low":
        adjustments["carb_adjustment_g"] += 30
        adjustments["notes"].append("Increase pre-practice carbs to support training energy.")

    if payload.soreness_level >= 7:
        adjustments["hydration_adjustment_oz"] += 16
        adjustments["notes"].append("Emphasize post-practice protein, fluids, and sleep.")

    if payload.hunger_level >= 7:
        adjustments["calorie_adjustment"] += 150
        adjustments["notes"].append("Shift calories toward higher-volume foods with lean protein and fruit.")

    return adjustments, warnings
