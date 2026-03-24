part of 'qa_lab_view.dart';

extension _QALabViewActionsPart on _QALabViewState {
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
                  AppSnackbar(
                    'common.success'.tr,
                    'QA Cloud Sync queued',
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
