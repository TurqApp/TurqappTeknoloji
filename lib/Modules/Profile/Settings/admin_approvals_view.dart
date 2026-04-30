import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/admin_approval_repository.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/Services/app_cloud_functions.dart';
import 'package:turqappv2/Core/Widgets/app_state_view.dart';
import 'package:turqappv2/Core/app_snackbar.dart';

class AdminApprovalsView extends StatefulWidget {
  const AdminApprovalsView({super.key});

  @override
  State<AdminApprovalsView> createState() => _AdminApprovalsViewState();
}

class _AdminApprovalsViewState extends State<AdminApprovalsView> {
  final AdminApprovalRepository _approvalRepository =
      AdminApprovalRepository.ensure();
  late final Future<bool> _canAccessFuture;
  late final Future<bool> _isPrimaryAdminFuture;

  @override
  void initState() {
    super.initState();
    _canAccessFuture = AdminAccessService.canAccessTask('approvals');
    _isPrimaryAdminFuture = AdminAccessService.isPrimaryAdmin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody(context));
  }

  Widget _buildBody(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          BackButtons(text: 'admin.approvals.title'.tr),
          Expanded(
            child: FutureBuilder<bool>(
                future: _canAccessFuture,
                builder: (context, accessSnap) {
                  if (accessSnap.connectionState == ConnectionState.waiting) {
                  return const AppStateView.loading();
                }
                if (accessSnap.data != true) {
                  return _buildNoAccessState();
                }
                return FutureBuilder<bool>(
                  future: _isPrimaryAdminFuture,
                  builder: (context, primarySnap) {
                    final isPrimaryAdmin = primarySnap.data == true;
                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _approvalRepository.watchApprovals(),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const AppStateView.loading();
                        }
                        final docs = snap.data?.docs ?? const [];
                        if (docs.isEmpty) {
                          return _buildEmptyState();
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(15, 8, 15, 24),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ApprovalCard(
                                doc: docs[index],
                                isPrimaryAdmin: isPrimaryAdmin,
                              ),
                            );
                          },
                        );
                      },
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

  Widget _buildNoAccessState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'admin.no_access'.tr,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'MontserratMedium',
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return AppStateView.empty(
      title: 'admin.approvals.empty'.tr,
    );
  }
}

class _ApprovalCard extends StatefulWidget {
  const _ApprovalCard({
    required this.doc,
    required this.isPrimaryAdmin,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final bool isPrimaryAdmin;

  @override
  State<_ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends State<_ApprovalCard> {
  final AdminApprovalRepository _approvalRepository =
      AdminApprovalRepository.ensure();
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    return _buildCardContent();
  }

  void _updateProcessing(bool value) {
    if (!mounted) {
      _processing = value;
      return;
    }
    setState(() => _processing = value);
  }

  Future<void> _approve() async {
    if (_processing) return;
    _updateProcessing(true);
    try {
      final data = widget.doc.data();
      final type = (data['type'] ?? '').toString().trim();
      final payload = Map<String, dynamic>.from(
        (data['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
      if (type == 'badge_change' || type == 'badge') {
        final callable = AppCloudFunctions.instanceFor(region: 'europe-west3')
            .httpsCallable('setUserBadgeByUserId');
        await callable.call<Map<String, dynamic>>(payload);
      } else if (type == 'user_ban') {
        final callable = AppCloudFunctions.instanceFor(region: 'europe-west3')
            .httpsCallable('setUserBanByUserId');
        await callable.call<Map<String, dynamic>>(payload);
      } else {
        throw Exception('unsupported_approval_type');
      }
      await _approvalRepository.approve(widget.doc.id);
      AppSnackbar(
        'admin.approvals.title'.tr,
        'admin.approvals.approved_body'.tr,
      );
    } catch (e) {
      AppSnackbar(
        'support.error_title'.tr,
        '${'admin.approvals.approve_failed'.tr} $e',
      );
    } finally {
      _updateProcessing(false);
    }
  }

  Future<void> _reject() async {
    if (_processing) return;
    _updateProcessing(true);
    try {
      await _approvalRepository.reject(widget.doc.id);
      AppSnackbar(
        'admin.approvals.title'.tr,
        'admin.approvals.rejected_body'.tr,
      );
    } catch (e) {
      AppSnackbar(
        'support.error_title'.tr,
        '${'admin.approvals.reject_failed'.tr} $e',
      );
    } finally {
      _updateProcessing(false);
    }
  }

  String? _formatTimestamp(dynamic raw) {
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

  Widget _buildCardContent() {
    final data = widget.doc.data();
    final title = (data['title'] ?? '').toString().trim();
    final summary = (data['summary'] ?? '').toString().trim();
    final status = (data['status'] ?? 'pending').toString().trim();
    final targetNickname = (data['targetNickname'] ?? '').toString().trim();
    final createdByNickname =
        (data['createdByNickname'] ?? '').toString().trim();
    final createdAt = _formatTimestamp(data['createdAt']);
    final rejectionReason = (data['rejectionReason'] ?? '').toString().trim();

    return Container(
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
                  title.isEmpty ? 'admin.approvals.default_title'.tr : title,
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
            targetNickname.isEmpty ? summary : '@$targetNickname • $summary',
            style: const TextStyle(
              fontFamily: 'MontserratMedium',
              fontSize: 12,
              color: Colors.black87,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${'admin.approvals.created_by'.tr}: ${createdByNickname.isEmpty ? '-' : '@$createdByNickname'}${createdAt == null ? '' : ' • $createdAt'}',
            style: const TextStyle(
              fontFamily: 'MontserratMedium',
              fontSize: 11,
              color: Colors.black54,
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
          if (status == 'pending' && widget.isPrimaryAdmin) ...[
            const SizedBox(height: 12),
            _buildApprovalActions(),
          ],
        ],
      ),
    );
  }

  Widget _buildApprovalActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _processing ? null : _approve,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _processing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'admin.approvals.approve'.tr,
                    style: const TextStyle(fontFamily: 'MontserratBold'),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: _processing ? null : _reject,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'admin.approvals.reject'.tr,
              style: const TextStyle(fontFamily: 'MontserratBold'),
            ),
          ),
        ),
      ],
    );
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
