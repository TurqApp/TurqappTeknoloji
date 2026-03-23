part of 'permissions_view.dart';

extension _PermissionDetailStatePart on _PermissionDetailViewState {
  Future<void> _loadStatus() async {
    final status = await IntegrationPermissionTestHarness.statusFor(
      widget.item.permission,
      permissionId: _permissionId(widget.item.permission),
    );
    _updatePermissionDetailState(() => _status = status);
  }

  bool get _enabled => _status.isGranted || _status.isLimited;

  bool get _usesDeviceSettingStyle =>
      widget.item.permission == Permission.camera ||
      widget.item.permission == Permission.microphone ||
      widget.item.permission == Permission.notification;
}
