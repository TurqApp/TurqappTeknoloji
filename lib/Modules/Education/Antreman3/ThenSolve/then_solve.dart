import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/scroll_to_top_button.dart';
import 'package:turqappv2/Core/full_screen_image_viewer.dart';
import 'package:turqappv2/Core/Repositories/antreman_repository.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Core/Widgets/app_state_view.dart';
import 'package:turqappv2/Modules/Education/Antreman3/AntremanComments/antreman_comments.dart';
import 'package:turqappv2/Modules/Education/Antreman3/antreman_controller.dart';
import 'package:turqappv2/Modules/Education/Antreman3/Complaint/complaint.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

part 'then_solve_question_part.dart';
part 'then_solve_shell_part.dart';
part 'then_solve_shell_content_part.dart';

const _thenSolveLgsType = 'LGS';

class ThenSolve extends StatelessWidget {
  ThenSolve({super.key});

  final AntremanController controller = ensureAntremanController();
  final AntremanRepository _antremanRepository = AntremanRepository.ensure();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) => _buildPage(context);

  Future<void> _removeFromSolveLater(dynamic question) async {
    await controller.addToSonraCoz(question);
    if (!controller.savedQuestions[question.docID]!) {
      controller.savedQuestionsList.remove(question);
    }
  }
}
