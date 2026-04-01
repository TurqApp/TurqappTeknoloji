import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Modules/Market/market_controller.dart';

part 'market_filter_sheet_content_part.dart';
part 'market_filter_sheet_actions_part.dart';

class MarketFilterSheet extends StatefulWidget {
  const MarketFilterSheet({
    super.key,
    required this.controller,
  });

  final MarketController controller;

  @override
  State<MarketFilterSheet> createState() => _MarketFilterSheetState();
}
