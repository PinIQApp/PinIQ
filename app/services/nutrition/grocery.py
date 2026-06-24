from __future__ import annotations

from collections import Counter
from urllib.parse import quote_plus

from app.models.nutrition import DailyMacros, DailyPlan, GroceryItem, NutritionPlanRequest


CATEGORY_MAP = {
    "berries": "produce",
    "berry": "produce",
    "banana": "produce",
    "apple": "produce",
    "broccoli": "produce",
    "vegetables": "produce",
    "asparagus": "produce",
    "carrots": "produce",
    "salad": "produce",
    "green beans": "produce",
    "sweet potato": "produce",
    "fruit": "produce",
    "greek yogurt": "dairy",
    "yogurt": "dairy",
    "string cheese": "dairy",
    "cottage cheese": "dairy",
    "egg whites": "protein",
    "egg scramble": "protein",
    "grilled chicken": "protein",
    "chicken rice bowl": "protein",
    "chicken wraps": "protein",
    "lean taco bowls": "protein",
    "ground turkey": "protein",
    "turkey sandwich": "protein",
    "salmon": "protein",
    "protein shake": "protein",
    "protein bar": "protein",
    "rice": "pantry",
    "oatmeal": "pantry",
    "granola": "pantry",
    "toast": "bakery",
    "pretzels": "pantry",
    "pasta": "pantry",
    "meat sauce": "pantry",
    "black beans": "pantry",
    "beans": "pantry",
    "peanut butter": "pantry",
}

WALMART_PRICE_ESTIMATES = {
    "apple": (0.82, "fresh apples"),
    "asparagus": (3.98, "fresh asparagus"),
    "bagel": (0.62, "plain bagels"),
    "banana": (0.27, "fresh bananas"),
    "bean": (0.32, "canned beans"),
    "berry": (1.25, "frozen mixed berries"),
    "black bean": (0.32, "canned black beans"),
    "broccoli": (0.82, "frozen broccoli"),
    "carrot": (0.34, "baby carrots"),
    "chicken rice bowl": (2.25, "chicken breast rice"),
    "chicken wrap": (1.95, "chicken wraps"),
    "cottage cheese": (0.78, "cottage cheese"),
    "egg scramble": (0.58, "eggs"),
    "egg white": (0.64, "liquid egg whites"),
    "fruit": (0.78, "fresh fruit"),
    "granola": (0.68, "granola"),
    "greek yogurt": (0.92, "plain greek yogurt"),
    "green bean": (0.62, "frozen green beans"),
    "grilled chicken": (1.95, "boneless skinless chicken breast"),
    "ground turkey": (1.55, "ground turkey"),
    "lean taco bowl": (2.15, "ground turkey rice beans"),
    "oatmeal": (0.32, "old fashioned oats"),
    "pasta": (0.36, "pasta"),
    "peanut butter": (0.22, "peanut butter"),
    "pretzel": (0.28, "pretzels"),
    "protein bar": (1.38, "protein bars"),
    "protein shake": (1.58, "protein shakes"),
    "rice": (0.24, "long grain white rice"),
    "salad": (0.98, "salad mix"),
    "salmon": (3.35, "salmon fillets"),
    "string cheese": (0.42, "string cheese"),
    "sweet potato": (0.54, "sweet potatoes"),
    "toast": (0.22, "whole wheat bread"),
    "turkey sandwich": (1.65, "deli turkey whole wheat bread"),
    "vegetable": (0.72, "frozen vegetables"),
    "yogurt": (0.68, "yogurt"),
}


def _normalize_item(food: str) -> str:
    cleaned = food.strip().lower()
    if cleaned.endswith("ies"):
        return cleaned[:-3] + "y"
    if cleaned.endswith("s") and not cleaned.endswith("ss"):
        return cleaned[:-1]
    return cleaned


def _serving_count(quantity: str) -> int:
    for token in quantity.split():
        if token.isdigit():
            return max(1, min(int(token), 21))
    return 1


