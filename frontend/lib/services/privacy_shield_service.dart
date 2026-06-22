import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PrivacyShieldService {
  static const MethodChannel _methodChannel =
      MethodChannel('wrestletech/privacy_shield');
  static const EventChannel _eventChannel =
      EventChannel('wrestletech/privacy_shield_events');

  StreamSubscription<dynamic>? _subscription;

  Future<void> startMonitoring({
    required ValueChanged<bool> onScreenCaptureChanged,
    required VoidCallback onScreenshotDetected,
  }) async {
    if (kIsWeb || !Platform.isIOS) {
      return;
    }

    try {
      final active =
          await _methodChannel.invokeMethod<bool>('isScreenCaptureActive') ??
              false;
      onScreenCaptureChanged(active);

      _subscription ??= _eventChannel.receiveBroadcastStream().listen((event) {
        final payload = Map<String, dynamic>.from(event as Map);
        switch (payload['type']) {
          case 'screen_capture_changed':
            onScreenCaptureChanged(payload['active'] == true);
            break;
          case 'screenshot_detected':
            onScreenshotDetected();
            break;
        }
      });
    } catch (_) {
      // Best-effort privacy shielding only.
    }
  }
}
