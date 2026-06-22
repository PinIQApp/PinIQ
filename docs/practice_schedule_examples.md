# WrestleTech Practice + Schedule Examples

This slice covers only the practice planner and team schedule system.

## Visibility rules

- Coaches and assistant coaches with approved team membership can create, edit, duplicate, assign, and delete schedule content.
- Athletes with approved team membership can view the team calendar, practice plans linked to their team, and event details.
- Parents can view a linked athlete's team schedule when they either have approved team membership or an active `ParentLink` for that team.
- Admins can view and manage all schedule data.

## Example event payload

```json
{
  "team_id": 1,
  "title": "Riverdale vs. North Ridge",
  "description": "Home dual with full varsity lineup.",
  "event_type": "dual_meet",
  "starts_at": "2026-04-19T18:30:00Z",
  "ends_at": "2026-04-19T21:00:00Z",
  "location": "Riverdale Main Gym",
  "notes": "Lineup card due 45 minutes before first whistle.",
  "checklist": ["Singlet", "Headgear", "Warm-up gear"],
  "weigh_in_note": "Weigh-ins begin at 5:30 PM in the auxiliary locker room."
}
```

## Example practice payload

```json
{
  "team_id": 1,
  "title": "Thursday Hard Room",
  "description": "High pace varsity room focused on re-attacks and top pressure.",
  "focus": "Re-attack chains and hard mat returns",
  "practice_date": "2026-04-16",
  "notes": "Bring heart-rate straps, ankle bands, and film notebooks.",
  "blocks": [
    {
      "block_order": 1,
      "block_type": "warm_up",
      "title": "Dynamic mat warm-up",
      "duration_minutes": 12
    },
    {
      "block_order": 2,
      "block_type": "drilling",
      "title": "Re-attack finishes from ties",
      "duration_minutes": 18
    },
    {
      "block_order": 3,
      "block_type": "live_goes",
      "title": "Three hard goes",
      "duration_minutes": 24
    },
    {
      "block_order": 4,
      "block_type": "conditioning",
      "title": "Sprint ladder finisher",
      "duration_minutes": 12
    }
  ]
}
```

## Example practice template payload

```json
{
  "team_id": 1,
  "template_name": "Tournament Prep",
  "description": "Scenario-based plan for bracket readiness and mat awareness.",
  "focus": "Situations, match management, and quick resets",
  "blocks": [
    {
      "block_order": 1,
      "block_type": "warm_up",
      "title": "Activation and movement",
      "duration_minutes": 10
    },
    {
      "block_order": 2,
      "block_type": "neutral",
      "title": "First-score neutral chains",
      "duration_minutes": 16
    },
    {
      "block_order": 3,
      "block_type": "film_review",
      "title": "Opponent tendencies and reminders",
      "duration_minutes": 15
    }
  ]
}
```

## Curl examples

Replace `TOKEN` with a valid bearer token from `/api/v1/auth/login`.

```bash
curl -X POST http://localhost:8000/api/v1/events \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d @event.json
```

```bash
curl "http://localhost:8000/api/v1/events/team/1?event_type=practice" \
  -H "Authorization: Bearer TOKEN"
```

```bash
curl -X PATCH http://localhost:8000/api/v1/events/1 \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"location":"Riverdale Main Gym","notes":"Updated arrival time for staff."}'
```

```bash
curl -X DELETE http://localhost:8000/api/v1/events/1 \
  -H "Authorization: Bearer TOKEN"
```

```bash
curl -X POST http://localhost:8000/api/v1/practices \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d @practice.json
```

```bash
curl http://localhost:8000/api/v1/practices/team/1 \
  -H "Authorization: Bearer TOKEN"
```

```bash
curl http://localhost:8000/api/v1/practices/1 \
  -H "Authorization: Bearer TOKEN"
```

```bash
curl -X PATCH http://localhost:8000/api/v1/practices/1 \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"notes":"Shortened room session before dual.","focus":"Sharp finishes","blocks":[]}'
```

```bash
curl -X POST http://localhost:8000/api/v1/practice-templates \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d @template.json
```

```bash
curl http://localhost:8000/api/v1/practice-templates/team/1 \
  -H "Authorization: Bearer TOKEN"
```

```bash
curl -X POST http://localhost:8000/api/v1/practices/1/duplicate \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Thursday Hard Room Copy","practice_date":"2026-04-20"}'
```

```bash
curl -X POST http://localhost:8000/api/v1/practices/1/assign-to-date \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "target_date":"2026-04-20",
    "starts_at":"2026-04-20T16:00:00Z",
    "ends_at":"2026-04-20T17:45:00Z",
    "location":"Riverdale Wrestling Room",
    "notes":"Assigned from saved hard practice template.",
    "checklist":["Headgear","Water jug"]
  }'
```

## Suggested test cases

- Coach can create an event for a team they manage.
- Assistant coach can update an existing practice plan.
- Athlete receives `403` when attempting to `POST /events`.
- Parent with active `ParentLink` can `GET /events/team/{team_id}`.
- Parent without team membership and without `ParentLink` receives `403`.
- Assigning a practice with `ends_at <= starts_at` returns `400`.
- Creating a practice with ordered blocks stores the correct `total_duration_minutes`.
- Duplicating a practice creates a new practice id and preserves ordered blocks.
