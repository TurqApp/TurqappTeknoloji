import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../network_awareness_service.dart';
import '../video_state_manager.dart';
import 'cache_manager.dart';
import 'hls_data_usage_probe.dart';
import 'hls_segment_policy.dart';
import 'm3u8_parser.dart';
import 'network_policy.dart';

part 'hls_proxy_server_fields_part.dart';
part 'hls_proxy_server_facade_part.dart';
part 'hls_proxy_server_playlist_part.dart';
part 'hls_proxy_server_segment_part.dart';
part 'hls_proxy_server_runtime_part.dart';

/// Lokal HTTP proxy — HLS isteklerini cache üzerinden serv eder.
///
/// Player `http://127.0.0.1:PORT/Posts/{docID}/hls/master.m3u8` URL'sine istek atar.
/// Proxy cache'te varsa disk'ten serv eder, yoksa CDN'den çeker + cache'ler + serv eder.
/// M3U8 playlist'lerde relative path kullanıldığı için rewriting gerekmez.
