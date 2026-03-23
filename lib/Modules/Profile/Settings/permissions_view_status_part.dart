part of 'permissions_view.dart';

extension _PermissionsViewStatusPart on _PermissionsViewState {
  Future<void> _refreshStatuses() async {
    _updatePermissionsViewState(() => _loading = true);
    final next = <String, PermissionStatus>{};
    for (final item in _items) {
      next[_permissionId(item.permission)] =
          await IntegrationPermissionTestHarness.statusFor(
        item.permission,
        permissionId: _permissionId(item.permission),
      );
    }
    IntegrationTestStateProbe.updatePermissionStatuses(next);
    _updatePermissionsViewState(() {
      _statuses
        ..clear()
        ..addAll(next);
      _loading = false;
    });
  }

  String _statusLabel(PermissionStatus status) {
    if (status.isGranted || status.isLimited) return 'permissions.allowed'.tr;
    return 'permissions.denied'.tr;
  }

  Widget _buildPermissionListItem(_PermissionItem item) {
    final permissionId = _permissionId(item.permission);
    final status = _statuses[permissionId] ?? PermissionStatus.denied;
    return InkWell(
      key: ValueKey<String>(IntegrationTestKeys.permissionItem(permissionId)),
      onTap: () async {
        await Get.to(() => _PermissionDetailView(item: item));
        await _refreshStatuses();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: 'MontserratMedium',
                ),
              ),
            ),
            Text(
              _statusLabel(status),
              key: ValueKey<String>(
                IntegrationTestKeys.permissionStatus(permissionId),
              ),
              style: const TextStyle(
                color: Colors.black38,
                fontSize: 15,
                fontFamily: 'MontserratMedium',
              ),
            ),
            const SizedBox(width: 8),
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
