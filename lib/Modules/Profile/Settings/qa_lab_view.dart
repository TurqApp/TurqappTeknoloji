import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Services/qa_lab_catalog.dart';
import 'package:turqappv2/Core/Services/qa_lab_mode.dart';
import 'package:turqappv2/Core/Services/qa_lab_recorder.dart';
import 'package:turqappv2/Core/Services/qa_lab_remote_uploader.dart';
import 'package:turqappv2/Core/app_snackbar.dart';

part 'qa_lab_view_summary_part.dart';
part 'qa_lab_view_actions_part.dart';
part 'qa_lab_view_findings_part.dart';
part 'qa_lab_view_routes_part.dart';

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
    _remoteUploader = QALabRemoteUploader.ensure();
    if (_recorder.sessionId.value.isEmpty) {
      _recorder.startSession(trigger: 'qa_lab_open');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey<String>(IntegrationTestKeys.screenQaLab),
      appBar: AppBar(
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
            Text('origin: $byOrigin'),
            Text('tags: $byTag'),
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
                'Critical Surfaces',
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
}
