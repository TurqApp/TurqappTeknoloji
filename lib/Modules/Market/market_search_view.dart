import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/search_reset_on_page_return_scope.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Core/Widgets/turq_search_bar.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Modules/Market/market_controller.dart';
import 'package:turqappv2/Modules/Market/market_filter_sheet.dart';
import 'package:turqappv2/Modules/Market/market_offer_utils.dart';

part 'market_search_view_shell_part.dart';
part 'market_search_view_search_part.dart';
part 'market_search_view_content_part.dart';

class MarketSearchView extends StatefulWidget {
  const MarketSearchView({super.key});

  @override
  State<MarketSearchView> createState() => _MarketSearchViewState();
}

class _MarketSearchViewState extends State<MarketSearchView> {
  late final MarketController controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    controller = MarketController.ensure();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SearchResetOnPageReturnScope(
        onReset: () {
          _focusNode.unfocus();
          controller.setSearchQuery('');
        },
        child: _buildPage(context),
      );
}
