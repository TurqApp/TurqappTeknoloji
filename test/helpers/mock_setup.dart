import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';

import '../mocks/mock_api.dart';
import '../mocks/mock_storage.dart';

void stubLoginSuccess(
  MockApiService api, {
  String email = 'test@mail.com',
  String password = '123456',
  String body = '{"token":"abc123"}',
}) {
  when(api.login(email, password)).thenAnswer(
    (_) async => http.Response(
      body,
      200,
      headers: <String, String>{
        'content-type': 'application/json',
      },
    ),
  );
}

void stubLoginFailure(
  MockApiService api, {
  String email = 'test@mail.com',
  String password = '123456',
  int statusCode = 401,
  String body = '{"message":"error"}',
}) {
  when(api.login(email, password)).thenAnswer(
    (_) async => http.Response(body, statusCode),
  );
}

void stubCacheValue(MockStorage storage, String? value) {
  when(storage.read()).thenReturn(value);
}
