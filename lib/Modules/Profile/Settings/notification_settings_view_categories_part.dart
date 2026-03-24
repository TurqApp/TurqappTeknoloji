part of 'notification_settings_view.dart';

class _NotificationPreferenceItem {
  final String path;
  final String titleKey;
  final String subtitleKey;

  const _NotificationPreferenceItem({
    required this.path,
    required this.titleKey,
    required this.subtitleKey,
  });
}

extension _NotificationSettingsViewCategoriesPart
    on _NotificationSettingsViewState {
  List<_NotificationPreferenceItem> get _postsCommentsItems => const [
        _NotificationPreferenceItem(
          path: 'posts.comments',
          titleKey: 'notifications.comments',
          subtitleKey: 'notifications.comments_desc',
        ),
        _NotificationPreferenceItem(
          path: 'posts.postActivity',
          titleKey: 'notifications.post_activity',
          subtitleKey: 'notifications.post_activity_desc',
        ),
      ];

  List<_NotificationPreferenceItem> get _followsItems => const [
        _NotificationPreferenceItem(
          path: 'followers.follows',
          titleKey: 'notifications.follow_notifs',
          subtitleKey: 'notifications.follow_notifs_desc',
        ),
      ];

  List<_NotificationPreferenceItem> get _messagesItems => const [
        _NotificationPreferenceItem(
          path: 'messages.directMessages',
          titleKey: 'notifications.direct_messages',
          subtitleKey: 'notifications.direct_messages_desc',
        ),
      ];

  List<_NotificationPreferenceItem> get _opportunitiesItems => const [
        _NotificationPreferenceItem(
          path: 'opportunities.jobApplications',
          titleKey: 'notifications.job_apps',
          subtitleKey: 'notifications.job_apps_desc',
        ),
        _NotificationPreferenceItem(
          path: 'opportunities.tutoringApplications',
          titleKey: 'notifications.tutoring_apps',
          subtitleKey: 'notifications.tutoring_apps_desc',
        ),
        _NotificationPreferenceItem(
          path: 'opportunities.applicationStatus',
          titleKey: 'notifications.application_status',
          subtitleKey: 'notifications.application_status_desc',
        ),
      ];

  List<Widget> _buildCategorySection(BuildContext context) {
    return [
      _SectionLabel('notifications.categories'.tr),
      _NavTile(
        title: 'notifications.posts_comments'.tr,
        subtitle: 'notifications.posts_comments_desc'.tr,
        onTap: () => _openCategory(
          context,
          title: 'notifications.posts_comments'.tr,
          items: _postsCommentsItems,
        ),
      ),
      _NavTile(
        title: 'notifications.follows'.tr,
        subtitle: 'notifications.follows_desc'.tr,
        onTap: () => _openCategory(
          context,
          title: 'notifications.follows'.tr,
          items: _followsItems,
        ),
      ),
      _NavTile(
        title: 'notifications.messages'.tr,
        subtitle: 'notifications.messages_desc'.tr,
        onTap: () => _openCategory(
          context,
          title: 'notifications.messages'.tr,
          items: _messagesItems,
        ),
      ),
      _NavTile(
        title: 'notifications.opportunities'.tr,
        subtitle: 'notifications.opportunities_desc'.tr,
        onTap: () => _openCategory(
          context,
          title: 'notifications.opportunities'.tr,
          items: _opportunitiesItems,
        ),
      ),
    ];
  }

  void _openCategory(
    BuildContext context, {
    required String title,
    required List<_NotificationPreferenceItem> items,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _NotificationCategoryView(
          title: title,
          items: items,
          initialPrefs: _prefs,
        ),
      ),
    );
  }
}
