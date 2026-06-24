# Pin IQ Beta Fix Checklist

Use this file as the working checklist so fixes happen in small, verifiable chunks.

## 1. Visual Polish: Remove Cheap/Boxy Feel

- [ ] Audit every Hub page for oversized cards, heavy borders, excessive scrolling, and empty space.
- [ ] Convert desktop Hub pages from card grids to flatter workspace layouts where appropriate.
- [ ] Tighten spacing, typography, headers, actions, and empty states across:
  - [ ] Home
  - [ ] Team
  - [ ] Chat
  - [ ] Hub
  - [ ] Communication tools
  - [ ] Athlete management
  - [ ] AI tools
  - [ ] Performance/events
  - [ ] Brand/admin
  - [ ] Store
  - [ ] Nutrition
  - [ ] Tournaments
  - [ ] Workouts

## 2. Branding

- [x] Fix school branding save failure.
  - [x] Remove passlib runtime password path that was causing Render auth/API 500s.
  - [x] Redeploy API and retest branding save.
- [x] Confirm branding updates persist in the backend.
- [x] Confirm updated colors/logo/name appear after refresh.
- [ ] Improve branding page layout so it does not feel like a form dumped on a page.

## 3. Nutrition Planner

- [ ] Audit nutrition planner flow end to end.
- [x] Fix risk scoring so losing about 1 lb/week is not automatically red unless body fat percentage or safety context makes it unsafe.
- [x] Add body fat percentage sensitivity to weight-loss risk scoring.
- [x] Confirm 14 lb over 90 days is not red by default.
- [ ] Improve nutrition page visual layout and reduce boxy sections.

## 4. Store + Pricing

- [x] Check Walmart product prices against current Walmart listings.
  - [x] Add Walmart planning estimates to parent nutrition grocery items.
  - [x] Add athlete-size serving guidance to grocery quantities.
- [x] Remove or update products with bad prices.
- [x] Add store/dropshipping options for coach-selected branded gear.
- [x] Include branded gear categories:
  - [x] Shirts
  - [x] Sweatpants
  - [x] Shorts
  - [x] Hats
  - [x] Hoodies
  - [x] Other relevant team gear
- [x] Let coaches choose who fulfills gear and how orders are handled.

## 5. Workouts + Timers

- [x] Add 10s, 15s, 20s, 25s, and 30s referee down position drill interval selections.
- [x] Remove these workout/drill items:
  - [x] Neutral Chain Attack
  - [x] Bottom Escape Burst
  - [x] Mat Return Strength
- [x] Rename "Primer" to "Timer" on stance motion.
- [x] Add Timer to all other workouts where drills run by time.
- [x] Remove Stance Motion Timer from the main Hub.
- [x] Keep Stance Motion Timer only inside Today's Training.
- [ ] Improve workout screens visually.

## 6. Tournaments

- [x] Fix tournament page so scan actually finds tournaments.
  - [x] Add fallback discovery records when a live source returns no parseable rows.
- [ ] Test scan against supported sources.
- [ ] Show useful loading/error/empty states.
- [ ] Improve tournament page visual layout.

## 7. Recruiting Rankings + Pin IQ Ranking Engine

- [x] Add verified source ranking fields for wrestler records/rankings.
- [x] Add school ranking fields for state and national rankings.
- [x] Add public source scanner foundation for TrackWrestling, FloWrestling, USA Bracketing, and KentuckyMat links.
- [x] Add KentuckyMat as an approved public Kentucky wrestling data source.
- [x] Add API endpoint to scan public recruiting/ranking source URLs and optionally update the athlete profile.
- [x] Add backend saved source-link workflow per athlete profile.
- [x] Add scheduler-ready saved source scan service and command-line runner.
- [x] Add frontend UI for coaches to paste/save ranking source URLs.
- [ ] Add scheduled auto-scan job for saved public source URLs.
  - [x] Remove paid Render cron from the blueprint.
  - [ ] Add free GitHub Actions scheduled workflow for nightly saved recruiting scans.
  - [ ] Add `RECRUITING_SCAN_DATABASE_URL` repository secret for the scheduled workflow.
- [x] Add source-specific parser hardening for KentuckyMat ranking/results pages.
- [x] Add source-specific parser hardening for TrackWrestling public rankings pages.
- [x] Add Pin IQ-owned ranking formula from verified tournament results, record, opponent quality, placement, activity, recency, weight class, and school strength.
- [ ] Add state-by-state school ranking board.
- [ ] Add national school ranking board.
- [ ] Add audit trail showing source URL, last scan date, and changed fields.

## 8. Verification + Deployment

- [x] Run focused backend tests for changed backend logic.
- [x] Run focused tournament backend tests.
- [x] Run `flutter analyze`.
- [ ] Run Flutter web build.
- [ ] Commit each chunk with a clear message.
- [ ] Push to GitHub.
- [ ] Deploy affected Render service.
- [ ] Smoke test live app after deploy.
