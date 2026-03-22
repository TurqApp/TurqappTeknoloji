import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/app_icon_surface.dart';

class FeedInboxActionsRow extends StatelessWidget {
  const FeedInboxActionsRow({
    super.key,
    required this.actionSize,
    required this.spacing,
    required this.showChatBadge,
    required this.showNotificationBadge,
    required this.onChatTap,
    required this.onNotificationsTap,
  });

  final double actionSize;
  final double spacing;
  final bool showChatBadge;
  final bool showNotificationBadge;
  final VoidCallback onChatTap;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppHeaderActionButton(
          key: const ValueKey(IntegrationTestKeys.navChat),
          badgeKey: const ValueKey('feed-chat-badge'),
          size: actionSize,
          showBadge: showChatBadge,
          onTap: onChatTap,
          child: const Icon(
            CupertinoIcons.mail,
            color: Colors.black,
            size: AppIconSurface.kIconSize,
          ),
        ),
        SizedBox(width: spacing),
        AppHeaderActionButton(
          key: const ValueKey(IntegrationTestKeys.actionOpenNotifications),
          badgeKey: const ValueKey('feed-notifications-badge'),
          size: actionSize,
          showBadge: showNotificationBadge,
          onTap: onNotificationsTap,
          child: const Icon(
            CupertinoIcons.bell,
            color: Colors.black,
            size: AppIconSurface.kIconSize,
          ),
        ),
      ],
    );
  }
}
