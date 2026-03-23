import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Localization/app_language_service.dart';

part 'language_settings_view_shell_part.dart';
part 'language_settings_view_header_part.dart';
part 'language_settings_view_labels_part.dart';
part 'language_settings_view_list_part.dart';
part 'language_settings_view_option_part.dart';

class LanguageSettingsView extends StatelessWidget {
  const LanguageSettingsView({super.key});

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
