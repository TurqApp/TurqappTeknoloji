import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app code does not pass storage into WebpUploadService', () async {
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.endsWith('webp_upload_service.dart'));

    final offenders = <String>[];
    for (final file in dartFiles) {
      final source = await file.readAsString();
      final callPattern = RegExp(
        r'WebpUploadService\.(?:uploadFileAsWebp|uploadBytesAsWebp)\s*\(',
      );
      for (final match in callPattern.allMatches(source)) {
        var depth = 1;
        var index = match.end;
        while (index < source.length && depth > 0) {
          final char = source[index];
          if (char == '(') depth++;
          if (char == ')') depth--;
          index++;
        }
        final args = source.substring(match.end, index - 1);
        if (args.contains('storage:')) {
          offenders.add(file.path);
          break;
        }
      }
    }

    expect(offenders, isEmpty);
  });
}
