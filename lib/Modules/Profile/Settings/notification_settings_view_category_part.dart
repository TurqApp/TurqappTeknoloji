part of 'notification_settings_view.dart';

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
