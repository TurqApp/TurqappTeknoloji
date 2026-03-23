import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Helpers/custom_nickname_formatter.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'package:turqappv2/Modules/Profile/EditorNickname/editor_nickname_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'editor_nickname_shell_part.dart';
part 'editor_nickname_content_part.dart';

class EditorNickname extends StatefulWidget {
  const EditorNickname({super.key});

  @override
  State<EditorNickname> createState() => _EditorNicknameState();
}

class _EditorNicknameState extends State<EditorNickname> {
  late final EditorNicknameController controller;
  late final bool _ownsController;
  final userService = CurrentUserService.instance;

  @override
  void initState() {
    super.initState();
    final existingController = EditorNicknameController.maybeFind();
    if (existingController != null) {
      controller = existingController;
      _ownsController = false;
    } else {
      controller = EditorNicknameController.ensure();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(EditorNicknameController.maybeFind(), controller)) {
      Get.delete<EditorNicknameController>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildEditorNicknameShell(context);
  }
}