def _portion_multiplier(payload: NutritionPlanRequest, macros: DailyMacros) -> float:
    weight = payload.weight_lbs
    multiplier = 1.0
    if weight < 115:
        multiplier = 0.8
    elif weight < 145:
        multiplier = 0.9
    elif weight < 185:
        multiplier = 1.0
    elif weight < 225:
        multiplier = 1.15
    else:
        multiplier = 1.3

    if macros.calories >= 3200:
        multiplier += 0.1
    elif macros.calories <= 2100:
        multiplier -= 0.05

    return round(max(0.75, min(multiplier, 1.45)), 2)


def _quantity_description(count: int, portion_multiplier: float) -> str:
    size_label = (
        "small athlete"
        if portion_multiplier < 0.9
        else "light athlete"
        if portion_multiplier < 1
        else "standard athlete"
        if portion_multiplier <= 1.05
        else "large athlete"
        if portion_multiplier <= 1.2
        else "heavyweight athlete"
    )
    if count == 1:
        return f"1 {size_label} serving"
    if count <= 4:
        return f"{count} {size_label} servings"
    return f"{count} {size_label} servings (weekly)"


def _serving_size_note(food: str, portion_multiplier: float) -> str:
    def scaled(base: float) -> str:
        value = base * portion_multiplier
        if value < 1:
            return f"{value:.1f}".rstrip("0").rstrip(".")
        return f"{value:.1f}".rstrip("0").rstrip(".")

    if any(token in food for token in ["chicken", "turkey", "salmon", "tuna", "beef"]):
        return f"Plan about {scaled(5)} oz cooked protein per athlete serving."
    if any(token in food for token in ["rice", "pasta", "oatmeal", "bean"]):
        return f"Plan about {scaled(1)} cup cooked carbs per athlete serving."
    if any(token in food for token in ["yogurt", "cottage cheese"]):
        return f"Plan about {scaled(1)} cup per athlete serving."
    if any(token in food for token in ["banana", "apple", "fruit"]):
        return "Plan 1 piece or 1 cup fruit per athlete serving."
    if any(token in food for token in ["broccoli", "vegetable", "asparagus", "green bean", "salad", "carrot"]):
        return f"Plan about {scaled(1.5)} cups vegetables per athlete serving."
    if "peanut butter" in food:
        return f"Plan about {scaled(2)} tbsp per athlete serving."
    if "protein" in food:
        return "Plan 1 bar/shake per athlete serving unless the coach adjusts macros."
    return f"Portion target is {portion_multiplier}x the standard athlete serving."


def _price_estimate(food: str, quantity: str, portion_multiplier: float) -> tuple[float, float, str]:
    unit_price, shopping_query = WALMART_PRICE_ESTIMATES.get(
        food,
        (0.95, food),
    )
    total = min(unit_price * _serving_count(quantity) * portion_multiplier, 80)
    return round(unit_price, 2), round(total, 2), shopping_query


def build_grocery_list(
    weekly_plan: list[DailyPlan],
    *,
    payload: NutritionPlanRequest,
    macros: DailyMacros,
) -> list[GroceryItem]:
    counter: Counter[str] = Counter()
    portion_multiplier = _portion_multiplier(payload, macros)
    for day in weekly_plan:
        for meal in day.meals:
            for food in meal.foods:
                counter[_normalize_item(food)] += 1

    groceries: list[GroceryItem] = []
    for food, count in sorted(counter.items()):
        quantity = _quantity_description(count, portion_multiplier)
        unit_price, total_price, shopping_query = _price_estimate(food, quantity, portion_multiplier)
        groceries.append(
            GroceryItem(
                item=food.title(),
                quantity=quantity,
                category=CATEGORY_MAP.get(food, "general"),
                estimated_unit_price=unit_price,
                estimated_total_price=total_price,
                price_source="Walmart planning estimate",
                serving_size_note=_serving_size_note(food, portion_multiplier),
                shopping_query=shopping_query,
                shopping_url=f"https://www.walmart.com/search?q={quote_plus(shopping_query)}",
            )
        )
    return groceries
