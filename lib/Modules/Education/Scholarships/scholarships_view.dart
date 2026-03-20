import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Buttons/action_button.dart';
import 'package:turqappv2/Core/Buttons/scroll_to_top_button.dart';
import 'package:turqappv2/Core/Helpers/scholarship_rich_text.dart';
import 'package:turqappv2/Core/Widgets/education_share_icon_button.dart';
import 'package:turqappv2/Core/formatters.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/rozet_permissions.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Modules/Education/Scholarships/CreateScholarship/create_scholarship_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/CreateScholarship/create_scholarship_controller.dart';
import 'package:turqappv2/Modules/Education/Scholarships/SavedItems/saved_items_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/Applications/applications_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/MyScholarship/my_scholarship_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/Personalized/personalized_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarship_constants.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarship_type_utils.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarships_controller.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipDetail/scholarship_detail_view.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Modules/TypeWriter/type_writer.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import 'dart:ui' as ui;
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Core/Widgets/scale_tap.dart';

part 'scholarships_view_body_part.dart';
part 'scholarships_view_actions_part.dart';

class ScholarshipsView extends StatefulWidget {
  const ScholarshipsView({
    super.key,
    this.embedded = false,
    this.showEmbeddedControls = true,
  });

  final bool embedded;
  final bool showEmbeddedControls;

  @override
  State<ScholarshipsView> createState() => _ScholarshipsViewState();
}

class _ScholarshipsViewState extends State<ScholarshipsView> {
  final ScholarshipsController controller =
      Get.isRegistered<ScholarshipsController>()
          ? Get.find<ScholarshipsController>()
          : Get.put(ScholarshipsController(), permanent: true);
  final DateTime startTime = DateTime.now();
  final TextEditingController _searchController = TextEditingController();

  ScrollController get _scrollController => controller.scrollController;
  late final VoidCallback _scrollListener;

  @override
  void initState() {
    super.initState();
    _scrollListener = () {
      controller.scrollOffset.value = _scrollController.offset;
    };
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Stack(
        children: [
          Column(
            children: [
              _buildBody(),
            ],
          ),
          if (widget.showEmbeddedControls) _buildScrollToTopButton(),
          if (widget.showEmbeddedControls) _buildActionButton(context),
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                _buildSearchField(),
                _buildBody(),
              ],
            ),
            _buildScrollToTopButton(),
            _buildActionButton(context),
          ],
        ),
      ),
    );
  }
}
