import 'package:flutter/services.dart';

class WatchCompanionService {
  static const MethodChannel _channel = MethodChannel('wrestletech/watch_companion');

  Future<Map<String, dynamic>> fetchHealthSnapshot() async {
    final result = await _channel.invokeMapMethod<String, dynamic>('fetchHealthSnapshot');
    return result ?? <String, dynamic>{};
  }

  Future<bool> requestHealthPermissions() async {
    final result = await _channel.invokeMethod<bool>('requestHealthPermissions');
    return result ?? false;
  }

  Future<bool> syncWatchSnapshot({
    required int unreadMessages,
    required int alerts,
    String? nextEvent,
    String? nextWeighIn,
  }) async {
    final result = await _channel.invokeMethod<bool>(
      'syncWatchSnapshot',
      <String, dynamic>{
        'unreadMessages': unreadMessages,
        'alerts': alerts,
        'nextEvent': nextEvent,
        'nextWeighIn': nextWeighIn,
      },
    );
    return result ?? false;
  }
}
