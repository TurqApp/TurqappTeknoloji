import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Helpers/safe_external_link_guard.dart';
import 'package:turqappv2/Core/Utils/url_utils.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Modules/Education/Scholarships/CreateScholarship/create_scholarship_controller.dart';
import 'package:turqappv2/Themes/app_colors.dart';
import 'dart:io';
import 'dart:math' as math;

import 'package:turqappv2/Utils/empty_padding.dart';

part 'scholarship_preview_view_visual_part.dart';
part 'scholarship_preview_view_content_part.dart';

class ScholarshipPreviewView extends StatelessWidget {
  const ScholarshipPreviewView({super.key, required this.controllerTag});

  final String controllerTag;

  @override
  Widget build(BuildContext context) {
    final controller = ensureCreateScholarshipController(tag: controllerTag);
    final CarouselSliderController carouselController =
        CarouselSliderController();
    final ScrollController scrollController = ScrollController();
    final currentIndex = 0.obs;
    final logoSize =
        (MediaQuery.of(context).size.width * 0.35).clamp(108.0, 133.0);

    return _buildPage(
      context: context,
      controller: controller,
      carouselController: carouselController,
      scrollController: scrollController,
      currentIndex: currentIndex,
      logoSize: logoSize,
    );
  }
}
