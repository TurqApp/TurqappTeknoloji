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
  'Yaz Okulu': '1.png',
  'Orta Öğretim': '2.png',
  'İlk Öğretim': '3.png',
  'Yabancı Dil': '4.png',
  'Yazılım': '5.png',
  'Direksiyon': '6.png',
  'Spor': '7.png',
  'Sanat': '8.png',
  'Müzik': '9.png',
  'Tiyatro': '10.png',
  'Kişisel Gelişim': '11.png',
  'Mesleki': '12.png',
  'Özel Eğitim': '13.png',
  'Çocuk': '14.png',
  'Diksiyon': '15.png',
  'Fotoğrafçılık': '16.png',
};

extension CreateTutoringControllerSupportPart on CreateTutoringController {
  Map<String, String> get branchIconMap => _createTutoringBranchIconMap;
}
