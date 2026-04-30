import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Widgets/app_state_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/SavedItems/saved_items_controller.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipDetail/scholarship_detail_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarship_type_utils.dart';
import 'package:turqappv2/Themes/app_icons.dart';

part 'saved_items_view_actions_part.dart';
part 'saved_items_view_content_part.dart';

class SavedItemsView extends StatefulWidget {
  const SavedItemsView({super.key});

  @override
  State<SavedItemsView> createState() => _SavedItemsViewState();
}

class _SavedItemsViewState extends State<SavedItemsView> {
  late final SavedItemsController controller;
  late final String _controllerTag;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'saved_items_${identityHashCode(this)}';
    final existing = maybeFindSavedItemsController(tag: _controllerTag);
    _ownsController = existing == null;
    controller = existing ?? ensureSavedItemsController(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          maybeFindSavedItemsController(tag: _controllerTag),
          controller,
        )) {
      Get.delete<SavedItemsController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
