import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../helpers/feed_api_smoke_support.dart';

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

void main() {
  final feedUri = Uri.parse('https://api.example.com/feed');
  late http.Client client;
  late FeedApiSmokeService api;

  test('SMOKE - Feed response structure', () async {
    client = FakeHttpClient(
      (request) async => http.Response(
        '{"items":[{"id":"1","videoUrl":"https://cdn.example.com/v1.m3u8"}]}',
        200,
      ),
    );
    api = FeedApiSmokeService(client: client, uri: feedUri);

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
    late http.Request capturedRequest;
    client = FakeHttpClient(
      (request) async {
        capturedRequest = request;
        return http.Response(
          '{"items":[{"id":"1","videoUrl":"https://cdn.example.com/v1.m3u8"}]}',
          200,
        );
      },
    );
    api = FeedApiSmokeService(client: client, uri: feedUri);

    await api.getFeed();

    expect(capturedRequest.url, feedUri);
    expect(capturedRequest.headers['accept'], 'application/json');
  });

  test('SMOKE - Feed rejects non-200 status', () async {
    client = FakeHttpClient(
      (request) async => http.Response('{"error":"bad"}', 500),
    );
    api = FeedApiSmokeService(client: client, uri: feedUri);

    expect(
      api.getFeed,
      throwsA(isA<HttpException>()),
    );
  });

  test('SMOKE - Feed rejects empty items list', () async {
    client = FakeHttpClient(
      (request) async => http.Response('{"items":[]}', 200),
    );
    api = FeedApiSmokeService(client: client, uri: feedUri);

    expect(
      api.getFeed,
      throwsA(isA<StateError>()),
    );
  });

  test('SMOKE - Feed rejects missing required video field', () async {
    client = FakeHttpClient(
      (request) async => http.Response(
        '{"items":[{"id":"1","title":"No video"}]}',
        200,
      ),
    );
    api = FeedApiSmokeService(client: client, uri: feedUri);

    expect(
      api.getFeed,
      throwsA(isA<StateError>()),
    );
  });
}
