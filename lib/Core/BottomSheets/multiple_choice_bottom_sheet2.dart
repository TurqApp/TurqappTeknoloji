import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/text_styles.dart';

part 'multiple_choice_bottom_sheet2_content_part.dart';
part 'multiple_choice_bottom_sheet2_selection_part.dart';

class MultiSelectBottomSheet2 extends StatelessWidget {
  static const String _allUniversitiesKey = 'scholarship.all_universities';
  static const String _allUniversitiesValue = 'Tüm Üniversiteler';
  final String title;
  final List<String> items;
  final List<String> selectedItems;
  final Function(List<String>) onConfirm;
  final Map<String, List<String>>? relatedItems;
  final String? parentSelection;
  final String Function(String)? itemLabelBuilder;

  const MultiSelectBottomSheet2({
    super.key,
    required this.title,
    required this.items,
    required this.selectedItems,
    required this.onConfirm,
    this.relatedItems,
    this.parentSelection,
    this.itemLabelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return _MultiSelectBottomSheet2Content(sheet: this);
  }
}
