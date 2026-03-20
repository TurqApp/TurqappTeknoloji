import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/telemetry_threshold_policy.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/telemetry_threshold_policy_adapter.dart';

class RuntimeHealthExporter {
  const RuntimeHealthExporter._();

  static Map<String, dynamic> exportFromKpiService(
    PlaybackKpiService service, {
    int recentEventLimit = 60,
  }) {
    final snapshots = TelemetryThresholdPolicyAdapter.buildSnapshots(service);
    final report = TelemetryThresholdPolicy.evaluateSnapshots(snapshots);
    final recentEvents = service.recentEvents;
    final startIndex = recentEvents.length > recentEventLimit
        ? recentEvents.length - recentEventLimit
        : 0;
    return <String, dynamic>{
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'surfaceCount': snapshots.length,
      'surfaces': snapshots.map((snapshot) => snapshot.toJson()).toList(
            growable: false,
          ),
      'thresholdReport': report.toJson(),
      'recentEvents': recentEvents
          .skip(startIndex)
          .map(
            (event) => <String, dynamic>{
              'type': event.type.name,
              'payload': Map<String, dynamic>.from(event.payload),
            },
          )
          .toList(growable: false),
    };
  }
}
