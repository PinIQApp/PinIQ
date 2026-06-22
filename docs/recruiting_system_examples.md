# Wrestling OS Recruiting System Examples

## Example Create Profile Payload

```json
{
  "athlete_id": 2,
  "team_id": 1,
  "graduation_year": 2027,
  "school_team": "Riverdale High Varsity",
  "weight_class": "144 lbs",
  "height": "5'8\"",
  "gpa": "3.7",
  "bio": "Fast neutral wrestler with strong re-attacks and late-match pressure.",
  "achievements": [
    "Section finalist",
    "2x captain",
    "38-11 last season"
  ],
  "contact_email": "family.reed@wrestlingos.com",
  "contact_phone": "555-1102",
  "location_label": "Riverdale, NY",
  "stats_summary": {
    "takedowns_per_match": 2.7,
    "shot_conversion_rate": 0.47
  },
  "profile_image_url": "https://placehold.co/400x400/png?text=Tyson+Reed",
  "is_open": true,
  "is_actively_looking": true,
  "is_featured": false,
  "boost_requested": false,
  "visibility_level": "coaches_only",
  "contact_visibility": "coaches_only",
  "visibility": {
    "show_contact_to_coaches": true,
    "show_gpa": true,
    "show_location": true,
    "show_profile_photo": true,
    "parent_visibility_required": true,
    "allow_direct_contact_request": true
  },
  "highlights": [
    {
      "title": "Section run film",
      "highlight_url": "https://www.youtube.com/watch?v=reed_section_run",
      "sort_order": 0
    },
    {
      "title": "Ride-and-turn breakdown",
      "highlight_url": "https://www.youtube.com/watch?v=reed_top_work",
      "sort_order": 1
    }
  ]
}
```

## Example Update Payload

```json
{
  "bio": "Updated bio with stronger college fit summary.",
  "is_actively_looking": true,
  "boost_requested": true,
  "visibility": {
    "show_contact_to_coaches": true,
    "show_gpa": false,
    "show_location": true,
    "show_profile_photo": true,
    "parent_visibility_required": true,
    "allow_direct_contact_request": true
  },
  "highlights": [
    {
      "title": "Senior season film",
      "highlight_url": "https://www.youtube.com/watch?v=new_clip",
      "sort_order": 0
    }
  ]
}
```

## Curl Examples

Create profile:

```bash
curl -X POST http://localhost:8000/api/v1/recruiting/profile \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d @create_profile.json
```

Update profile:

```bash
curl -X PATCH http://localhost:8000/api/v1/recruiting/profile/2 \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d @update_profile.json
```

Search athletes:

```bash
curl "http://localhost:8000/api/v1/recruiting/search?weight_class=144%20lbs&graduation_year=2027&min_win_percentage=0.6&is_open=true" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

View recruiting board:

```bash
curl http://localhost:8000/api/v1/recruiting/board \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Save athlete to watchlist:

```bash
curl -X POST http://localhost:8000/api/v1/recruiting/watchlist \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "coach_id": 1,
    "athlete_id": 5,
    "tag_labels": ["Top Priority", "Strong Top Game"]
  }'
```

Save private recruiting note:

```bash
curl -X POST http://localhost:8000/api/v1/recruiting/notes \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "coach_id": 1,
    "athlete_id": 5,
    "note": "High motor and strong mat returns. Re-evaluate after next qualifier.",
    "tag_labels": ["Follow Up", "Regional Target"]
  }'
```

Trending athletes:

```bash
curl "http://localhost:8000/api/v1/recruiting/trending?limit=8" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Permission Model

- Athletes can create and edit their own recruiting profile.
- Linked parents can also edit the athlete profile and always see full contact details for their athlete.
- Coaches and assistant coaches can search, view eligible profiles, save athletes, build watchlists, and store private notes and tags.
- Public users are blocked from `coaches_only` and `private` profiles and never receive direct contact data.
- `parent_visibility_required` keeps coach outreach compliant by requiring the Chat 2 messaging workflow instead of direct unrestricted contact.
- Contact visibility is separated from profile visibility, so a coach can view a full profile while direct athlete contact remains hidden.
