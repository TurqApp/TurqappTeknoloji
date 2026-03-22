part of 'permissions_view.dart';

extension _PermissionsViewMainPart on _PermissionsViewState {
  void _initializePermissionsView() {
    _loadQuota();
    _loadAdminVisibility();
    _loadNetworkSettings();
    _refreshStatuses();
  }

  int _normalizeDisplayQuota(int gb) => gb.clamp(
        _PermissionsViewState._minDisplayQuotaGb,
        _PermissionsViewState._maxDisplayQuotaGb,
      );

  int _effectiveQuotaGb(int displayGb) =>
      (_normalizeDisplayQuota(displayGb) + 1).clamp(4, 7);

  Future<void> _loadAdminVisibility() async {
    final canManage = await AdminAccessService.canManageSliders();
    _updatePermissionsViewState(() => _showPlaybackPreferences = canManage);
  }

  Future<void> _loadQuota() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = _normalizeDisplayQuota(
      prefs.getInt(_PermissionsViewState._quotaKey) ?? 3,
    );
    final effectiveQuota = _effectiveQuotaGb(saved);
    await StorageBudgetManager.maybeFind()?.applyPlanGb(effectiveQuota);
    await SegmentCacheManager.maybeFind()?.setUserLimitGB(effectiveQuota);
    _updatePermissionsViewState(() => _selectedQuota = saved);
  }

  Future<void> _setQuota(int gb) async {
    final displayQuota = _normalizeDisplayQuota(gb);
    final effectiveQuota = _effectiveQuotaGb(displayQuota);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_PermissionsViewState._quotaKey, displayQuota);
    try {
      await StorageBudgetManager.maybeFind()?.applyPlanGb(effectiveQuota);
      await SegmentCacheManager.maybeFind()?.setUserLimitGB(effectiveQuota);
    } catch (_) {}
    _updatePermissionsViewState(() => _selectedQuota = displayQuota);
  }

  Future<void> _loadNetworkSettings() async {
    final networkService = NetworkAwarenessService.maybeFind();
    if (networkService == null) return;
    final settings = networkService.settings;
    _updatePermissionsViewState(() {
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

    _updatePermissionsViewState(() => _networkSettings = next);
  }

  Future<void> _refreshStatuses() async {
    _updatePermissionsViewState(() => _loading = true);
    final next = <String, PermissionStatus>{};
    for (final item in _items) {
      next[item.title] = await item.permission.status;
    }
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

  Widget _buildPermissionsScaffold(BuildContext context) {
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

  Widget _buildPermissionListItem(_PermissionItem item) {
    final status = _statuses[item.title] ?? PermissionStatus.denied;
    return InkWell(
      onTap: () => Get.to(() => _PermissionDetailView(item: item)),
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
      _effectiveQuotaGb(_selectedQuota),
    );
    final cacheManager = SegmentCacheManager.maybeFind();
    final usage = cacheManager == null
        ? null
        : StorageBudgetManager.usageSnapshotForProfile(
            profile,
            streamUsageBytes: cacheManager.totalSizeBytes,
          );
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
            style: const TextStyle(
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
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontFamily: 'MontserratSemiBold',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'permissions.playback.limit_cellular_desc'.tr,
                      style: const TextStyle(
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
}
