import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Core/Buttons/action_button.dart';
import 'package:turqappv2/Core/Buttons/scroll_to_top_button.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Core/Slider/education_slider.dart';
import 'package:turqappv2/Core/Services/answer_key_navigation_service.dart';
import 'package:turqappv2/Core/Services/slider_admin_navigation_service.dart';
import 'package:turqappv2/Core/Widgets/app_state_view.dart';
import 'package:turqappv2/Core/Widgets/pasaj_listing_ad_layout.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/AnswerKeyContent/answer_key_content.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/answer_key_controller.dart';
import 'package:turqappv2/Modules/TypeWriter/type_writer.dart';
import 'package:turqappv2/Themes/app_assets.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

part 'answer_key_shell_part.dart';
part 'answer_key_shell_content_part.dart';
part 'answer_key_sections_part.dart';

String _answerKeyExamLabel(String raw) {
  switch (raw) {
    case 'Dil':
      return 'common.language'.tr;
    case 'Yazılım':
      return 'tutoring.branch.software'.tr;
    case 'Spor':
      return 'tutoring.branch.sports'.tr;
    case 'Tasarım':
      return 'common.design'.tr;
    default:
      return raw;
  }
}

class AnswerKey extends StatelessWidget {
  AnswerKey({
    super.key,
    this.embedded = false,
    this.showEmbeddedControls = true,
  });

  final bool embedded;
  final bool showEmbeddedControls;
  final AnswerKeyController controller =
      ensureAnswerKeyController(permanent: true);
  ScrollController get _scrollController => controller.scrollController;

  @override
  Widget build(BuildContext context) {
    return _buildPage(context);
  }
}
