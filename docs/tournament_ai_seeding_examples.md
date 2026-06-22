# Wrestling OS Tournament + AI Seeding Examples

## Create Tournament

```bash
curl -X POST http://localhost:8000/api/v1/tournaments \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "River City Invitational",
    "host_team_id": 1,
    "event_type": "bracket_style_event",
    "start_date": "2026-12-12",
    "end_date": "2026-12-13",
    "location": "River City Fieldhouse",
    "notes": "Varsity + JV divisions. Weigh-ins start at 7:00 AM.",
    "is_public": false,
    "divisions": [
      {
        "name": "Varsity",
        "min_weight_class": "106",
        "max_weight_class": "285",
        "notes": "Top bracket"
      },
      {
        "name": "JV",
        "min_weight_class": "106",
        "max_weight_class": "215",
        "notes": "Development bracket"
      }
    ],
    "teams": [
      {"team_id": 1, "notes": "Host"},
      {"team_id": 2, "notes": "Confirmed"},
      {"team_id": 3, "notes": "Confirmed"}
    ]
  }'
```

## Add Entry

```bash
curl -X POST http://localhost:8000/api/v1/tournaments/1/entries \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "team_id": 2,
    "athlete_id": 14,
    "division_name": "Varsity",
    "weight_class": "126",
    "entry_status": "entered",
    "notes": "Certified at 126. Backup available."
  }'
```

## Scratch / Replace / Late Update

```bash
curl -X PATCH http://localhost:8000/api/v1/tournaments/entries/9 \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "athlete_id": 21,
    "entry_status": "replaced",
    "notes": "Starter scratched after skin check, backup entered."
  }'
```

## Calculate Seeds

```bash
curl -X POST http://localhost:8000/api/v1/seeding/calculate/1 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Fetch Seeds for a Weight Class

```bash
curl http://localhost:8000/api/v1/seeding/1/126 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Manual Override with Audit Trail

```bash
curl -X POST http://localhost:8000/api/v1/seeding/override \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "tournament_id": 1,
    "entry_id": 9,
    "seed_number": 2,
    "override_reason": "State qualifier with late-entered results not yet reflected in season snapshot."
  }'
```

## Generate Bracket

```bash
curl -X POST http://localhost:8000/api/v1/brackets/generate/1/126 \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "division_name": "Varsity",
    "bracket_type": "8_man",
    "finalize_now": true,
    "publish_now": false
  }'
```

## Update Match Advancement

```bash
curl -X PATCH http://localhost:8000/api/v1/brackets/matches/18 \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "winner_entry_id": 9,
    "match_status": "completed",
    "result_summary": "Fall 1:42",
    "mat_label": "Mat 2"
  }'
```

## Permission Rules

- `coach` / `assistant_coach`: can view assigned tournaments, review entries, and manage entries for their own team.
- `tournament director`: represented by `director_user_id` on the tournament; can edit the tournament, run AI seeding, override seeds, finalize brackets, and publish.
- `admin`: full system access.
- `athlete`: cannot view entries or seeding review; can only view finalized or published brackets.
- `parent`: can only view finalized or published brackets for linked athletes.

## Suggested Test Flow

1. Create tournament with 2-4 teams and at least one division.
2. Enter 4, 8, or 16 athletes into the same weight class.
3. Run `POST /seeding/calculate/{tournament_id}` and confirm each entry receives a seed number and explanation.
4. Submit one manual override and verify `GET /seeding/explanations/{tournament_id}/{weight_class}` returns the audit history.
5. Generate a bracket and verify the bracket preview pairs seeds correctly.
6. Update a completed match and confirm the winner advances into the next match slot.
