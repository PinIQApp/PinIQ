# WrestleTech Merch Designer Examples

## Create Design

```json
{
  "team_id": 1,
  "product_type": "hoodie",
  "template_key": "clean-modern",
  "design_name": "Varsity Travel Hoodie",
  "colorway_name": "black",
  "primary_color": "#111827",
  "secondary_color": "#E5E7EB",
  "accent_color": "#D4AF37",
  "front_text": "CENTRAL WRESTLING",
  "back_text": "STATE READY",
  "sleeve_text": "WRESTLETECH",
  "sponsor_text": "Proudly Backed By Titan Auto"
}
```

## Publish Design

```bash
curl -X POST "$BASE_URL/api/v1/merch/designs/12/publish" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

## Export Manufacturer Sheet

```bash
curl -X POST "$BASE_URL/api/v1/merch/designs/12/export" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "export_type": "manufacturer_sheet",
    "notes": "Need a vendor-ready handoff document"
  }'
```
