import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Buttons/action_button.dart';
import 'package:turqappv2/Core/Buttons/scroll_to_top_button.dart';
import 'package:turqappv2/Core/Widgets/turq_search_bar.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Core/Slider/education_slider.dart';
import 'package:turqappv2/Core/Slider/slider_admin_view.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Modules/Education/Tutoring/CreateTutoring/create_tutoring_view.dart';
import 'package:turqappv2/Modules/Education/Tutoring/FilterBottomSheet/tutoring_filter_bottom_sheet.dart';
import 'package:turqappv2/Modules/Education/Tutoring/FilterBottomSheet/tutoring_filter_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/LocationBasedTutoring/location_based_tutoring.dart';
import 'package:turqappv2/Modules/Education/Tutoring/MyTutorings/my_tutorings.dart';
import 'package:turqappv2/Modules/Education/Tutoring/SavedTutorings/saved_tutorings_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_category.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringSearch/tutoring_search.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_widget_builder.dart';
import 'package:turqappv2/Modules/Education/Tutoring/SavedTutorings/saved_tutorings.dart';
import 'package:turqappv2/Modules/Education/Tutoring/MyTutoringApplications/my_tutoring_applications.dart';
import 'package:turqappv2/Modules/Education/Tutoring/view_mode_controller.dart';
import 'package:turqappv2/Modules/TypeWriter/type_writer.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Themes/app_assets.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

part 'tutoring_view_content_part.dart';
part 'tutoring_view_shell_part.dart';
part 'tutoring_view_shell_content_part.dart';
part 'tutoring_view_shell_layout_part.dart';

class TutoringView extends StatelessWidget {
  TutoringView({
    super.key,
    this.embedded = false,
    this.showEmbeddedControls = true,
  });

  final bool embedded;
  final bool showEmbeddedControls;
  final TutoringController tutoringController =
      ensureTutoringController(permanent: true);
  final ViewModeController viewModeController =
      ensureViewModeController(permanent: true);
  final TutoringFilterController filterController =
      ensureTutoringFilterController(permanent: true);
  final applyFilterTrigger = false.obs;
  ScrollController get _scrollController => tutoringController.scrollController;

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
