import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';

part 'app_bottom_sheet_view_part.dart';
part 'app_bottom_sheet_controller_part.dart';

class AppBottomSheet extends StatefulWidget {
  final List<dynamic> list;
  final Function(dynamic) onBackData;
  final Function(List<dynamic>)? onBackUpdatedList;
  final String title;
  final dynamic startSelection;
  final String Function(dynamic)? itemLabelBuilder;

  const AppBottomSheet({
    required this.list,
    required this.onBackData,
    required this.title,
    required this.startSelection,
    this.itemLabelBuilder,
    this.onBackUpdatedList,
    super.key,
  });

  static Future<void> show({
    required BuildContext context,
    required List<dynamic> items,
    required String title,
    required Function(dynamic) onSelect,
    dynamic selectedItem,
    bool isSearchable = false,
    String Function(dynamic)? itemLabelBuilder,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return AppBottomSheet(
          list: items,
          title: title,
          startSelection: selectedItem,
          onBackData: onSelect,
          itemLabelBuilder: itemLabelBuilder,
        );
      },
    );
  }

  @override
  State<AppBottomSheet> createState() => _AppBottomSheetState();
}
