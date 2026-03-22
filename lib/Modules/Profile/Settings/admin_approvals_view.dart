import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/admin_approval_repository.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';

part 'admin_approvals_view_content_part.dart';
part 'admin_approvals_view_actions_part.dart';

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
