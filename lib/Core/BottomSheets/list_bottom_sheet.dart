import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Themes/app_icons.dart';

part 'list_bottom_sheet_view_part.dart';
part 'list_bottom_sheet_controller_part.dart';
part 'list_bottom_sheet_controller_actions_part.dart';
part 'list_bottom_sheet_controller_fields_part.dart';

class ListBottomSheet extends StatefulWidget {
  final List<dynamic> list;
  final Function(dynamic) onBackData;
  final Function(List<dynamic>)? onBackUpdatedList;
  final String title;
  final String searchHintText;
  final dynamic startSelection;
  final String Function(dynamic item)? searchTextBuilder;
  final String Function(dynamic item)? itemLabelBuilder;

  const ListBottomSheet({
    required this.list,
    required this.onBackData,
    required this.title,
    this.searchHintText = "common.search",
    required this.startSelection,
    this.onBackUpdatedList,
    this.searchTextBuilder,
    this.itemLabelBuilder,
    super.key,
  });

  static Future<void> show({
    required BuildContext context,
    required List<dynamic> items,
    required String title,
    required Function(dynamic) onSelect,
    dynamic selectedItem,
    bool isSearchable = false,
    String searchHintText = "common.search",
    String Function(dynamic item)? searchTextBuilder,
    String Function(dynamic item)? itemLabelBuilder,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: FractionallySizedBox(
            heightFactor: bottomInset > 0 ? 0.88 : 0.72,
            child: ListBottomSheet(
              list: items,
              title: title,
              searchHintText: searchHintText,
              startSelection: selectedItem,
              onBackData: onSelect,
              searchTextBuilder: searchTextBuilder,
              itemLabelBuilder: itemLabelBuilder,
            ),
          ),
        );
      },
    );
  }

  @override
  _ListBottomSheetState createState() => _ListBottomSheetState();
}
