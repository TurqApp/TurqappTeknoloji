import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/admin_approval_repository.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'my_admin_approval_results_view_shell_part.dart';
part 'my_admin_approval_results_view_content_part.dart';
part 'my_admin_approval_results_view_format_part.dart';
part 'my_admin_approval_results_view_state_part.dart';
part 'my_admin_approval_results_view_status_part.dart';

class MyAdminApprovalResultsView extends StatelessWidget {
  const MyAdminApprovalResultsView({super.key});

  String get _currentUid => CurrentUserService.instance.effectiveUserId;

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
