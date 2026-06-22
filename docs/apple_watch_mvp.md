# WrestleTech Apple Watch MVP

## Positioning
WrestleTech on Apple Watch should be a companion app, not a tiny version of the full platform.

The watch experience should focus on:
- glanceable status
- timed reminders
- quick confirmations
- health signals
- tournament timing
- short replies

## Best Role Fits

### Athlete
- heart rate
- steps
- practice check-in
- weigh-in countdown
- hydration reminders
- next event timing

### Coach
- unread thread counts
- parent-visible reply prompts
- tournament / weigh-in alerts
- athlete arrival confirmations
- quick staff replies

### Parent
- event reminders
- arrival prompts
- approved team updates
- parent-visible message digests

## MVP Surfaces

### Messages
- unread count
- latest approved thread title
- quick reply presets

### Tournament
- next event
- weigh-in time
- arrival report time
- bracket update alert

### Health
- heart rate
- step count
- active minutes
- workout summary

### Weight / Nutrition
- hydration reminders
- weigh-in countdown
- simple safe reminders only

### Practice
- arrival check-in
- workout mode shortcut
- drill / timer reminder

## Guardrails
- no full roster management
- no long message threads
- no store or heavy admin flows
- no aggressive cut prompts
- no athlete-sensitive data on parent watch views by default

## Build Order

1. Companion MVP in main app
2. Apple Health data contracts
3. Native watchOS target in Xcode
4. Quick reply and bracket alert polish
