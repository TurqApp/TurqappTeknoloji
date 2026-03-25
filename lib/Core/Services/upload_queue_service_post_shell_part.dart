part of 'upload_queue_service.dart';

extension UploadQueueServicePostShellPart on UploadQueueService {
  Future<void> _performCreatePendingPostShell(QueuedUpload upload) async {
    final postDataMap = jsonDecode(upload.postData) as Map<String, dynamic>;
    final String userID = _resolveUploadQueueActiveUserId(postDataMap);
    if (userID.isEmpty) return;

    final String text = (postDataMap['text'] ?? '')
        .toString()
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '')
        .trim();
    final String location = (postDataMap['location'] ?? '').toString().trim();
    final Map<String, dynamic> yorumMap =
        Map<String, dynamic>.from(postDataMap['yorumMap'] ?? {});
    final Map<String, dynamic> reshareMap =
        Map<String, dynamic>.from(postDataMap['reshareMap'] ?? {});
    final Map<String, dynamic> poll =
        Map<String, dynamic>.from(postDataMap['poll'] ?? {});
    final bool sharedAsPost = (postDataMap['sharedAsPost'] ?? false) == true;
    final String originalUserID =
        (postDataMap['originalUserID'] ?? '').toString().trim();
    final String originalPostID =
        (postDataMap['originalPostID'] ?? '').toString().trim();
    final String sourcePostID =
        (postDataMap['sourcePostID'] ?? '').toString().trim();
    final bool quotedPost = (postDataMap['quotedPost'] ?? false) == true;
    final String quotedOriginalText =
        (postDataMap['quotedOriginalText'] ?? '').toString().trim();
    final String quotedSourceUserID =
        (postDataMap['quotedSourceUserID'] ?? '').toString().trim();
    final String quotedSourceDisplayName =
        (postDataMap['quotedSourceDisplayName'] ?? '').toString().trim();
    final String quotedSourceUsername =
        (postDataMap['quotedSourceUsername'] ?? '').toString().trim();
    final String quotedSourceAvatarUrl =
        (postDataMap['quotedSourceAvatarUrl'] ?? '').toString().trim();
    final currentUser = CurrentUserService.instance;
    final String authorNickname = _uploadQueueFirstNonEmptyValue([
      normalizeHandleInput(postDataMap['nickname']?.toString() ?? ''),
      normalizeHandleInput(postDataMap['authorNickname']?.toString() ?? ''),
      normalizeHandleInput(currentUser.nickname),
    ]);
    final String username = _uploadQueueFirstNonEmptyValue([
      normalizeHandleInput(postDataMap['username']?.toString() ?? ''),
    ]);
    final String fullName = _uploadQueueFirstNonEmptyValue([
      postDataMap['fullName'],
      postDataMap['authorDisplayName'],
      postDataMap['displayName'],
      currentUser.fullName,
      authorNickname,
    ]);
    final String authorDisplayName = _uploadQueueFirstNonEmptyValue([
      postDataMap['authorDisplayName'],
      postDataMap['displayName'],
      fullName,
      authorNickname,
    ]);
    final String authorAvatarUrl =
        (postDataMap['authorAvatarUrl'] ?? currentUser.avatarUrl)
            .toString()
            .trim();
    final String authorRozet = _uploadQueueFirstNonEmptyValue([
      postDataMap['rozet'],
      currentUser.currentUser?.rozet.trim() ?? '',
    ]);
    final int scheduledAt =
        int.tryParse('${postDataMap['scheduledAt'] ?? 0}') ?? 0;

    bool flood = false;
    String mainFlood = '';
    try {
      final idxStr = upload.id.substring(upload.id.lastIndexOf('_') + 1);
      final idx = int.tryParse(idxStr) ?? 0;
      flood = idx != 0;
      if (flood) {
        final base = upload.id.substring(0, upload.id.lastIndexOf('_'));
        mainFlood = '${base}_0';
      }
    } catch (_) {}

    int floodCount = 1;
    try {
      final base = upload.id.substring(0, upload.id.lastIndexOf('_'));
      floodCount = _queue.where((q) => q.id.startsWith('${base}_')).length;
      if (floodCount <= 0) floodCount = 1;
    } catch (_) {}

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final publishTime = scheduledAt != 0 ? scheduledAt : nowMs;

    await FirebaseFirestore.instance.collection('Posts').doc(upload.id).set({
      "arsiv": true,
      "debugMode": false,
      "deletedPost": false,
      "deletedPostTime": 0,
      "flood": flood,
      "floodCount": floodCount,
      "gizlendi": false,
      "img": const <String>[],
      "imgMap": const <Map<String, dynamic>>[],
      "isAd": false,
      "ad": false,
      "izBirakYayinTarihi": publishTime,
      "konum": location,
      "mainFlood": mainFlood,
      "metin": text,
      "scheduledAt": scheduledAt,
      "sikayetEdildi": false,
      "stabilized": false,
      "stats": {
        "commentCount": 0,
        "likeCount": 0,
        "reportedCount": 0,
        "retryCount": 0,
        "savedCount": 0,
        "statsCount": 0
      },
      "tags": const <String>[],
      "thumbnail": "",
      "timeStamp": nowMs,
      "userID": userID,
      "authorNickname": authorNickname,
      "authorDisplayName": authorDisplayName,
      "authorAvatarUrl": authorAvatarUrl,
      "nickname": authorNickname,
      "username": username,
      "fullName": fullName,
      "displayName": authorDisplayName,
      "avatarUrl": authorAvatarUrl,
      "rozet": authorRozet,
      "video": "",
      "isUploading": true,
      "yorumMap": yorumMap,
      "reshareMap": reshareMap,
      if (poll.isNotEmpty) "poll": poll,
      "originalUserID": sharedAsPost ? originalUserID : "",
      "originalPostID": sharedAsPost ? originalPostID : "",
      "sourcePostID": sharedAsPost ? sourcePostID : "",
      "sharedAsPost": sharedAsPost,
      "quotedPost": sharedAsPost ? quotedPost : false,
      "quotedOriginalText":
          (sharedAsPost && quotedPost) ? quotedOriginalText : "",
      "quotedSourceUserID":
          (sharedAsPost && quotedPost) ? quotedSourceUserID : "",
      "quotedSourceDisplayName":
          (sharedAsPost && quotedPost) ? quotedSourceDisplayName : "",
      "quotedSourceUsername":
          (sharedAsPost && quotedPost) ? quotedSourceUsername : "",
      "quotedSourceAvatarUrl":
          (sharedAsPost && quotedPost) ? quotedSourceAvatarUrl : "",
    }, SetOptions(merge: true));
  }
}
