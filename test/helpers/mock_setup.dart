import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';

import '../mocks/mock_api.dart';
import '../mocks/mock_storage.dart';

void stubLoginSuccess(
  MockApiService api, {
  String body = '{"token":"abc123"}',
}) {
  when(api.login(any, any)).thenAnswer(
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
  int statusCode = 401,
  String body = '{"message":"error"}',
}) {
  when(api.login(any, any)).thenAnswer(
    (_) async => http.Response(body, statusCode),
  );
}

void stubCacheValue(MockStorage storage, String? value) {
  when(storage.read()).thenReturn(value);
}
