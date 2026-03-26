// ignore_for_file: file_names

part of 'package:turqappv2/Modules/Profile/Settings/settings.dart';

extension _SettingsViewDiagnosticsDetailPart on _SettingsViewState {
  void _showOfflineQueueDetails() {
    final offline = ensureOfflineModeService();

    Get.dialog(
      AlertDialog(
        title: Text("settings.diagnostics.offline_queue_detail".tr),
        content: SizedBox(
          width: double.maxFinite,
          child: Obx(() {
            final pending = offline.pendingActions.toList();
            final dead = offline.deadLetterActions.toList();
            final stats = offline.getQueueStats();

            String fmtMs(int ms) {
              if (ms <= 0) return '-';
              final dt = DateTime.fromMillisecondsSinceEpoch(ms);
              return dt.toString();
            }

            Widget buildItem(PendingAction a) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.type,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'attempt=${a.attemptCount}  next=${fmtMs(a.nextAttemptAtMs)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                      if ((a.lastError ?? '').isNotEmpty)
                        Text(
                          'error=${a.lastError}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.redAccent,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      "${'settings.diagnostics.online'.tr}: ${stats['isOnline']}"),
                  Text(
                      "${'settings.diagnostics.sync'.tr}: ${stats['isSyncing']}"),
                  Text(
                      "${'settings.diagnostics.pending'.tr}: ${pending.length}"),
                  Text(
                      "${'settings.diagnostics.dead_letter'.tr}: ${dead.length}"),
                  Text(
                      "${'settings.diagnostics.processed'.tr}: ${stats['processedCount'] ?? 0}"),
                  Text(
                      "${'settings.diagnostics.failed'.tr}: ${stats['failedCount'] ?? 0}"),
                  const SizedBox(height: 10),
                  Text(
                    'settings.diagnostics.pending_first8'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  if (pending.isEmpty)
                    const Text('-', style: TextStyle(color: Colors.black54)),
                  ...pending.take(8).map(buildItem),
                  const SizedBox(height: 8),
                  Text(
                    'settings.diagnostics.dead_letter_first8'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  if (dead.isEmpty)
                    const Text('-', style: TextStyle(color: Colors.black54)),
                  ...dead.take(8).map(buildItem),
                ],
              ),
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await OfflineModeService.instance
                  .processPendingNow(ignoreBackoff: true);
            },
            child: Text('settings.diagnostics.sync_now'.tr),
          ),
          TextButton(
            onPressed: () async {
              await OfflineModeService.instance.retryDeadLetter(limit: 100);
            },
            child: Text('settings.diagnostics.dead_letter_retry'.tr),
          ),
          TextButton(
            onPressed: () async {
              await OfflineModeService.instance.clearDeadLetter();
            },
            child: Text('settings.diagnostics.dead_letter_clear'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: Text("common.close".tr),
          ),
        ],
      ),
    );
  }

  void _showLastErrorSummary() {
    final errorService = ErrorHandlingService.ensure();
    final last = errorService.getLastErrorSummary();

    Get.dialog(
      AlertDialog(
        title: Text("settings.diagnostics.last_error_summary".tr),
        content: last == null
            ? Text("settings.diagnostics.no_recorded_error".tr)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      "${'settings.diagnostics.error_code'.tr}: ${last['code']}"),
                  Text(
                      "${'settings.diagnostics.error_category'.tr}: ${last['category']}"),
                  Text(
                      "${'settings.diagnostics.error_severity'.tr}: ${last['severity']}"),
                  Text(
                      "${'settings.diagnostics.error_retryable'.tr}: ${last['retryable']}"),
                  Text(
                      "${'settings.diagnostics.error_message'.tr}: ${last['userFriendlyMessage']}"),
                  Text(
                      "${'settings.diagnostics.error_time'.tr}: ${last['timestamp']}"),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("common.close".tr),
          ),
        ],
      ),
    );
  }
}
