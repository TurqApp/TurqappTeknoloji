import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Services/notification_preferences_service.dart';

part 'notification_settings_view_main_part.dart';
part 'notification_settings_view_category_part.dart';

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

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
