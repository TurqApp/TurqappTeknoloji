class HashtagModel {
  final String hashtag;
  final num count;
  final bool hasHashtag;
  final int? lastSeenTs;

  HashtagModel({
    required this.hashtag,
    required this.count,
    this.hasHashtag = false,
    this.lastSeenTs,
  });
}
