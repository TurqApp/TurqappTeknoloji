import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Buttons/action_button.dart';
import 'package:turqappv2/Core/Buttons/scroll_to_top_button.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/rozet_permissions.dart';
import 'package:turqappv2/Core/Slider/slider_admin_view.dart';
import 'package:turqappv2/Core/Widgets/turq_search_bar.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/AnswerKeyCreatingOption/answer_key_creating_option.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/MyBookletResults/my_booklet_results.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/OpticalFormEntry/optical_form_entry.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/OpticsAndBooksPublished/optics_and_books_published.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/SavedOpticalForms/saved_optical_forms.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/SearchAnswerKey/search_answer_key.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/answer_key_controller.dart';
import 'package:turqappv2/Modules/Education/Antreman3/ThenSolve/then_solve.dart';
import 'package:turqappv2/Modules/Education/Antreman3/antreman_controller.dart';
import 'package:turqappv2/Modules/Education/education_controller.dart';
import 'package:turqappv2/Modules/Education/pasaj_tabs.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarships_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/CreateScholarship/create_scholarship_controller.dart';
import 'package:turqappv2/Modules/Education/Scholarships/CreateScholarship/create_scholarship_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/MyScholarship/my_scholarship_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/Personalized/personalized_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarships_controller.dart';
import 'package:turqappv2/Modules/Education/Scholarships/SavedItems/saved_items_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/Applications/applications_view.dart';
import 'package:turqappv2/Modules/Education/Antreman3/antreman_view.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/deneme_sinavlari.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/MyPracticeExams/my_practice_exams.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SavedPracticeExams/saved_practice_exams.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SearchDeneme/search_deneme.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavHazirla/sinav_hazirla.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavSonuclarim/sinav_sonuclarim.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/deneme_sinavlari_controller.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_soru_sonuclar.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/answer_key.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_view.dart';
import 'package:turqappv2/Modules/Education/widgets/market_top_action_button.dart';
import 'package:turqappv2/Modules/Education/Tutoring/CreateTutoring/create_tutoring_view.dart';
import 'package:turqappv2/Modules/Education/Tutoring/FilterBottomSheet/tutoring_filter_bottom_sheet.dart';
import 'package:turqappv2/Modules/Education/Tutoring/FilterBottomSheet/tutoring_filter_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/LocationBasedTutoring/location_based_tutoring.dart';
import 'package:turqappv2/Modules/Education/Tutoring/MyTutorings/my_tutorings.dart';
import 'package:turqappv2/Modules/Education/Tutoring/MyTutoringApplications/my_tutoring_applications.dart';
import 'package:turqappv2/Modules/Education/Tutoring/SavedTutorings/saved_tutorings.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringSearch/tutoring_search.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/view_mode_controller.dart';
import 'package:turqappv2/Modules/Market/market_controller.dart';
import 'package:turqappv2/Modules/Market/market_create_view.dart';
import 'package:turqappv2/Modules/Market/market_filter_sheet.dart';
import 'package:turqappv2/Modules/Market/market_search_view.dart';
import 'package:turqappv2/Modules/Market/market_view.dart';
import 'package:turqappv2/Modules/JobFinder/job_finder.dart';
import 'package:turqappv2/Modules/JobFinder/job_finder_controller.dart';
import 'package:turqappv2/Modules/JobFinder/JobCreator/job_creator.dart';
import 'package:turqappv2/Modules/JobFinder/CareerProfile/career_profile.dart';
import 'package:turqappv2/Modules/JobFinder/MyApplications/my_applications.dart';
import 'package:turqappv2/Modules/JobFinder/MyJobAds/my_job_ads.dart';
import 'package:turqappv2/Modules/JobFinder/SavedJobs/saved_jobs.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_controller.dart';

part 'education_view_actions_part.dart';
part 'education_view_body_part.dart';

class EducationView extends StatelessWidget {
  EducationView({super.key});

  final EducationController controller = EducationController.ensure(
    permanent: true,
  );

  @override
  Widget build(BuildContext context) {
    controller.ensureVisibleSurfaceReset();
    return _buildEducationScaffold(context);
  }
}
