import 'package:flutter/material.dart';

class LessonConfig {
  static const List<Color> lessonColors = [
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.red,
    Colors.orange,
    Colors.teal,
    Colors.indigo,
  ];

  static const List<String> examTypes = [
    "LGS",
    "TYT",
    "AYT",
    "KPSS",
    "ALES",
    "DGS",
    "YDS",
  ];

  static const Map<String, List<String>> examTypeLessons = {
    "LGS": [
      "Matematik",
      "Fen Bilimleri",
      "Türkçe",
      "İnkilap Tarihi",
      "Din Kültürü",
      "Yabancı Dil",
    ],
    "TYT": ["Temel Matematik", "Fen Bilimleri", "Türkçe", "Sosyal Bilimler"],
    "AYT": [
      "Matematik",
      "Fen Bilimleri",
      "Edebiyat - Sosyal Bilimler 1",
      "Sosyal Bilimler 2",
    ],
    "KPSS": ["Genel Yetenek", "Genel Kültür"],
    "ALES": ["Sayısal", "Sözel"],
    "DGS": ["Sayısal", "Sözel"],
    "YDS": ["İngilizce", "Almanca", "Arapça", "Fransızca", "Rusça"],
  };

  static const List<String> kpssSubTypes = [
    "Ortaöğretim",
    "Ön Lisans",
    "Lisans",
    "Eğitim Birimleri",
    "A Grubu 1",
    "A Grubu 2",
  ];

  static const Map<String, List<String>> kpssSubTypeLessons = {
    "Ortaöğretim": ["Genel Yetenek", "Genel Kültür"],
    "Ön Lisans": ["Genel Yetenek", "Genel Kültür"],
    "Lisans": ["Genel Yetenek", "Genel Kültür"],
    "Eğitim Birimleri": ["Eğitim Birimleri"],
    "A Grubu 1": [
      "Çalışma Ekonomisi",
      "İstatistik",
      "Uluslararası İlişkiler",
      "Kamu Yönetimi",
    ],
    "A Grubu 2": ["Hukuk", "İktisat", "İşletme", "Maliye", "Muhasebe"],
  };
}
