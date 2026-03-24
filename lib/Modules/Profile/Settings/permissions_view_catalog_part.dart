part of 'permissions_view.dart';

class _PermissionItem {
  final String title;
  final Permission permission;
  final String accessText;
  final String helpText;
  final String helpSheetTitle;
  final String helpSheetBody;
  final String? helpSheetBody2;
  final String? helpSheetLinkText;

  const _PermissionItem({
    required this.title,
    required this.permission,
    required this.accessText,
    required this.helpText,
    required this.helpSheetTitle,
    required this.helpSheetBody,
    this.helpSheetBody2,
    this.helpSheetLinkText,
  });
}

String _permissionId(Permission permission) {
  if (permission == Permission.camera) return 'camera';
  if (permission == Permission.contacts) return 'contacts';
  if (permission == Permission.locationWhenInUse) return 'location';
  if (permission == Permission.microphone) return 'microphone';
  if (permission == Permission.notification) return 'notification';
  if (permission == Permission.photos) return 'photos';
  return permission.toString().split('.').last;
}

extension _PermissionsViewCatalogPart on _PermissionsViewState {
  List<_PermissionItem> get _items => [
        _PermissionItem(
          title: 'permissions.item.camera.title'.tr,
          permission: Permission.camera,
          accessText: 'permissions.item.camera.access'.tr,
          helpText: 'permissions.item.camera.help_text'.tr,
          helpSheetTitle: 'permissions.item.camera.help_sheet_title'.tr,
          helpSheetBody: 'permissions.item.camera.help_sheet_body'.tr,
          helpSheetBody2: 'permissions.item.camera.help_sheet_body2'.tr,
          helpSheetLinkText: 'permissions.item.camera.help_sheet_link'.tr,
        ),
        _PermissionItem(
          title: 'permissions.item.contacts.title'.tr,
          permission: Permission.contacts,
          accessText: 'permissions.item.contacts.access'.tr,
          helpText: 'permissions.item.contacts.help_text'.tr,
          helpSheetTitle: 'permissions.item.contacts.help_sheet_title'.tr,
          helpSheetBody: 'permissions.item.contacts.help_sheet_body'.tr,
          helpSheetLinkText: 'permissions.item.contacts.help_sheet_link'.tr,
        ),
        _PermissionItem(
          title: 'permissions.item.location.title'.tr,
          permission: Permission.locationWhenInUse,
          accessText: 'permissions.item.location.access'.tr,
          helpText: 'permissions.item.location.help_text'.tr,
          helpSheetTitle: 'permissions.item.location.help_sheet_title'.tr,
          helpSheetBody: 'permissions.item.location.help_sheet_body'.tr,
          helpSheetBody2: 'permissions.item.location.help_sheet_body2'.tr,
          helpSheetLinkText: 'permissions.item.location.help_sheet_link'.tr,
        ),
        _PermissionItem(
          title: 'permissions.item.microphone.title'.tr,
          permission: Permission.microphone,
          accessText: 'permissions.item.microphone.access'.tr,
          helpText: 'permissions.item.microphone.help_text'.tr,
          helpSheetTitle: 'permissions.item.microphone.help_sheet_title'.tr,
          helpSheetBody: 'permissions.item.microphone.help_sheet_body'.tr,
          helpSheetBody2: 'permissions.item.microphone.help_sheet_body2'.tr,
          helpSheetLinkText: 'permissions.item.microphone.help_sheet_link'.tr,
        ),
        _PermissionItem(
          title: 'permissions.item.notifications.title'.tr,
          permission: Permission.notification,
          accessText: 'permissions.item.notifications.access'.tr,
          helpText: 'permissions.item.notifications.help_text'.tr,
          helpSheetTitle: 'permissions.item.notifications.help_sheet_title'.tr,
          helpSheetBody: 'permissions.item.notifications.help_sheet_body'.tr,
          helpSheetBody2: 'permissions.item.notifications.help_sheet_body2'.tr,
          helpSheetLinkText:
              'permissions.item.notifications.help_sheet_link'.tr,
        ),
        _PermissionItem(
          title: 'permissions.item.photos.title'.tr,
          permission: Permission.photos,
          accessText: 'permissions.item.photos.access'.tr,
          helpText: 'permissions.item.photos.help_text'.tr,
          helpSheetTitle: 'permissions.item.photos.help_sheet_title'.tr,
          helpSheetBody: 'permissions.item.photos.help_sheet_body'.tr,
        ),
      ];

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
