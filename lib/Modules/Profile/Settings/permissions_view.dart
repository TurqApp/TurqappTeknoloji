import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Services/integration_permission_test_harness.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Services/integration_test_state_probe.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/storage_budget_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_metrics.dart';
import 'package:turqappv2/Core/Services/network_awareness_service.dart';

part 'permissions_view_main_part.dart';
part 'permissions_view_detail_part.dart';

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

class PermissionsView extends StatefulWidget {
  const PermissionsView({super.key});

  @override
  State<PermissionsView> createState() => _PermissionsViewState();
}

class _PermissionsViewState extends State<PermissionsView> {
  static const String _quotaKey = 'offline_cache_quota_gb';
  static const List<int> _quotaOptions = [3, 4, 5, 6];
  static const int _minDisplayQuotaGb = 3;
  static const int _maxDisplayQuotaGb = 6;
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

  final Map<String, PermissionStatus> _statuses = {};
  bool _loading = true;
  int _selectedQuota = 3;
  bool _showPlaybackPreferences = false;
  NetworkSettings _networkSettings = NetworkSettings();

  @override
  void initState() {
    super.initState();
    _initializePermissionsView();
  }

  @override
  void dispose() {
    IntegrationTestStateProbe.clearPermissionStatuses();
    super.dispose();
  }

  void _updatePermissionsViewState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return _buildPermissionsScaffold(context);
  }
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

class _PermissionDetailView extends StatefulWidget {
  final _PermissionItem item;
  const _PermissionDetailView({required this.item});

  @override
  State<_PermissionDetailView> createState() => _PermissionDetailViewState();
}

class _PermissionDetailViewState extends State<_PermissionDetailView> {
  PermissionStatus _status = PermissionStatus.denied;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  void _updatePermissionDetailState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return _buildPermissionDetailScaffold(context);
  }
}
