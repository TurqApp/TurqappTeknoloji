part of 'upload_queue_service.dart';

String _uploadQueueFirstNonEmptyValue(Iterable<dynamic> candidates) {
  for (final candidate in candidates) {
    final value = candidate?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return '';
}

String _resolveUploadQueueActiveUserId([Map<String, dynamic>? postDataMap]) {
  return _uploadQueueFirstNonEmptyValue([
    CurrentUserService.instance.effectiveUserId,
    postDataMap?['userID'],
  ]);
}

bool _isUploadQueueAuthRetryableStorageError(FirebaseException e) {
  final code = normalizeLowercase(e.code);
  return code == 'unauthenticated' || code == 'unauthorized';
}
