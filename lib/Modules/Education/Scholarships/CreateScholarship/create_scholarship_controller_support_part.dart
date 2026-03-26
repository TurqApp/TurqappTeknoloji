part of 'create_scholarship_controller.dart';

final UserRepository _userRepository = UserRepository.ensure();
final CityDirectoryService _cityDirectoryService = ensureCityDirectoryService();
final EducationReferenceDataService _referenceDataService =
    EducationReferenceDataService.ensure();

const List<String> _defaultScholarshipConditions = <String>[
  'T.C. vatandaşı olmak.',
  'En az lise düzeyinde öğrenim görüyor olmak.',
  'Herhangi bir disiplin cezası almamış olmak.',
  'Ailesinin aylık toplam gelirinin belirli bir seviyenin altında olması.',
  'Başka bir kurumdan karşılıksız burs almıyor olmak.',
  'Örgün öğretim programında kayıtlı öğrenci olmak.',
  'Akademik not ortalamasının en az 2.50/4.00 olması.',
  'Adli sicil kaydının temiz olması.',
  'İlan edilen son başvuru tarihine kadar başvuru yapılmış olması.',
  'Belirtilen belgelerin eksiksiz şekilde teslim edilmiş olması.',
  'Burs başvuru formunun eksiksiz doldurulması.',
  'Burs verilen il/ilçede ikamet ediyor olmak (gerekiyorsa).',
  'Eğitim süresi boyunca düzenli olarak başarı göstereceğini taahhüt etmek.',
  'Başvuru sırasında gerçeğe aykırı beyanda bulunmamak.',
  'Bursu sağlayan kurumun düzenlediği mülakat veya değerlendirme süreçlerine katılmak.',
];

const List<String> _defaultScholarshipRequiredDocuments = <String>[
  'Kimlik Kart Fotoğrafı',
  'Öğrenci Belgesi (E Devlet)',
  'Transkript Belgesi',
  'Adli Sicil Kaydı (E Devlet)',
  'Aile Nüfus Kayıt Belgesi (E Devlet)',
  'YKS - AYT Sonuç Belgesi (ÖSYM)',
  'SGK Hizmet Dökümü (E Devlet Kendisi)',
  'SGK Hizmet Dökümü (E Devlet Anne Ve Baba)',
  'Tapu Tescil Belgesi (E Devlet Kendisi)',
  'Engelli Sağlık Kurulu Raporu',
];

const List<String> _defaultScholarshipAwardMonths = <String>[
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
];

String get _currentUid => CurrentUserService.instance.effectiveUserId;

extension CreateScholarshipControllerSupportPart
    on CreateScholarshipController {
  String get turkeyValue => turkeyCountryValue;
}
