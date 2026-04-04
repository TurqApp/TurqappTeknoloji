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

part 'become_verified_account_fields_part.dart';
part 'become_verified_account_flow_part.dart';

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
    controller = ensureBecomeVerifiedAccountController(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (maybeFindBecomeVerifiedAccountController(tag: _controllerTag) != null &&
        identical(
          maybeFindBecomeVerifiedAccountController(tag: _controllerTag),
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

  Widget _buildVerifiedScaffold(BuildContext context) {
    return Obx(
      () => PopScope(
        canPop: controller.bodySelection.value == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          final step = controller.bodySelection.value;
          if (step > 0 && step < 3) {
            controller.bodySelection.value--;
          }
        },
        child: Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Row(
                  children: [
                    IgnorePointer(
                      ignoring: controller.bodySelection.value == 3,
                      child: Opacity(
                        opacity: controller.bodySelection.value == 3 ? 0.35 : 1,
                        child: AppBackButton(
                          onTap: () {
                            final step = controller.bodySelection.value;
                            if (step == 3) return;
                            if (step != 0) {
                              controller.bodySelection.value--;
                            } else {
                              Get.back();
                            }
                          },
                          icon: CupertinoIcons.arrow_left,
                          iconSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 15,
                        right: 15,
                        bottom: 15,
                      ),
                      child: _buildStepBody(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepBody() {
    return switch (controller.bodySelection.value) {
      0 => build1(),
      1 => build2(),
      2 => build3(),
      3 => build4(),
      _ => const SizedBox.shrink(),
    };
  }
}
