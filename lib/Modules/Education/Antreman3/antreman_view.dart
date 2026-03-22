import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Buttons/action_button.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Modules/Education/Antreman3/antreman_controller.dart';
import 'package:turqappv2/Modules/Education/Antreman3/ThenSolve/then_solve.dart';
import 'package:turqappv2/Modules/Education/education_controller.dart';
import 'package:turqappv2/Modules/TypeWriter/type_writer.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

part 'antreman_view_content_part.dart';
part 'antreman_view_shell_part.dart';

class AntremanView2 extends StatelessWidget {
  AntremanView2({
    super.key,
    this.embedded = false,
    this.showEmbeddedControls = true,
  });

  final bool embedded;
  final bool showEmbeddedControls;
  final AntremanController controller =
      AntremanController.ensure(permanent: true);

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      return Stack(
        children: [
          Column(
            children: [
              _buildBody(context),
            ],
          ),
          if (showEmbeddedControls) _buildActionButton(context),
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildBody(context),
          ],
        ),
      ),
      floatingActionButton: ActionButton(
        context: context,
        menuItems: [
          PullDownMenuItem(
            title: 'pasaj.question_bank.solve_later'.tr,
            icon: CupertinoIcons.repeat,
            onTap: () {
              controller.fetchSavedQuestions();
              Get.to(() => ThenSolve());
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
