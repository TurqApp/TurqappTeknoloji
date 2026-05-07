import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ManifestDiskCipher {
  ManifestDiskCipher._();

  static final ManifestDiskCipher instance = ManifestDiskCipher._();

  static const String _envelopePrefix = 'turq_manifest_cipher_v1:';
  static const String _secureKeyName = 'turq_manifest_disk_cipher_key_v1';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  final Random _random = Random.secure();
  Future<Uint8List>? _keyFuture;
  Uint8List? _volatileFallbackKey;

  bool isEncryptedEnvelope(String raw) => raw.startsWith(_envelopePrefix);

  Future<String> encodeForDisk(
    String plaintext, {
    required String context,
  }) async {
    final normalizedContext = _normalizeContext(context);
    final key = await _readOrCreateKey();
    final nonce = _randomBytes(16);
    final plaintextBytes = Uint8List.fromList(utf8.encode(plaintext));
    final stream = _keyStream(
      key: _deriveKey(key, 'enc:$normalizedContext'),
      nonce: nonce,
      length: plaintextBytes.length,
    );
    final cipherBytes = Uint8List(plaintextBytes.length);
    for (var i = 0; i < plaintextBytes.length; i++) {
      cipherBytes[i] = plaintextBytes[i] ^ stream[i];
    }

    final tag = _hmac(
      _deriveKey(key, 'mac:$normalizedContext'),
      <int>[
        ...utf8.encode(normalizedContext),
        0,
        ...nonce,
        ...cipherBytes,
      ],
    );
    final envelope = <String, String>{
      'n': base64UrlEncode(nonce),
      'c': base64UrlEncode(cipherBytes),
      't': base64UrlEncode(tag),
    };
    return '$_envelopePrefix${base64UrlEncode(utf8.encode(jsonEncode(envelope)))}';
  }

  Future<String?> decodeFromDisk(
    String stored, {
    required String context,
  }) async {
    if (!isEncryptedEnvelope(stored)) {
      return stored;
    }
    try {
      final normalizedContext = _normalizeContext(context);
      final encodedEnvelope = stored.substring(_envelopePrefix.length);
      final envelopeRaw = utf8.decode(base64Url.decode(encodedEnvelope));
      final decoded = jsonDecode(envelopeRaw);
      if (decoded is! Map) return null;
      final envelope = Map<String, dynamic>.from(decoded);
      final nonce = Uint8List.fromList(
        base64Url.decode((envelope['n'] ?? '').toString()),
      );
      final cipherBytes = Uint8List.fromList(
        base64Url.decode((envelope['c'] ?? '').toString()),
      );
      final storedTag = Uint8List.fromList(
        base64Url.decode((envelope['t'] ?? '').toString()),
      );
      if (nonce.isEmpty || storedTag.isEmpty) return null;

      final key = await _readOrCreateKey();
      final expectedTag = _hmac(
        _deriveKey(key, 'mac:$normalizedContext'),
        <int>[
          ...utf8.encode(normalizedContext),
          0,
          ...nonce,
          ...cipherBytes,
        ],
      );
      if (!_constantTimeEquals(storedTag, expectedTag)) {
        return null;
      }

      final stream = _keyStream(
        key: _deriveKey(key, 'enc:$normalizedContext'),
        nonce: nonce,
        length: cipherBytes.length,
      );
      final plaintext = Uint8List(cipherBytes.length);
      for (var i = 0; i < cipherBytes.length; i++) {
        plaintext[i] = cipherBytes[i] ^ stream[i];
      }
      return utf8.decode(plaintext);
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List> _readOrCreateKey() {
    final existing = _keyFuture;
    if (existing != null) return existing;
    final future = _readOrCreateKeyInner();
    _keyFuture = future;
    return future;
  }

  Future<Uint8List> _readOrCreateKeyInner() async {
    try {
      final existing = await _secureStorage.read(key: _secureKeyName);
      if (existing != null && existing.trim().isNotEmpty) {
        final bytes = base64Url.decode(existing.trim());
        if (bytes.length >= 32) {
          return Uint8List.fromList(bytes.take(32).toList(growable: false));
        }
      }
      final key = _randomBytes(32);
      await _secureStorage.write(
        key: _secureKeyName,
        value: base64UrlEncode(key),
      );
      return key;
    } catch (_) {
      return _volatileFallbackKey ??= _randomBytes(32);
    }
  }

  Uint8List _randomBytes(int length) {
    return Uint8List.fromList(
      List<int>.generate(length, (_) => _random.nextInt(256)),
    );
  }

  Uint8List _deriveKey(Uint8List key, String label) {
    return _hmac(key, utf8.encode(label));
  }

  Uint8List _keyStream({
    required Uint8List key,
    required Uint8List nonce,
    required int length,
  }) {
    final output = BytesBuilder(copy: false);
    var counter = 0;
    while (output.length < length) {
      output.add(
        _hmac(
          key,
          <int>[
            ...nonce,
            (counter >> 24) & 0xff,
            (counter >> 16) & 0xff,
            (counter >> 8) & 0xff,
            counter & 0xff,
          ],
        ),
      );
      counter++;
    }
    return Uint8List.fromList(
      output.toBytes().take(length).toList(growable: false),
    );
  }

  Uint8List _hmac(Uint8List key, List<int> bytes) {
    return Uint8List.fromList(Hmac(sha256, key).convert(bytes).bytes);
  }

  bool _constantTimeEquals(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    var diff = 0;
    for (var i = 0; i < left.length; i++) {
      diff |= left[i] ^ right[i];
    }
    return diff == 0;
  }

  String _normalizeContext(String context) {
    final normalized = context.trim();
    return normalized.isEmpty ? 'manifest' : normalized;
  }
}
