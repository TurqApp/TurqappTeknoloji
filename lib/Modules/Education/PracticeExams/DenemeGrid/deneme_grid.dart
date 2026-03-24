import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/pasaj_card_styles.dart';
import 'package:turqappv2/Core/Widgets/pasaj_grid_card.dart';
import 'package:turqappv2/Core/Widgets/pasaj_list_card_metrics.dart';
import 'package:turqappv2/Core/Widgets/education_share_icon_button.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeGrid/deneme_grid_controller.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeSinaviPreview/deneme_sinavi_preview.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SavedPracticeExams/saved_practice_exams_controller.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavHazirla/sinav_hazirla.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

part 'deneme_grid_actions_part.dart';
part 'deneme_grid_content_part.dart';
part 'deneme_grid_list_part.dart';
part 'deneme_grid_list_sections_part.dart';

class DenemeGrid extends StatelessWidget {
  const DenemeGrid({
    super.key,
    required this.model,
    required this.getData,
    this.isListLayout = false,
  });

  final SinavModel model;
  final Future<void> Function() getData;
  final bool isListLayout;

  String get _currentUid => CurrentUserService.instance.effectiveUserId;

  bool get _isOwner => model.userID == _currentUid;

  @override
  Widget build(BuildContext context) {
    final DenemeGridController controller = DenemeGridController.ensure(
      tag: model.docID,
    );
    final SavedPracticeExamsController savedController =
        SavedPracticeExamsController.ensure();
    controller.initData(model);

    return _buildBody(
      controller: controller,
      savedController: savedController,
    );
  }
}
