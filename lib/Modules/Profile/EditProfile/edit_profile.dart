import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'package:turqappv2/Modules/Profile/AddressSelector/address_selector.dart';
import 'package:turqappv2/Modules/Profile/Cv/cv.dart';
import 'package:turqappv2/Modules/Profile/DeleteAccount/delete_account.dart';
import 'package:turqappv2/Modules/Profile/EditProfile/edit_profile_controller.dart';
import 'package:turqappv2/Modules/Profile/EditorEmail/editor_email.dart';
import 'package:turqappv2/Modules/Profile/EditorNickname/editor_nickname.dart';
import 'package:turqappv2/Modules/Profile/EditorPhoneNumber/editor_phone_number.dart';
import 'package:turqappv2/Modules/Profile/JobSelector/job_selector.dart';
import 'package:turqappv2/Modules/Profile/ProfileContact/profile_contact.dart';
import 'package:turqappv2/Modules/Profile/SocialMediaLinks/social_media_links.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Core/Buttons/turq_app_toggle.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';

import '../BiographyMaker/biography_maker.dart';

part 'edit_profile_header_part.dart';
part 'edit_profile_settings_part.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  late final EditProfileController controller;
  late final String _controllerTag;
  final CurrentUserService currentUserService = CurrentUserService.instance;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'edit_profile_${identityHashCode(this)}';
    controller = EditProfileController.ensure(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (EditProfileController.maybeFind(tag: _controllerTag) != null &&
        identical(
          EditProfileController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<EditProfileController>(tag: _controllerTag);
    }
    super.dispose();
  }

  String get _avatarUrl => currentUserService.avatarUrl.trim();
  String get _nickname => currentUserService.nickname;
  String get _email {
    final primary = currentUserService.email.trim();
    if (primary.isNotEmpty) return primary;
    return controller.email.value;
  }

  String _formatDisplayPhone(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('+')) return trimmed;
    if (trimmed.startsWith('0')) return '+9$trimmed';
    return '+90$trimmed';
  }

  void _updateEditProfileState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return _buildEditProfileScaffold(context);
  }
}
