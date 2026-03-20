import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';

import 'cache_first_telemetry.dart';

class CacheFirstKpiTelemetry<T> implements CacheFirstTelemetry<T> {
  const CacheFirstKpiTelemetry();

  @override
  void onEvent(CacheFirstTelemetryEvent<T> event) {
    if (!Get.isRegistered<PlaybackKpiService>()) return;

    final resource = event.resource;
    final payload = <String, dynamic>{
      'event': event.type.name,
      'surfaceKey': event.key.surfaceKey,
      'hasScope': event.key.scopeId.trim().isNotEmpty,
      'isUserScoped': event.key.isUserScoped,
      'source': resource?.source.name ?? 'none',
      'hasData': resource?.hasData ?? false,
      'hasLocalSnapshot': resource?.hasLocalSnapshot ?? false,
      'isRefreshing': resource?.isRefreshing ?? false,
      'isStale': resource?.isStale ?? false,
      'hasLiveError': resource?.hasLiveError ?? false,
      if (resource?.snapshotAt != null)
        'snapshotAgeMs':
            DateTime.now().difference(resource!.snapshotAt!).inMilliseconds,
      if (resource?.data != null) 'itemCount': _inferItemCount(resource!.data),
      if (event.error != null) 'errorType': event.error.runtimeType.toString(),
    };

    Get.find<PlaybackKpiService>().track(
      PlaybackKpiEventType.cacheFirstLifecycle,
      payload,
    );
  }

  int? _inferItemCount(Object? data) {
    if (data is Iterable<dynamic>) {
      return data.length;
    }
    if (data is Map<dynamic, dynamic>) {
      return data.length;
    }
    return null;
  }
}
