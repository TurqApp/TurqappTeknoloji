import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'story_highlights_controller.dart';

part 'highlight_picker_sheet_content_part.dart';
part 'highlight_picker_sheet_create_part.dart';

class HighlightPickerSheet extends StatefulWidget {
  final String storyId;
  final String initialCoverUrl;
  const HighlightPickerSheet({
    super.key,
    required this.storyId,
    this.initialCoverUrl = '',
  });

  @override
  State<HighlightPickerSheet> createState() => _HighlightPickerSheetState();
}

class _HighlightPickerSheetState extends State<HighlightPickerSheet> {
  final TextEditingController _titleController = TextEditingController();
  bool _isCreatingNew = false;
  bool _isSubmitting = false;

  String get _currentUid {
    final userService = CurrentUserService.instance;
    final authUid = userService.authUserId.trim();
    if (authUid.isNotEmpty) return authUid;
    return userService.effectiveUserId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);

  void _updateViewState(VoidCallback updater) {
    if (!mounted) return;
    setState(updater);
  }
}
