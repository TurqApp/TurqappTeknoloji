import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Widgets/cache_first_network_image.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Modules/Market/market_create_controller.dart';

part 'market_create_view_form_part.dart';
part 'market_create_view_taxonomy_part.dart';
part 'market_create_view_media_part.dart';

class MarketCreateView extends StatefulWidget {
  const MarketCreateView({
    super.key,
    this.initialItem,
  });

  final MarketItemModel? initialItem;

  @override
  State<MarketCreateView> createState() => _MarketCreateViewState();
}

class _MarketCreateViewState extends State<MarketCreateView> {
  late final String _controllerTag;
  late final MarketCreateController controller;
  bool _ownsController = false;
  final PageController _imagePreviewController = PageController();
  int _imagePreviewIndex = 0;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'market_create_${widget.initialItem?.id ?? 'new'}_${identityHashCode(this)}';
    final existing = maybeFindMarketCreateController(tag: _controllerTag);
    if (existing != null) {
      controller = existing;
    } else {
      controller = ensureMarketCreateController(
        initialItem: widget.initialItem,
        tag: _controllerTag,
      );
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    _imagePreviewController.dispose();
    final existing = maybeFindMarketCreateController(tag: _controllerTag);
    if (_ownsController && identical(existing, controller)) {
      Get.delete<MarketCreateController>(tag: _controllerTag);
    }
    super.dispose();
  }

  void _updateMarketCreateState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return _buildMarketCreateScaffold(context);
  }
}
