import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/education_detail_navigation_service.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/cache_first_network_image.dart';
import 'package:turqappv2/Core/Widgets/pasaj_card_styles.dart';
import 'package:turqappv2/Core/Widgets/pasaj_grid_card.dart';
import 'package:turqappv2/Core/Widgets/pasaj_list_card_metrics.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:turqappv2/Modules/JobFinder/JobContent/job_content_controller.dart';
import 'package:turqappv2/Themes/app_icons.dart';

import '../job_finder_controller.dart';

part 'job_content_grid_part.dart';
part 'job_content_list_part.dart';

class JobContent extends StatefulWidget {
  final bool isGrid;
  final JobModel model;
  const JobContent({super.key, required this.model, required this.isGrid});

  @override
  State<JobContent> createState() => _JobContentState();
}

class _JobContentState extends State<JobContent> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final JobContentController controller;
  final EducationDetailNavigationService detailNavigationService =
      const EducationDetailNavigationService();

  bool get isGrid => widget.isGrid;
  JobModel get model => widget.model;

  String get _workTypeText {
    if (model.calismaTuru.isEmpty) {
      return 'pasaj.job_finder.salary_not_specified'.tr;
    }
    return model.calismaTuru.join(', ');
  }

  String get _cityTownText {
    final city = model.city.trim();
    final town = model.town.trim();
    if (city.isNotEmpty && town.isNotEmpty) {
      return '$city, $town';
    }
    if (city.isNotEmpty) return city;
    if (town.isNotEmpty) return town;
    return 'pasaj.market.location_missing'.tr;
  }

  @override
  void initState() {
    super.initState();
    _controllerTag = 'job_content_${_baseTag}_${identityHashCode(this)}';
    _ownsController =
        maybeFindJobContentController(tag: _controllerTag) == null;
    controller = ensureJobContentController(tag: _controllerTag);
    _primeSavedState();
  }

  @override
  void didUpdateWidget(covariant JobContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model.docID != model.docID) {
      _primeSavedState();
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
            maybeFindJobContentController(tag: _controllerTag), controller)) {
      Get.delete<JobContentController>(tag: _controllerTag);
    }
    super.dispose();
  }

  String get _baseTag {
    final docId = model.docID.trim();
    if (docId.isNotEmpty) return docId;
    return 'job_fallback_${model.timeStamp}_${model.brand.hashCode}_${model.logo.hashCode}_${model.meslek.hashCode}';
  }

  void _primeSavedState() {
    if (model.docID.trim().isNotEmpty) {
      controller.primeSavedState(model.docID);
    }
  }

  Widget _buildLogo({
    required String imageUrl,
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    final normalizedUrl = imageUrl.trim();
    final hasLogoValue = normalizedUrl.isNotEmpty;
    final fallback = Container(
      width: width,
      height: height,
      color: const Color(0xFFF1F4F7),
      alignment: Alignment.center,
      child: Icon(
        Icons.work_outline_rounded,
        color: Colors.grey.shade500,
        size: ((width ?? height ?? 96) * 0.32).clamp(22, 40).toDouble(),
      ),
    );

    if (!hasLogoValue) {
      return borderRadius == null
          ? fallback
          : ClipRRect(borderRadius: borderRadius, child: fallback);
    }

    final image = SizedBox(
      width: width,
      height: height,
      child: CacheFirstNetworkImage(
        imageUrl: normalizedUrl,
        cacheManager: TurqImageCacheManager.instance,
        fit: BoxFit.cover,
        memCacheWidth: width == null ? null : (width * 2).round(),
        memCacheHeight: height == null ? null : (height * 2).round(),
        fallback: fallback,
      ),
    );
    return borderRadius == null
        ? image
        : ClipRRect(borderRadius: borderRadius, child: image);
  }

  @override
  Widget build(BuildContext context) {
    return isGrid ? _buildGridView(controller) : _buildListingView(controller);
  }

  Future<void> _openDetails() async {
    await detailNavigationService.openJobDetails(model);
    final finderController = maybeFindJobFinderController();
    if (finderController != null) {
      await finderController.refreshJob(model.docID);
    }
  }
}
