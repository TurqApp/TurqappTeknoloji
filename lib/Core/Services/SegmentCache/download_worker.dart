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
  final String requestID;

  DownloadRequest({
    required this.url,
    required this.segmentKey,
    required this.docID,
    required this.requestID,
  });
}

class DownloadResult {
  final String segmentKey;
  final String docID;
  final String requestID;
  final Uint8List? bytes;
  final String? error;

  DownloadResult({
    required this.segmentKey,
    required this.docID,
    required this.requestID,
    Uint8List? bytes,
    this.error,
  }) : bytes = bytes == null ? null : Uint8List.fromList(bytes);

  bool get success => bytes != null;
}

class DownloadWorker {
  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _receivePort;
  StreamSubscription<dynamic>? _receiveSub;
  final _resultController = StreamController<DownloadResult>.broadcast();
  final _readyCompleter = Completer<void>();
  bool _isStopping = false;

  static String _readMessageString(
    Map<String, dynamic> message,
    String key, {
    String fallback = '',
  }) {
    final value = message[key];
    if (value == null) return fallback;
    final normalized = value.toString().trim();
    return normalized.isEmpty ? fallback : normalized;
  }

  Stream<DownloadResult> get results => _resultController.stream;

  /// Isolate'i başlat.
  Future<void> start() async {
    _isStopping = false;
    final receivePort = ReceivePort();
    _receivePort = receivePort;
    _isolate = await Isolate.spawn(
      _isolateEntry,
      receivePort.sendPort,
    );

    _receiveSub = receivePort.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
        if (!_readyCompleter.isCompleted) {
          _readyCompleter.complete();
        }
      } else if (message is Map<String, dynamic>) {
        if (_isStopping || _resultController.isClosed) return;
        final result = DownloadResult(
          segmentKey: _readMessageString(message, 'segmentKey'),
          docID: _readMessageString(message, 'docID'),
          requestID: _readMessageString(message, 'requestID'),
          bytes: message['bytes'] as Uint8List?,
          error: _readMessageString(message, 'error', fallback: '').isEmpty
              ? null
              : _readMessageString(message, 'error'),
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
      'requestID': request.requestID,
    });
  }

  /// Isolate'i durdur — önce graceful shutdown sinyali gönder, sonra kill.
  void stop() {
    _isStopping = true;
    // Graceful: isolate'e 'stop' mesajı gönder → client.close() çağırır
    _sendPort?.send('stop');
    _receiveSub?.cancel();
    _receiveSub = null;
    _receivePort?.close();
    _receivePort = null;
    // Kısa süre sonra zorla kapat (graceful tamamlanmazsa)
    Future.delayed(const Duration(milliseconds: 500), () {
      _isolate?.kill(priority: Isolate.immediate);
      _isolate = null;
    });
    _sendPort = null;
    if (!_resultController.isClosed) {
      _resultController.close();
    }
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

      final url = _readMessageString(message, 'url');
      final segmentKey = _readMessageString(message, 'segmentKey');
      final docID = _readMessageString(message, 'docID');
      final requestID = _readMessageString(message, 'requestID');
      if (url.isEmpty ||
          segmentKey.isEmpty ||
          docID.isEmpty ||
          requestID.isEmpty) {
        mainSendPort.send({
          'segmentKey': segmentKey,
          'docID': docID,
          'requestID': requestID,
          'bytes': null,
          'error': 'invalid_download_request',
        });
        return;
      }

      try {
        final response = await client
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          mainSendPort.send({
            'segmentKey': segmentKey,
            'docID': docID,
            'requestID': requestID,
            'bytes': response.bodyBytes,
            'error': null,
          });
        } else {
          mainSendPort.send({
            'segmentKey': segmentKey,
            'docID': docID,
            'requestID': requestID,
            'bytes': null,
            'error': 'HTTP ${response.statusCode}',
          });
        }
      } catch (e) {
        mainSendPort.send({
          'segmentKey': segmentKey,
          'docID': docID,
          'requestID': requestID,
          'bytes': null,
          'error': e.toString(),
        });
      }
    });
  }
}
