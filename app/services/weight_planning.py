from __future__ import annotations

from dataclasses import dataclass
from datetime import date, datetime, timedelta
from math import ceil

from app.models.weight import WeightAlertType, WeightPlanStatus


HIGH_SCHOOL_WEIGHT_CLASSES = [106, 113, 120, 126, 132, 138, 144, 150, 157, 165, 175, 190, 215, 285]


@dataclass(frozen=True)
class WeightPlanningPolicy:
    max_weekly_loss_percent: float = 0.015
    max_weekly_loss_lbs_cap: float = 2.5
    minimum_days_between_logs_before_alert: int = 4
    stale_logs_red_after_days: int = 7
    caution_weigh_in_window_days: int = 7
    off_target_margin_lbs: float = 1.5
    minimum_body_fat_percent: float = 7.0
    caution_pace_ratio: float = 0.9
    red_pace_ratio: float = 1.1


POLICY = WeightPlanningPolicy()


def _round_weight(value: float) -> float:
    return round(value, 1)


def _resolve_reachable_class(projected_weight: float) -> float:
    for weight_class in HIGH_SCHOOL_WEIGHT_CLASSES:
        if projected_weight <= weight_class:
            return float(weight_class)
    return float(HIGH_SCHOOL_WEIGHT_CLASSES[-1])


def calculate_plan(
    *,
    current_weight: float,
    body_fat_percentage: float | None,
    target_weight_class: float,
    target_date: date,
    as_of: datetime | None = None,
    policy: WeightPlanningPolicy = POLICY,
) -> dict:
    as_of = as_of or datetime.utcnow()
    days_until_target = max((target_date - as_of.date()).days, 0)
    weeks_until_target = max(days_until_target / 7, 1 / 7)
    weekly_allowed_loss = min(current_weight * policy.max_weekly_loss_percent, policy.max_weekly_loss_lbs_cap)
    required_weekly_loss = max(current_weight - target_weight_class, 0) / weeks_until_target
    safe_loss_budget = weekly_allowed_loss * weeks_until_target

    minimum_safe_weight = 0.0
    if body_fat_percentage is not None:
        lean_mass = current_weight * (1 - (body_fat_percentage / 100))
        minimum_safe_weight = lean_mass / (1 - (policy.minimum_body_fat_percent / 100))

    projected_reachable_weight = max(current_weight - safe_loss_budget, minimum_safe_weight or 0.0)
    projected_reachable_weight = _round_weight(projected_reachable_weight)
    pace_ratio = required_weekly_loss / weekly_allowed_loss if weekly_allowed_loss > 0 else float("inf")
    reachable_class = _resolve_reachable_class(projected_reachable_weight)
    weeks_needed = max(current_weight - target_weight_class, 0) / weekly_allowed_loss if weekly_allowed_loss else 0
    projected_target_date = as_of.date() + timedelta(days=ceil(weeks_needed * 7))

    warnings: list[str] = []
    status = WeightPlanStatus.green

    if body_fat_percentage is not None and target_weight_class < minimum_safe_weight:
        warnings.append(
            "Target class falls below the planning floor based on the reported body-fat percentage."
        )
        status = WeightPlanStatus.red

    if target_weight_class < projected_reachable_weight:
        warnings.append(
            "Target class is not projected to be safely reachable by the requested weigh-in date."
        )
        status = WeightPlanStatus.red

    if pace_ratio > policy.red_pace_ratio:
        warnings.append("Required weekly drop is above the configured safe planning pace.")
        status = WeightPlanStatus.red
    elif pace_ratio > policy.caution_pace_ratio and status != WeightPlanStatus.red:
        warnings.append("Required pace is close to the current weekly planning limit.")
        status = WeightPlanStatus.yellow

    if days_until_target <= policy.caution_weigh_in_window_days and status == WeightPlanStatus.green:
        warnings.append("Weigh-in date is close, so daily logging consistency matters more.")
        status = WeightPlanStatus.yellow

    summary = {
        WeightPlanStatus.green: "On track for the selected class within the current planning rules.",
        WeightPlanStatus.yellow: "Needs attention, but the target may still be manageable with consistent logging.",
        WeightPlanStatus.red: "Target is outside the current safe planning rules and should be reviewed by staff.",
    }[status]

    return {
        "current_weight": _round_weight(current_weight),
        "body_fat_percentage": body_fat_percentage,
        "target_weight_class": _round_weight(target_weight_class),
        "target_date": target_date,
        "weekly_allowed_loss": _round_weight(weekly_allowed_loss),
        "required_weekly_loss": _round_weight(required_weekly_loss),
        "projected_reachable_weight": projected_reachable_weight,
        "estimated_reachable_class": _round_weight(reachable_class),
        "projected_target_date": projected_target_date,
        "status": status,
        "warning_message": " ".join(warnings) if warnings else None,
        "summary": summary,
        "plan_details": {
            "days_until_target": days_until_target,
            "pace_ratio": round(pace_ratio, 2),
            "minimum_safe_weight": _round_weight(minimum_safe_weight) if minimum_safe_weight else None,
            "weight_classes": HIGH_SCHOOL_WEIGHT_CLASSES,
            "warnings": warnings,
            "disclaimer": (
                "Planning tool for education and team visibility only. "
                "It does not replace school policy or medical guidance."
            ),
        },
    }


