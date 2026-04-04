part of 'permissions_view.dart';

extension _PermissionsViewQuotaPart on _PermissionsViewState {
  int _normalizeDisplayQuota(int gb) => normalizeStorageBudgetPlanGb(gb);

  Future<void> _loadQuota() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = _normalizeDisplayQuota(
      prefs.getInt(_PermissionsViewState._quotaKey) ?? 3,
    );
    await StorageBudgetManager.maybeFind()?.applyPlanGb(saved);
    await SegmentCacheManager.maybeFind()?.setUserLimitGB(saved);
    _updatePermissionsViewState(() => _selectedQuota = saved);
  }

  Future<void> _setQuota(int gb) async {
    final displayQuota = _normalizeDisplayQuota(gb);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_PermissionsViewState._quotaKey, displayQuota);
    try {
      await StorageBudgetManager.maybeFind()?.applyPlanGb(displayQuota);
      await SegmentCacheManager.maybeFind()?.setUserLimitGB(displayQuota);
      await _restartQuotaFillPlan();
    } catch (_) {}
    _updatePermissionsViewState(() => _selectedQuota = displayQuota);
  }

  Future<void> _restartQuotaFillPlan() async {
    final prefetch = maybeFindPrefetchScheduler();
    if (prefetch == null) return;
    prefetch.resetWifiQuotaFillPlan();
    await prefetch.ensureWifiQuotaFillPlan();
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
    final profile = storageBudgetProfileForPlanGb(_selectedQuota);
    final cacheManager = SegmentCacheManager.maybeFind();
    final capacityBytes = profile.streamCacheSoftStopBytes;
    final rawUsedBytes = cacheManager?.totalTrackedUsageBytes ?? 0;
    final usedBytes = rawUsedBytes.clamp(0, capacityBytes);
    final fillRatio = capacityBytes <= 0
        ? 0.0
        : (usedBytes / capacityBytes).clamp(0.0, 1.0);
    final visibleRatio = usedBytes > 0
        ? fillRatio.clamp(0.01, 1.0)
        : 0.0;
    final percent = usedBytes > 0
        ? (fillRatio * 100).round().clamp(1, 100)
        : 0;
    final isLowUsage = fillRatio <= 0.25;
    final fillStartColor = isLowUsage
        ? const Color(0xFFFF5A5F)
        : const Color(0xFF34C759);
    final fillEndColor = isLowUsage
        ? const Color(0xFFD92D20)
        : const Color(0xFF0E9F3E);
    final badgeBackground = isLowUsage
        ? const Color(0xFFFFE3E3)
        : const Color(0xFFE8F7EC);
    final badgeTextColor = isLowUsage
        ? const Color(0xFFD92D20)
        : const Color(0xFF15803D);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFF8F8F8),
            Color(0xFFF1F1F1),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${CacheMetrics.formatBytes(usedBytes)} / ${CacheMetrics.formatBytes(capacityBytes)}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontFamily: 'MontserratSemiBold',
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: badgeBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '%$percent',
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 13,
                    fontFamily: 'MontserratBold',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 30,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.black12),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Stack(
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(end: visibleRatio),
                          duration: const Duration(milliseconds: 520),
                          curve: Curves.easeOutCubic,
                          builder: (context, animatedRatio, child) {
                            return FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: animatedRatio,
                              child: child,
                            );
                          },
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: <Color>[
                                  fillStartColor,
                                  fillEndColor,
                                ],
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: fillEndColor.withAlpha(110),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    height: 8,
                                    margin: const EdgeInsets.only(
                                      left: 10,
                                      right: 10,
                                      top: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(70),
                                      borderRadius: BorderRadius.circular(999),
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
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 7,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
