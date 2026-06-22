# Tournament Discovery API Examples

## GET `/api/v1/tournaments/discover`

Query example:

```text
/api/v1/tournaments/discover?team_id=1&search=rumble&age_group=High%20School&radius_miles=100&origin_latitude=40.9126&origin_longitude=-73.8371
```

Response shape:

```json
{
  "tournaments": [
    {
      "id": 1,
      "source_id": 2,
      "created_by_user_id": null,
      "external_id": "track-rumble-2026",
      "name": "Hudson Valley Spring Rumble",
      "start_date": "2026-04-25",
      "end_date": "2026-04-25",
      "location_name": "Hudson Valley Field House",
      "city": "Poughkeepsie",
      "state": "NY",
      "latitude": 41.7004,
      "longitude": -73.921,
      "age_divisions": ["High School Varsity", "JV"],
      "weight_classes": ["106", "113", "120", "126"],
      "event_type": "open",
      "registration_link": "https://www.trackwrestling.com/example/hudson-valley-spring-rumble",
      "event_page_link": "https://www.trackwrestling.com/example/hudson-valley-spring-rumble/details",
      "contact_name": "Chris Palmer",
      "contact_email": "events@hudsonvalleyrumble.org",
      "contact_phone": "555-2100",
      "description": "One-day early season open with varsity and JV brackets.",
      "deadline": "2026-04-22",
      "cost": "$325 team / $40 individual",
      "source_label": "TrackWrestling",
      "ingestion_status": "normalized",
      "ingestion_notes": null,
      "last_seen_at": "2026-04-15T09:00:00",
      "created_at": "2026-04-15T09:00:00",
      "updated_at": "2026-04-15T09:00:00",
      "source": {
        "id": 2,
        "source_key": "track",
        "display_name": "TrackWrestling",
        "ingestion_mode": "hybrid_placeholder",
        "base_url": "https://www.trackwrestling.com",
        "supports_scraping": true,
        "supports_api": false,
        "is_active": true,
        "notes": "Placeholder source for scraping-first ingestion with optional API augmentation later."
      },
      "is_saved": true,
      "is_on_team_schedule": false,
      "distance_miles": 63.4,
      "recommendation_score": 8.5
    }
  ],
  "recommended": [],
  "nearby": [],
  "upcoming_weekend": [],
  "saved_filter": null,
  "available_sources": []
}
```

## POST `/api/v1/tournaments/save`

```json
{
  "team_id": 1,
  "tournament_id": 1,
  "notes": "Great fit for our varsity lineup."
}
```

## POST `/api/v1/tournaments/add-to-schedule`

```json
{
  "team_id": 1,
  "tournament_id": 1,
  "starts_at": "2026-04-25T08:00:00Z",
  "ends_at": "2026-04-25T17:00:00Z",
  "notes": "Bus leaves at 5:45 AM.",
  "checklist": ["Singlet", "Headgear", "Team warmup"],
  "bus_departure_note": "Depart school lot by 5:45 AM.",
  "weigh_in_note": "Track coach packet and ID bands at check-in."
}
```

## POST `/api/v1/tournaments/manual`

```json
{
  "team_id": 1,
  "name": "Riverdale Summer Open",
  "start_date": "2026-06-12",
  "end_date": "2026-06-13",
  "location_name": "Riverdale Main Gym",
  "city": "Riverdale",
  "state": "NY",
  "age_divisions": ["High School Varsity", "Middle School"],
  "weight_classes": ["106", "113", "120", "126"],
  "event_type": "open",
  "registration_link": "https://example.com/register",
  "contact_name": "Jordan Blake",
  "contact_email": "coach@wrestlingos.com",
  "description": "Manual entry created by the coaching staff.",
  "deadline": "2026-06-05",
  "cost": "$30 entry",
  "notes": "Needs to be shared in announcements."
}
```
