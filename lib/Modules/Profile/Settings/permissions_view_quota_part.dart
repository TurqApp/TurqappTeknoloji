part of 'permissions_view.dart';

extension _PermissionsViewQuotaPart on _PermissionsViewState {
  int _normalizeDisplayQuota(int gb) => gb.clamp(
        _PermissionsViewState._minDisplayQuotaGb,
        _PermissionsViewState._maxDisplayQuotaGb,
      );

  int _effectiveQuotaGb(int displayGb) =>
      (_normalizeDisplayQuota(displayGb) + 1).clamp(4, 7);

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
}
