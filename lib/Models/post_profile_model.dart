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
        .map((value) => value.trim())
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
    required this.video,
    required this.thumbnasilOfVideo,
    required this.metin,
    required this.sikayetEdildi,
    required this.gonderiGizlendi,
    required this.userID,
    required this.izBirakYayinTarihi,
    required this.timeStamp,
    List<String>? goruntuleme,
  })  : img = _cloneStringList(img),
        goruntuleme = _cloneNullableStringList(goruntuleme);
}
