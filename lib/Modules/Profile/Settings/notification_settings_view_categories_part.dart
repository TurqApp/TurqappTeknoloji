part of 'notification_settings_view.dart';

extension _NotificationSettingsViewCategoriesPart
    on _NotificationSettingsViewState {
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
