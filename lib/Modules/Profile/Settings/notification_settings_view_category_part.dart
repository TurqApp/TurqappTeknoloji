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

  @override
  Widget build(BuildContext context) => _buildCategoryPage(context);
}
