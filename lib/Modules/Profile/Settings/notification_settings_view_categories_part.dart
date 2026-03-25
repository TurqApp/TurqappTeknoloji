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
      _SwitchTile(
        title: 'notifications.posts'.tr,
        subtitle: 'notifications.posts_desc'.tr,
        value: _boolValue('posts.posts'),
        onChanged: (value) => _setValue('posts.posts', value),
      ),
      _SwitchTile(
        title: 'notifications.comments'.tr,
        subtitle: 'notifications.comments_desc'.tr,
        value: _boolValue('posts.comments'),
        onChanged: (value) => _setValue('posts.comments', value),
      ),
      _SwitchTile(
        title: 'notifications.likes'.tr,
        subtitle: 'notifications.likes_desc'.tr,
        value: _boolValue('posts.likes'),
        onChanged: (value) => _setValue('posts.likes', value),
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

class _NotificationCategoryView extends StatefulWidget {
  final String title;
  final List<_NotificationPreferenceItem> items;
  final Map<String, dynamic> initialPrefs;

  const _NotificationCategoryView({
    required this.title,
    required this.items,
    required this.initialPrefs,
  });

  @override
  State<_NotificationCategoryView> createState() =>
      _NotificationCategoryViewState();
}

class _NotificationCategoryViewState extends State<_NotificationCategoryView> {
  late Map<String, dynamic> _prefs;

  @override
  void initState() {
    super.initState();
    _prefs = NotificationPreferencesService.mergeWithDefaults(
      widget.initialPrefs,
    );
  }

  Widget _buildCategoryPage(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: widget.title),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: widget.items.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0x12000000)),
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  return _SwitchTile(
                    title: item.titleKey.tr,
                    subtitle: item.subtitleKey.tr,
                    value: _boolValue(item.path),
                    onChanged: (value) => _setValue(item.path, value),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _boolValue(String path) {
    dynamic current = _prefs;
    for (final segment in path.split('.')) {
      if (current is! Map) return false;
      current = current[segment];
    }
    return current == true;
  }

  Future<void> _setValue(String path, bool value) async {
    final next = NotificationPreferencesService.mergeWithDefaults(_prefs);
    final segments = path.split('.');
    Map<String, dynamic> current = next;
    for (var i = 0; i < segments.length - 1; i++) {
      final key = segments[i];
      final nested = current[key];
      if (nested is Map<String, dynamic>) {
        current = nested;
      } else if (nested is Map) {
        current = Map<String, dynamic>.from(nested);
      } else {
        final created = <String, dynamic>{};
        current[key] = created;
        current = created;
      }
    }
    current[segments.last] = value;
    setState(() {
      _prefs = next;
    });
    await NotificationPreferencesService.setValue(path, value);
  }

  @override
  Widget build(BuildContext context) => _buildCategoryPage(context);
}
