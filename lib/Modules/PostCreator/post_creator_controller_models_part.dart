part of 'post_creator_controller.dart';

class PreparedPostModel {
  final String text;
  final List<Uint8List> images;
  final List<String> reusedImageUrls;
  final double reusedImageAspectRatio;
  final File? video;
  final String reusedVideoUrl;
  final String reusedVideoThumbnail;
  final double reusedVideoAspectRatio;
  final String videoLookPreset;
  final String location;
  final String gif;
  final Uint8List? customThumbnail;
  final Map<String, dynamic> poll;

  PreparedPostModel({
    required this.text,
    required this.images,
    required this.reusedImageUrls,
    required this.reusedImageAspectRatio,
    required this.video,
    required this.reusedVideoUrl,
    required this.reusedVideoThumbnail,
    required this.reusedVideoAspectRatio,
    required this.videoLookPreset,
    required this.location,
    required this.gif,
    required this.customThumbnail,
    required this.poll,
  });

  Map<String, dynamic> toMap({required String docID}) => {
        'id': docID,
        'text': text,
        'location': location,
        'gif': gif,
        'timeStamp': DateTime.now().millisecondsSinceEpoch,
      };
}
