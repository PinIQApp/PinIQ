# Launch Checklist

Status key:
- `[x]` done
- `[ ]` still needed
- `[-]` deferred because it requires an external service, product decision, or code not present in this repo

## Platform hardening

- [x] Move demo-only startup behavior behind environment flags
- [x] Add explicit environment-aware CORS configuration
- [x] Add liveness and readiness health endpoints
- [x] Fail fast on obviously unsafe production settings
- [ ] Replace SQLite production default with managed Postgres in deployed environments
- [x] Add structured logging and centralized error monitoring hooks
- [x] Add request rate limiting for auth and sensitive routes

## Auth and account safety

- [x] Block inactive users from authenticating
- [x] Enforce basic password strength checks on registration and password changes
- [x] Add password reset flow
- [x] Add email verification flow
- [x] Add refresh token / token revocation strategy
- [x] Add admin tooling for deactivating and reactivating accounts safely

## File uploads and media

- [x] Enforce upload extension allowlist
- [x] Enforce max upload size
- [ ] Move media storage from local disk to cloud object storage
- [x] Add storage provider abstraction and S3-compatible migration prep
- [ ] Add image scanning / moderation strategy for uploads
- [ ] Add signed or access-controlled media delivery where needed

## Product and monetization

- [ ] Integrate real checkout and payment provider
- [x] Add payment abstraction with mock and Stripe-ready groundwork
- [ ] Add tax, refund, receipt, and webhook reconciliation flows
- [-] Replace merch export placeholders with a real rendering/export pipeline
- [-] Replace nutrition mock provider with a live provider integration

## Quality and release tooling

- [x] Add backend test scaffolding
- [x] Add CI workflow for backend tests
- [x] Add container build scaffold
- [x] Add deployment-oriented environment docs
- [x] Add production Docker Compose, web container, and env validation scripts
- [x] Expand test coverage across store, messaging, and compliance-sensitive flows
- [x] Add staging deployment workflow

## Client packaging

- [x] Add a complete Flutter app scaffold in this repo
- [x] Add environment switching and release build configuration for mobile/web clients
- [x] Add PWA install metadata, shortcuts, and offline fallback page
- [x] Add role-aware first-run onboarding after login

## Product improvements

- [ ] Add product analytics so you can see which teams and features are actually being used
- [x] Add role-based onboarding flows for coaches, parents, athletes, and admins
- [x] Add background-task hooks for approvals, password resets, and email verification delivery
- [ ] Add stronger admin/support tools such as activity views, safer recovery flows, and support-friendly account management
- [ ] Add exports and reports for coaches, admins, and store operations
- [ ] Add feature flags so new modules can be rolled out gradually
- [ ] Improve search, filtering, and pagination across large lists like athletes, orders, tournaments, and messages
- [ ] Improve client error, loading, retry, and offline states
- [ ] Add performance improvements such as query tuning, pagination defaults, caching, and background jobs where needed
- [ ] Add compliance and audit dashboards for messaging and parent-visibility rules

## Bug and risk hardening

- [x] Replace the in-memory auth rate limiter with a shared production-safe store
- [x] Add cleanup jobs/scripts for expired refresh tokens, password reset tokens, and email verification tokens
- [x] Add idempotency protection for payment, checkout, and webhook-driven flows before live billing is enabled
- [x] Add background-task hooks for outbound emails and future async job expansion
- [x] Add pagination and response-size limits to key list endpoints that can grow large
- [x] Add stronger audit logging for auth lifecycle events and admin account-status changes
- [ ] Add database backup, restore, and migration rollback drills
- [x] Add load-testing scaffold and guidance for core routes before launch
- [x] Add dependency scanning workflow and security-review scaffolding
- [ ] Add vendor/integration failure handling so email, payment, storage, and provider outages degrade safely
- [ ] Add cleanup and retention rules for media, logs, and old compliance artifacts
- [x] Add object-storage migration prep and configuration scaffolding

## Notes

- This checklist reflects the code currently present in this repository.
- Items marked deferred need external integrations or missing app-level context and cannot be fully completed from this backend workspace alone.
- Monitoring hooks and request-correlation logging are implemented in-repo; wiring them to a hosted monitoring platform is an environment task.
