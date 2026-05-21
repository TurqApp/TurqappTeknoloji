part of 'create_tutoring_controller.dart';

const List<String> _createTutoringWeekDays = <String>[
  'Pazartesi',
  'Salı',
  'Çarşamba',
  'Perşembe',
  'Cuma',
  'Cumartesi',
  'Pazar',
];

const List<String> _createTutoringTimeSlots = <String>[
  '08:00-10:00',
  '10:00-12:00',
  '12:00-14:00',
  '14:00-16:00',
  '16:00-18:00',
  '18:00-20:00',
  '20:00-22:00',
];

const Map<String, String> _createTutoringBranchIconMap = <String, String>{
  'Yaz Okulu': '1.webp',
  'Orta Öğretim': '2.webp',
  'İlk Öğretim': '3.webp',
  'Yabancı Dil': '4.webp',
  'Yazılım': '5.webp',
  'Direksiyon': '6.webp',
  'Spor': '7.webp',
  'Sanat': '8.webp',
  'Müzik': '9.webp',
  'Tiyatro': '10.webp',
  'Kişisel Gelişim': '11.webp',
  'Mesleki': '12.webp',
  'Özel Eğitim': '13.webp',
  'Çocuk': '14.webp',
  'Diksiyon': '15.webp',
  'Fotoğrafçılık': '16.webp',
};

extension CreateTutoringControllerSupportPart on CreateTutoringController {
  Map<String, String> get branchIconMap => _createTutoringBranchIconMap;
}
