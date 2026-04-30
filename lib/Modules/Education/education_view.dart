import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Buttons/action_button.dart';
import 'package:turqappv2/Core/Buttons/scroll_to_top_button.dart';
import 'package:turqappv2/Core/Services/answer_key_navigation_service.dart';
import 'package:turqappv2/Core/Services/education_detail_navigation_service.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Services/market_detail_navigation_service.dart';
import 'package:turqappv2/Core/Services/education_question_bank_navigation_service.dart';
import 'package:turqappv2/Core/Services/practice_exam_navigation_service.dart';
import 'package:turqappv2/Core/Services/slider_admin_navigation_service.dart';
import 'package:turqappv2/Core/Widgets/search_reset_on_page_return_scope.dart';
import 'package:turqappv2/Core/rozet_permissions.dart';
import 'package:turqappv2/Core/Widgets/turq_search_bar.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/answer_key_controller.dart';
import 'package:turqappv2/Modules/Education/Antreman3/antreman_controller.dart';
import 'package:turqappv2/Modules/Education/education_controller.dart';
import 'package:turqappv2/Modules/Education/pasaj_tabs.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarships_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarships_controller.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarship_navigation_service.dart';
import 'package:turqappv2/Modules/Education/Antreman3/antreman_view.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/deneme_sinavlari.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/deneme_sinavlari_controller.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular_controller.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/answer_key.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_view.dart';
import 'package:turqappv2/Modules/Education/widgets/market_top_action_button.dart';
import 'package:turqappv2/Modules/Education/Tutoring/FilterBottomSheet/tutoring_filter_bottom_sheet.dart';
import 'package:turqappv2/Modules/Education/Tutoring/FilterBottomSheet/tutoring_filter_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/view_mode_controller.dart';
import 'package:turqappv2/Modules/Market/market_controller.dart';
import 'package:turqappv2/Modules/Market/market_filter_sheet.dart';
import 'package:turqappv2/Modules/Market/market_view.dart';
import 'package:turqappv2/Modules/JobFinder/job_finder.dart';
import 'package:turqappv2/Modules/JobFinder/job_finder_controller.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_controller.dart';

part 'education_view_actions_part.dart';
part 'education_view_body_part.dart';

class EducationView extends StatelessWidget {
  EducationView({super.key});

  final EducationController controller = ensureEducationController(
    permanent: true,
  );

  @override
  Widget build(BuildContext context) {
    controller.ensureVisibleSurfaceReset();
    return SearchResetOnPageReturnScope(
      onReset: controller.resetVisibleSearchOnReturn,
      child: _buildEducationScaffold(context),
    );
  }
}
