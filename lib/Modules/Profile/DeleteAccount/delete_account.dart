import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/app_cloud_functions.dart';
import 'package:turqappv2/Core/Utils/email_utils.dart';
import 'package:turqappv2/Runtime/session_exit_coordinator.dart';
import 'package:turqappv2/Services/account_center_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import '../../../Core/app_snackbar.dart';
import '../../../Services/phone_account_limiter.dart';

part 'delete_account_actions_part.dart';
part 'delete_account_content_part.dart';

class DeleteAccount extends StatefulWidget {
  const DeleteAccount({super.key});

  @override
  State<DeleteAccount> createState() => _DeleteAccountState();
}

class _DeleteAccountState extends State<DeleteAccount> {
  static const int _deletionGraceDays = 30;
  final TextEditingController _codeController = TextEditingController();
  final int _color = 0xFF000000;

  String _phoneNumber = "";
  String _email = "";

  bool _isCodeSent = false;
  bool _isBusy = false;
  int _countdown = 0;
  Timer? _timer;
  final UserRepository _userRepository = UserRepository.ensure();
  final PostRepository _postRepository = PostRepository.ensure();

  @override
  void initState() {
    super.initState();
    final current = CurrentUserService.instance.currentUser;
    _phoneNumber = (current?.phoneNumber ?? '').trim();
    _email = normalizeEmailAddress(current?.email);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);

  void _updateViewState(VoidCallback updater) {
    if (!mounted) return;
    setState(updater);
  }
}
