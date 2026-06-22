# Pin IQ

FastAPI backend plus Flutter frontend for Pin IQ.

## Included

- JWT auth
- Users with wrestling-specific roles
- Team creation
- Team join by coach-issued code
- Team member management
- Staff approval/removal workflow
- School logo upload
- Join code rotation
- School branding controls
- SQLite starter database
- Alembic migration scaffolding
- Health probes
- Upload size/type guardrails
- Pytest + GitHub Actions backend CI
- Container build scaffold
- Structured request/error logging with request IDs
- Webhook-based exception alerting
- Staging CI workflow scaffold
- Scheduled staging health monitor scaffold
- Token cleanup script and security audit workflow
- Basic pagination limits on key large-list endpoints
- Storage provider abstraction with local and S3-compatible groundwork
- Mock/Stripe-ready checkout and webhook groundwork

## Roles

- `coach`
- `assistant_coach`
- `athlete`
- `parent`
- `admin`

## Local setup

Use Python 3.11, matching CI and the production Docker image.

```bash
python3.11 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
alembic upgrade head
uvicorn app.main:app --reload
```

`AUTO_CREATE_SCHEMA` now defaults to `false`, even for local development, so startup doesn't mask migration drift. If you intentionally want metadata-driven table creation for a throwaway local database, opt in explicitly in `.env`.

## Frontend

The Flutter app now lives in [`frontend/`](frontend).

```bash
cd frontend
flutter pub get
flutter run
```

If iOS Simulator builds fail with a local codesign metadata error, see [docs/simulator_fix.md](docs/simulator_fix.md).

## Production notes

- Set `ENVIRONMENT=production`
- Set a real `SECRET_KEY`
- Set `AUTO_CREATE_SCHEMA=false`
- Set `SEED_DEMO_DATA_ON_STARTUP=false`
- Use Postgres instead of SQLite
- Set `CORS_ORIGINS` to your real frontend domains

More detail is in [docs/deployment.md](docs/deployment.md) and the tracked launch worklist is in [docs/launch_checklist.md](docs/launch_checklist.md).

For storage and payments, local/mock mode remains the default until you add real S3-compatible and Stripe credentials.

## Demo account

```text
coach@wrestlingos.com
Password123
```

## API routes

- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/refresh`
- `POST /api/v1/auth/logout`
- `POST /api/v1/auth/password-reset/request`
- `POST /api/v1/auth/password-reset/confirm`
- `POST /api/v1/auth/email-verification/request`
- `POST /api/v1/auth/email-verification/confirm`
- `GET /api/v1/users/me`
- `PUT /api/v1/users/me`
- `PUT /api/v1/users/me/password`
- `PATCH /api/v1/users/{user_id}/status`
- `GET /api/v1/teams`
- `GET /api/v1/teams/{team_id}`
- `GET /api/v1/teams/{team_id}/roster`
- `GET /api/v1/teams/{team_id}/athletes/{athlete_user_id}`
- `POST /api/v1/teams`
- `POST /api/v1/teams/join`
- `GET /api/v1/team-members/teams/{team_id}`
- `POST /api/v1/team-members/teams/{team_id}`
- `PUT /api/v1/team-members/teams/{team_id}/{member_id}/status`
- `DELETE /api/v1/team-members/teams/{team_id}/{member_id}`
- `POST /api/v1/teams/{team_id}/rotate-join-code`
- `POST /api/v1/uploads/teams/{team_id}/logo`
- `POST /api/v1/store/orders`
- `POST /api/v1/store/orders/{order_id}/checkout-session`
- `GET /api/v1/store/orders/team/{team_id}`
- `GET /api/v1/store/orders/user/{user_id}`
- `PATCH /api/v1/store/orders/{order_id}/status`
- `POST /api/v1/store/payments/webhook/{provider}`
- `PUT /api/v1/branding/teams/{team_id}`
- `GET /health/live`
- `GET /health/ready`
