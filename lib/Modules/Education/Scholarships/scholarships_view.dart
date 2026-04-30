import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Buttons/action_button.dart';
import 'package:turqappv2/Core/Buttons/scroll_to_top_button.dart';
import 'package:turqappv2/Core/Helpers/scholarship_rich_text.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Core/Widgets/app_state_view.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/education_share_icon_button.dart';
import 'package:turqappv2/Core/Helpers/safe_external_link_guard.dart';
import 'package:turqappv2/Core/Widgets/search_reset_on_page_return_scope.dart';
import 'package:turqappv2/Core/Utils/url_utils.dart';
import 'package:turqappv2/Core/formatters.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/rozet_permissions.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Services/profile_navigation_service.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarship_constants.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarship_listing_card.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarship_navigation_service.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarship_type_utils.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarships_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Modules/TypeWriter/type_writer.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Core/Widgets/scale_tap.dart';

part 'scholarships_view_body_part.dart';
part 'scholarships_view_list_part.dart';
part 'scholarships_view_actions_part.dart';
part 'scholarships_view_user_part.dart';

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
      ensureScholarshipsController(permanent: true);
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

    return SearchResetOnPageReturnScope(
      onReset: () {
        _searchController.clear();
        controller.resetSearch();
      },
      child: Scaffold(
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
      ),
    );
  }
}
