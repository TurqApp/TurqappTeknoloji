import 'package:cloud_firestore/cloud_firestore.dart';

class SocialMediaModel {
  String docID;
  String logo;
  String title;
  String url;
  num sira;

  SocialMediaModel({
    required this.docID,
    required this.title,
    required this.url,
    required this.sira,
    required this.logo,
  });

  factory SocialMediaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SocialMediaModel(
      docID: doc.id,
      title: data['title'] ?? '',
      url: data['url'] ?? '',
      sira: data['sira'] ?? 0,
      logo: data['logo'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'url': url,
      'sira': sira,
      'logo': logo,
    };
  }
}
