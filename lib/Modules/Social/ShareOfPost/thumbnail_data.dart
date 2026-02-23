import 'dart:io';

class ThumbnailData {
  final File file;
  final String? nsfwLabel;
  final double score;

  ThumbnailData({required this.file, this.nsfwLabel, required this.score});
}
