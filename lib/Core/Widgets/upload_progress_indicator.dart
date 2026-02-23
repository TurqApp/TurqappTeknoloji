import 'package:flutter/material.dart';
import '../upload_constants.dart';

class UploadProgressIndicator extends StatelessWidget {
  final int currentImageCount;
  final int currentVideoCount;
  final int totalSizeBytes;
  final bool showDetails;

  const UploadProgressIndicator({
    super.key,
    required this.currentImageCount,
    required this.currentVideoCount,
    required this.totalSizeBytes,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    final sizeProgress = totalSizeBytes / UploadConstants.maxTotalPostSizeBytes;
    final imageProgress = currentImageCount / UploadConstants.maxImagesPerPost;
    final videoProgress = currentVideoCount / UploadConstants.maxVideosPerPost;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Total size indicator
          _buildProgressRow(
            label: 'Toplam Boyut',
            current: UploadConstants.formatBytes(totalSizeBytes),
            max: UploadConstants.getMaxTotalSizeText(),
            progress: sizeProgress,
            color: _getProgressColor(sizeProgress),
          ),

          if (showDetails) ...[
            const SizedBox(height: 8),

            // Image count indicator
            _buildProgressRow(
              label: 'Fotoğraflar',
              current: '$currentImageCount',
              max: '${UploadConstants.maxImagesPerPost}',
              progress: imageProgress,
              color: _getProgressColor(imageProgress),
            ),

            const SizedBox(height: 4),

            // Video count indicator
            _buildProgressRow(
              label: 'Videolar',
              current: '$currentVideoCount',
              max: '${UploadConstants.maxVideosPerPost}',
              progress: videoProgress,
              color: _getProgressColor(videoProgress),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressRow({
    required String label,
    required String current,
    required String max,
    required double progress,
    required Color color,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    current,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    max,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress <= 0.7) {
      return Colors.green;
    } else if (progress <= 0.9) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}

class UploadLimitInfo extends StatelessWidget {
  const UploadLimitInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 18),
              SizedBox(width: 8),
              Text(
                'Upload Limitleri',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLimitRow('Fotoğraf:', 'Maksimum ${UploadConstants.getMaxImageSizeText()} per fotoğraf'),
          _buildLimitRow('Video:', 'Maksimum ${UploadConstants.getMaxVideoSizeText()}, ${UploadConstants.maxVideoLengthSeconds} saniye'),
          _buildLimitRow('Toplam:', 'Post başına maksimum ${UploadConstants.getMaxTotalSizeText()}'),
          _buildLimitRow('Sayı:', '${UploadConstants.maxImagesPerPost} fotoğraf veya ${UploadConstants.maxVideosPerPost} video'),
        ],
      ),
    );
  }

  Widget _buildLimitRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}