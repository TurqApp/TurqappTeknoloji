import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Helpers/safe_external_link_guard.dart';
import 'package:turqappv2/Core/Utils/nickname_utils.dart';
import 'package:turqappv2/Core/Utils/url_utils.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/admin_approval_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Repositories/verified_account_repository.dart';
import 'package:turqappv2/Core/rozet_permissions.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';

part 'badge_admin_view_actions_part.dart';
part 'badge_admin_view_applications_part.dart';
part 'badge_admin_view_content_part.dart';
part 'badge_admin_view_shell_part.dart';

class BadgeAdminView extends StatefulWidget {
  const BadgeAdminView({super.key});

  @override
  State<BadgeAdminView> createState() => _BadgeAdminViewState();
}

class _BadgeAdminViewState extends State<BadgeAdminView> {
  static const List<String> _badgeOptions = <String>[
    '',
    'gray',
    'turquoise',
    'yellow',
    'blue',
    'black',
    'red',
  ];

  final TextEditingController _nicknameController = TextEditingController();
  final VerifiedAccountRepository _verifiedAccountRepository =
      VerifiedAccountRepository.ensure();
  final AdminApprovalRepository _approvalRepository =
      AdminApprovalRepository.ensure();
  final UserRepository _userRepository = UserRepository.ensure();
  late final Future<bool> _canAccessFuture;
  String _selectedBadge = '';
  bool _saving = false;
  _BadgeChangeResult? _lastResult;

  String _badgeTitleKey(String badgeKey) {
    switch (badgeKey) {
      case 'blue':
        return 'become_verified.badge_blue';
      case 'red':
        return 'become_verified.badge_red';
      case 'yellow':
        return 'become_verified.badge_yellow';
      case 'turquoise':
        return 'become_verified.badge_turquoise';
      case 'gray':
        return 'become_verified.badge_gray';
      case 'black':
        return 'become_verified.badge_black';
      default:
        return badgeKey;
    }
  }

  String _badgeDescKey(String badgeKey) {
    switch (badgeKey) {
      case 'blue':
        return 'become_verified.badge_blue_desc';
      case 'red':
        return 'become_verified.badge_red_desc';
      case 'yellow':
        return 'become_verified.badge_yellow_desc';
      case 'turquoise':
        return 'become_verified.badge_turquoise_desc';
      case 'gray':
        return 'become_verified.badge_gray_desc';
      case 'black':
        return 'become_verified.badge_black_desc';
      default:
        return badgeKey;
    }
  }

  String _localizedBadgeTitle(String badgeKey) => _badgeTitleKey(badgeKey).tr;
  String _localizedBadgeDesc(String badgeKey) => _badgeDescKey(badgeKey).tr;

  String _badgeStorageValue(String badgeKey) {
    switch (badgeKey) {
      case 'gray':
        return 'Gri';
      case 'turquoise':
        return 'Turkuaz';
      case 'yellow':
        return 'Sarı';
      case 'blue':
        return 'Mavi';
      case 'black':
        return 'Siyah';
      case 'red':
        return 'Kırmızı';
      default:
        return '';
    }
  }

  String _badgeKeyFromStorageValue(String rawValue) {
    switch (normalizeRozetValue(rawValue)) {
      case 'gri':
        return 'gray';
      case 'turkuaz':
        return 'turquoise';
      case 'sari':
        return 'yellow';
      case 'mavi':
        return 'blue';
      case 'siyah':
        return 'black';
      case 'kirmizi':
        return 'red';
      default:
        return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _canAccessFuture = AdminAccessService.canAccessTask('badges');
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _updateBadgeAdminState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
