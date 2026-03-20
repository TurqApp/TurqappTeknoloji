import 'package:get/get.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

String localizeJobDisplayText(String value) {
  var text = value.trim();
  if (text.isEmpty) return text;
  const replacements = <String, String>{
    'Yari': 'Yarı',
    'Zamanli': 'Zamanlı',
    'Calisma': 'Çalışma',
    'Sirket': 'Şirket',
    'Goruntulenme': 'Görüntülenme',
    'Basvuru': 'Başvuru',
    'Ilan': 'İlan',
    'Ogrenim': 'Öğrenim',
    'Ogretim': 'Öğretim',
    'Pozisyon Sayisi': 'Pozisyon Sayısı',
  };
  replacements.forEach((source, target) {
    text = text.replaceAll(source, target);
  });

  switch (text.toLowerCase()) {
    case 'tam zamanlı':
      return 'pasaj.job_finder.work_type.full_time'.tr;
    case 'yarı zamanlı':
    case 'part-time':
      return 'pasaj.job_finder.work_type.part_time'.tr;
    case 'uzaktan':
      return 'pasaj.job_finder.work_type.remote'.tr;
    case 'hibrit':
      return 'pasaj.job_finder.work_type.hybrid'.tr;
    case 'pazartesi':
      return 'pasaj.job_finder.day.monday'.tr;
    case 'salı':
      return 'pasaj.job_finder.day.tuesday'.tr;
    case 'çarşamba':
      return 'pasaj.job_finder.day.wednesday'.tr;
    case 'perşembe':
      return 'pasaj.job_finder.day.thursday'.tr;
    case 'cuma':
      return 'pasaj.job_finder.day.friday'.tr;
    case 'cumartesi':
      return 'pasaj.job_finder.day.saturday'.tr;
    case 'pazar':
      return 'pasaj.job_finder.day.sunday'.tr;
    case 'yemek':
    case 'yol ücreti':
    case 'servis':
    case 'prim':
    case 'özel sağlık sigortası':
    case 'bireysel emeklilik':
    case 'esnek çalışma saatleri':
    case 'uzaktan çalışma':
      return localizeJobBenefit(text);
    default:
      return text;
  }
}

String localizeJobDisplayList(List<String> values) {
  return values.map(localizeJobDisplayText).join(', ');
}

String localizeJobWorkType(String value) => localizeJobDisplayText(value);

String localizeJobDay(String value) => localizeJobDisplayText(value);

String localizeJobBenefit(String value) {
  switch (normalizeSearchText(value)) {
    case 'yemek':
      return 'pasaj.job_finder.benefit.meal'.tr;
    case 'yol ücreti':
      return 'pasaj.job_finder.benefit.road_fee'.tr;
    case 'servis':
      return 'pasaj.job_finder.benefit.shuttle'.tr;
    case 'prim':
      return 'pasaj.job_finder.benefit.bonus'.tr;
    case 'özel sağlık sigortası':
      return 'pasaj.job_finder.benefit.private_health'.tr;
    case 'bireysel emeklilik':
      return 'pasaj.job_finder.benefit.retirement'.tr;
    case 'esnek çalışma saatleri':
      return 'pasaj.job_finder.benefit.flexible_hours'.tr;
    case 'uzaktan çalışma':
      return 'pasaj.job_finder.benefit.remote_work'.tr;
    default:
      return value;
  }
}
