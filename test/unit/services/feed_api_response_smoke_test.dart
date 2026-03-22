import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';

import '../../helpers/feed_api_smoke_support.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient client;
  late FeedApiSmokeService api;

  setUp(() {
    client = MockHttpClient();
    api = FeedApiSmokeService(
      client: client,
      uri: Uri.parse('https://api.example.com/feed'),
    );
  });

  test('SMOKE - Feed response structure', () async {
    when(
      client.get(
        any,
        headers: anyNamed('headers'),
      ),
    ).thenAnswer(
      (_) async => http.Response(
        '{"items":[{"id":"1","videoUrl":"https://cdn.example.com/v1.m3u8"}]}',
        200,
      ),
    );

    final response = await api.getFeed();

    expect(response.statusCode, 200);
    expect(response.data, isA<Map<String, dynamic>>());
    expect(response.data.containsKey('items'), isTrue);

    final items = response.data['items'];
    expect(items, isA<List>());
    expect(items, isNotEmpty);

    final first = Map<String, dynamic>.from((items as List).first as Map);
    expect(first['videoUrl'], isNotNull);
    expect(response.elapsed, lessThan(const Duration(seconds: 2)));
  });

  test('SMOKE - Feed request sends basic accept header', () async {
    when(
      client.get(
        any,
        headers: anyNamed('headers'),
      ),
    ).thenAnswer(
      (_) async => http.Response(
        '{"items":[{"id":"1","videoUrl":"https://cdn.example.com/v1.m3u8"}]}',
        200,
      ),
    );

    await api.getFeed();

    verify(
      client.get(
        Uri.parse('https://api.example.com/feed'),
        headers: const <String, String>{'accept': 'application/json'},
      ),
    ).called(1);
  });

  test('SMOKE - Feed rejects non-200 status', () async {
    when(
      client.get(
        any,
        headers: anyNamed('headers'),
      ),
    ).thenAnswer((_) async => http.Response('{"error":"bad"}', 500));

    expect(
      api.getFeed,
      throwsA(isA<HttpException>()),
    );
  });

  test('SMOKE - Feed rejects empty items list', () async {
    when(
      client.get(
        any,
        headers: anyNamed('headers'),
      ),
    ).thenAnswer((_) async => http.Response('{"items":[]}', 200));

    expect(
      api.getFeed,
      throwsA(isA<StateError>()),
    );
  });

  test('SMOKE - Feed rejects missing required video field', () async {
    when(
      client.get(
        any,
        headers: anyNamed('headers'),
      ),
    ).thenAnswer(
      (_) async => http.Response(
        '{"items":[{"id":"1","title":"No video"}]}',
        200,
      ),
    );

    expect(
      api.getFeed,
      throwsA(isA<StateError>()),
    );
  });
}
