import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Isolate bazlı segment indirici.
/// UI thread'i bloklamadan segment'leri CDN'den indirir.

class DownloadRequest {
  final String url;
  final String segmentKey;
  final String docID;

  DownloadRequest({
    required this.url,
    required this.segmentKey,
    required this.docID,
  });
}

class DownloadResult {
  final String segmentKey;
  final String docID;
  final Uint8List? bytes;
  final String? error;

  DownloadResult({
    required this.segmentKey,
    required this.docID,
    this.bytes,
    this.error,
  });

  bool get success => bytes != null;
}

class DownloadWorker {
  Isolate? _isolate;
  SendPort? _sendPort;
  final _resultController = StreamController<DownloadResult>.broadcast();
  final _readyCompleter = Completer<void>();

  Stream<DownloadResult> get results => _resultController.stream;

  /// Isolate'i başlat.
  Future<void> start() async {
    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(
      _isolateEntry,
      receivePort.sendPort,
    );

    receivePort.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
        _readyCompleter.complete();
      } else if (message is Map<String, dynamic>) {
        final result = DownloadResult(
          segmentKey: message['segmentKey'] as String,
          docID: message['docID'] as String,
          bytes: message['bytes'] as Uint8List?,
          error: message['error'] as String?,
        );
        _resultController.add(result);
      }
    });

    await _readyCompleter.future;
  }

  /// Segment indirme isteği gönder.
  void download(DownloadRequest request) {
    _sendPort?.send({
      'url': request.url,
      'segmentKey': request.segmentKey,
      'docID': request.docID,
    });
  }

  /// Isolate'i durdur — önce graceful shutdown sinyali gönder, sonra kill.
  void stop() {
    // Graceful: isolate'e 'stop' mesajı gönder → client.close() çağırır
    _sendPort?.send('stop');
    // Kısa süre sonra zorla kapat (graceful tamamlanmazsa)
    Future.delayed(const Duration(milliseconds: 500), () {
      _isolate?.kill(priority: Isolate.immediate);
      _isolate = null;
    });
    _sendPort = null;
    _resultController.close();
  }

  /// Isolate entry point — CDN'den segment indirir.
  static void _isolateEntry(SendPort mainSendPort) {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);
    final client = http.Client();

    receivePort.listen((message) async {
      // Graceful shutdown sinyali
      if (message == 'stop') {
        client.close();
        receivePort.close();
        return;
      }

      if (message is! Map<String, dynamic>) return;

      final url = message['url'] as String;
      final segmentKey = message['segmentKey'] as String;
      final docID = message['docID'] as String;

      try {
        final response = await client
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          mainSendPort.send({
            'segmentKey': segmentKey,
            'docID': docID,
            'bytes': response.bodyBytes,
            'error': null,
          });
        } else {
          mainSendPort.send({
            'segmentKey': segmentKey,
            'docID': docID,
            'bytes': null,
            'error': 'HTTP ${response.statusCode}',
          });
        }
      } catch (e) {
        mainSendPort.send({
          'segmentKey': segmentKey,
          'docID': docID,
          'bytes': null,
          'error': e.toString(),
        });
      }
    });
  }
}
