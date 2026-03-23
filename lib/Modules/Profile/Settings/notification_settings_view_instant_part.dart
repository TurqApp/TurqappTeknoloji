part of 'notification_settings_view.dart';

extension _NotificationSettingsViewInstantPart
    on _NotificationSettingsViewState {
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
}
