part of 'permissions_view.dart';

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
}
