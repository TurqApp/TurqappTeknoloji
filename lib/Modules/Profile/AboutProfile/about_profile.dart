import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Modules/Profile/AboutProfile/about_profile_controller.dart';

part 'about_profile_shell_part.dart';
part 'about_profile_content_part.dart';

class AboutProfile extends StatefulWidget {
  final String userID;
  const AboutProfile({super.key, required this.userID});

  @override
  State<AboutProfile> createState() => _AboutProfileState();
}

class _AboutProfileState extends State<AboutProfile> {
  late final AboutProfileController controller;
  late final String _controllerTag;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'about_profile_${widget.userID}_${identityHashCode(this)}';
    final existingController =
        AboutProfileController.maybeFind(tag: _controllerTag);
    if (existingController != null) {
      controller = existingController;
    } else {
      controller = AboutProfileController.ensure(tag: _controllerTag);
      _ownsController = true;
    }
    controller.getUserData(widget.userID);
  }

  @override
  void didUpdateWidget(covariant AboutProfile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userID != widget.userID) {
      controller.getUserData(widget.userID);
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          AboutProfileController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<AboutProfileController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildAboutProfileShell(context);
  }
}
