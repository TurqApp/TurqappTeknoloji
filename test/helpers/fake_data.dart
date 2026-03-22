final class FakeData {
  static Map<String, dynamic> user({
    String id = 'user_1',
    String nickname = 'turqapp',
    String email = 'turqapp@example.com',
  }) {
    return <String, dynamic>{
      'userID': id,
      'nickname': nickname,
      'email': email,
    };
  }

  static Map<String, dynamic> post({
    String id = 'post_1',
    String ownerId = 'user_1',
    String text = 'Test post',
  }) {
    return <String, dynamic>{
      'postID': id,
      'ownerID': ownerId,
      'text': text,
    };
  }

  static List<String> feedIds({int count = 5}) {
    return List<String>.generate(count, (index) => 'feed_$index');
  }
}
