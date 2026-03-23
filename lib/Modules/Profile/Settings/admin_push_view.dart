import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/Repositories/admin_push_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/job_categories.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'admin_push_view_actions_part.dart';
part 'admin_push_view_content_part.dart';
part 'admin_push_view_shell_part.dart';

class AdminPushView extends StatefulWidget {
  const AdminPushView({super.key});

  @override
  State<AdminPushView> createState() => _AdminPushViewState();
}

class _AdminPushViewState extends State<AdminPushView> {
  final AdminPushRepository _adminPushRepository = AdminPushRepository.ensure();
  final _uidController = TextEditingController();
  final _konumController = TextEditingController();
  final _genderController = TextEditingController();
  final _minAgeController = TextEditingController();
  final _maxAgeController = TextEditingController();
  late final TextEditingController _titleController;
  final _bodyController = TextEditingController();
  final List<String> _pushTypes = const [
    "posts",
    "follow",
    "comment",
    "message",
    "like",
    "reshared_posts",
    "shared_as_posts",
  ];
  String _selectedType = "posts";
  String _selectedMeslek = "";
  bool _sending = false;
  bool _checkingAccess = true;
  bool _canManagePush = false;
  String _lastReport = "";

  String get _currentUid => CurrentUserService.instance.effectiveUserId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: 'app.name'.tr);
    _checkAdminAccess();
  }

  @override
  void dispose() {
    _uidController.dispose();
    _konumController.dispose();
    _genderController.dispose();
    _minAgeController.dispose();
    _maxAgeController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _updateViewState(VoidCallback updater) {
    if (!mounted) return;
    setState(updater);
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
