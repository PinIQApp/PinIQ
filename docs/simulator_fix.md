# iOS Simulator Fix

If `flutter run` fails on iOS Simulator with a codesign error like:

```text
resource fork, Finder information, or similar detritus not allowed
```

the issue is usually local macOS metadata on generated framework files during the Flutter iOS packaging step.

## Symptom

The build fails while signing one of these simulator artifacts:

- `Flutter.framework/Flutter`
- `App.framework/App`

Typical error:

```text
Failed to codesign ... with identity -.
... resource fork, Finder information, or similar detritus not allowed
```

## Local fix used in this repo

The working fix on this machine was:

1. Clear extended attributes on the frontend folder:

```bash
xattr -rc /Users/courtneymaynard/Documents/Playground/wrestling_os_backend/frontend
```

2. Patch the local Flutter SDK so simulator builds do not codesign `Flutter.framework` and `App.framework`.

Patched file:

`/opt/homebrew/share/flutter/packages/flutter_tools/lib/src/build_system/targets/ios.dart`

The simulator path was changed so signing only happens for `EnvironmentType.physical`.

3. Clear Flutter's cached tool snapshot so the patched tool source is recompiled:

```bash
rm -f /opt/homebrew/share/flutter/bin/cache/flutter_tools.snapshot
rm -f /opt/homebrew/share/flutter/bin/cache/flutter_tools.stamp
```

4. Re-run:

```bash
cd /Users/courtneymaynard/Documents/Playground/wrestling_os_backend/frontend
flutter run -d "iPhone 17 Pro"
```

## Important note

This is a local machine fix, not a normal app-code fix.

If Flutter is upgraded or reinstalled, the patched SDK file may be overwritten and the simulator issue may come back. If that happens:

- reapply the SDK patch
- clear the Flutter tool snapshot again

## Verify

This repo was successfully launched after the fix with:

```bash
cd /Users/courtneymaynard/Documents/Playground/wrestling_os_backend/frontend
flutter run -d E07D35AF-D5A3-4533-8229-87B2D21D557F
```
