part of 'qa_lab_recorder.dart';

extension _QALabRecorderSessionPart on QALabRecorder {
  Future<void> _prepareFreshStartImpl({String trigger = 'launch'}) async {
    if (!QALabMode.enabled) return;
    final clearedTargets = <String>[];
    final cleanupFailures = <Map<String, String>>[];

    Future<void> clearChildren(
      Directory directory, {
      required String label,
    }) async {
      if (!await directory.exists()) {
        return;
      }
      var cleared = 0;
      await for (final entity in directory.list(followLinks: false)) {
        await entity.delete(recursive: true);
        cleared += 1;
      }
      if (cleared > 0) {
        clearedTargets.add('$label:$cleared');
      }
    }

    Future<void> deleteDirectory(
      Directory directory, {
      required String label,
    }) async {
      if (!await directory.exists()) {
        return;
      }
      await directory.delete(recursive: true);
      clearedTargets.add(label);
    }

    Future<void> safeCleanup(
      Future<void> Function() action, {
      required String label,
    }) async {
      try {
        await action();
      } catch (error) {
        cleanupFailures.add(
          <String, String>{
            'target': label,
            'error': error.toString(),
          },
        );
      }
    }

    await safeCleanup(
      () async => clearChildren(
        await getTemporaryDirectory(),
        label: 'temp',
      ),
      label: 'temp',
    );
    await safeCleanup(
      () async {
        final supportDirectory = await getApplicationSupportDirectory();
        await deleteDirectory(
          Directory('${supportDirectory.path}/hls_cache'),
          label: 'hls_cache',
        );
        await deleteDirectory(
          Directory('${supportDirectory.path}/index_pool'),
          label: 'index_pool',
        );
      },
      label: 'app_support',
    );
    await safeCleanup(
      () async {
        final documentsDirectory = await getApplicationDocumentsDirectory();
        await deleteDirectory(
          Directory('${documentsDirectory.path}/qa_lab'),
          label: 'qa_lab_reports',
        );
      },
      label: 'documents',
    );

    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      clearedTargets.add('image_cache');
    } catch (error) {
      cleanupFailures.add(
        <String, String>{
          'target': 'image_cache',
          'error': error.toString(),
        },
      );
    }

    QALabRemoteUploader.maybeFind()?.resetLocalState();
    startSession(trigger: 'fresh_start:$trigger');
    captureCheckpoint(
      label: 'fresh_start_applied',
      surface: lastSurface.value.isEmpty ? 'app' : lastSurface.value,
      extra: <String, dynamic>{
        'trigger': trigger,
        'clearedTargets': clearedTargets,
        'cleanupFailureCount': cleanupFailures.length,
      },
    );
    for (final failure in cleanupFailures) {
      recordIssue(
        source: QALabIssueSource.cache,
        code: 'qa_fresh_start_cleanup_failed',
        severity: QALabIssueSeverity.warning,
        message: 'QA fresh-start cache cleanup failed.',
        metadata: failure,
      );
    }
  }
}
