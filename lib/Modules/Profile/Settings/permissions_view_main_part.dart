part of 'permissions_view.dart';

extension _PermissionsViewMainPart on _PermissionsViewState {
  void _initializePermissionsView() {
    _loadQuota();
    _loadAdminVisibility();
    _loadNetworkSettings();
    _refreshStatuses();
  }

  Future<void> _loadAdminVisibility() async {
    final canManage = await AdminAccessService.canManageSliders();
    _updatePermissionsViewState(() => _showPlaybackPreferences = canManage);
  }
}
