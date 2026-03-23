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
