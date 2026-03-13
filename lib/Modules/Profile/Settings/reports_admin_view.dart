import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/report_repository.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';

class ReportsAdminView extends StatefulWidget {
  const ReportsAdminView({super.key});

  @override
  State<ReportsAdminView> createState() => _ReportsAdminViewState();
}

class _ReportsAdminViewState extends State<ReportsAdminView> {
  final ReportRepository _reportRepository = ReportRepository.ensure();
  late final Future<bool> _canAccessFuture;
  bool _provisioning = false;
  String _busyAggregateId = '';

  @override
  void initState() {
    super.initState();
    _canAccessFuture = AdminAccessService.canManageSliders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Reports"),
            Expanded(
              child: FutureBuilder<bool>(
                future: _canAccessFuture,
                builder: (context, accessSnap) {
                  if (accessSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (accessSnap.data != true) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Bu alan sadece admin erişimine açıktır.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'MontserratMedium',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }
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
                              if (snap.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              if (snap.hasError) {
                                return const Center(
                                  child: Text(
                                    'Reports verisi alınamadı.',
                                    style: TextStyle(
                                      fontFamily: 'MontserratMedium',
                                    ),
                                  ),
                                );
                              }
                              final items =
                                  snap.data ?? const <ReportAggregateItem>[];
                              if (items.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'Henüz report aggregate oluşmadı.',
                                    style: TextStyle(
                                      fontFamily: 'MontserratMedium',
                                    ),
                                  ),
                                );
                              }
                              return ListView.separated(
                                itemCount: items.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
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
                },
              ),
            ),
          ],
        ),
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
          const Text(
            'Varsayılan kategori eşiği: 5\nEşik aşımı: içerik otomatik yayından kaldırılır\nAdmin aksiyonu: tekrar yayınla veya kapalı tut',
            style: TextStyle(
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
                _provisioning ? 'Kuruluyor...' : 'Config Kur/Yenile',
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

  Future<void> _ensureConfig() async {
    if (_provisioning) return;
    setState(() => _provisioning = true);
    try {
      await _reportRepository.ensureConfigWithCallable();
      AppSnackbar('Reports', 'adminConfig/reports güncellendi.');
    } catch (e) {
      AppSnackbar('Hata', 'Reports config güncellenemedi: $e');
    } finally {
      if (mounted) {
        setState(() => _provisioning = false);
      }
    }
  }

  Future<void> _handleReview(String aggregateId, bool restore) async {
    if (_busyAggregateId.isNotEmpty) return;
    setState(() => _busyAggregateId = aggregateId);
    try {
      await _reportRepository.reviewAggregate(
        aggregateId: aggregateId,
        restore: restore,
      );
      AppSnackbar(
        'Reports',
        restore ? 'İçerik tekrar yayına alındı.' : 'İçerik kapalı tutuldu.',
      );
    } catch (e) {
      AppSnackbar('Hata', 'Admin işlemi başarısız: $e');
    } finally {
      if (mounted) {
        setState(() => _busyAggregateId = '');
      }
    }
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
                      'Toplam: $totalCount • Durum: $status',
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
          const Text(
            'Kategori Sayaçları',
            style: TextStyle(
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
                return const Text(
                  'Kategori verisi yok.',
                  style: TextStyle(
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
          const Text(
            'Neden Şikayet Edildi',
            style: TextStyle(
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
                return const Text(
                  'Henüz detay report kaydı yok.',
                  style: TextStyle(
                    fontFamily: 'MontserratMedium',
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                );
              }
              return Column(
                children: reasons.map((reason) {
                  final reasonData = reason.data;
                  final title = (reasonData['title'] ?? 'Sebep yok').toString();
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
                    child: const Text(
                      'Yayına Al',
                      style: TextStyle(
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
                      busy ? 'İşleniyor...' : 'Kapalı Tut',
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
