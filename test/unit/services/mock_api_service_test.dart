import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../mocks/api/mock_api.dart';

class FakeApiService implements ApiService {
  FakeApiService({
    required this.loginHandler,
    this.dataHandler,
  });

  final Future<http.Response> Function(String username, String password)
      loginHandler;
  final Future<String> Function()? dataHandler;

  @override
  Future<String> getData() {
    return dataHandler?.call() ?? Future<String>.value('');
  }

  @override
  Future<http.Response> login(String username, String password) {
    return loginHandler(username, password);
  }
}

void main() {
  test('Login success', () async {
    final api = FakeApiService(
      loginHandler: (username, password) async {
        expect(username, 'test');
        expect(password, '123');
        return http.Response('OK', 200);
      },
    );

    final response = await api.login('test', '123');

    expect(response.statusCode, 200);
  });
}
