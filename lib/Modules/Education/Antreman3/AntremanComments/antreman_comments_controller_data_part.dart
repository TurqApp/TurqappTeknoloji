part of 'antreman_comments_controller.dart';

extension AntremanCommentsControllerDataPart on AntremanCommentsController {
  Future<void> fetchComments({bool silent = false}) async {
    if (!silent || comments.isEmpty) {
      isLoading.value = true;
    }
    try {
      final fetchedComments = await _antremanRepository.fetchComments(
        question.docID,
      );
      final fetchedReplies = <String, List<Reply>>{};
      for (final comment in fetchedComments) {
        fetchedReplies[comment.docID] = await _antremanRepository.fetchReplies(
          question.docID,
          comment.docID,
        );
        repliesVisible[comment.docID] = repliesVisible[comment.docID] ?? false;
      }
      comments.assignAll(fetchedComments);
      replies.assignAll(fetchedReplies);
    } catch (e) {
      log('Yorumlar cekilirken hata: $e');
      AppSnackbar('common.error'.tr, 'training.comments_load_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchReplies(String commentDocID) async {
    try {
      replies[commentDocID] = await _antremanRepository.fetchReplies(
        question.docID,
        commentDocID,
      );
    } catch (e) {
      log('Yanitlar cekilirken hata: $e');
    }
  }

  Future<Map<String, dynamic>> fetchUserInfo(String userID) async {
    if (userInfoCache.containsKey(userID)) {
      return userInfoCache[userID]!;
    }
    try {
      final data = await _userSummaryResolver.resolve(
        userID,
        preferCache: true,
      );
      if (data == null) {
        userInfoCache[userID] = {
          'avatarUrl': '',
          'nickname': 'training.unknown_user'.tr,
          'displayName': 'training.unknown_user'.tr,
        };
        return userInfoCache[userID]!;
      }
      final profileImage = data.avatarUrl;
      final profileName = data.preferredName.isNotEmpty
          ? data.preferredName
          : 'training.unknown_user'.tr;
      userInfoCache[userID] = {
        'avatarUrl': profileImage,
        'nickname': profileName,
        'username': data.username,
        'displayName': profileName,
      };
      return userInfoCache[userID]!;
    } catch (e) {
      log('Kullanici bilgisi alinirken hata: $e');
      userInfoCache[userID] = {
        'avatarUrl': '',
        'nickname': 'training.unknown_user'.tr,
        'displayName': 'training.unknown_user'.tr,
      };
      return userInfoCache[userID]!;
    }
  }

  String getTimeAgo(int timeStamp) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final difference = now - timeStamp;
    final seconds = (difference / 1000).floor();
    final minutes = (seconds / 60).floor();
    final hours = (minutes / 60).floor();
    final days = (hours / 24).floor();
    final weeks = (days / 7).floor();

    if (minutes < 1) {
      return 'training.time_now'.tr;
    } else if (minutes < 60) {
      return 'training.time_min'.trParams({'count': minutes.toString()});
    } else if (hours < 24) {
      return 'training.time_hour'.trParams({'count': hours.toString()});
    } else if (days < 7) {
      return 'training.time_day'.trParams({'count': days.toString()});
    } else {
      return 'training.time_week'.trParams({'count': weeks.toString()});
    }
  }
}
