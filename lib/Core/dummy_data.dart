class AdItemModel {
  final String imageAsset;
  final String title;
  final String category;
  final String price;
  final String shortDescription;
  final int? discount; // yüzde cinsinden indirim (örn. 10 = %10)

  AdItemModel({
    required this.imageAsset,
    required this.title,
    required this.category,
    required this.price,
    required this.shortDescription,
    this.discount,
  });
}

final List<AdItemModel> dummyAds = [
  AdItemModel(
    imageAsset: "televizyon",
    title: "Samsung 4K 55'' Smart TV",
    category: "Elektronik",
    price: "35.245 TL",
    shortDescription: "Yüksek çözünürlüklü ekranı ve akıllı özellikleriyle ev sineması deneyimi sunar.",
    discount: 15,
  ),
  AdItemModel(
    imageAsset: "telefon",
    title: "iPhone 14 Pro 256 GB",
    category: "Elektronik",
    price: "33.245 TL",
    shortDescription: "Güçlü işlemcisi ve gelişmiş kamera sistemiyle yeni nesil akıllı telefon.",
    discount: 10,
  ),
  AdItemModel(
    imageAsset: "araba",
    title: "1967 Ford Mustang",
    category: "Vasıta",
    price: "1.400.999 TL",
    shortDescription: "Koleksiyonluk klasik araç. Mükemmel kondisyon, orijinal parçalarla.",
  ),
  AdItemModel(
    imageAsset: "gozluk",
    title: "Ray-Ban Aviator Güneş Gözlüğü",
    category: "Aksesuar",
    price: "8.234 TL",
    shortDescription: "İkonik tasarımı ve UV korumalı camlarıyla stil sahibi görünüm.",
  ),
];

