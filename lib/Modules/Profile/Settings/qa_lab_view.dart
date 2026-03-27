import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/telemetry_threshold_policy_adapter.dart';
import 'package:turqappv2/Core/Services/qa_lab_catalog.dart';
import 'package:turqappv2/Core/Services/qa_lab_mode.dart';
import 'package:turqappv2/Core/Services/qa_lab_recorder.dart';
import 'package:turqappv2/Core/Services/qa_lab_remote_uploader.dart';
import 'package:turqappv2/Core/app_snackbar.dart';

part 'qa_lab_view_summary_part.dart';
part 'qa_lab_view_findings_part.dart';

class QALabView extends StatefulWidget {
  const QALabView({super.key});

  @override
  State<QALabView> createState() => _QALabViewState();
}

class _QALabViewState extends State<QALabView> {
  late final QALabRecorder _recorder;
  late final QALabRemoteUploader _remoteUploader;

  @override
  void initState() {
    super.initState();
    _recorder = QALabRecorder.ensure();
    _remoteUploader = ensureQALabRemoteUploader();
    if (_recorder.sessionId.value.isEmpty) {
      _recorder.startSession(trigger: 'qa_lab_open');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey<String>(IntegrationTestKeys.screenQaLab),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.maybePop();
            }
          },
        ),
        title: Text('settings.diagnostics.qa_lab'.tr),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 16),
            _buildActionsCard(),
            const SizedBox(height: 16),
            _buildPrioritySurfacesCard(),
            const SizedBox(height: 16),
            _buildCatalogCard(),
            const SizedBox(height: 16),
            _buildFindingsCard(),
            const SizedBox(height: 16),
            _buildRoutesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogCard() {
    final summary = QALabCatalog.summaryJson();
    final byOrigin = summary['byOrigin'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final byTag =
        summary['byTag'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final focusCoverage = summary['focusCoverage'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final focusSurfaces =
        focusCoverage['surfaces'] as List<dynamic>? ?? const <dynamic>[];
    final playbackKpi = maybeFindPlaybackKpiService();
    final telemetryCoverage = playbackKpi == null
        ? const <String, dynamic>{
            'configuredSurfaceCount': 0,
            'observedSurfaceCount': 0,
            'coverageRatio': 0.0,
            'observedSurfaces': <String>[],
            'unobservedSurfaces': <String>[],
          }
        : TelemetryThresholdPolicyAdapter.buildCoverageSummary(playbackKpi);
    final observedTelemetrySurfaces =
        telemetryCoverage['observedSurfaces'] as List<dynamic>? ??
            const <dynamic>[];
    final missingTelemetrySurfaces =
        telemetryCoverage['unobservedSurfaces'] as List<dynamic>? ??
            const <dynamic>[];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'settings.diagnostics.qa_catalog'.tr,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${'settings.diagnostics.qa_total_tests'.tr}: ${summary['totalCount'] ?? 0}',
            ),
            Text(
              '${'settings.diagnostics.qa_runnable'.tr}: ${summary['runnableInAppCount'] ?? 0}',
            ),
            const SizedBox(height: 8),
            Text(
              'focus coverage: ${focusCoverage['completeCount'] ?? 0}/${focusCoverage['surfaceCount'] ?? 0} complete',
            ),
            Text(
              'focus avg coverage: ${(((focusCoverage['averageCoverage'] ?? 0.0) as num) * 100).toStringAsFixed(0)}%',
            ),
            const SizedBox(height: 8),
            Text(
              'runtime telemetry: ${telemetryCoverage['observedSurfaceCount'] ?? 0}/${telemetryCoverage['configuredSurfaceCount'] ?? 0} observed',
            ),
            Text(
              'runtime telemetry ratio: ${(((telemetryCoverage['coverageRatio'] ?? 0.0) as num) * 100).toStringAsFixed(0)}%',
            ),
            const SizedBox(height: 8),
            Text('origin: $byOrigin'),
            Text('tags: $byTag'),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Runtime Telemetry Coverage'),
              children: [
                ListTile(
                  dense: true,
                  title: const Text('Observed surfaces'),
                  subtitle: Text(
                    observedTelemetrySurfaces.isEmpty
                        ? '-'
                        : observedTelemetrySurfaces.join(', '),
                  ),
                ),
                ListTile(
                  dense: true,
                  title: const Text('Missing surfaces'),
                  subtitle: Text(
                    missingTelemetrySurfaces.isEmpty
                        ? '-'
                        : missingTelemetrySurfaces.join(', '),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Critical Surface Coverage'),
              children:
                  focusSurfaces.whereType<Map<String, dynamic>>().map((item) {
                final missingTags =
                    item['missingTags'] as List<dynamic>? ?? const <dynamic>[];
                final missingLabel =
                    missingTags.isEmpty ? '-' : missingTags.join(', ');
                return ListTile(
                  dense: true,
                  title: Text(
                    '${item['surface']} • ${(((item['coverageRatio'] ?? 0.0) as num) * 100).toStringAsFixed(0)}%',
                  ),
                  subtitle: Text('missing: $missingLabel'),
                );
              }).toList(growable: false),
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Catalog Entries'),
              children: QALabCatalog.entries
                  .map(
                    (entry) => ListTile(
                      dense: true,
                      title: Text(entry.title),
                      subtitle: Text(
                        '${entry.origin.name} • ${entry.tags.join(', ')}\n${entry.path}',
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySurfacesCard() {
    return Obx(() {
      final diagnostics = _recorder.buildFocusSurfaceDiagnostics();
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Surface Diagnostics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ...diagnostics.map(
                (item) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${item.surface} • health ${item.healthScore}/100',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'route=${item.latestRoute.isEmpty ? '-' : item.latestRoute}\n'
                    'coverage=${(item.coverage.coverageRatio * 100).toStringAsFixed(0)}% '
                    'missing=${item.coverage.missingTags.isEmpty ? "-" : item.coverage.missingTags.join(", ")}\n'
                    'checkpoints=${item.runtime['checkpointCount'] ?? 0} '
                    'frames=${item.runtime['frameCount'] ?? 0} '
                    'slowFrames=${item.runtime['slowFrameCount'] ?? 0} '
                    'slowRatio=${((((item.runtime['slowFrameRatio'] ?? 0.0) as num) * 100)).toStringAsFixed(1)}% '
                    'avgFrame=${item.runtime['averageFrameTotalMs'] ?? 0}ms '
                    'maxFrame=${item.runtime['maxFrameTotalMs'] ?? 0}ms\n'
                    'frameSamples=${item.runtime['frameSampleCount'] ?? 0} '
                    'videoStarts=${item.runtime['videoSessionStartCount'] ?? 0} '
                    'firstFrames=${item.runtime['videoFirstFrameCount'] ?? 0} '
                    'cacheFails=${item.runtime['cacheFailureCount'] ?? 0} '
                    'jank=${item.runtime['jankEventCount'] ?? 0} '
                    'worstFrame=${item.runtime['worstFrameJankMs'] ?? 0}ms '
                    'noise=${item.runtime['suppressedNoiseCount'] ?? 0} '
                    'permBlocks=${item.runtime['permissionBlockCount'] ?? 0} '
                    'findings=${item.findings.length}\n'
                    'timeline=${item.runtime['timelineEventCount'] ?? 0} '
                    'dupFetch=${item.runtime['duplicateFeedTriggerCount'] ?? 0} '
                    'dupPlay=${item.runtime['duplicatePlaybackDispatchCount'] ?? 0} '
                    'scrollDispatch=${item.runtime['latestScrollDispatchLatencyMs'] ?? 0}ms '
                    'scrollFirstFrame=${item.runtime['latestScrollFirstFrameLatencyMs'] ?? 0}ms '
                    'ads=${item.runtime['adRequestCount'] ?? 0}/${item.runtime['adLoadCount'] ?? 0} '
                    'adFails=${item.runtime['adFailureCount'] ?? 0} '
                    'worstAd=${item.runtime['worstAdLoadMs'] ?? 0}ms'
                    '${item.surface == 'feed' || item.surface == 'short' ? '\n'
                        'nativeStatus=${item.runtime['nativePlaybackStatus'] ?? '-'} '
                        'nativeErrors=${item.runtime['nativePlaybackErrorCount'] ?? 0} '
                        'nativePlaying=${item.runtime['nativePlaybackPlaying'] ?? false} '
                        'nativeBuffering=${item.runtime['nativePlaybackBuffering'] ?? false} '
                        'nativeFirstFrame=${item.runtime['nativePlaybackFirstFrame'] ?? false} '
                        'nativeStalls=${item.runtime['nativePlaybackStallCount'] ?? 0}' : ''}',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton(
              key: const ValueKey<String>(
                IntegrationTestKeys.actionQaCaptureCheckpoint,
              ),
              onPressed: () {
                _recorder.captureCheckpoint(
                  label: 'manual_capture',
                  surface: _recorder.lastSurface.value.isEmpty
                      ? 'manual'
                      : _recorder.lastSurface.value,
                );
                AppSnackbar(
                  'common.success'.tr,
                  'settings.diagnostics.qa_capture'.tr,
                );
              },
              child: Text('settings.diagnostics.qa_capture'.tr),
            ),
            FilledButton(
              key: const ValueKey<String>(
                IntegrationTestKeys.actionQaExportReport,
              ),
              onPressed: () async {
                try {
                  final file = await _recorder.exportSessionJson();
                  AppSnackbar(
                    'common.success'.tr,
                    '${'settings.diagnostics.qa_export_success'.tr}: ${file.path}',
                  );
                } catch (error) {
                  AppSnackbar(
                    'common.error'.tr,
                    '${'settings.diagnostics.qa_export_failed'.tr}: $error',
                  );
                }
              },
              child: Text('settings.diagnostics.qa_export'.tr),
            ),
            FilledButton.tonal(
              onPressed: () async {
                try {
                  await _recorder.syncRemoteSummary(
                    reason: 'manual_cloud_sync',
                    immediate: true,
                  );
                  final syncState = _remoteUploader.lastSyncState.value.trim();
                  final syncError = _remoteUploader.lastSyncError.value.trim();
                  if (syncState == 'synced') {
                    _recorder.resetSession();
                    AppSnackbar(
                      'common.success'.tr,
                      'QA Cloud Sync complete. Session reset.',
                    );
                    return;
                  }
                  AppSnackbar(
                    syncState == 'error' ||
                            syncState == 'permission_denied' ||
                            syncState == 'gate_error'
                        ? 'common.error'.tr
                        : 'common.warning'.tr,
                    syncError.isNotEmpty
                        ? 'QA Cloud Sync state=$syncState error=$syncError'
                        : 'QA Cloud Sync state=$syncState',
                  );
                } catch (error) {
                  AppSnackbar(
                    'common.error'.tr,
                    'QA Cloud Sync failed: $error',
                  );
                }
              },
              child: const Text('Cloud Sync'),
            ),
            OutlinedButton(
              key: const ValueKey<String>(
                IntegrationTestKeys.actionQaShareReport,
              ),
              onPressed: () async {
                try {
                  await _recorder.shareLatestExport();
                } catch (error) {
                  AppSnackbar(
                    'common.error'.tr,
                    '${'settings.diagnostics.qa_export_failed'.tr}: $error',
                  );
                }
              },
              child: Text('settings.diagnostics.qa_share'.tr),
            ),
            TextButton(
              key: const ValueKey<String>(
                IntegrationTestKeys.actionQaResetSession,
              ),
              onPressed: () {
                _recorder.resetSession();
                AppSnackbar(
                  'common.success'.tr,
                  'settings.diagnostics.qa_reset'.tr,
                );
              },
              child: Text('settings.diagnostics.qa_reset'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
