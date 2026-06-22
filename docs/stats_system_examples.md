# WrestleTech Stats System

## Backend files

- `app/models/stats.py`
- `app/schemas/stats.py`
- `app/services/stats_service.py`
- `app/routers/stats.py`
- `alembic/versions/20260415_0008_stats_match_tracking.py`

## Example payloads

### `POST /api/v1/matches`

```json
{
  "athlete_id": 14,
  "team_id": 3,
  "opponent_name": "Jace Miller",
  "opponent_school": "North Ridge",
  "event_name": "County Duals",
  "match_date": "2026-01-18",
  "weight_class": "132",
  "result": "win",
  "result_type": "major_decision",
  "score_for": 12,
  "score_against": 4,
  "pin_time": null,
  "notes": "Controlled ties and finished clean on re-attacks."
}
```

### `POST /api/v1/matches/{match_id}/stats`

```json
{
  "takedowns": 4,
  "escapes": 2,
  "reversals": 1,
  "nearfall_points": 3,
  "stall_calls": 1,
  "ride_time_seconds": 78,
  "shot_attempts": 9,
  "shot_conversions": 4
}
```

### `PATCH /api/v1/matches/{match_id}`

```json
{
  "result_type": "pin",
  "pin_time": "3:41",
  "notes": "Corrected after film review."
}
```

## Curl examples

```bash
curl -X POST http://localhost:8000/api/v1/matches \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "athlete_id": 14,
    "team_id": 3,
    "opponent_name": "Jace Miller",
    "opponent_school": "North Ridge",
    "event_name": "County Duals",
    "match_date": "2026-01-18",
    "weight_class": "132",
    "result": "win",
    "result_type": "major_decision",
    "score_for": 12,
    "score_against": 4
  }'
```

```bash
curl http://localhost:8000/api/v1/stats/athlete/14?team_id=3 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

```bash
curl http://localhost:8000/api/v1/stats/team/3 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Visibility rules

- Coaches and assistant coaches can create, edit, and view all team-wide match history and dashboards.
- Athletes can only access their own athlete-specific history and stats endpoints.
- Parents can only access athlete-specific stats when they have an active `ParentLink` to that athlete on the same team.
- All match and stat edits write a simple audit row in `stat_audit_logs` with before/after payloads for correction history.
