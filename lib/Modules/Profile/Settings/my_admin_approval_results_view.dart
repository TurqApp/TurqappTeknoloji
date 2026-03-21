import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/admin_approval_repository.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class MyAdminApprovalResultsView extends StatelessWidget {
  const MyAdminApprovalResultsView({super.key});

  String get _currentUid {
    final serviceUid = CurrentUserService.instance.userId.trim();
    if (serviceUid.isNotEmpty) return serviceUid;
    return FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final uid = _currentUid;
    final repo = AdminApprovalRepository.ensure();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'admin.my_approvals.title'.tr),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: repo.watchOwnApprovals(uid),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Text(
                        'admin.my_approvals.load_failed'.tr,
                        style: const TextStyle(
                          fontFamily: 'MontserratMedium',
                          fontSize: 13,
                        ),
                      ),
                    );
                  }
                  final docs = snap.data?.docs ?? const [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        'admin.my_approvals.empty'.tr,
                        style: const TextStyle(
                          fontFamily: 'MontserratMedium',
                          fontSize: 13,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(15, 8, 15, 24),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final status = (data['status'] ?? 'pending')
                          .toString()
                          .trim();
                      final title =
                          (data['title'] ?? 'admin.my_approvals.default_title'.tr)
                              .toString()
                              .trim();
                      final summary =
                          (data['summary'] ?? '').toString().trim();
                      final targetNickname =
                          (data['targetNickname'] ?? '').toString().trim();
                      final resolvedByNickname =
                          (data['resolvedByNickname'] ?? '').toString().trim();
                      final rejectionReason =
                          (data['rejectionReason'] ?? '').toString().trim();
                      final createdAt = _formatTimestamp(data['createdAt']);
                      final resolvedAt = _formatTimestamp(data['resolvedAt']);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontFamily: 'MontserratBold',
                                      fontSize: 15,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                _StatusChip(status: status),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              targetNickname.isEmpty
                                  ? summary
                                  : '@$targetNickname • $summary',
                              style: const TextStyle(
                                fontFamily: 'MontserratMedium',
                                fontSize: 12,
                                color: Colors.black87,
                                height: 1.35,
                              ),
                            ),
                            if (createdAt != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${'admin.my_approvals.requested'.tr}: $createdAt',
                                style: const TextStyle(
                                  fontFamily: 'MontserratMedium',
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                            if (resolvedAt != null || resolvedByNickname.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${'admin.my_approvals.result'.tr}: ${resolvedAt ?? '-'}${resolvedByNickname.isEmpty ? '' : ' • @$resolvedByNickname'}',
                                  style: const TextStyle(
                                    fontFamily: 'MontserratMedium',
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            if (rejectionReason.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${'admin.approvals.rejection_reason'.tr}: $rejectionReason',
                                style: const TextStyle(
                                  fontFamily: 'MontserratMedium',
                                  fontSize: 11,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String? _formatTimestamp(dynamic raw) {
    DateTime? date;
    if (raw is Timestamp) {
      date = raw.toDate();
    } else if (raw is int) {
      date = DateTime.fromMillisecondsSinceEpoch(raw);
    }
    if (date == null) return null;
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)}.${date.year} ${two(date.hour)}:${two(date.minute)}';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (status) {
      'approved' => Colors.green,
      'rejected' => Colors.redAccent,
      _ => Colors.orange,
    };
    final String label = switch (status) {
      'approved' => 'admin.approvals.approved'.tr,
      'rejected' => 'admin.approvals.rejected'.tr,
      _ => 'admin.approvals.pending'.tr,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'MontserratBold',
          fontSize: 11,
          color: color,
        ),
      ),
    );
  }
}
