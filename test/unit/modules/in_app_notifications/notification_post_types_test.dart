import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Modules/InAppNotifications/notification_post_types.dart';

void main() {
  test('normalizeNotificationCreateType preserves specific interaction types',
      () {
    expect(normalizeNotificationCreateType('like'), 'like');
    expect(normalizeNotificationCreateType('comment'), 'comment');
    expect(normalizeNotificationCreateType('reshared_posts'), 'reshared_posts');
    expect(
      normalizeNotificationCreateType('shared_as_posts'),
      'shared_as_posts',
    );
  });

  test('normalizeNotificationCreateType keeps generic posts generic', () {
    expect(
        normalizeNotificationCreateType('Posts'), kNotificationPostTypePosts);
    expect(normalizeNotificationCreateType('post'), kNotificationPostTypePosts);
  });
}
