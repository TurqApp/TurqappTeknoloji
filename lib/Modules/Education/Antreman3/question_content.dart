import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/scroll_to_top_button.dart';
import 'package:turqappv2/Core/full_screen_image_viewer.dart';
import 'package:turqappv2/Core/Repositories/antreman_repository.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Modules/Education/Antreman3/AntremanComments/antreman_comments.dart';
import 'package:turqappv2/Modules/Education/Antreman3/antreman_controller.dart';
import 'package:turqappv2/Modules/Education/Antreman3/Complaint/complaint.dart';
import 'package:turqappv2/Modules/Education/Antreman3/ThenSolve/then_solve.dart';
import 'package:turqappv2/Themes/app_icons.dart';

part 'question_content_shell_part.dart';
part 'question_content_item_part.dart';

const _antremanLgsType = 'LGS';

class QuestionContent extends StatelessWidget {
  QuestionContent({super.key});

  final AntremanController controller = AntremanController.ensure();
  final AntremanRepository _antremanRepository = AntremanRepository.ensure();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