def build_alert_payloads(
    *,
    athlete_name: str,
    latest_log_at: datetime | None,
    latest_weight: float | None,
    plan: dict | None,
    as_of: datetime | None = None,
    policy: WeightPlanningPolicy = POLICY,
) -> list[dict]:
    as_of = as_of or datetime.utcnow()
    alerts: list[dict] = []

    if latest_log_at is None or (as_of - latest_log_at).days >= policy.minimum_days_between_logs_before_alert:
        severity = (
            WeightPlanStatus.red
            if latest_log_at is None or (as_of - latest_log_at).days >= policy.stale_logs_red_after_days
            else WeightPlanStatus.yellow
        )
        message = (
            f"{athlete_name} does not have a recent weight log."
            if latest_log_at is None
            else f"{athlete_name} has not logged weight since {latest_log_at.date().isoformat()}."
        )
        alerts.append(
            {
                "alert_type": WeightAlertType.missing_logs,
                "alert_message": message,
                "severity": severity,
            }
        )

    if plan:
        if plan["status"] == WeightPlanStatus.red:
            alerts.append(
                {
                    "alert_type": WeightAlertType.unsafe_cut_pace,
                    "alert_message": f"{athlete_name}'s current target is beyond the configured safe descent pace.",
                    "severity": WeightPlanStatus.red,
                }
            )

        days_until_target = int(plan["plan_details"].get("days_until_target", 0))
        if days_until_target <= policy.caution_weigh_in_window_days:
            alerts.append(
                {
                    "alert_type": WeightAlertType.approaching_weigh_in,
                    "alert_message": f"{athlete_name} is within {policy.caution_weigh_in_window_days} days of weigh-in.",
                    "severity": WeightPlanStatus.yellow,
                }
            )

        if latest_log_at and latest_weight is not None:
            elapsed_days = max((as_of.date() - plan["calculated_at"].date()).days, 0)
            elapsed_weeks = elapsed_days / 7
            expected_weight = max(
                plan["current_weight"] - (plan["weekly_allowed_loss"] * elapsed_weeks),
                plan["target_weight_class"],
            )
            if latest_weight > expected_weight + policy.off_target_margin_lbs:
                alerts.append(
                    {
                        "alert_type": WeightAlertType.off_target,
                        "alert_message": f"{athlete_name} is above the projected pace for the current plan.",
                        "severity": WeightPlanStatus.yellow if plan["status"] != WeightPlanStatus.red else WeightPlanStatus.red,
                    }
                )

    deduped: dict[tuple[str, str], dict] = {}
    for alert in alerts:
        key = (alert["alert_type"].value, alert["alert_message"])
        deduped[key] = alert
    return list(deduped.values())
