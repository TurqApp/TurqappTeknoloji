part of 'reports_admin_view.dart';

extension _ReportsAdminViewContentPart on _ReportsAdminViewState {
  Future<void> _ensureConfig() async {
    if (_provisioning) return;
    _updateViewState(() => _provisioning = true);
    try {
      await _reportRepository.ensureConfigWithCallable();
      AppSnackbar('admin.reports.title'.tr, 'admin.reports.config_updated'.tr);
    } catch (e) {
      AppSnackbar(
        'support.error_title'.tr,
        '${'admin.reports.config_failed'.tr}: $e',
      );
    } finally {
      _updateViewState(() => _provisioning = false);
    }
  }

  Future<void> _handleReview(String aggregateId, bool restore) async {
    if (_busyAggregateId.isNotEmpty) return;
    _updateViewState(() => _busyAggregateId = aggregateId);
    try {
      await _reportRepository.reviewAggregate(
        aggregateId: aggregateId,
        restore: restore,
      );
      AppSnackbar(
        'admin.reports.title'.tr,
        restore ? 'admin.reports.restored'.tr : 'admin.reports.kept_hidden'.tr,
      );
    } catch (e) {
      AppSnackbar(
        'support.error_title'.tr,
        '${'admin.reports.action_failed'.tr}: $e',
      );
    } finally {
      _updateViewState(() => _busyAggregateId = '');
    }
  }

  Widget _buildReportsAdminContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        children: [
          _buildConfigCard(),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<ReportAggregateItem>>(
              stream: _reportRepository.watchAggregates(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      'admin.reports.data_failed'.tr,
                      style: const TextStyle(
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                  );
                }
                final items = snap.data ?? const <ReportAggregateItem>[];
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'admin.reports.empty'.tr,
                      style: const TextStyle(
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _ReportAggregateCard(
                      item: item,
                      busy: _busyAggregateId == item.id,
                      repository: _reportRepository,
                      onReview: _handleReview,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'adminConfig/reports',
            style: TextStyle(
              fontFamily: 'MontserratBold',
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'admin.reports.config_help'.tr,
            style: const TextStyle(
              fontFamily: 'MontserratMedium',
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: _provisioning ? null : _ensureConfig,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.black.withValues(alpha: 0.25)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              icon: _provisioning
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(CupertinoIcons.gear, size: 15),
              label: Text(
                _provisioning
                    ? 'admin.moderation.provisioning'.tr
                    : 'admin.moderation.ensure_config'.tr,
                style: const TextStyle(
                  fontFamily: 'MontserratMedium',
                  fontSize: 12,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportAggregateCard extends StatelessWidget {
  const _ReportAggregateCard({
    required this.item,
    required this.busy,
    required this.repository,
    required this.onReview,
  });

  final ReportAggregateItem item;
  final bool busy;
  final ReportRepository repository;
  final Future<void> Function(String aggregateId, bool restore) onReview;

  @override
  Widget build(BuildContext context) {
    final data = item.data;
    final totalCount = _asInt(data['count']);
    final thresholdReached = _asMap(data['thresholdsReached']);
    final targetType = (data['targetType'] ?? '').toString();
    final targetId = (data['targetId'] ?? '').toString();
    final status = (data['status'] ?? 'open').toString();
    final requiresReview = data['requiresAdminReview'] == true;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${targetType.toUpperCase()} • $targetId',
                      style: const TextStyle(
                        fontFamily: 'MontserratBold',
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'admin.reports.total_status'.trParams(
                        <String, String>{
                          'count': '$totalCount',
                          'status': status,
                        },
                      ),
                      style: const TextStyle(
                        fontFamily: 'MontserratMedium',
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (requiresReview)
                const Icon(
                  CupertinoIcons.exclamationmark_triangle_fill,
                  color: Colors.red,
                  size: 18,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'admin.reports.category_counts'.tr,
            style: const TextStyle(
              fontFamily: 'MontserratBold',
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          StreamBuilder<List<ReportReasonItem>>(
            stream: repository.watchReasonsForTarget(item.id, limit: 12),
            builder: (context, snap) {
              final reasons = snap.data ?? const <ReportReasonItem>[];
              if (reasons.isEmpty) {
                return Text(
                  'admin.reports.no_category_data'.tr,
                  style: const TextStyle(
                    fontFamily: 'MontserratMedium',
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                );
              }
              return Wrap(
                spacing: 6,
                runSpacing: 6,
                children: reasons.map((entry) {
                  final key = entry.id;
                  final count = _asInt(entry.data['count']);
                  final hitThreshold = thresholdReached[key] == true;
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: hitThreshold
                          ? const Color(0xFFFFECE9)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$key: $count',
                      style: TextStyle(
                        fontFamily: 'MontserratMedium',
                        fontSize: 11,
                        color:
                            hitThreshold ? Colors.red.shade700 : Colors.black,
                      ),
                    ),
                  );
                }).toList(growable: false),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            'admin.reports.report_reasons'.tr,
            style: const TextStyle(
              fontFamily: 'MontserratBold',
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          StreamBuilder<List<ReportReasonItem>>(
            stream: repository.watchReasonsForTarget(item.id, limit: 6),
            builder: (context, snap) {
              final reasons = snap.data ?? const <ReportReasonItem>[];
              if (reasons.isEmpty) {
                return Text(
                  'admin.reports.no_detail_reports'.tr,
                  style: const TextStyle(
                    fontFamily: 'MontserratMedium',
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                );
              }
              return Column(
                children: reasons.map((reason) {
                  final reasonData = reason.data;
                  final title =
                      (reasonData['title'] ?? 'admin.reports.no_reason'.tr)
                          .toString();
                  final desc = (reasonData['description'] ?? '').toString();
                  final createdAt = _asInt(reasonData['updatedAt']);
                  final count = _asInt(reasonData['count']);
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$title • $count',
                          style: const TextStyle(
                            fontFamily: 'MontserratBold',
                            fontSize: 12,
                          ),
                        ),
                        if (desc.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            desc,
                            style: const TextStyle(
                              fontFamily: 'MontserratMedium',
                              fontSize: 11,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(createdAt),
                          style: const TextStyle(
                            fontFamily: 'MontserratMedium',
                            fontSize: 10,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(growable: false),
              );
            },
          ),
          if (targetType == 'post') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : () => onReview(item.id, true),
                    child: Text(
                      'admin.reports.restore'.tr,
                      style: const TextStyle(
                        fontFamily: 'MontserratMedium',
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: busy ? null : () => onReview(item.id, false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                    child: Text(
                      busy
                          ? 'admin.reports.processing'.tr
                          : 'admin.reports.keep_hidden'.tr,
                      style: const TextStyle(
                        fontFamily: 'MontserratMedium',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  static int _asInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static String _formatDate(int ms) {
    if (ms <= 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day.$month.${dt.year} $hour:$minute';
  }
}
