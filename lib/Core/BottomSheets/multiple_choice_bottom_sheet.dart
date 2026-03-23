import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Modules/Education/Scholarships/CreateScholarship/create_scholarship_controller.dart';

part 'multiple_choice_bottom_sheet_content_part.dart';
part 'multiple_choice_bottom_sheet_actions_part.dart';

class MultipleChoiceBottomSheet extends StatelessWidget {
  final CreateScholarshipController controller;
  final String title;
  final List<String> items;
  final String? selectionType;
  final String Function(String)? itemLabelBuilder;

  const MultipleChoiceBottomSheet({
    super.key,
    required this.controller,
    required this.title,
    required this.items,
    this.selectionType,
    this.itemLabelBuilder,
  });

  String get _resolvedSelectionType {
    if (selectionType != null) return selectionType!;
    return "";
  }

  @override
  Widget build(BuildContext context) {
    _initializeSelectionState();
    return _buildSheetContent(context);
  }
}
