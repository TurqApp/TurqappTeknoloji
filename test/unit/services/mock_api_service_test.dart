import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';

import '../../mocks/mock_api.dart';

void main() {
  late MockApiService api;

  setUp(() {
    api = MockApiService();
  });

  test('Login success', () async {
    when(api.login(any, any)).thenAnswer(
      (_) async => http.Response('OK', 200),
    );

    final response = await api.login('test', '123');

    expect(response.statusCode, 200);
  });
}
