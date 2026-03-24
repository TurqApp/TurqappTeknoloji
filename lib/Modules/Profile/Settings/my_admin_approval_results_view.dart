import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/admin_approval_repository.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'my_admin_approval_results_view_format_part.dart';
part 'my_admin_approval_results_view_stream_part.dart';
part 'my_admin_approval_results_view_tile_part.dart';

class MyAdminApprovalResultsView extends StatelessWidget {
  const MyAdminApprovalResultsView({super.key});

  String get _currentUid => CurrentUserService.instance.effectiveUserId;

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
