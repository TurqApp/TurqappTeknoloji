import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

enum PlaybackKpiEventType {
  startup,
  cacheFirstLifecycle,
  firstFrame,
  rebuffer,
  cacheHitRatio,
  prefetchHealth,
  playbackIntent,
  mobileBytesPerMinute,
  profileLocalHitRatio,
}

class PlaybackKpiEvent {
  final PlaybackKpiEventType type;
  final Map<String, dynamic> payload;

  const PlaybackKpiEvent({
    required this.type,
    required this.payload,
  });
}

class PlaybackKpiService extends GetxService {
  final RxList<PlaybackKpiEvent> _recent = <PlaybackKpiEvent>[].obs;

  List<PlaybackKpiEvent> get recentEvents => List.unmodifiable(_recent);

  void track(PlaybackKpiEventType type, Map<String, dynamic> payload) {
    final event = PlaybackKpiEvent(type: type, payload: payload);
    _recent.add(event);
    if (_recent.length > 200) {
      _recent.removeRange(0, _recent.length - 200);
    }
    if (kDebugMode) {
      debugPrint('[PlaybackKPI] ${type.name}: $payload');
    }
  }
}
