# WrestleTech Weight Tracking API Examples

These examples are for planning, education, and school visibility workflows. They are not medical advice.

## Create weight log

```bash
curl -X POST http://localhost:8000/api/v1/weights/log \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "athlete_id": 12,
    "team_id": 3,
    "logged_at": "2026-04-14T06:45:00",
    "weight": 154.2,
    "body_fat_percentage": 10.5,
    "hydration_note": "Hydrated after morning lift",
    "comments": "Felt strong, no concerns."
  }'
```

## Get athlete history

```bash
curl "http://localhost:8000/api/v1/weights/history/12?team_id=3" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Calculate plan

```bash
curl -X POST http://localhost:8000/api/v1/weights/plan/calculate \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "athlete_id": 12,
    "team_id": 3,
    "current_weight": 154.2,
    "body_fat_percentage": 10.5,
    "target_weight_class": 150,
    "target_date": "2026-05-10"
  }'
```

## Get athlete plan

```bash
curl "http://localhost:8000/api/v1/weights/plan/12?team_id=3" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Get team dashboard

```bash
curl "http://localhost:8000/api/v1/weights/team-dashboard/3?group=Varsity&grade=11&weight_class=150" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Get team alerts

```bash
curl "http://localhost:8000/api/v1/weights/alerts/3" \
  -H "Authorization: Bearer YOUR_TOKEN"
```
