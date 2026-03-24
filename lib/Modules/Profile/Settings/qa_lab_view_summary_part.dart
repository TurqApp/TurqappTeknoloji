part of 'qa_lab_view.dart';

extension _QALabViewSummaryPart on _QALabViewState {
  Widget _buildSummaryCard() {
    return Obx(() {
      final topAlerts = _recorder.buildSurfaceAlertSummaries().take(3).toList();
      final nativePlayback = Map<String, dynamic>.from(
        _recorder.lastNativePlaybackSnapshot,
      );
      final nativeErrors =
          (nativePlayback['errors'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => item.toString())
              .where((item) => item.isNotEmpty)
              .join(', ');
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'settings.diagnostics.qa_summary'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${'settings.diagnostics.qa_health_score'.tr}: ${_recorder.healthScore}/100',
              ),
              Text(
                '${'settings.diagnostics.qa_live_surface'.tr}: ${_recorder.lastSurface.value}',
              ),
              Text(
                '${'settings.diagnostics.qa_live_route'.tr}: ${_recorder.lastRoute.value}',
              ),
              Text(
                '${'settings.diagnostics.qa_last_export'.tr}: ${_recorder.lastExportPath.value.isEmpty ? '-' : _recorder.lastExportPath.value}',
              ),
              Text(
                'lifecycle=${_recorder.lastLifecycleState.value.isEmpty ? "-" : _recorder.lastLifecycleState.value}',
              ),
              Text(
                'permissions=${_recorder.lastPermissionStatuses.isEmpty ? "-" : _recorder.lastPermissionStatuses.entries.map((entry) => "${entry.key}:${entry.value}").join("  ")}',
              ),
              const SizedBox(height: 8),
              Text(
                'blocking=${_recorder.blockingIssueCount} error=${_recorder.errorIssueCount} warning=${_recorder.warningIssueCount}',
              ),
              Text(
                'routes=${_recorder.routes.length} checkpoints=${_recorder.checkpoints.length}',
              ),
              if (nativePlayback.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'native=${nativePlayback['platform'] ?? '-'} '
                  'status=${(nativePlayback['status'] ?? '').toString().isEmpty ? 'OK' : nativePlayback['status']} '
                  'active=${nativePlayback['active'] == true} '
                  'playing=${nativePlayback['isPlaying'] == true} '
                  'buffering=${nativePlayback['isBuffering'] == true} '
                  'firstFrame=${nativePlayback['firstFrameRendered'] == true} '
                  'stalls=${nativePlayback['stallCount'] ?? 0}',
                ),
                Text(
                  'nativeErrors=${nativeErrors.isEmpty ? '-' : nativeErrors}',
                ),
              ],
              if (topAlerts.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'critical now',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                ...topAlerts.map(
                  (item) => Text(
                    '${item.surface} • health ${item.healthScore} • '
                    'blocking=${item.blockingCount} error=${item.errorCount} '
                    'route=${item.latestRoute.isEmpty ? "-" : item.latestRoute}\n'
                    '${item.headlineCode}: ${item.headlineMessage}\n'
                    'rootCause=${item.primaryRootCauseCategory} • ${item.primaryRootCauseDetail}',
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}
