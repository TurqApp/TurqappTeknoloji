import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/admin_approval_repository.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'my_admin_approval_results_view_shell_part.dart';
part 'my_admin_approval_results_view_content_part.dart';
part 'my_admin_approval_results_view_status_part.dart';

class MyAdminApprovalResultsView extends StatelessWidget {
  const MyAdminApprovalResultsView({super.key});

  String get _currentUid => CurrentUserService.instance.effectiveUserId;

  @override
  Widget build(BuildContext context) => _buildPage(context);

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
