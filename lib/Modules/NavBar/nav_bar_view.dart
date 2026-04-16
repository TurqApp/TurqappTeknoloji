import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:svg_flutter/svg.dart';
import 'package:turqappv2/Themes/app_colors.dart';
import 'nav_bar_controller.dart';
import 'package:turqappv2/Core/page_line_bar.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Services/integration_test_mode.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Modules/Explore/explore_controller.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/Education/education_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Core/Helpers/UnreadMessagesController/unread_messages_controller.dart';
import '../Agenda/agenda_view.dart';
import '../Explore/explore_view.dart';
import '../Profile/MyProfile/profile_view.dart';
import '../Education/education_view.dart';
import '../Short/short_view.dart';
import '../Short/short_controller.dart';
import '../Story/StoryRow/story_row_controller.dart';
import '../Profile/Settings/settings_controller.dart';
import '../Profile/MyProfile/profile_controller.dart';
import '../../Core/Widgets/cached_user_avatar.dart';
import '../../Core/Widgets/offline_indicator.dart';

part 'nav_bar_view_shell_part.dart';
part 'nav_bar_view_shell_content_part.dart';
part 'nav_bar_view_avatar_part.dart';

class NavBarView extends StatelessWidget {
  final selection = 0;

  NavBarView({super.key}) {
    _ensureControllersReady();
  }
  final NavBarController controller = ensureNavBarController();
  final SettingsController settingController = ensureSettingsController();

  // Ensure controllers are available
  void _ensureControllersReady() {
    final isIOS = GetPlatform.isIOS;
    ensureAgendaController();
    if (!isIOS) {
      ensureStoryRowController();
    }

    ensureUnreadMessagesControllerStarted();
  }

  late final AnimationController animationController;

  int _stackIndexForSelected({
    required int selected,
    required bool hasEducation,
  }) {
    if (selected == 1) return 1;
    if (hasEducation && selected == 3) return 2;
    final profileIndex = hasEducation ? 4 : 3;
    if (selected == profileIndex) return hasEducation ? 3 : 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) => _buildNavBarView(context);
}
