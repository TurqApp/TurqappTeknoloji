import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Services/notification_preferences_service.dart';

class NotificationSettingsView extends StatefulWidget {
  const NotificationSettingsView({super.key});

  @override
  State<NotificationSettingsView> createState() =>
      _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView> {
  Map<String, dynamic> _prefs = NotificationPreferencesService.defaults();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs =
        await NotificationPreferencesService.getCurrentUserPreferences();
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _loading = false;
    });
  }

  Future<void> _setValue(String path, bool value) async {
    final next = NotificationPreferencesService.mergeWithDefaults(_prefs);
    _writePath(next, path, value);
    setState(() {
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

  @override
  Widget build(BuildContext context) {
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
                                    titleKey:
                                        'notifications.direct_messages',
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
                                    subtitleKey:
                                        'notifications.job_apps_desc',
                                  ),
                                  _NotificationPreferenceItem(
                                    path: 'opportunities.tutoringApplications',
                                    titleKey:
                                        'notifications.tutoring_apps',
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
  Widget build(BuildContext context) {
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
}

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

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black45,
            fontSize: 13,
            fontFamily: 'MontserratBold',
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    fontFamily: 'MontserratMedium',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 13,
                    height: 1.25,
                    fontFamily: 'MontserratMedium',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black45,
                      fontSize: 13,
                      height: 1.25,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              CupertinoIcons.chevron_right,
              color: Colors.black38,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
