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

  StoryContentModel({
    required this.start,
    required this.end,
    required this.konum,
    required this.begeniler,
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
  });
}
