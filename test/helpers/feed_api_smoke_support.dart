import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class FeedApiSmokeResult {
  FeedApiSmokeResult({
    required this.statusCode,
    required this.data,
    required this.elapsed,
  });

  final int statusCode;
  final Map<String, dynamic> data;
  final Duration elapsed;
}

class FeedApiSmokeService {
  FeedApiSmokeService({
    required this.client,
    required this.uri,
    this.headers = const <String, String>{'accept': 'application/json'},
    this.timeout = const Duration(seconds: 3),
    this.itemsKey = 'items',
    this.videoFieldKey = 'videoUrl',
  });

  final http.Client client;
  final Uri uri;
  final Map<String, String> headers;
  final Duration timeout;
  final String itemsKey;
  final String videoFieldKey;

  Future<FeedApiSmokeResult> getFeed() async {
    final stopwatch = Stopwatch()..start();
    final response = await client.get(uri, headers: headers).timeout(timeout);
    stopwatch.stop();

    if (response.statusCode != 200) {
      throw HttpException('Feed request failed: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Feed response must be a JSON object.');
    }

    final items = decoded[itemsKey];
    if (items is! List) {
      throw FormatException('Feed response is missing "$itemsKey" list.');
    }
    if (items.isEmpty) {
      throw StateError('Feed items must not be empty.');
    }

    final first = items.first;
    if (first is! Map) {
      throw const FormatException('Feed item must be a JSON object.');
    }

    final firstItem = Map<String, dynamic>.from(first);
    final videoValue = firstItem[videoFieldKey];
    if (videoValue == null ||
        (videoValue is String && videoValue.trim().isEmpty)) {
      throw StateError('Feed item is missing required "$videoFieldKey".');
    }

    return FeedApiSmokeResult(
      statusCode: response.statusCode,
      data: decoded,
      elapsed: stopwatch.elapsed,
    );
  }
}
