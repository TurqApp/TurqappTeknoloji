import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Utils/nickname_utils.dart';
import 'package:turqappv2/Core/Repositories/admin_approval_repository.dart';
import 'package:turqappv2/Core/Repositories/moderation_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/Services/moderation_config_service.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Models/moderation_config_model.dart';

part 'moderation_settings_view_content_part.dart';
part 'moderation_settings_view_ban_part.dart';

class ModerationSettingsView extends StatefulWidget {
  const ModerationSettingsView({super.key});

  @override
  State<ModerationSettingsView> createState() => _ModerationSettingsViewState();
}

class _ModerationSettingsViewState extends State<ModerationSettingsView> {
  final ModerationConfigService _configService =
      const ModerationConfigService();
  late final Future<bool> _canAccessFuture;
  bool _provisioning = false;

  @override
  void initState() {
    super.initState();
    _canAccessFuture = AdminAccessService.canAccessAnyTask(
      const <String>['moderation', 'user_bans'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildModerationSettingsScaffold(context);
  }

  void _updateModerationSettingsState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }
}
