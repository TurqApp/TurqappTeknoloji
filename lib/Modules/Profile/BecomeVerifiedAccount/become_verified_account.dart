import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'package:turqappv2/Core/Helpers/safe_external_link_guard.dart';
import 'package:turqappv2/Core/rozet_permissions.dart';
import 'package:turqappv2/Core/verified_account_data_list.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Modules/Profile/BecomeVerifiedAccount/become_verified_account_controller.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import 'package:turqappv2/Core/extension.dart';

part 'become_verified_account_steps_part.dart';
part 'become_verified_account_fields_part.dart';

class BecomeVerifiedAccount extends StatefulWidget {
  const BecomeVerifiedAccount({super.key});

  @override
  State<BecomeVerifiedAccount> createState() => _BecomeVerifiedAccountState();
}

class _BecomeVerifiedAccountState extends State<BecomeVerifiedAccount> {
  late final BecomeVerifiedAccountController controller;
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'become_verified_${identityHashCode(this)}';
    controller = BecomeVerifiedAccountController.ensure(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (BecomeVerifiedAccountController.maybeFind(tag: _controllerTag) !=
            null &&
        identical(
          BecomeVerifiedAccountController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<BecomeVerifiedAccountController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildVerifiedScaffold(context);
  }
}
