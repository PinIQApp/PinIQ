# WrestleTech Apple Watch Xcode Target

The repo now contains the native source foundation for an Apple Watch companion:

- `frontend/ios/WrestleTechWatch/WatchApp.swift`
- `frontend/ios/WrestleTechWatch/WatchHomeView.swift`
- `frontend/ios/WrestleTechWatch/WatchHomeViewModel.swift`
- iPhone-side bridge code in:
  - `frontend/ios/Runner/HealthKitManager.swift`
  - `frontend/ios/Runner/WatchConnectivityManager.swift`

## What is already done
- Flutter-side watch companion planning screen
- iPhone method channel for watch sync + health snapshot requests
- HealthKit read support foundation for:
  - heart rate
  - steps
  - active energy
- WatchConnectivity application-context sync foundation
- watchOS SwiftUI companion scaffold

## What still needs to be done in Xcode
The watchOS app source files are present, but the Xcode target is not yet wired into `Runner.xcodeproj`.

Add in Xcode:

1. `File > New > Target`
2. Choose `watchOS App`
3. Name it `WrestleTechWatch`
4. Use `SwiftUI`
5. Point the new target at the source files in `frontend/ios/WrestleTechWatch/`
6. Enable capabilities:
   - HealthKit
   - App Groups if you want future shared storage
   - Background Modes only if later needed
7. Keep `WatchConnectivity` on both iPhone and watch targets

## First native MVP after target hookup
- unread message count
- next event
- next weigh-in
- alerts
- heart rate
- steps

## Rule
Do not copy the phone app onto the watch.
Keep it:
- glanceable
- actionable
- coach-safe
- fast
