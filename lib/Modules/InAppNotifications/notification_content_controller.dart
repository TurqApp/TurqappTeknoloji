import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Repositories/notify_lookup_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/posts_model.dart';

class NotificationContentController extends GetxController {
  String userID;

  NotificationContentController({required this.userID});
  var avatarUrl = "".obs;
  var nickname = "".obs;
  var following = false.obs;
  var followLoading = false.obs;
  var model = PostsModel.empty().obs;
  final UserRepository _userRepository = UserRepository.ensure();
  final FollowRepository _followRepository = FollowRepository.ensure();
  final NotifyLookupRepository _notifyLookupRepository =
      NotifyLookupRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    _loadUser();
    _loadFollowingState();
  }

  Future<void> getPostData(String docID) async {
    final lookup = await _notifyLookupRepository.getPostLookup(docID);
    final m = lookup.model;
    if (m == null) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final isVisibleNow = m.timeStamp <= nowMs;
    if (isVisibleNow && m.deletedPost != true) {
      model.value = m;
    } else {
      model.value = PostsModel.empty();
    }
  }

  Future<void> toggleFollowStatus(String userID) async {
    if (followLoading.value) return;
    final wasFollowing = following.value;
    following.value = !wasFollowing; // optimistic
    followLoading.value = true;
    try {
      final outcome = await FollowService.toggleFollow(userID);
      following.value = outcome.nowFollowing; // reconcile
      if (outcome.limitReached) {
        AppSnackbar('Takip Limiti', 'Günlük daha fazla kişi takip edilemiyor.');
      }
    } catch (e) {
      following.value = wasFollowing; // revert
    } finally {
      followLoading.value = false;
    }
  }

  Future<void> _loadUser() async {
    final user = await _userRepository.getUser(
      userID,
      preferCache: true,
      cacheOnly: false,
    );
    if (user == null) {
      avatarUrl.value = "";
      nickname.value = "TurqApp";
      return;
    }
    avatarUrl.value = user.avatarUrl;
    nickname.value = user.nickname.isNotEmpty ? user.nickname : user.preferredName;
  }

  Future<void> _loadFollowingState() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid.isEmpty) return;
    following.value = await _followRepository.isFollowing(
      userID,
      currentUid: currentUid,
      preferCache: true,
    );
  }
}
