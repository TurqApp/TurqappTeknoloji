library;

const String hlsCacheCdnOrigin = 'https://cdn.turqapp.com';

String? hlsRelativePathFromUrlOrPath(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;

  String candidate = trimmed;
  try {
    final uri = Uri.parse(trimmed);
    if (uri.hasScheme && uri.path.isNotEmpty) {
      candidate = uri.path;
    }
  } catch (_) {}

  if (candidate.startsWith('/')) {
    candidate = candidate.substring(1);
  }

  if (candidate.startsWith('Posts/') || candidate.startsWith('stories/')) {
    return candidate;
  }

  const objectMarker = '/o/';
  final objectIndex = candidate.indexOf(objectMarker);
  if (objectIndex < 0) return null;

  var encodedObjectPath =
      candidate.substring(objectIndex + objectMarker.length);
  if (encodedObjectPath.startsWith('/')) {
    encodedObjectPath = encodedObjectPath.substring(1);
  }

  final decodedObjectPath = Uri.decodeComponent(encodedObjectPath);
  if (decodedObjectPath.startsWith('Posts/') ||
      decodedObjectPath.startsWith('stories/')) {
    return decodedObjectPath;
  }

  return null;
}

String canonicalizeHlsCdnUrl(String originalUrl) {
  final relativePath = hlsRelativePathFromUrlOrPath(originalUrl);
  if (relativePath == null) return originalUrl.trim();
  return '$hlsCacheCdnOrigin/$relativePath';
}

String? hlsDocIdFromUrlOrPath(String value) {
  final relativePath = hlsRelativePathFromUrlOrPath(value);
  if (relativePath == null) return null;

  if (relativePath.startsWith('Posts/')) {
    final parts = relativePath.split('/');
    return parts.length >= 2 ? parts[1].trim() : null;
  }

  if (relativePath.startsWith('stories/')) {
    final parts = relativePath.split('/');
    return parts.length >= 3 ? parts[2].trim() : null;
  }

  return null;
}

String? hlsSegmentKeyFromUrlOrPath(String value) {
  final relativePath = hlsRelativePathFromUrlOrPath(value);
  if (relativePath == null) return null;

  final hlsIndex = relativePath.indexOf('/hls/');
  if (hlsIndex < 0) return null;
  final keyStart = hlsIndex + '/hls/'.length;
  if (keyStart >= relativePath.length) return null;
  return relativePath.substring(keyStart);
}
