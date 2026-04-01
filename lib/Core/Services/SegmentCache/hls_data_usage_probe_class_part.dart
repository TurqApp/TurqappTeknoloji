part of 'hls_data_usage_probe.dart';

class HlsDataUsageProbe extends GetxController {
  static HlsDataUsageProbe ensure() => ensureHlsDataUsageProbe();

  static HlsDataUsageProbe? maybeFind() => maybeFindHlsDataUsageProbe();

  final _state = _HlsDataUsageProbeState();
}
