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

part 'permissions_view_catalog_part.dart';
part 'permissions_view_model_part.dart';
part 'permissions_view_status_part.dart';
part 'permissions_view_playback_part.dart';
part 'permissions_view_quota_part.dart';
part 'permissions_view_detail_actions_part.dart';
part 'permissions_view_detail_content_part.dart';

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

  Widget _buildPage(BuildContext context) {
    return Scaffold(
      key: const ValueKey<String>(IntegrationTestKeys.screenPermissions),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'permissions.title'.tr),
            Expanded(
              child: _loading
                  ? const Center(child: CupertinoActivityIndicator())
                  : RefreshIndicator(
                      onRefresh: _refreshStatuses,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          Text(
                            'permissions.preferences'.tr,
                            style: const TextStyle(
                              color: Colors.black45,
                              fontSize: 13,
                              fontFamily: 'MontserratMedium',
                            ),
                          ),
                          const SizedBox(height: 10),
                          ..._items.map(_buildPermissionListItem),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          Text(
                            'permissions.offline_space'.tr,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontFamily: 'MontserratMedium',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              for (int i = 0;
                                  i <
                                      _PermissionsViewState
                                          ._quotaOptions.length;
                                  i++) ...[
                                Expanded(
                                  child: _buildQuotaButton(
                                    _PermissionsViewState._quotaOptions[i],
                                  ),
                                ),
                                if (i !=
                                    _PermissionsViewState._quotaOptions.length -
                                        1)
                                  const SizedBox(width: 10),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'permissions.offline_space_desc'.tr,
                            style: const TextStyle(
                              color: Colors.black45,
                              fontSize: 13,
                              fontFamily: 'Montserrat',
                              height: 1.3,
                            ),
                          ),
                          _buildQuotaBreakdown(),
                          if (_showPlaybackPreferences)
                            _buildPlaybackPolicyCard(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
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
