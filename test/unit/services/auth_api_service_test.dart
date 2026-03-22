import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class FakeHttpClient extends http.BaseClient {
  FakeHttpClient(this._handler);

  final Future<http.Response> Function(http.Request request) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request is! http.Request) {
      throw UnsupportedError('Only http.Request is supported in tests.');
    }
    final response = await _handler(request);
    return http.StreamedResponse(
      Stream<List<int>>.fromIterable(<List<int>>[response.bodyBytes]),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
      request: request,
    );
  }
}

class AuthApiService {
  AuthApiService(
    this.client, {
    required this.baseUrl,
  });

  final http.Client client;
  final String baseUrl;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await client
        .post(
          Uri.parse('$baseUrl/login'),
          headers: const <String, String>{
            'content-type': 'application/json',
            'accept': 'application/json',
          },
          body: jsonEncode(<String, String>{
            'email': email,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 3));

    if (response.statusCode != 200) {
      throw HttpException('Login failed: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid login JSON');
    }

    return decoded;
  }
}

void main() {
  final loginUri = Uri.parse('https://api.example.com/login');
  late http.Client client;
  late AuthApiService service;

  test('returns parsed JSON on 200', () async {
    client = FakeHttpClient(
      (request) async => http.Response('{"token":"abc"}', 200),
    );
    service = AuthApiService(client, baseUrl: 'https://api.example.com');

    final result = await service.login('test@mail.com', '123456');

    expect(result['token'], 'abc');
  });

  test('throws on non-200 responses', () async {
    client = FakeHttpClient(
      (request) async => http.Response('{"error":"unauthorized"}', 401),
    );
    service = AuthApiService(client, baseUrl: 'https://api.example.com');

    expect(
      () => service.login('test@mail.com', '123456'),
      throwsA(isA<HttpException>()),
    );
  });

  test('throws on timeout', () async {
    client = FakeHttpClient(
      (request) => Future<http.Response>.delayed(
        const Duration(seconds: 5),
        () => http.Response('{"token":"late"}', 200),
      ),
    );
    service = AuthApiService(client, baseUrl: 'https://api.example.com');

    expect(
      () => service.login('test@mail.com', '123456'),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('throws on invalid JSON body', () async {
    client = FakeHttpClient(
      (request) async => http.Response('invalid-json', 200),
    );
    service = AuthApiService(client, baseUrl: 'https://api.example.com');

    expect(
      () => service.login('test@mail.com', '123456'),
      throwsA(isA<FormatException>()),
    );
  });

  test('sends expected request payload and headers', () async {
    late http.Request capturedRequest;
    client = FakeHttpClient((request) async {
      capturedRequest = request;
      return http.Response('{"token":"abc"}', 200);
    });
    service = AuthApiService(client, baseUrl: 'https://api.example.com');

    await service.login('test@mail.com', '123456');

    expect(capturedRequest.url, loginUri);
    expect(capturedRequest.headers['content-type'], 'application/json');
    expect(capturedRequest.headers['accept'], 'application/json');
    expect(
        capturedRequest.body, '{"email":"test@mail.com","password":"123456"}');
  });
}
