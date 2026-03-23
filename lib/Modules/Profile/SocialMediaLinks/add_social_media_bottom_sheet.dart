import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'package:turqappv2/Models/social_media_model.dart';
import 'package:turqappv2/Modules/Profile/SocialMediaLinks/social_media_branding.dart';

import 'social_media_links_controller.dart';

part 'add_social_media_bottom_sheet_content_part.dart';
part 'add_social_media_bottom_sheet_actions_part.dart';

class AddSocialMediaBottomSheet extends StatelessWidget {
  AddSocialMediaBottomSheet({super.key})
      : controller = SocialMediaController.ensure();
  final SocialMediaController controller;

  @override
  Widget build(BuildContext context) {
    return _buildSheetContent(context);
  }
}
