import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Models/stored_account.dart';
import 'package:turqappv2/Modules/Profile/EditorEmail/editor_email.dart';
import 'package:turqappv2/Modules/Profile/EditorPhoneNumber/editor_phone_number.dart';
import 'package:turqappv2/Modules/SignIn/sign_in.dart';
import 'package:turqappv2/Modules/SignIn/sign_in_controller.dart';
import 'package:turqappv2/Services/account_center_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'account_center_view_actions_part.dart';
part 'account_center_view_account_row_part.dart';
part 'account_center_view_account_data_part.dart';
part 'account_center_view_accounts_part.dart';
part 'account_center_view_accounts_card_part.dart';
part 'account_center_view_accounts_add_part.dart';
part 'account_center_view_accounts_add_body_part.dart';
part 'account_center_view_accounts_add_action_part.dart';
part 'account_center_view_accounts_empty_part.dart';
part 'account_center_view_empty_text_part.dart';
part 'account_center_view_accounts_header_part.dart';
part 'account_center_view_accounts_body_part.dart';
part 'account_center_view_accounts_section_label_part.dart';
part 'account_center_view_accounts_title_part.dart';
part 'account_center_view_accounts_list_part.dart';
part 'account_center_view_accounts_list_children_part.dart';
part 'account_center_view_accounts_list_divider_part.dart';
part 'account_center_view_accounts_list_item_part.dart';
part 'account_center_view_avatar_part.dart';
part 'account_center_view_avatar_fallback_part.dart';
part 'account_center_view_body_part.dart';
part 'account_center_view_body_content_part.dart';
part 'account_center_view_body_loading_part.dart';
part 'account_center_view_card_decoration_part.dart';
part 'account_center_view_card_shell_part.dart';
part 'account_center_view_chevron_part.dart';
part 'account_center_view_row_shell_part.dart';
part 'account_center_view_contact_details_part.dart';
part 'account_center_view_contact_details_data_part.dart';
part 'account_center_view_contact_details_email_action_part.dart';
part 'account_center_view_contact_details_email_part.dart';
part 'account_center_view_contact_details_phone_action_part.dart';
part 'account_center_view_contact_details_phone_part.dart';
part 'account_center_view_contact_details_divider_part.dart';
part 'account_center_view_contact_details_state_part.dart';
part 'account_center_view_contact_status_part.dart';
part 'account_center_view_info_content_part.dart';
part 'account_center_view_personal_data_part.dart';
part 'account_center_view_personal_data_direct_part.dart';
part 'account_center_view_personal_data_fallback_part.dart';
part 'account_center_view_personal_details_part.dart';
part 'account_center_view_personal_card_body_part.dart';
part 'account_center_view_personal_card_part.dart';
part 'account_center_view_personal_card_state_part.dart';
part 'account_center_view_personal_empty_part.dart';
part 'account_center_view_personal_header_part.dart';
part 'account_center_view_personal_body_part.dart';
part 'account_center_view_personal_section_label_part.dart';
part 'account_center_view_personal_loading_part.dart';
part 'account_center_view_personal_rows_list_part.dart';
part 'account_center_view_personal_row_part.dart';
part 'account_center_view_personal_rows_part.dart';
part 'account_center_view_personal_section_part.dart';
part 'account_center_view_password_provider_part.dart';
part 'account_center_view_password_reauth_part.dart';
part 'account_center_view_password_switch_part.dart';
part 'account_center_view_session_cleanup_part.dart';
part 'account_center_view_username_switch_part.dart';
part 'account_center_view_remove_part.dart';
part 'account_center_view_security_part.dart';
part 'account_center_view_security_section_label_part.dart';
part 'account_center_view_security_toggle_labels_part.dart';
part 'account_center_view_security_toggle_title_part.dart';
part 'account_center_view_security_toggle_subtitle_part.dart';
part 'account_center_view_security_toggle_action_part.dart';
part 'account_center_view_security_stream_part.dart';
part 'account_center_view_security_toggle_part.dart';
part 'account_center_view_shell_part.dart';

class AccountCenterView extends StatelessWidget {
  AccountCenterView({super.key});

  final AccountCenterService accountCenter = AccountCenterService.ensure();
  final UserRepository _userRepository = UserRepository.ensure();
  final SignInController _signInController = SignInController();
  final Future<void> _initFuture = AccountCenterService.ensure().init();

  bool get _isLoggedIn => _currentUid.isNotEmpty;

  CurrentUserService get _currentUserService => CurrentUserService.instance;

  String get _currentUid => _currentUserService.effectiveUserId;

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
