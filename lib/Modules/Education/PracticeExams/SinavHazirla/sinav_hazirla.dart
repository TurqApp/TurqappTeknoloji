import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavHazirla/sinav_hazirla_controller.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Modules/Education/Scholarships/FamilyInfo/family_info_view.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

part 'sinav_hazirla_body_part.dart';

class SinavHazirla extends StatefulWidget {
  final SinavModel? sinavModel;

  const SinavHazirla({super.key, this.sinavModel});

  @override
  State<SinavHazirla> createState() => _SinavHazirlaState();
}

class _SinavHazirlaState extends State<SinavHazirla> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final SinavHazirlaController controller;

  SinavModel? get sinavModel => widget.sinavModel;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'practice_exam_prepare_${widget.sinavModel?.docID ?? 'new'}_${identityHashCode(this)}';
    final existing = SinavHazirlaController.maybeFind(tag: _controllerTag);
    _ownsController = existing == null;
    controller = existing ??
        SinavHazirlaController.ensure(
          tag: _controllerTag,
          sinavModel: sinavModel,
        );
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          SinavHazirlaController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<SinavHazirlaController>(tag: _controllerTag, force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => buildContent(context);
}
