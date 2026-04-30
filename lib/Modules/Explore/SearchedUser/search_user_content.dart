import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/Repositories/username_lookup_repository.dart';
import 'package:turqappv2/Core/Services/profile_navigation_service.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/Utils/account_status_utils.dart';
import 'package:turqappv2/Core/Utils/nickname_utils.dart';
import 'package:turqappv2/Models/ogrenci_model.dart';
import 'package:turqappv2/Modules/Explore/explore_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class SearchUserContent extends StatelessWidget {
  final OgrenciModel model;
  final bool isSearch;
  static final UserRepository _userRepository = UserRepository.ensure();
  static final UserSummaryResolver _userSummaryResolver =
      UserSummaryResolver.ensure();
  static final UserSubcollectionRepository _userSubcollectionRepository =
      ensureUserSubcollectionRepository();
  static final UsernameLookupRepository _usernameLookupRepository =
      UsernameLookupRepository.ensure();

  const SearchUserContent(
      {super.key, required this.model, required this.isSearch});

  String get _currentUid => CurrentUserService.instance.effectiveUserId;

  Future<String> _resolveTargetUid() async {
    var targetUid = model.userID.trim();
    if (targetUid.isNotEmpty) return targetUid;
    final handle = normalizeNicknameInput(model.nickname);
    if (handle.isEmpty) return "";
    return await _usernameLookupRepository.findUidForHandle(handle) ?? "";
  }

  Future<void> _saveRecentIfNeeded(String targetUid) async {
    final explore = maybeFindExploreController();
    if (explore != null) {
      await explore.saveRecentSearch(targetUid);
      return;
    }
    try {
      final currentUserID = _currentUid;
      if (currentUserID.isEmpty) return;
      await _userSubcollectionRepository.upsertEntry(
        currentUserID,
        subcollection: 'lastSearches',
        docId: targetUid,
        data: {
          'userID': targetUid,
          'updatedDate': DateTime.now().millisecondsSinceEpoch,
          'timeStamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      await CurrentUserService.instance.addRecentSearchLocal(targetUid);
      await maybeFindExploreController()?.refreshRecentSearchUsers();
    } catch (_) {}
  }

  Future<bool> _isTargetAccountActive(String targetUid) async {
    try {
      final summary = await _userSummaryResolver.resolve(
        targetUid,
        preferCache: true,
      );
      if (summary != null && summary.isDeleted) {
        return false;
      }
      final data = await _userRepository.getUserRaw(targetUid);
      if (data == null) return false;
      if (isDeactivatedAccount(
        accountStatus: data['accountStatus'],
        isDeleted: data['isDeleted'],
      )) {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _removeRecent() async {
    final targetUid = await _resolveTargetUid();
    if (targetUid.isEmpty) return;
    final c = maybeFindExploreController();
    if (c != null) {
      await c.removeRecentSearch(targetUid);
      c.isSearchMode.value = true;
      return;
    }
    try {
      final currentUserID = _currentUid;
      if (currentUserID.isNotEmpty) {
        await _userSubcollectionRepository.deleteEntry(
          currentUserID,
          subcollection: 'lastSearches',
          docId: targetUid,
        );
        await CurrentUserService.instance.removeRecentSearchLocal(targetUid);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(left: 15, right: 15, bottom: 7, top: 7),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    final targetUid = await _resolveTargetUid();
                    if (targetUid.isEmpty) return;
                    final isActive = await _isTargetAccountActive(targetUid);
                    if (!isActive) {
                      await _removeRecent();
                      AppSnackbar(
                          'common.info'.tr, 'explore.account_unavailable'.tr);
                      return;
                    }
                    final explore = maybeFindExploreController();
                    explore?.suspendExplorePreview();
                    await const ProfileNavigationService().openSocialProfile(
                      targetUid,
                      preventDuplicates: false,
                    );
                    explore?.resumeExplorePreview();
                    await _saveRecentIfNeeded(targetUid);
                  },
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.withAlpha(50)),
                        ),
                        child: ClipOval(
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: CachedUserAvatar(
                              imageUrl: model.avatarUrl,
                              radius: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Container(
                          color: Colors.transparent,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    model.nickname,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontFamily: "MontserratMedium",
                                    ),
                                  ),
                                  RozetContent(size: 14, userID: model.userID)
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                "${model.firstName.trimRight()} ${model.lastName.trimRight()}",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                  fontFamily: "MontserratMedium",
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isSearch)
                TextButton(
                  onPressed: _removeRecent,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.all(10),
                    minimumSize: const Size(4, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Icon(
                    CupertinoIcons.xmark,
                    size: 20,
                    color: Colors.grey,
                  ),
                )
              else
                Icon(
                  CupertinoIcons.chevron_right,
                  color: Colors.blueAccent,
                  size: 15,
                )
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 15, left: 65),
          child: SizedBox(
            height: 1,
            child: Divider(color: Colors.grey.withAlpha(20)),
          ),
        ),
      ],
    );
  }
}
