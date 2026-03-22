import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Utils/nickname_utils.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/admin_task_assignment_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/admin_task_catalog.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'admin_task_assignments_view_actions_part.dart';
part 'admin_task_assignments_view_content_part.dart';

class AdminTaskAssignmentsView extends StatefulWidget {
  const AdminTaskAssignmentsView({super.key});

  @override
  State<AdminTaskAssignmentsView> createState() =>
      _AdminTaskAssignmentsViewState();
}

class _AdminTaskAssignmentsViewState extends State<AdminTaskAssignmentsView> {
  final TextEditingController _nicknameController = TextEditingController();
  final AdminTaskAssignmentRepository _assignmentRepository =
      AdminTaskAssignmentRepository.ensure();
  final UserRepository _userRepository = UserRepository.ensure();
  late final Future<bool> _canAccessFuture;

  Map<String, dynamic>? _selectedUser;
  List<String> _selectedTaskIds = <String>[];
  bool _searching = false;
  bool _saving = false;
  bool _clearing = false;

  String get _currentUid => CurrentUserService.instance.effectiveUserId;

  @override
  void initState() {
    super.initState();
    _canAccessFuture = AdminAccessService.canManageSliders();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _updateViewState(VoidCallback updater) {
    if (!mounted) return;
    setState(updater);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'admin.tasks.title'.tr),
            Expanded(
              child: FutureBuilder<bool>(
                future: _canAccessFuture,
                builder: (context, accessSnap) {
                  if (accessSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (accessSnap.data != true) {
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
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(15, 8, 15, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildEditorCard(),
                        const SizedBox(height: 14),
                        _buildAssignmentsSection(),
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
}
