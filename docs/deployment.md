# Deployment Notes

## Environment

Recommended production values:

```env
ENVIRONMENT=production
SECRET_KEY=<long-random-secret>
ACCESS_TOKEN_EXPIRE_MINUTES=10080
REFRESH_TOKEN_EXPIRE_MINUTES=43200
DATABASE_URL=postgresql+psycopg://<user>:<password>@<host>:5432/<db>
CORS_ORIGINS=https://piniqapp.com
AUTO_CREATE_SCHEMA=false
SEED_DEMO_DATA_ON_STARTUP=false
MEDIA_DIR=media
STORAGE_PROVIDER=s3
MEDIA_BASE_URL=https://cdn.piniqapp.com
S3_BUCKET_NAME=<bucket>
S3_REGION=<region>
S3_ENDPOINT_URL=<optional-r2-or-minio-endpoint>
S3_ACCESS_KEY_ID=<access-key>
S3_SECRET_ACCESS_KEY=<secret-key>
S3_PUBLIC_BASE_URL=https://cdn.piniqapp.com
PAYMENT_PROVIDER=stripe
STRIPE_SECRET_KEY=<secret>
STRIPE_PUBLISHABLE_KEY=<publishable>
STRIPE_WEBHOOK_SECRET=<webhook-secret>
CHECKOUT_SUCCESS_URL=https://piniqapp.com/store/success
CHECKOUT_CANCEL_URL=https://piniqapp.com/store/cancel
MAX_UPLOAD_SIZE_BYTES=5242880
ALLOWED_IMAGE_EXTENSIONS=.png,.jpg,.jpeg,.webp
AUTH_RATE_LIMIT_ATTEMPTS=10
AUTH_RATE_LIMIT_WINDOW_SECONDS=300
PASSWORD_RESET_TOKEN_EXPIRE_MINUTES=30
MONITORING_WEBHOOK_URL=<optional-alert-webhook>
MONITORING_WEBHOOK_TIMEOUT_SECONDS=5
SMS_PROVIDER=twilio
SMS_FROM_NUMBER=<twilio-from-number>
TWILIO_ACCOUNT_SID=<twilio-account-sid>
TWILIO_AUTH_TOKEN=<twilio-auth-token>
EMAIL_PROVIDER=postmark
ALERT_EMAIL_FROM=Support@PinIQApp.com
POSTMARK_SERVER_TOKEN=<postmark-token>
PUSH_PROVIDER=webhook
PUSH_WEBHOOK_URL=<push-provider-webhook-url>
PUSH_WEBHOOK_SECRET=<optional-shared-secret>
NUTRITION_PROVIDER=fitchef
FITCHEF_API_BASE=<fitchef-api-base>
FITCHEF_API_KEY=<fitchef-api-key>
```

## Startup checklist

1. Run database migrations before starting the app.
2. Keep `AUTO_CREATE_SCHEMA=false` everywhere by default, including local development, unless you are intentionally bootstrapping a disposable database.
3. Keep `SEED_DEMO_DATA_ON_STARTUP=false` outside local development.
4. Point `DATABASE_URL` at Postgres instead of SQLite for deployed environments.
5. Replace local `MEDIA_DIR` storage with object storage before public launch.
6. Back password reset and email verification requests with a real delivery channel before public launch.
7. Switch `STORAGE_PROVIDER` to `s3` only after bucket permissions and public URL behavior are verified.
8. Switch `PAYMENT_PROVIDER` to `stripe` only after checkout URLs and webhook secret are configured.
9. Switch SMS, email, push, and nutrition providers to live production providers before `ENVIRONMENT=production`.

## Production compose deployment

This repo includes a production-ready Docker Compose skeleton:

```bash
cp .env.production.example .env.production
```

Fill every placeholder in `.env.production`, then run:

```bash
python3 scripts/validate_production_env.py
scripts/deploy_production.sh
scripts/production_health_check.sh https://api.piniqapp.com https://piniqapp.com
```

The deploy script:

- validates `.env.production`
- builds the API and web containers
- starts Postgres, API, and web
- runs `alembic upgrade head`
- prints service status

