part of 'upload_queue_service.dart';

extension UploadQueueServicePostShellContentPart on UploadQueueService {
  Future<void> _performCreatePendingPostShellContent(
      QueuedUpload upload) async {
    final postDataMap = jsonDecode(upload.postData) as Map<String, dynamic>;
    final String userID = _resolveUploadQueueActiveUserId(postDataMap);
    if (userID.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[UploadQueue][Shell] skip_empty_user id=${upload.id} '
          'postDataKeys=${postDataMap.keys.toList()}',
        );
      }
      return;
    }

    final int scheduledAt =
        int.tryParse('${postDataMap['scheduledAt'] ?? 0}') ?? 0;
    final int postTimeStamp =
        int.tryParse('${postDataMap['timeStamp'] ?? 0}') ?? 0;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final publishTime = scheduledAt != 0
        ? scheduledAt
        : (postTimeStamp != 0 ? postTimeStamp : nowMs);

    final shellData = <String, dynamic>{
      "scheduledAt": scheduledAt,
      "timeStamp": postTimeStamp != 0 ? postTimeStamp : publishTime,
      "userID": userID,
      "isUploading": true,
      "hlsStatus": "none",
    };
    try {
      if (kDebugMode) {
        debugPrint(
          '[UploadQueue][Shell] write_start id=${upload.id} '
          'uid=$userID keys=${shellData.keys.toList()} '
          'scheduledAt=$scheduledAt timeStamp=${shellData["timeStamp"]}',
        );
      }
      await AppFirestore.instance
          .collection('Posts')
          .doc(upload.id)
          .set(shellData, SetOptions(merge: true));
      if (kDebugMode) {
        debugPrint('[UploadQueue][Shell] write_ok id=${upload.id}');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[UploadQueue][Shell] write_failed id=${upload.id} '
          'uid=$userID error=$e stack=$stackTrace',
        );
      }
      rethrow;
    }
  }
}
