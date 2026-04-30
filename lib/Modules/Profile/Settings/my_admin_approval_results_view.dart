import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/admin_approval_repository.dart';
import 'package:turqappv2/Core/Widgets/app_state_view.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'my_admin_approval_results_view_tile_part.dart';

class MyAdminApprovalResultsView extends StatelessWidget {
  const MyAdminApprovalResultsView({super.key});

  String get _currentUid => CurrentUserService.instance.effectiveUserId;

  Stream<QuerySnapshot<Map<String, dynamic>>> _watchOwnApprovals(String uid) {
    final repo = AdminApprovalRepository.ensure();
    return repo.watchOwnApprovals(uid);
  }

  Widget _buildApprovalList(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(15, 8, 15, 24),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        return _ApprovalResultTile(data: docs[index].data());
      },
    );
  }

  Widget _buildMessageState(String text) {
    return AppStateView.empty(
      title: text,
    );
  }

  Widget _buildApprovalStream(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _watchOwnApprovals(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const AppStateView.loading();
        }
        if (snap.hasError) {
          return _buildMessageState(
            'admin.my_approvals.load_failed'.tr,
          );
        }
        final docs = snap.data?.docs ?? const [];
        if (docs.isEmpty) {
          return _buildMessageState(
            'admin.my_approvals.empty'.tr,
          );
        }
        return _buildApprovalList(docs);
      },
    );
  }

  Widget _buildPage(BuildContext context) {
    final uid = _currentUid;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'admin.my_approvals.title'.tr),
            Expanded(
              child: _buildApprovalStream(uid),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
