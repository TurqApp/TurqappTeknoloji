import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Services/notification_preferences_service.dart';

part 'notification_settings_view_categories_part.dart';
part 'notification_settings_view_data_part.dart';
part 'notification_settings_view_notice_part.dart';
part 'notification_settings_view_category_part.dart';
part 'notification_settings_view_category_catalog_part.dart';
part 'notification_settings_view_category_data_part.dart';
part 'notification_settings_view_components_part.dart';

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

  void _updateViewState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
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
                        ..._buildInstantSection(),
                        const SizedBox(height: 14),
                        ..._buildCategorySection(context),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildInstantSection() {
    return [
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
        onChanged: (value) => _setValue('messagesOnly', value),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
