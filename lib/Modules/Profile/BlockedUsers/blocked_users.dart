import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Modules/Profile/BlockedUsers/blocked_users_controller.dart';

part 'blocked_users_content_part.dart';

class BlockedUsers extends StatefulWidget {
  const BlockedUsers({super.key});

  @override
  State<BlockedUsers> createState() => _BlockedUsersState();
}

class _BlockedUsersState extends State<BlockedUsers> {
  late final String _controllerTag;
  late final BlockedUsersController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'profile_blocked_users_${identityHashCode(this)}';
    final existingController =
        BlockedUsersController.maybeFind(tag: _controllerTag);
    if (existingController != null) {
      controller = existingController;
      _ownsController = false;
    } else {
      controller = BlockedUsersController.ensure(tag: _controllerTag);
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          BlockedUsersController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<BlockedUsersController>(tag: _controllerTag, force: true);
    }
    super.dispose();
  }

  Widget _buildBlockedUsersShell(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "settings.blocked_users".tr),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: _buildBlockedUsersContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildBlockedUsersShell(context);
  }
}
