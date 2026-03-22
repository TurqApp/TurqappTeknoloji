import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

class NotificationActionsSheetContent extends StatelessWidget {
  const NotificationActionsSheetContent({
    super.key,
    required this.unreadCount,
    required this.busyMarkAllRead,
    required this.onMarkAllRead,
    required this.onDeleteAll,
  });

  final int unreadCount;
  final bool busyMarkAllRead;
  final VoidCallback onMarkAllRead;
  final VoidCallback onDeleteAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(215),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 8),
                _NotificationActionTile(
                  icon: Icons.mark_email_read_outlined,
                  title: busyMarkAllRead
                      ? 'notifications.marking_read'.tr
                      : 'notifications.mark_all_read'.tr,
                  integrationKey:
                      IntegrationTestKeys.actionNotificationsMarkAllRead,
                  enabled: unreadCount > 0 && !busyMarkAllRead,
                  onTap: onMarkAllRead,
                ),
                Divider(height: 1, color: Colors.black.withAlpha(18)),
                _NotificationActionTile(
                  icon: Icons.delete_outline,
                  title: 'notifications.delete_all'.tr,
                  integrationKey:
                      IntegrationTestKeys.actionNotificationsDeleteAll,
                  isDestructive: true,
                  onTap: onDeleteAll,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationActionTile extends StatelessWidget {
  const _NotificationActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.integrationKey,
    this.enabled = true,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? integrationKey;
  final bool enabled;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final textColor = !enabled
        ? Colors.black38
        : (isDestructive ? Colors.redAccent : Colors.black87);
    return InkWell(
      key: integrationKey == null ? null : ValueKey(integrationKey),
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontFamily: 'MontserratMedium',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
