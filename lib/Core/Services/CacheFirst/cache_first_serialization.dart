typedef SnapshotEncoder<T> = Map<String, dynamic> Function(T value);
typedef SnapshotDecoder<T> = T Function(Map<String, dynamic> json);

