part of 'global_video_adapter_pool.dart';

extension GlobalVideoAdapterPoolFacadePart on GlobalVideoAdapterPool {
  HLSVideoAdapter acquire({
    required String cacheKey,
    required String url,
    bool autoPlay = false,
    bool loop = true,
    bool coordinateAudioFocus = true,
  }) =>
      _GlobalVideoAdapterPoolRuntimeX(this).acquire(
        cacheKey: cacheKey,
        url: url,
        autoPlay: autoPlay,
        loop: loop,
        coordinateAudioFocus: coordinateAudioFocus,
      );

  Future<void> release(
    HLSVideoAdapter adapter, {
    bool keepWarm = true,
  }) =>
      _GlobalVideoAdapterPoolRuntimeX(this).release(
        adapter,
        keepWarm: keepWarm,
      );

  Future<void> clear() => _GlobalVideoAdapterPoolRuntimeX(this).clear();

  HLSVideoAdapter? adapterForTesting(String cacheKey) =>
      _GlobalVideoAdapterPoolRuntimeX(this).adapterForTesting(cacheKey);

  Map<String, dynamic> debugSnapshot() =>
      _GlobalVideoAdapterPoolRuntimeX(this).debugSnapshot();
}
