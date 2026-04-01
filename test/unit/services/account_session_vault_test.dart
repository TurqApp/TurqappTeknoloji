import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Services/account_session_vault.dart';

void main() {
  test('AccountSessionCredential legacy payloadlarini sifresiz sanitize eder', () {
    final credential = AccountSessionCredential.fromJson(<String, dynamic>{
      'email': '  TEST@MAIL.COM ',
      'password': 'super-secret',
    });

    expect(credential.email, 'test@mail.com');
    expect(credential.password, isEmpty);
    expect(credential.toJson(), <String, String>{
      'email': 'test@mail.com',
    });
  });
}
