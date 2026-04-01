class HashtagModel {
  final String hashtag;
  final num count;
  final bool hasHashtag;
  final int? lastSeenTs;
  HashtagModel(this.hashtag, this.count,
      {this.hasHashtag = false, this.lastSeenTs});
}
