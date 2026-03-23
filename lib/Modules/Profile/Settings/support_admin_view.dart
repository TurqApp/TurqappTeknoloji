import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/support_message_repository.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';

part 'support_admin_view_actions_part.dart';
part 'support_admin_view_content_part.dart';
part 'support_admin_view_shell_part.dart';

class SupportAdminView extends StatefulWidget {
  const SupportAdminView({super.key});

  @override
  State<SupportAdminView> createState() => _SupportAdminViewState();
}

class _SupportAdminViewState extends State<SupportAdminView> {
  final SupportMessageRepository _repository =
      SupportMessageRepository.ensure();
  late final Future<bool> _accessFuture;

  @override
  void initState() {
    super.initState();
    _accessFuture = AdminAccessService.canAccessTask('support');
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
