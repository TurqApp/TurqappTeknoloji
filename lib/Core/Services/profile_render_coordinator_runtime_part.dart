part of 'profile_render_coordinator.dart';

int _profileEntryTimestamp(Map<String, dynamic> entry) {
  final value = entry['timestamp'];
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value.trim());
    if (parsed != null) return parsed;
    final parsedNum = num.tryParse(value.trim());
    if (parsedNum != null) return parsedNum.toInt();
  }
  return 0;
}

List<Map<String, dynamic>> _buildProfileMergedEntries({
  required List<PostsModel> allPosts,
  required List<PostsModel> reshares,
  required int Function(String postId, int fallback) reshareSortTimestampFor,
}) {
  final combined = <Map<String, dynamic>>[];

  for (final post in allPosts.where((post) =>
      !post.deletedPost && !post.arsiv && !post.shouldHideWhileUploading)) {
    combined.add(<String, dynamic>{
      'docID': post.docID,
      'post': post,
      'isReshare': false,
      'timestamp': post.timeStamp,
    });
  }

  for (final reshare in reshares.where((post) =>
      !post.deletedPost && !post.arsiv && !post.shouldHideWhileUploading)) {
    final reshareTimestamp = reshareSortTimestampFor(
      reshare.docID,
      reshare.timeStamp.toInt(),
    );
    combined.add(<String, dynamic>{
      'docID': reshare.docID,
      'post': reshare,
      'isReshare': true,
      'timestamp': reshareTimestamp,
    });
  }

  combined.sort(
    (a, b) => _profileEntryTimestamp(b).compareTo(_profileEntryTimestamp(a)),
  );
  return combined;
}
