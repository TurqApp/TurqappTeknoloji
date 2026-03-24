import 'package:flutter/services.dart';

class ComposerHashtagInsertResult {
  const ComposerHashtagInsertResult({
    required this.text,
    required this.cursorOffset,
  });

  final String text;
  final int cursorOffset;
}

bool _isComposerHashtagBoundary(String char) {
  return char.trim().isEmpty;
}

String normalizeComposerHashtag(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  return trimmed.startsWith('#') ? trimmed : '#$trimmed';
}

TextRange? findComposerHashtagRange(String text, int cursorOffset) {
  if (text.isEmpty) return null;
  final cursor = cursorOffset.clamp(0, text.length);
  int start = cursor;
  while (start > 0 && !_isComposerHashtagBoundary(text[start - 1])) {
    start--;
  }

  int end = cursor;
  while (end < text.length && !_isComposerHashtagBoundary(text[end])) {
    end++;
  }

  if (start >= end) return null;
  final token = text.substring(start, end);
  if (!token.startsWith('#')) return null;
  return TextRange(start: start, end: end);
}

String? extractComposerHashtagQuery(String text, int cursorOffset) {
  final range = findComposerHashtagRange(text, cursorOffset);
  if (range == null) return null;
  final token = text.substring(range.start, range.end);
  if (!token.startsWith('#')) return null;
  return token.substring(1);
}

ComposerHashtagInsertResult applyComposerHashtagSelection({
  required String text,
  required int cursorOffset,
  required String hashtag,
}) {
  final normalizedHashtag = normalizeComposerHashtag(hashtag);
  if (normalizedHashtag.isEmpty) {
    return ComposerHashtagInsertResult(
      text: text,
      cursorOffset: cursorOffset.clamp(0, text.length),
    );
  }

  final cursor = cursorOffset.clamp(0, text.length);
  final activeRange = findComposerHashtagRange(text, cursor);
  if (activeRange == null) {
    final prefix =
        text.isNotEmpty && text.substring(text.length - 1).trim().isNotEmpty
            ? ' '
            : '';
    final replacement = '$prefix$normalizedHashtag ';
    final nextText = '$text$replacement';
    return ComposerHashtagInsertResult(
      text: nextText,
      cursorOffset: nextText.length,
    );
  }

  final hasTrailingWhitespace =
      activeRange.end < text.length && text[activeRange.end].trim().isEmpty;
  final replacement =
      hasTrailingWhitespace ? normalizedHashtag : '$normalizedHashtag ';
  final nextText =
      text.replaceRange(activeRange.start, activeRange.end, replacement);
  return ComposerHashtagInsertResult(
    text: nextText,
    cursorOffset: activeRange.start + replacement.length,
  );
}
