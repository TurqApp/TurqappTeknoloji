import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
import 'package:url_launcher/url_launcher.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'admin.badges.title'.tr),
            Expanded(
              child: FutureBuilder<bool>(
                future: _canAccessFuture,
                builder: (context, accessSnap) {
                  if (accessSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (accessSnap.data != true) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'admin.no_access'.tr,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'MontserratMedium',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(15, 8, 15, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F6F6),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'admin.badges.manage_by_username'.tr,
                                style: TextStyle(
                                  fontFamily: 'MontserratBold',
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'admin.badges.manage_help'.tr,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: 'MontserratMedium',
                                  color: Colors.black54,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _nicknameController,
                                textInputAction: TextInputAction.done,
                                style: const TextStyle(
                                  fontFamily: 'MontserratMedium',
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'admin.tasks.username'.tr,
                                  hintText: 'admin.tasks.username_hint'.tr,
                                  labelStyle: const TextStyle(
                                    fontFamily: 'MontserratMedium',
                                  ),
                                  prefixIcon: const Icon(Icons.alternate_email),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedBadge,
                                items: _badgeOptions
                                    .map(
                                      (badge) => DropdownMenuItem<String>(
                                        value: badge,
                                        child: _BadgeMenuRow(
                                          badge: badge,
                                          label: badge.isEmpty
                                              ? 'admin.badges.no_badge'.tr
                                              : _localizedBadgeTitle(badge),
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                                onChanged: _saving
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _selectedBadge = value ?? '';
                                        });
                                      },
                                decoration: InputDecoration(
                                  labelText: 'admin.badges.badge_label'.tr,
                                  labelStyle: const TextStyle(
                                    fontFamily: 'MontserratMedium',
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              if (_selectedDescription != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  _selectedDescription!,
                                  style: const TextStyle(
                                    fontFamily: 'MontserratMedium',
                                    fontSize: 12,
                                    color: Colors.black54,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: _saving ? null : _saveBadge,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: _saving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.save_outlined),
                                  label: Text(
                                    _saving
                                        ? 'admin.tasks.saving'.tr
                                        : 'admin.badges.save_badge'.tr,
                                    style: const TextStyle(
                                      fontFamily: 'MontserratBold',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_lastResult != null) ...[
                          const SizedBox(height: 14),
                          _ResultCard(result: _lastResult!),
                        ],
                        const SizedBox(height: 14),
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _verifiedAccountRepository.watchApplications(),
                          builder: (context, snap) {
                            if (snap.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final docs = snap.data?.docs ?? const [];
                            return _ApplicationsSection(docs: docs);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? get _selectedDescription {
    if (_selectedBadge.isEmpty) {
      return 'admin.badges.remove_selected_desc'.tr;
    }
    return _localizedBadgeDesc(_selectedBadge);
  }

  Future<void> _saveBadge() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final nickname = normalizeNicknameInput(_nicknameController.text);
    if (nickname.isEmpty) {
      AppSnackbar(
        'admin.tasks.missing_info'.tr,
        'admin.tasks.username_required'.tr,
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final isPrimaryAdmin = await AdminAccessService.isPrimaryAdmin();
      if (!isPrimaryAdmin) {
        final user = await _userRepository.findUserByNickname(nickname);
        if (user == null) {
          AppSnackbar(
            'support.error_title'.tr,
            'admin.tasks.user_not_found'.tr,
          );
          return;
        }
        await _approvalRepository.createApproval(
          type: 'badge_change',
          title: 'admin.badges.change_approval_title'.tr,
          summary: _selectedBadge.isEmpty
              ? 'admin.badges.remove_badge_summary'
                  .trParams(<String, String>{'nickname': nickname})
              : 'admin.badges.give_badge_summary'.trParams(
                  <String, String>{
                    'nickname': nickname,
                    'badge': _localizedBadgeTitle(_selectedBadge),
                  },
                ),
          targetUserId: (user['id'] ?? '').toString(),
          targetNickname: (user['nickname'] ?? '').toString(),
          payload: <String, dynamic>{
            'userId': (user['id'] ?? '').toString(),
            'rozet': _badgeStorageValue(_selectedBadge),
          },
        );
        AppSnackbar(
          'admin.badges.title'.tr,
          'admin.badges.sent_for_approval'.tr,
        );
        return;
      }

      final callable = FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('setUserBadgeByNickname');
      final response = await callable.call<Map<String, dynamic>>({
        'nickname': nickname,
        'rozet': _badgeStorageValue(_selectedBadge),
      });

      final result = _BadgeChangeResult.fromMap(
        Map<String, dynamic>.from(response.data),
      );
      if (!mounted) return;
      setState(() {
        _lastResult = result;
      });
      AppSnackbar(
        'admin.badges.title'.tr,
        result.badge.isEmpty
            ? 'admin.badges.badge_removed'.trParams(
                <String, String>{'nickname': result.nickname},
              )
            : 'admin.badges.badge_saved'.trParams(<String, String>{
                'nickname': result.nickname,
                'badge':
                    _localizedBadgeTitle(_badgeKeyFromStorageValue(result.badge)),
              }),
      );
    } on FirebaseFunctionsException catch (e) {
      AppSnackbar('support.error_title'.tr, _errorMessage(e));
    } catch (e) {
      AppSnackbar(
        'support.error_title'.tr,
        '${'admin.badges.save_failed'.tr}: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String _errorMessage(FirebaseFunctionsException error) {
    switch (error.code) {
      case 'not-found':
        return 'admin.tasks.user_not_found'.tr;
      case 'permission-denied':
        return 'admin.badges.permission_required'.tr;
      case 'invalid-argument':
        return error.message ?? 'admin.badges.invalid_input'.tr;
      case 'failed-precondition':
        return 'admin.badges.multiple_users'.tr;
      default:
        return error.message ?? 'admin.badges.save_failed'.tr;
    }
  }
}

class _ApplicationsSection extends StatelessWidget {
  const _ApplicationsSection({
    required this.docs,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.badges.applications_title'.tr,
            style: TextStyle(
              fontFamily: 'MontserratBold',
              fontSize: 15,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'admin.badges.applications_help'.tr,
            style: const TextStyle(
              fontFamily: 'MontserratMedium',
              fontSize: 12,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          if (docs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'admin.badges.no_applications'.tr,
                style: const TextStyle(
                  fontFamily: 'MontserratMedium',
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
            )
          else
            ...docs.map(
              (doc) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ApplicationCard(data: doc.data()),
              ),
            ),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatefulWidget {
  const _ApplicationCard({
    required this.data,
  });

  final Map<String, dynamic> data;

  @override
  State<_ApplicationCard> createState() => _ApplicationCardState();
}

class _ApplicationCardState extends State<_ApplicationCard> {
  final AdminApprovalRepository _approvalRepository =
      AdminApprovalRepository.ensure();
  bool _approving = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final selected = (data['selected'] ?? '').toString().trim();
    final currentNickname = (data['currentNickname'] ?? '').toString().trim();
    final requestedNickname = (data['talepNickname'] ?? '').toString().trim();
    final userId = (data['userID'] ?? '').toString().trim();
    final timeStamp = (data['timeStamp'] as num?)?.toInt() ?? 0;
    final status = (data['status'] ?? 'pending').toString().trim();
    final links = <_ApplicationLink>[
      _ApplicationLink(
        label: 'Instagram',
        url: _pickSocialUrl(
          data['instagramUrl'],
          data['instagram'],
          prefix: 'https://instagram.com/',
        ),
      ),
      _ApplicationLink(
        label: 'X',
        url: _pickSocialUrl(
          data['twitterUrl'],
          data['twitter'],
          prefix: 'https://x.com/',
        ),
      ),
      _ApplicationLink(
        label: 'TikTok',
        url: _pickSocialUrl(
          data['tiktokUrl'],
          data['tiktok'],
          prefix: 'https://tiktok.com/@',
        ),
      ),
      _ApplicationLink(
        label: 'YouTube',
        url: _pickSocialUrl(
          data['youtubeUrl'],
          data['youtube'],
          prefix: 'https://youtube.com/@',
        ),
      ),
      _ApplicationLink(
        label: 'LinkedIn',
        url: _pickSocialUrl(
          data['linkedinUrl'],
          data['linkedin'],
          prefix: 'https://linkedin.com/in/',
        ),
      ),
      _ApplicationLink(
        label: 'Website',
        url: _pickWebsiteUrl(data['websiteUrl'], data['website']),
      ),
    ].where((item) => item.url.isNotEmpty).toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requestedNickname.isEmpty ? '@-' : requestedNickname,
                      style: const TextStyle(
                        fontFamily: 'MontserratBold',
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: userId.isEmpty
                          ? null
                          : () => Get.to(() => SocialProfile(userID: userId)),
                      child: Text(
                        'TurqApp: ${currentNickname.isEmpty ? '@-' : currentNickname}',
                        style: TextStyle(
                          fontFamily: 'MontserratMedium',
                          fontSize: 12,
                          color: userId.isEmpty ? Colors.black54 : Colors.blue,
                          decoration: userId.isEmpty
                              ? TextDecoration.none
                              : TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'UID: $userId',
                      style: const TextStyle(
                        fontFamily: 'MontserratMedium',
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  selected.isEmpty
                      ? 'admin.badges.no_badge_selected'.tr
                      : selected,
                  style: const TextStyle(
                    fontFamily: 'MontserratBold',
                    fontSize: 11,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'admin.badges.status'
                .trParams(<String, String>{'status': status}),
            style: const TextStyle(
              fontFamily: 'MontserratMedium',
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
          if (timeStamp > 0) ...[
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(timeStamp),
              style: const TextStyle(
                fontFamily: 'MontserratMedium',
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
          if (links.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: links
                  .map((item) => _LinkChip(link: item))
                  .toList(growable: false),
            ),
          ],
          if (status != 'approved' && selected.isNotEmpty && userId.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ElevatedButton.icon(
                onPressed: _approving ? null : () => _approve(userId, selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _approving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.verified_outlined, size: 18),
                label: Text(
                  'admin.badges.approve_and_assign'.tr,
                  style: const TextStyle(
                    fontFamily: 'MontserratBold',
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _approve(String userId, String rozet) async {
    setState(() {
      _approving = true;
    });
    try {
      final isPrimaryAdmin = await AdminAccessService.isPrimaryAdmin();
      if (!isPrimaryAdmin) {
        await _approvalRepository.createApproval(
          type: 'badge_change',
          title: 'admin.badges.application_approval_title'.tr,
          summary: 'admin.badges.application_approval_summary'.trParams(
            <String, String>{
              'nickname':
                  (widget.data['talepNickname'] ?? '').toString().trim(),
              'badge': rozet,
            },
          ),
          targetUserId: userId,
          targetNickname:
              (widget.data['currentNickname'] ?? '').toString().trim(),
          payload: <String, dynamic>{
            'userId': userId,
            'rozet': rozet,
          },
        );
        AppSnackbar(
          'admin.badges.title'.tr,
          'admin.badges.application_sent_for_approval'.tr,
        );
        return;
      }

      final callable = FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('setUserBadgeByUserId');
      await callable.call<Map<String, dynamic>>({
        'userId': userId,
        'rozet': rozet,
      });
      AppSnackbar(
        'admin.badges.title'.tr,
        'admin.badges.application_approved'.tr,
      );
    } on FirebaseFunctionsException catch (e) {
      final message = e.message ?? 'admin.badges.application_approve_failed'.tr;
      AppSnackbar('support.error_title'.tr, message);
    } catch (e) {
      AppSnackbar(
        'support.error_title'.tr,
        '${'admin.badges.application_approve_failed'.tr}: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _approving = false;
        });
      }
    }
  }

  String _formatTimestamp(int value) {
    final dt = DateTime.fromMillisecondsSinceEpoch(value);
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dd.$mm.${dt.year} $hh:$min';
  }

  String _pickSocialUrl(Object? urlValue, Object? rawValue,
      {required String prefix}) {
    final url = (urlValue ?? '').toString().trim();
    if (url.isNotEmpty) return url;
    final raw = normalizeHandleInput((rawValue ?? '').toString());
    if (raw.isEmpty) return '';
    return '$prefix$raw';
  }

  String _pickWebsiteUrl(Object? urlValue, Object? rawValue) {
    final url = normalizeWebsiteUrl((urlValue ?? '').toString());
    if (url.isNotEmpty) return url;
    return normalizeWebsiteUrl((rawValue ?? '').toString());
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({
    required this.link,
  });

  final _ApplicationLink link;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => launchUrl(
        Uri.parse(link.url),
        mode: LaunchMode.externalApplication,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.black12),
        ),
        child: Text(
          link.label,
          style: const TextStyle(
            fontFamily: 'MontserratBold',
            fontSize: 12,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class _ApplicationLink {
  _ApplicationLink({
    required this.label,
    Object? url,
  }) : url = (url ?? '').toString().trim();

  final String label;
  final String url;
}

class _BadgeMenuRow extends StatelessWidget {
  const _BadgeMenuRow({
    required this.badge,
    required this.label,
  });

  final String badge;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = badge.isEmpty ? Colors.transparent : mapRozetToColor(badge);
    return Row(
      children: [
        Icon(
          badge.isEmpty ? Icons.remove_circle_outline : Icons.verified,
          color: badge.isEmpty ? Colors.black54 : color,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'MontserratMedium',
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final _BadgeChangeResult result;

  @override
  Widget build(BuildContext context) {
    final appliedBadge =
        result.badge.isEmpty ? 'admin.badges.no_badge'.tr : result.badge;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.badges.last_action'.tr,
            style: TextStyle(
              fontFamily: 'MontserratBold',
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '@${result.nickname}',
            style: const TextStyle(
              fontFamily: 'MontserratBold',
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'UID: ${result.userId}',
            style: const TextStyle(
              fontFamily: 'MontserratMedium',
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _BadgeMenuRow(
                badge: result.badge,
                label: appliedBadge,
              ),
              const Spacer(),
              Text(
                result.updatedAtLabel,
                style: const TextStyle(
                  fontFamily: 'MontserratMedium',
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeChangeResult {
  const _BadgeChangeResult({
    required this.userId,
    required this.nickname,
    required this.badge,
    required this.updatedAtMs,
  });

  final String userId;
  final String nickname;
  final String badge;
  final int updatedAtMs;

  factory _BadgeChangeResult.fromMap(Map<String, dynamic> data) {
    int updatedAt = 0;
    final rawUpdatedAt = data['updatedAt'];
    if (rawUpdatedAt is int) {
      updatedAt = rawUpdatedAt;
    } else if (rawUpdatedAt is num) {
      updatedAt = rawUpdatedAt.toInt();
    }
    return _BadgeChangeResult(
      userId: (data['userId'] ?? '').toString(),
      nickname: (data['nickname'] ?? '').toString(),
      badge: (data['rozet'] ?? '').toString(),
      updatedAtMs: updatedAt,
    );
  }

  String get updatedAtLabel {
    if (updatedAtMs <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(updatedAtMs);
    final twoDigitMonth = dt.month.toString().padLeft(2, '0');
    final twoDigitDay = dt.day.toString().padLeft(2, '0');
    final twoDigitHour = dt.hour.toString().padLeft(2, '0');
    final twoDigitMinute = dt.minute.toString().padLeft(2, '0');
    return '$twoDigitDay.$twoDigitMonth.${dt.year} $twoDigitHour:$twoDigitMinute';
  }
}
