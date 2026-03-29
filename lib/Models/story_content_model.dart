class StoryContentModel {
  num start;
  num end;
  bool cevaplanabilir;
  String img;
  String music;
  String shortUrl;
  String video;
  String docID;
  String userID;
  String konum;
  num kacGun;
  List<String> begeniler;
  num aspectRatio;
  num seenCount;

  static List<String> _cloneStringList(List<String> source) =>
      List<String>.from(source, growable: false);

  StoryContentModel({
    required this.start,
    required this.end,
    required this.konum,
    required List<String> begeniler,
    required this.img,
    required this.cevaplanabilir,
    required this.music,
    required this.shortUrl,
    required this.video,
    required this.kacGun,
    required this.docID,
    required this.userID,
    required this.aspectRatio,
    required this.seenCount,
  }) : begeniler = _cloneStringList(begeniler);
}
