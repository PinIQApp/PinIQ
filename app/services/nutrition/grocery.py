from __future__ import annotations

from collections import Counter

from app.models.nutrition import DailyPlan, GroceryItem


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


def _normalize_item(food: str) -> str:
    cleaned = food.strip().lower()
    if cleaned.endswith("ies"):
        return cleaned[:-3] + "y"
    if cleaned.endswith("s") and not cleaned.endswith("ss"):
        return cleaned[:-1]
    return cleaned


def _quantity_description(count: int) -> str:
    if count == 1:
        return "1 serving"
    if count <= 4:
        return f"{count} servings"
    return f"{count} servings (weekly)"


def build_grocery_list(weekly_plan: list[DailyPlan]) -> list[GroceryItem]:
    counter: Counter[str] = Counter()
    for day in weekly_plan:
        for meal in day.meals:
            for food in meal.foods:
                counter[_normalize_item(food)] += 1

    groceries: list[GroceryItem] = []
    for food, count in sorted(counter.items()):
        groceries.append(
            GroceryItem(
                item=food.title(),
                quantity=_quantity_description(count),
                category=CATEGORY_MAP.get(food, "general"),
            )
        )
    return groceries