For local smoke checks of the production compose file before real secrets exist:

```bash
PRODUCTION_ENV_FILE=.env.production.example docker compose --env-file .env.production.example -f docker-compose.production.yml config
```

## Free beta deployment

For a free/low-cost beta, keep the backend in `ENVIRONMENT=staging` and leave paid integrations in mock mode:

```bash
cp .env.beta.example .env.beta
```

Fill:

- `SECRET_KEY`
- `DATABASE_URL` from a free Supabase Postgres project
- `FRONTEND_ORIGIN` if you rename the Render web service
- `CORS_ORIGINS` to match the web app URL
- `API_BASE_URL` if you rename the Render API service

Then validate:

```bash
scripts/validate_beta_env.sh
```

The included `render.yaml` creates two free Render services:

- `wrestletech-api`: Docker API service
- `wrestletech-beta`: Docker web/PWA service

In this beta mode, Stripe, Twilio, Postmark, push, S3/R2, and FitChef stay disabled so you can test the product without paid provider accounts. Do not use this mode for a public paid launch.

## Health checks

- `GET /health/live`
- `GET /health/ready`

`/health/ready` verifies the database connection and is the preferred readiness probe.

## Web client hosting

- Build the web client with `flutter build web --dart-define=API_BASE_URL=https://api.piniqapp.com`.
- Serve `frontend/build/web` as the public web root so `manifest.json`, icons, and `offline.html` are delivered with the app.
- Configure the host to fall back unknown app routes to `index.html`, and use `offline.html` as the network-error fallback when the CDN or host supports one.

## Observability

- Every request now returns `X-Request-ID`.
- Request logs include method, path, status, duration, and request ID.
- Unhandled server errors are logged with the same request ID for correlation.
- `MONITORING_WEBHOOK_URL` now forwards unhandled exception alerts as JSON to your incident channel or alerting bridge.

Example alert payload:

```json
{
  "event_type": "unhandled_exception",
  "summary": "RuntimeError: database unavailable",
  "service": "Pin IQ API",
  "environment": "production",
  "request_id": "f3f6d7a6...",
  "timestamp": "2026-05-05T20:14:10.021Z",
  "metadata": {
    "exception_type": "RuntimeError"
  }
}
```

## Operational jobs

- Run `python scripts/cleanup_auth_tokens.py` on a schedule to purge expired or spent auth tokens.

## Scheduled Recruiting Source Scan

The Render blueprint includes `wrestletech-recruiting-source-scan`, a cron service that runs:

```bash
python scripts/run_recruiting_source_scan.py --limit 500 --show-failures
```

It scans saved public recruiting source links, updates verified wrestler and school ranking fields, and prints summary/failure lines to the cron logs. Configure the cron service with the same production `DATABASE_URL` secret as the API service before enabling it.
- Auth rate limiting now uses the shared application database instead of per-process memory. Redis remains an optional future optimization if traffic volume outgrows the database-backed approach.

## Staging workflow

- GitHub Actions includes `.github/workflows/staging-checks.yml`.
- Pushes to `staging` or manual dispatch run tests and a container build using staging-safe startup flags.
- GitHub Actions includes `.github/workflows/staging-health-monitor.yml` for a scheduled `/health/live` and `/health/ready` heartbeat against staging.
- Configure `STAGING_BASE_URL` and `STAGING_ALERT_WEBHOOK_URL` GitHub secrets so failed heartbeats send the same JSON alert format as app-side exception reporting.

## Security and load checks

- GitHub Actions includes `.github/workflows/security-audit.yml` for dependency auditing.
- Load-test guidance lives in `loadtest/README.md`.

## Payment groundwork

- `POST /api/v1/store/orders/{order_id}/checkout-session` creates a mock or Stripe-ready checkout session.
- `POST /api/v1/store/payments/webhook/{provider}` processes mock or Stripe-style payment events.
- Mock mode is the default and is useful for local flow testing before real billing is enabled.

## Container

Build:

```bash
docker build -t wrestling-os-backend .
```

Run:

```bash
docker run --env-file .env -p 8000:8000 wrestling-os-backend
```
