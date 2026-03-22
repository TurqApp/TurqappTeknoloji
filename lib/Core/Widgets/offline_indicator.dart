import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Services/offline_mode_service.dart';

class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final offlineService = OfflineModeService.maybeFind();
    if (offlineService == null) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      if (offlineService.isOnline.value) {
        return const SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.orange.shade700,
        child: SafeArea(
          bottom: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                'offline_indicator.offline_cached'.tr,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'Montserrat',
                ),
              ),
              if (offlineService.pendingActions.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'offline_indicator.pending_count'.trParams(
                        {'count': '${offlineService.pendingActions.length}'}),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontFamily: 'Montserrat',
                    ),
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
