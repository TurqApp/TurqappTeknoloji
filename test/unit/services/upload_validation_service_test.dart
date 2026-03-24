import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/upload_validation_service.dart';

void main() {
  group('UploadValidationService text limits', () {
    test('rejects caption beyond provided max length', () {
      final result = UploadValidationService.validateTextLength(
        'a' * 301,
        maxLength: 300,
      );

      expect(result.isValid, isFalse);
    });

    test('accepts caption within provided max length', () {
      final result = UploadValidationService.validateTextLength(
        'a' * 300,
        maxLength: 300,
      );

      expect(result.isValid, isTrue);
    });
  });
}
