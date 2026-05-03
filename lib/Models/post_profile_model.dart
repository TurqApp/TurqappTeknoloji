import 'package:turqappv2/Core/Utils/cdn_url_builder.dart';

class PostProfileModel {
  String docID;
  List<String> img;
  String video;
  String thumbnasilOfVideo;
  String metin;
  bool gonderiGizlendi;
  bool sikayetEdildi;
  String userID;
  num izBirakYayinTarihi;
  num timeStamp;
  List<String>? goruntuleme;

  static List<String> _cloneStringList(List<String> source) {
    if (source.isEmpty) return const <String>[];
    return source
        .map((value) => CdnUrlBuilder.toCdnUrl(value.trim()))
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  static List<String>? _cloneNullableStringList(List<String>? source) {
    if (source == null) return null;
    return _cloneStringList(source);
  }

  PostProfileModel({
    required this.docID,
    required List<String> img,
    required String video,
    required String thumbnasilOfVideo,
    required this.metin,
    required this.sikayetEdildi,
    required this.gonderiGizlendi,
    required this.userID,
    required this.izBirakYayinTarihi,
    required this.timeStamp,
    List<String>? goruntuleme,
  })  : img = _cloneStringList(img),
        video = CdnUrlBuilder.toCdnUrl(video.trim()),
        thumbnasilOfVideo = CdnUrlBuilder.toCdnUrl(thumbnasilOfVideo.trim()),
        goruntuleme = _cloneNullableStringList(goruntuleme);
}
