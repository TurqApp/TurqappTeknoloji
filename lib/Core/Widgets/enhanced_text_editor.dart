import 'package:flutter/material.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:get/get.dart';
import '../Services/post_editing_service.dart';

part 'enhanced_text_editor_shell_part.dart';
part 'enhanced_text_editor_support_part.dart';

class EnhancedTextEditor extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final int? maxLines;
  final int? maxLength;
  final bool showFormatting;
  final bool showSuggestions;
  final Function(String)? onChanged;

  const EnhancedTextEditor({
    super.key,
    required this.controller,
    this.hintText = 'Write something...',
    this.maxLines,
    this.maxLength,
    this.showFormatting = true,
    this.showSuggestions = true,
    this.onChanged,
  });

  @override
  State<EnhancedTextEditor> createState() => _EnhancedTextEditorState();
}
