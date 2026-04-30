import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PostDeleteService uses AppFirestore boundary', () async {
    final source =
        await File('lib/Services/post_delete_service.dart').readAsString();
    final hasDirectFirestore = source.split('\n').any((line) {
      if (line.contains('AppFirestore.instance')) return false;
      return line.contains('FirebaseFirestore.instance');
    });

    expect(
      hasDirectFirestore,
      isFalse,
      reason: 'PostDeleteService should access Firestore through AppFirestore.',
    );
  });
}
