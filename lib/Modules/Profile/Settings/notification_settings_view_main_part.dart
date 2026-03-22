part of 'notification_settings_view.dart';

extension _NotificationSettingsViewMainPart on _NotificationSettingsViewState {
  Future<void> _load() async {
    final prefs =
        await NotificationPreferencesService.getCurrentUserPreferences();
    if (!mounted) return;
    _updateViewState(() {
      _prefs = prefs;
      _loading = false;
    });
  }

  Future<void> _setValue(String path, bool value) async {
    final next = NotificationPreferencesService.mergeWithDefaults(_prefs);
    _writePath(next, path, value);
    _updateViewState(() {
      _prefs = next;
    });
    await NotificationPreferencesService.setValue(path, value);
  }

  void _writePath(Map<String, dynamic> source, String path, dynamic value) {
    final segments = path.split('.');
    Map<String, dynamic> current = source;
    for (var i = 0; i < segments.length - 1; i++) {
      final key = segments[i];
      final next = current[key];
      if (next is Map<String, dynamic>) {
        current = next;
      } else if (next is Map) {
        current = Map<String, dynamic>.from(next);
      } else {
        final created = <String, dynamic>{};
        current[key] = created;
        current = created;
      }
    }
    current[segments.last] = value;
  }

  bool _boolValue(String path) {
    dynamic current = _prefs;
    for (final segment in path.split('.')) {
      if (current is! Map) return false;
      current = current[segment];
    }
    return current == true;
  }

  Widget _buildPage(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'notifications.title'.tr),
            Expanded(
              child: _loading
                  ? const Center(child: CupertinoActivityIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        _deviceNoticeCard(),
                        const SizedBox(height: 18),
                        _SectionLabel('notifications.instant'.tr),
                        _SwitchTile(
                          title: 'notifications.pause_all'.tr,
                          subtitle: 'notifications.pause_all_desc'.tr,
                          value: _boolValue('pauseAll'),
                          onChanged: (value) => _setValue('pauseAll', value),
                        ),
                        _SwitchTile(
                          title: 'notifications.sleep_mode'.tr,
                          subtitle: 'notifications.sleep_mode_desc'.tr,
                          value: _boolValue('sleepMode'),
                          onChanged: (value) => _setValue('sleepMode', value),
                        ),
                        _SwitchTile(
                          title: 'notifications.messages_only'.tr,
                          subtitle: 'notifications.messages_only_desc'.tr,
                          value: _boolValue('messagesOnly'),
                          onChanged: (value) =>
                              _setValue('messagesOnly', value),
                        ),
                        const SizedBox(height: 14),
                        _SectionLabel('notifications.categories'.tr),
                        _NavTile(
                          title: 'notifications.posts_comments'.tr,
                          subtitle: 'notifications.posts_comments_desc'.tr,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _NotificationCategoryView(
                                title: 'notifications.posts_comments'.tr,
                                items: const [
                                  _NotificationPreferenceItem(
                                    path: 'posts.comments',
                                    titleKey: 'notifications.comments',
                                    subtitleKey: 'notifications.comments_desc',
                                  ),
                                  _NotificationPreferenceItem(
                                    path: 'posts.postActivity',
                                    titleKey: 'notifications.post_activity',
                                    subtitleKey:
                                        'notifications.post_activity_desc',
                                  ),
                                ],
                                initialPrefs: _prefs,
                              ),
                            ),
                          ),
                        ),
                        _NavTile(
                          title: 'notifications.follows'.tr,
                          subtitle: 'notifications.follows_desc'.tr,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _NotificationCategoryView(
                                title: 'notifications.follows'.tr,
                                items: const [
                                  _NotificationPreferenceItem(
                                    path: 'followers.follows',
                                    titleKey: 'notifications.follow_notifs',
                                    subtitleKey:
                                        'notifications.follow_notifs_desc',
                                  ),
                                ],
                                initialPrefs: _prefs,
                              ),
                            ),
                          ),
                        ),
                        _NavTile(
                          title: 'notifications.messages'.tr,
                          subtitle: 'notifications.messages_desc'.tr,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _NotificationCategoryView(
                                title: 'notifications.messages'.tr,
                                items: const [
                                  _NotificationPreferenceItem(
                                    path: 'messages.directMessages',
                                    titleKey: 'notifications.direct_messages',
                                    subtitleKey:
                                        'notifications.direct_messages_desc',
                                  ),
                                ],
                                initialPrefs: _prefs,
                              ),
                            ),
                          ),
                        ),
                        _NavTile(
                          title: 'notifications.opportunities'.tr,
                          subtitle: 'notifications.opportunities_desc'.tr,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _NotificationCategoryView(
                                title: 'notifications.opportunities'.tr,
                                items: const [
                                  _NotificationPreferenceItem(
                                    path: 'opportunities.jobApplications',
                                    titleKey: 'notifications.job_apps',
                                    subtitleKey: 'notifications.job_apps_desc',
                                  ),
                                  _NotificationPreferenceItem(
                                    path: 'opportunities.tutoringApplications',
                                    titleKey: 'notifications.tutoring_apps',
                                    subtitleKey:
                                        'notifications.tutoring_apps_desc',
                                  ),
                                  _NotificationPreferenceItem(
                                    path: 'opportunities.applicationStatus',
                                    titleKey:
                                        'notifications.application_status',
                                    subtitleKey:
                                        'notifications.application_status_desc',
                                  ),
                                ],
                                initialPrefs: _prefs,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _deviceNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x12000000)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              CupertinoIcons.bell,
              size: 20,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'notifications.device_notice'.tr,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    height: 1.25,
                    fontFamily: 'MontserratMedium',
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: openAppSettings,
                  child: Text(
                    'notifications.device_settings'.tr,
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 13,
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
