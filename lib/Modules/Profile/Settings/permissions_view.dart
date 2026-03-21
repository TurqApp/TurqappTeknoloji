import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/storage_budget_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_metrics.dart';
import 'package:turqappv2/Core/Services/network_awareness_service.dart';

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
    _loadQuota();
    _loadAdminVisibility();
    _loadNetworkSettings();
    _refreshStatuses();
  }

  int _normalizeDisplayQuota(int gb) =>
      gb.clamp(_minDisplayQuotaGb, _maxDisplayQuotaGb);

  int _effectiveQuotaGb(int displayGb) =>
      (_normalizeDisplayQuota(displayGb) + 1).clamp(4, 7);

  Future<void> _loadAdminVisibility() async {
    final canManage = await AdminAccessService.canManageSliders();
    if (!mounted) return;
    setState(() => _showPlaybackPreferences = canManage);
  }

  Future<void> _loadQuota() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = _normalizeDisplayQuota(prefs.getInt(_quotaKey) ?? 3);
    final effectiveQuota = _effectiveQuotaGb(saved);
    if (Get.isRegistered<StorageBudgetManager>()) {
      await Get.find<StorageBudgetManager>().applyPlanGb(effectiveQuota);
    }
    if (Get.isRegistered<SegmentCacheManager>()) {
      await Get.find<SegmentCacheManager>().setUserLimitGB(effectiveQuota);
    }
    if (!mounted) return;
    setState(() => _selectedQuota = saved);
  }

  Future<void> _setQuota(int gb) async {
    final displayQuota = _normalizeDisplayQuota(gb);
    final effectiveQuota = _effectiveQuotaGb(displayQuota);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_quotaKey, displayQuota);
    try {
      if (Get.isRegistered<StorageBudgetManager>()) {
        await Get.find<StorageBudgetManager>().applyPlanGb(effectiveQuota);
      }
      if (Get.isRegistered<SegmentCacheManager>()) {
        await Get.find<SegmentCacheManager>().setUserLimitGB(effectiveQuota);
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _selectedQuota = displayQuota);
  }

  Future<void> _loadNetworkSettings() async {
    final networkService = NetworkAwarenessService.maybeFind();
    if (networkService == null) return;
    final settings = networkService.settings;
    if (!mounted) return;
    setState(() {
      _networkSettings = NetworkSettings(
        autoUploadOnWiFi: settings.autoUploadOnWiFi,
        pauseOnCellular: settings.pauseOnCellular,
        cellularDataMode: settings.cellularDataMode,
        wifiDataMode: settings.wifiDataMode,
        showDataWarnings: settings.showDataWarnings,
        monthlyDataLimitMB: settings.monthlyDataLimitMB,
        mobileTargetMbps: settings.mobileTargetMbps,
      );
    });
  }

  Future<void> _updateNetworkSettings({
    bool? pauseOnCellular,
    DataUsageMode? cellularDataMode,
    DataUsageMode? wifiDataMode,
  }) async {
    final next = NetworkSettings(
      autoUploadOnWiFi: _networkSettings.autoUploadOnWiFi,
      pauseOnCellular: pauseOnCellular ?? _networkSettings.pauseOnCellular,
      cellularDataMode: cellularDataMode ?? _networkSettings.cellularDataMode,
      wifiDataMode: wifiDataMode ?? _networkSettings.wifiDataMode,
      showDataWarnings: _networkSettings.showDataWarnings,
      monthlyDataLimitMB: _networkSettings.monthlyDataLimitMB,
      mobileTargetMbps: _networkSettings.mobileTargetMbps,
    );

    final networkService = NetworkAwarenessService.maybeFind();
    if (networkService != null) {
      await networkService.updateSettings(next);
    }

    if (!mounted) return;
    setState(() => _networkSettings = next);
  }

  Future<void> _refreshStatuses() async {
    setState(() => _loading = true);
    final next = <String, PermissionStatus>{};
    for (final item in _items) {
      next[item.title] = await item.permission.status;
    }
    if (!mounted) return;
    setState(() {
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

  Widget _buildQuotaButton(int gb) {
    final selected = _selectedQuota == gb;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _setQuota(gb),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.black : Colors.black26,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          '$gb GB',
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontSize: 14,
            fontFamily: 'MontserratMedium',
          ),
        ),
      ),
    );
  }

  Widget _buildQuotaBreakdown() {
    final profile = StorageBudgetManager.profileForPlanGb(
        _effectiveQuotaGb(_selectedQuota));
    final usage = Get.isRegistered<SegmentCacheManager>()
        ? StorageBudgetManager.usageSnapshotForProfile(
            profile,
            streamUsageBytes: Get.find<SegmentCacheManager>().totalSizeBytes,
          )
        : null;
    final recentProtectionWindow =
        StorageBudgetManager.recentProtectionWindowForUsage(
      profile,
      streamUsageBytes: usage?.streamUsageBytes ?? 0,
    );
    final rows = <MapEntry<String, int>>[
      MapEntry('permissions.quota.media_cache'.tr, profile.mediaQuotaBytes),
      MapEntry('permissions.quota.image_cache'.tr, profile.imageQuotaBytes),
      MapEntry('permissions.quota.metadata'.tr, profile.metadataQuotaBytes),
      MapEntry('permissions.quota.reserve'.tr, profile.reserveQuotaBytes),
      MapEntry('permissions.quota.os_safety'.tr, profile.osSafetyMarginBytes),
    ];

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'permissions.quota.plan_distribution'
                .trParams(<String, String>{'gb': '$_selectedQuota'}),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontFamily: 'MontserratSemiBold',
            ),
          ),
          const SizedBox(height: 10),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.key,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                  ),
                  Text(
                    CacheMetrics.formatBytes(row.value),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontFamily: 'MontserratSemiBold',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${'permissions.quota.soft_stop'.tr}: ${CacheMetrics.formatBytes(profile.streamCacheSoftStopBytes)}',
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 12,
              fontFamily: 'MontserratMedium',
            ),
          ),
          Text(
            '${'permissions.quota.hard_stop'.tr}: ${CacheMetrics.formatBytes(profile.streamCacheHardStopBytes)}',
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 12,
              fontFamily: 'MontserratMedium',
            ),
          ),
          Text(
            'permissions.quota.recent_window'
                .trParams(<String, String>{'count': '$recentProtectionWindow'}),
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 12,
              fontFamily: 'MontserratMedium',
            ),
          ),
          if (usage != null) ...[
            const SizedBox(height: 10),
            Text(
              '${'permissions.quota.active_stream'.tr}: ${CacheMetrics.formatBytes(usage.streamUsageBytes)}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontFamily: 'MontserratSemiBold',
              ),
            ),
            Text(
              '${'permissions.quota.soft_remaining'.tr}: ${CacheMetrics.formatBytes(usage.remainingBeforeSoftStopBytes)}',
              style: const TextStyle(
                color: Colors.black45,
                fontSize: 12,
                fontFamily: 'MontserratMedium',
              ),
            ),
            Text(
              '${'permissions.quota.hard_remaining'.tr}: ${CacheMetrics.formatBytes(usage.remainingBeforeHardStopBytes)}',
              style: const TextStyle(
                color: Colors.black45,
                fontSize: 12,
                fontFamily: 'MontserratMedium',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Colors.black : Colors.black26,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
              fontSize: 12,
              fontFamily: 'MontserratMedium',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataModeSelector({
    required String title,
    required String description,
    required DataUsageMode value,
    required ValueChanged<DataUsageMode> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontFamily: 'MontserratSemiBold',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 12,
              fontFamily: 'MontserratMedium',
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildModeButton(
                label: DataUsageMode.low.label,
                selected: value == DataUsageMode.low,
                onTap: () => onChanged(DataUsageMode.low),
              ),
              const SizedBox(width: 8),
              _buildModeButton(
                label: DataUsageMode.normal.label,
                selected: value == DataUsageMode.normal,
                onTap: () => onChanged(DataUsageMode.normal),
              ),
              const SizedBox(width: 8),
              _buildModeButton(
                label: DataUsageMode.high.label,
                selected: value == DataUsageMode.high,
                onTap: () => onChanged(DataUsageMode.high),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackPolicyCard() {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'permissions.playback.title'.tr,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontFamily: 'MontserratSemiBold',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'permissions.playback.help'.tr,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 12,
              fontFamily: 'MontserratMedium',
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'permissions.playback.limit_cellular'.tr,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontFamily: 'MontserratSemiBold',
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'permissions.playback.limit_cellular_desc'.tr,
                      style: TextStyle(
                        color: Colors.black45,
                        fontSize: 12,
                        fontFamily: 'MontserratMedium',
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch.adaptive(
                value: _networkSettings.pauseOnCellular,
                onChanged: (value) =>
                    _updateNetworkSettings(pauseOnCellular: value),
              ),
            ],
          ),
          _buildDataModeSelector(
            title: 'permissions.playback.cellular_mode'.tr,
            description: 'permissions.playback.cellular_mode_desc'.tr,
            value: _networkSettings.cellularDataMode,
            onChanged: (value) =>
                _updateNetworkSettings(cellularDataMode: value),
          ),
          _buildDataModeSelector(
            title: 'permissions.playback.wifi_mode'.tr,
            description: 'permissions.playback.wifi_mode_desc'.tr,
            value: _networkSettings.wifiDataMode,
            onChanged: (value) => _updateNetworkSettings(wifiDataMode: value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                            style: TextStyle(
                              color: Colors.black45,
                              fontSize: 13,
                              fontFamily: 'MontserratMedium',
                            ),
                          ),
                          const SizedBox(height: 10),
                          ..._items.map((item) {
                            final status = _statuses[item.title] ??
                                PermissionStatus.denied;
                            return InkWell(
                              onTap: () => Get.to(
                                  () => _PermissionDetailView(item: item)),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
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
                          }),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          Text(
                            'permissions.offline_space'.tr,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontFamily: 'MontserratMedium',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              for (int i = 0;
                                  i < _quotaOptions.length;
                                  i++) ...[
                                Expanded(
                                  child: _buildQuotaButton(_quotaOptions[i]),
                                ),
                                if (i != _quotaOptions.length - 1)
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

  Future<void> _loadStatus() async {
    final s = await widget.item.permission.status;
    if (!mounted) return;
    setState(() => _status = s);
  }

  bool get _enabled => _status.isGranted || _status.isLimited;

  bool get _usesDeviceSettingStyle =>
      widget.item.permission == Permission.camera ||
      widget.item.permission == Permission.microphone ||
      widget.item.permission == Permission.notification;

  Future<void> _onActionPressed() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final canDirectRequest =
          _status.isDenied || _status.isLimited || _status.isProvisional;
      if (!_usesDeviceSettingStyle && canDirectRequest && !_enabled) {
        await widget.item.permission.request();
        await _loadStatus();
      } else {
        final shouldOpen = await _confirmOpenSettings();
        if (shouldOpen) {
          await openAppSettings();
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirmOpenSettings() async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) {
        return CupertinoAlertDialog(
          title: Text('permissions.dialog.update_device_settings'.tr),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'permissions.dialog.update_body'.trParams(
                <String, String>{'title': widget.item.title},
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(true),
              isDefaultAction: true,
              child: Text('permissions.dialog.open_settings'.tr),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('permissions.dialog.not_now'.tr),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  String get _buttonText {
    if (_usesDeviceSettingStyle) {
      return 'permissions.dialog.update_device_settings'.tr;
    }
    final canDirectRequest =
        _status.isDenied || _status.isLimited || _status.isProvisional;
    if (!_enabled && canDirectRequest) return 'permissions.enable'.tr;
    if (widget.item.permission == Permission.locationWhenInUse && !_enabled) {
      return 'permissions.enable_location'.tr;
    }
    return 'permissions.dialog.update_device_settings'.tr;
  }

  List<Widget> _buildPreferenceBlock() {
    return [
      Text(
        'permissions.detail.set_preferences'.tr,
        style: TextStyle(
          color: Colors.black45,
          fontSize: 15,
          fontFamily: 'MontserratMedium',
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'permissions.detail.preference_body'.trParams(<String, String>{
          'access': widget.item.accessText,
          'title': widget.item.title,
        }),
        style: const TextStyle(
          color: Colors.black45,
          fontSize: 14,
          fontFamily: 'MontserratMedium',
          height: 1.2,
        ),
      ),
    ];
  }

  List<Widget> _buildDeviceSettingBlocks() {
    final currentStateTitle =
        _enabled ? 'permissions.allowed'.tr : 'permissions.denied'.tr;
    final otherStateTitle =
        _enabled ? 'permissions.denied'.tr : 'permissions.allowed'.tr;
    final currentStateDesc = _enabled
        ? 'permissions.detail.allowed_desc'
            .trParams(<String, String>{'access': widget.item.accessText})
        : 'permissions.detail.denied_desc'
            .trParams(<String, String>{'access': widget.item.accessText});
    final otherStateDesc = _enabled
        ? 'permissions.detail.denied_desc'
            .trParams(<String, String>{'access': widget.item.accessText})
        : 'permissions.detail.allowed_desc'
            .trParams(<String, String>{'access': widget.item.accessText});

    return [
      Text(
        'permissions.detail.device_setting'.tr,
        style: TextStyle(
          color: Colors.black45,
          fontSize: 15,
          fontFamily: 'MontserratMedium',
        ),
      ),
      const SizedBox(height: 8),
      Text(
        currentStateTitle,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontFamily: 'MontserratSemiBold',
          height: 1.0,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        currentStateDesc,
        style: const TextStyle(
          color: Colors.black45,
          fontSize: 14,
          fontFamily: 'MontserratMedium',
          height: 1.2,
        ),
      ),
      const SizedBox(height: 26),
      Text(
        'permissions.detail.other_option'.tr,
        style: TextStyle(
          color: Colors.black45,
          fontSize: 15,
          fontFamily: 'MontserratMedium',
        ),
      ),
      const SizedBox(height: 8),
      Text(
        otherStateTitle,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontFamily: 'MontserratSemiBold',
          height: 1.0,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        otherStateDesc,
        style: const TextStyle(
          color: Colors.black45,
          fontSize: 14,
          fontFamily: 'MontserratMedium',
          height: 1.2,
        ),
      ),
      const SizedBox(height: 14),
      Text(
        'permissions.detail.go_device_settings'.tr,
        style: TextStyle(
          color: Colors.black26,
          fontSize: 13,
          fontFamily: 'MontserratMedium',
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: widget.item.title),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...(_usesDeviceSettingStyle
                        ? _buildDeviceSettingBlocks()
                        : _buildPreferenceBlock()),
                    const SizedBox(height: 24),
                    InkWell(
                      onTap: _showHelpSheet,
                      child: Text(
                        widget.item.helpText,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.black,
                            ),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _busy ? null : _onActionPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.black38,
                        ),
                        child: Text(
                          _busy ? 'permissions.checking'.tr : _buttonText,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    widget.item.helpSheetTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 24,
                      fontFamily: 'MontserratBold',
                      height: 1.05,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.item.helpSheetBody,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontFamily: 'MontserratMedium',
                    height: 1.25,
                  ),
                ),
                if (widget.item.helpSheetBody2 != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.item.helpSheetBody2!,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontFamily: 'MontserratMedium',
                      height: 1.25,
                    ),
                  ),
                ],
                if (widget.item.helpSheetLinkText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.item.helpSheetLinkText!,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
