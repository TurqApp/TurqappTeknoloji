import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';

class MockHttpClient extends Mock implements http.Client {}

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
  late MockHttpClient client;
  late AuthApiService service;

  setUp(() {
    client = MockHttpClient();
    service = AuthApiService(
      client,
      baseUrl: 'https://api.example.com',
    );
  });

  test('returns parsed JSON on 200', () async {
    when(
      client.post(
        loginUri,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      ),
    ).thenAnswer((_) async => http.Response('{"token":"abc"}', 200));

    final result = await service.login('test@mail.com', '123456');

    expect(result['token'], 'abc');
  });

  test('throws on non-200 responses', () async {
    when(
      client.post(
        loginUri,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      ),
    ).thenAnswer((_) async => http.Response('{"error":"unauthorized"}', 401));

    expect(
      () => service.login('test@mail.com', '123456'),
      throwsA(isA<HttpException>()),
    );
  });

  test('throws on timeout', () async {
    when(
      client.post(
        loginUri,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      ),
    ).thenAnswer(
      (_) => Future<http.Response>.delayed(const Duration(seconds: 5)),
    );

    expect(
      () => service.login('test@mail.com', '123456'),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('throws on invalid JSON body', () async {
    when(
      client.post(
        loginUri,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      ),
    ).thenAnswer((_) async => http.Response('invalid-json', 200));

    expect(
      () => service.login('test@mail.com', '123456'),
      throwsA(isA<FormatException>()),
    );
  });

  test('sends expected request payload and headers', () async {
    when(
      client.post(
        loginUri,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      ),
    ).thenAnswer((_) async => http.Response('{"token":"abc"}', 200));

    await service.login('test@mail.com', '123456');

    verify(
      client.post(
        Uri.parse('https://api.example.com/login'),
        headers: const <String, String>{
          'content-type': 'application/json',
          'accept': 'application/json',
        },
        body: '{"email":"test@mail.com","password":"123456"}',
      ),
    ).called(1);
  });
}
