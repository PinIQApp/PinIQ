# Pin IQ Flutter App

Dark-theme Flutter app for Pin IQ.

## Included

- Splash screen
- Login and register flow
- Role selection
- Team setup flow
- Join team flow for athletes, parents, and assistant coaches
- Pending approval screen for staff-reviewed joins
- Dynamic school branding theme
- Dashboard shell
- Coach settings screen
- User profile settings screen
- Local token persistence
- Team logo upload and join code rotation

## Run locally

```bash
flutter pub get
flutter run
```

## Backend URL

Local debug builds use `http://127.0.0.1:8000` on mobile and
`http://<current-web-host>:8000` on local web.

Release mobile builds default to:

```text
https://api.piniqapp.com
```

Override the API for any build with:

```bash
flutter run --dart-define=API_BASE_URL=https://api.example.com
flutter build web --dart-define=API_BASE_URL=https://api.example.com
```

## Android Release Signing

Copy `android/key.properties.example` to `android/key.properties`, fill in the
real keystore values, and keep `android/key.properties` out of source control.
Release builds intentionally fail if signing credentials are missing.
