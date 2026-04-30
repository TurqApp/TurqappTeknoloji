import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FirestoreConfig uses AppFirestore boundary', () async {
    final source =
        await File('lib/Core/Services/firestore_config.dart').readAsString();
    final hasDirectFirestore = source.split('\n').any((line) {
      if (line.contains('AppFirestore.instance')) return false;
      return line.contains('FirebaseFirestore.instance');
    });

    expect(
      hasDirectFirestore,
      isFalse,
      reason: 'FirestoreConfig should access Firestore through AppFirestore.',
    );
  });
}
