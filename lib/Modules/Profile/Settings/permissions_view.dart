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
part 'permissions_view_catalog_part.dart';
part 'permissions_view_model_part.dart';
part 'permissions_view_status_part.dart';
part 'permissions_view_playback_part.dart';
part 'permissions_view_quota_part.dart';
part 'permissions_view_detail_actions_part.dart';
part 'permissions_view_detail_content_part.dart';
part 'permissions_view_detail_state_part.dart';
part 'permissions_view_detail_shell_part.dart';
part 'permissions_view_shell_part.dart';

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
  Widget build(BuildContext context) => _buildPage(context);
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
