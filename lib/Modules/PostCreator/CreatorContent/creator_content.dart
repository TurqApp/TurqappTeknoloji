import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/post_caption_limits.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import 'package:video_player/video_player.dart';
import '../post_creator_controller.dart';
import 'creator_content_controller.dart';
import 'composer_hashtag_utils.dart';
import 'post_creator_model.dart';

part 'creator_content_media_part.dart';
part 'creator_content_controller_media_video_part.dart';
part 'creator_content_controller_media_image_part.dart';
part 'creator_content_quoted_part.dart';
part 'creator_content_shell_part.dart';
part 'creator_content_text_part.dart';

class LineLimitingTextInputFormatter extends TextInputFormatter {
  final int maxLines;
  LineLimitingTextInputFormatter(this.maxLines);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final lines = newValue.text.split('\n');
    if (lines.length <= maxLines) return newValue;

    final limited = lines.take(maxLines).join('\n');
    return TextEditingValue(
      text: limited,
      selection: TextSelection.collapsed(offset: limited.length),
      composing: TextRange.empty,
    );
  }
}

class CreatorContent extends StatelessWidget {
  final PostCreatorModel model;
  final bool isSelected;

  CreatorContent({super.key, required this.model, required this.isSelected});
  late final CreatorContentController controller;
  final mainController = PostCreatorController.ensure();

  double get _singleImagePreviewAspect {
    final reused = controller.reusedImageAspectRatio.value;
    if (reused > 0) return reused;
    return 0.80;
  }

  double get _threadPickerWidthFactor {
    if (mainController.postList.length <= 1 || isSelected) return 1.0;
    return 0.5;
  }

  Widget _buildThreadPickerPreview(Widget child) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: _threadPickerWidthFactor,
        alignment: Alignment.centerLeft,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _buildComposer(context);
}
