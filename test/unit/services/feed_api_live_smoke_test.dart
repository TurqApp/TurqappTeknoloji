import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../helpers/feed_api_smoke_support.dart';

const bool _runRealApiSmoke =
    bool.fromEnvironment('RUN_REAL_API_SMOKE', defaultValue: false);
const String _feedApiSmokeUrl =
    String.fromEnvironment('FEED_API_SMOKE_URL', defaultValue: '');
const String _feedApiSmokeBearer =
    String.fromEnvironment('FEED_API_SMOKE_BEARER', defaultValue: '');
const String _feedApiSmokeItemsKey =
    String.fromEnvironment('FEED_API_SMOKE_ITEMS_KEY', defaultValue: 'items');
const String _feedApiSmokeVideoKey = String.fromEnvironment(
  'FEED_API_SMOKE_VIDEO_KEY',
  defaultValue: 'videoUrl',
);

void main() {
  test(
    'LIVE SMOKE - Feed response structure',
    () async {
      expect(
        _feedApiSmokeUrl,
        isNotEmpty,
        reason: 'Pass --dart-define=FEED_API_SMOKE_URL=...',
      );

      final client = http.Client();
      final api = FeedApiSmokeService(
        client: client,
        uri: Uri.parse(_feedApiSmokeUrl),
        headers: <String, String>{
          'accept': 'application/json',
          if (_feedApiSmokeBearer.isNotEmpty)
            HttpHeaders.authorizationHeader: 'Bearer $_feedApiSmokeBearer',
        },
        timeout: const Duration(seconds: 4),
        itemsKey: _feedApiSmokeItemsKey,
        videoFieldKey: _feedApiSmokeVideoKey,
      );

      try {
        final response = await api.getFeed();

        expect(response.statusCode, 200);
        expect(response.data, isNotEmpty);
        expect(response.data.containsKey(_feedApiSmokeItemsKey), isTrue);

        final items = response.data[_feedApiSmokeItemsKey] as List;
        expect(items, isNotEmpty);

        final first = Map<String, dynamic>.from(items.first as Map);
        expect(first[_feedApiSmokeVideoKey], isNotNull);
        expect(
          response.elapsed,
          lessThan(const Duration(seconds: 4)),
        );
      } finally {
        client.close();
      }
    },
    skip: !_runRealApiSmoke,
  );
}
