import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys {
    final base = <String, Map<String, String>>{
        'tr_TR': {
          'settings.title': 'Ayarlar',
          'settings.account': 'Hesap',
          'settings.content': 'İçerik',
          'settings.app': 'Uygulama',
          'settings.security_support': 'Güvenlik ve Destek',
          'settings.my_tasks': 'Görevlerim',
          'settings.system_diagnostics': 'Sistem ve Tanı',
          'settings.session': 'Oturum',
          'settings.language': 'Dil',
          'settings.edit_profile': 'Profili Düzenle',
          'settings.badge_application': 'Rozet Başvurum',
          'settings.badge_renew': 'Rozeti Yenile',
          'settings.become_verified': 'Onaylı Hesap Ol',
          'become_verified.intro':
              'Mobil uygulamamızda, farklı kullanıcı gruplarını tanımlamak ve güvenilirliklerini vurgulamak için onay rozetleri kullanılmaktadır.',
          'become_verified.annual_renewal':
              'Her yıl yenilenmesi gerekmektedir.',
          'become_verified.footer':
              'Rozetlerimiz, topluluğumuzun güvenli ve şeffaf bir ortamda etkileşim kurmasını sağlamayı hedefler.\n\nProfil doğrulama hakkında daha fazla bilgi almak için TurqApp destek ekibimize ulaşabilirsiniz.',
          'become_verified.feature_ads': 'Reklamlar',
          'become_verified.feature_limited_ads': 'Sınırlı Reklam',
          'become_verified.feature_post_boost': 'Gönderi Öne Çıkartma',
          'become_verified.feature_highest': 'En Yüksek',
          'become_verified.feature_video_download': 'Video İndirme',
          'become_verified.feature_long_video':
              'Uzun Süreli Video Yayınlama',
          'become_verified.feature_statistics': 'İstatistikler',
          'become_verified.feature_username': 'Kullanıcı Adı',
          'become_verified.feature_verification_mark': 'Onay İşareti',
          'become_verified.feature_account_protection':
              'Artırılmış Hesap Koruması',
          'become_verified.feature_channel_creation': 'Kanal Oluşturma',
          'become_verified.feature_priority_support': 'Gelişmiş Destek',
          'become_verified.feature_scheduled_video': 'Zamanlanmış Video',
          'become_verified.feature_unlimited_listings':
              'Sınırsız İlan Oluşturma',
          'become_verified.feature_unlimited_links':
              'Sınırsız Bağlantı Ekleme',
          'become_verified.feature_assistant': 'Asistan Ol',
          'become_verified.feature_scheduled_content':
              'Zamanlanmış İçerik Paylaşımı',
          'become_verified.feature_character_limit': 'Karakter Sınırı',
          'become_verified.feature_character_limit_value': '1000 Karakter',
          'become_verified.loss_title': 'Onay Rozetinin Kaybedilmesi',
          'become_verified.loss_body':
              'Ekibimiz, hesabınızı inceledikten sonra gereksinimlerin karşılanmaya devam ettiğine karar verirse onay işareti yeniden gösterilir. TurqApp ayrıca kurallarını ihlal ettiği saptanan hesaplardan onay işaretini kaldırabilir.',
          'become_verified.step_social_accounts':
              '1. Sosyal Medya Hesaplarınız',
          'become_verified.step_requested_username':
              '2. Talep Ettiğiniz Kullanıcı Adı',
          'become_verified.requested_username_hint':
              'Talep ettiğiniz kullanıcı adı',
          'become_verified.step_social_confirmation':
              '3. Sosyal Medya Onayı',
          'become_verified.social_confirmation_body':
              'Talep etmiş olduğunuz kullanıcı adı ile mevcut TurqApp kullanıcı adınızı, tarafınıza ait sosyal medya hesabınız üzerinden aşağıda belirtilen hesaplarımızdan birine mesaj yoluyla iletebilirsiniz.',
          'become_verified.consent':
              'Girdiğim bilgilerin bana ait olduğunu ve başvuru inceleme sürecini kabul ettiğimi onaylıyorum.',
          'become_verified.step_barcode':
              '5. E-Devlet Öğrenci Belgesi Barkod No',
          'become_verified.barcode_hint': '20 Haneli Barkod No',
          'become_verified.submit': 'Başvur',
          'become_verified.received_title': 'Başvurunuz Alındı',
          'become_verified.received_body':
              'Başvurunuz sıraya alındı. İnceleme olumlu sonuçlandığında size bildirim göndereceğiz.',
          'become_verified.received_note':
              'Değerlendirme süresi yoğunluğa göre değişebilir. Sonuçlandığında uygulama üzerinden bilgilendirileceksiniz.',
          'become_verified.session_missing': 'Oturum bulunamadı.',
          'become_verified.already_received': 'Başvurunuz zaten alınmış.',
          'become_verified.submit_failed': 'Başvuru kaydedilemedi.',
          'become_verified.badge_blue': 'Mavi',
          'become_verified.badge_red': 'Kırmızı',
          'become_verified.badge_yellow': 'Sarı',
          'become_verified.badge_turquoise': 'Turkuaz',
          'become_verified.badge_gray': 'Gri',
          'become_verified.badge_black': 'Siyah',
          'become_verified.badge_blue_desc':
              'Bireysel kullanıcılarımız için tasarlanmıştır.\nProfilin doğrulandığını ve güvenilir olduğunu belirtir.',
          'become_verified.badge_red_desc':
              'Öğrenci ve Öğretmenler için tasarlanmıştır.\nEğitimle ilgili doğrulanmış bir kimlik temsil eder.',
          'become_verified.badge_yellow_desc':
              'Şirketler ve ticari kuruluşlara verilir.\nKurumun resmi bir işletme olduğunu ifade eder.',
          'become_verified.badge_turquoise_desc':
              'Sivil Toplum Örgütlerine verilir.\nKuruluşların resmi ve güvenilir olduğunu ifade eder.',
          'become_verified.badge_gray_desc':
              'Kamu kuruluşları, devlet kurumları ve yetkilileri için özel olarak tanımlanmıştır.\nResmi statüyü ve güvenilirliği simgeler.',
          'become_verified.badge_black_desc':
              'İçerik denetçisi kullanıcılarımız için tasarlanmıştır.\nKullanıcıları engelleyen, içerikleri kaldıran bir kimlik temsil eder.',
          'settings.blocked_users': 'Engellenenler',
          'settings.interests': 'İlgi Alanları',
          'settings.account_center': 'Hesap Merkezi',
          'settings.career_profile': 'Kariyer Profili',
          'settings.saved_posts': 'Kaydedilenler',
          'settings.archive': 'Arşiv',
          'settings.liked_posts': 'Beğenilenler',
          'settings.notifications': 'Bildirimler',
          'settings.permissions': 'İzinler',
          'settings.pasaj': 'Pasaj',
          'settings.pasaj.practice_exam': 'Deneme Sınavı',
          'education.previous_questions': 'Denemeler',
          'tests.results_title': 'Sonuçlar',
          'tests.results_empty':
              'Sonuç bulunamadı.\nBu test için yanıt veya soru verisi mevcut değil.',
          'tests.correct': 'Doğru',
          'tests.wrong': 'Yanlış',
          'tests.blank': 'Boş',
          'tests.net': 'Net',
          'tests.score': 'Puan',
          'tests.question_number': '@index. Soru',
          'tests.solve_no_questions':
              'Soru bulunamadı.\nBu test için soru yüklenemedi.',
          'tests.finish_test': 'Testi Bitir',
          'tests.my_results_empty':
              'Sonuç bulunamadı.\nDaha önce hiç test çözmediniz.',
          'tests.saved_empty': 'Kaydedilen test bulunmamaktadır.',
          'tests.result_answer_missing':
              'Sonuç bulunamadı.\nBu test için yanıt verisi mevcut değil.',
          'tests.type_test': '@type Testi',
          'tests.description_test': '@description Testi',
          'tests.solve_count': '@count. kez çözdün',
          'tests.create_title': 'Test Oluştur',
          'tests.edit_title': 'Testi Düzenle',
          'tests.create_data_missing':
              'Veri bulunamadı.\nUygulama bağlantıları veya test soruları yüklenemedi.',
          'tests.create_upload_failed':
              'Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.',
          'tests.select_branch': 'Branş Seç',
          'tests.select_language': 'Dil Seç',
          'tests.cover_select': 'Kapak Fotoğrafı Seç',
          'tests.cover_load_failed':
              'Kapak fotoğrafı yüklenemedi. Lütfen tekrar deneyin.',
          'tests.create_description_hint':
              '9. Sınıf Üslü İfadeler Köklü İfadeler',
          'tests.details': 'Sınav Detayları',
          'tests.question_counts': 'Soru Sayıları',
          'tests.question_count': 'Soru Sayısı',
          'tests.date': 'Sınav Tarihi',
          'tests.time': 'Sınav Saati',
          'tests.duration': 'Sınav Süresi',
          'tests.questions_data_failed':
              'Ders bilgileri yüklenemedi. Lütfen sınav türünü kontrol edin veya tekrar deneyin.',
          'tests.creating': 'Sınav Oluşturuluyor...',
          'tests.image_pick_failed': 'Resim seçilemedi.',
          'tests.image_invalid': 'Seçilen resim uygun değil!',
          'tests.image_analyze_failed': 'Resim analizi yapılamadı.',
          'tests.image_upload_failed_short': 'Resim yüklenemedi.',
          'tests.save_failed': 'Sınav kaydedilemedi.',
          'tests.results_load_failed': 'Sınav sonuçları yüklenemedi.',
          'tests.exams_load_failed': 'Sınavlar yüklenemedi.',
          'tests.prepare_questions': 'Soru Hazırla',
          'tests.no_questions_for_lesson':
              'Bu ders için soru bulunamadı. Lütfen soruları ekleyin veya sınav türünü kontrol edin.',
          'tests.no_questions_at_all':
              'Hiç soru bulunamadı. Lütfen soruları ekleyin veya sınav türünü kontrol edin.',
          'tests.complete': 'Tamamla',
          'tests.questions_create_failed': 'Sorular oluşturulamadı.',
          'tests.complete_failed': 'Sınav tamamlanamadı.',
          'tests.not_found_in_type':
              '@type türünde sınav bulunamadı. Lütfen yeni bir sınav oluşturun veya farklı bir sınav türü seçin.',
          'tests.share_status': 'Herkese @status',
          'tests.status.open': 'Açık',
          'tests.status.closed': 'Kapalı',
          'tests.share_public_info':
              'Dijital etik kurallarına uygun olarak, telifli testler paylaşılmamalıdır.\nLütfen herkesin çözebileceği, telif hakkı içermeyen testler kullanın ve yayınlayın.',
          'tests.share_private_info':
              'Bu test yalnızca kendi öğrencilerinizle paylaşılabilir. Yayınladığınız teste, yalnızca size verilen ID değerini giren öğrenciler erişebilir ve çözebilir.',
          'tests.test_id': 'Test ID: @id',
          'tests.test_type': 'Test Türü',
          'tests.subjects': 'Dersler',
          'tests.exam_prep': 'Sınavlara Hazırlık',
          'tests.foreign_language': 'Yabancı Dil',
          'tests.delete_test': 'Testi Sil',
          'tests.prepare_test': 'Testi Hazırla',
          'tests.join_title': 'Teste Katıl',
          'tests.search_title': 'Test Ara',
          'tests.search_id_hint': 'Test ID Ara',
          'tests.join_help':
              'Öğretmeniniz tarafından size iletilen Test ID değerini buraya girerek teste başlayabilirsiniz.',
          'tests.join_not_found':
              'Test bulunamadı.\nGirilen Test ID ile eşleşen bir test bulunamadı.',
          'tests.join_button': 'Test''e Katıl',
          'tests.no_shared': 'Paylaşılan test yok.',
          'tests.my_tests_title': 'Testlerim',
          'tests.my_tests_empty':
              'Sonuç bulunamadı.\nDaha önce hiç test oluşturmadınız.',
          'tests.completed_title': 'Testi Bitirdin!',
          'tests.completed_body':
              'Sonuçlarım ekranında puanına ve doğru yanlış oranlarına bakabilirsin.',
          'tests.completed_short': 'Testi tamamladınız!',
          'tests.action_select': 'İşlem Seç',
          'tests.action_select_body':
              'Bu testle ilgili bir işlem yapmak istiyorsanız aşağıdaki seçeneklerden birini seçebilirsiniz.',
          'tests.copy_test_id': 'Test ID Kopyala',
          'tests.solve_title': 'Testi Çöz',
          'tests.delete_confirm': 'Bu testi silmek istediğinden emin misin?',
          'tests.id_copied': 'Test ID''si panoya kopyalandı',
          'tests.share_test_id_text':
              '@type Testi\n\nTeste katılmak için hemen TurqApp''ı indirin. Teste katılmak için gerekli TestID''niz @id\n\nUygulamayı hemen edinin:\n\nAppStore: @appStore\nPlay Store: @playStore\n\nTeste Katılmak için Talebe ekranına bulunan Testler ekranından Test ID girerek hemen çözmeye başlayabilirsiniz.',
          'tests.type.middle_school': 'Ortaokul',
          'tests.type.high_school': 'Lise',
          'tests.type.prep': 'Hazırlık',
          'tests.type.language': 'Dil',
          'tests.type.branch': 'Branş',
          'tests.lesson.turkish': 'Türkçe',
          'tests.lesson.literature': 'Edebiyat',
          'tests.lesson.math': 'Matematik',
          'tests.lesson.geometry': 'Geometri',
          'tests.lesson.physics': 'Fizik',
          'tests.lesson.chemistry': 'Kimya',
          'tests.lesson.biology': 'Biyoloji',
          'tests.lesson.history': 'Tarih',
          'tests.lesson.geography': 'Coğrafya',
          'tests.lesson.philosophy': 'Felsefe',
          'tests.lesson.psychology': 'Psikoloji',
          'tests.lesson.sociology': 'Sosyoloji',
          'tests.lesson.logic': 'Mantık',
          'tests.lesson.religion': 'Din Kültürü',
          'tests.lesson.science': 'Fen Bilimleri',
          'tests.lesson.revolution_history': 'İnkılap Tarihi',
          'tests.lesson.foreign_language': 'Yabancı Dil',
          'tests.lesson.basic_math': 'Temel Matematik',
          'tests.lesson.social_sciences': 'Sosyal Bilimler',
          'tests.lesson.literature_social_1':
              'Edebiyat - Sosyal Bilimler 1',
          'tests.lesson.social_sciences_2': 'Sosyal Bilimler 2',
          'tests.lesson.general_ability': 'Genel Yetenek',
          'tests.lesson.general_culture': 'Genel Kültür',
          'tests.language.english': 'İngilizce',
          'tests.language.german': 'Almanca',
          'tests.language.arabic': 'Arapça',
          'tests.language.french': 'Fransızca',
          'tests.language.russian': 'Rusça',
          'tests.lesson_based_title': '@type Testleri',
          'tests.none_in_category': 'Her hangi bir test yok',
          'tests.add_question': 'Soru Ekle',
          'tests.no_questions_added':
              'Soru bulunamadı.\nHenüz bu test için soru eklenmemiş.',
          'tests.level_easy': 'Kolay',
          'tests.title': 'Testler',
          'tests.report_title': 'Test Hakkında',
          'tests.report_wrong_answers':
              'Test yanlış cevaplar içeriyor',
          'tests.report_wrong_section': 'Test yanlış bölümde',
          'tests.question_content_failed':
              'Soru içeriği yüklenemedi.\nLütfen tekrar deneyin.',
          'tests.capture_and_upload': 'Çek ve Yükle',
          'tests.capture_and_upload_body':
              'Sorunun fotoğrafını çek, doğru cevabı seç ve kolayca hazırla!',
          'tests.select_from_gallery': 'Galeriden Seç',
          'tests.upload_from_camera': 'Kameradan Yükle',
          'tests.nsfw_check_failed':
              'Görsel güvenlik kontrolü tamamlanamadı.',
          'tests.nsfw_detected': 'Uygunsuz görsel tespit edildi.',
          'practice.title': 'Online Sınav',
          'practice.search_title': 'Deneme Sınavı Ara',
          'practice.empty_title': 'Henüz Deneme Sınavı Bulunmuyor',
          'practice.empty_body':
              'Şu anda sistemde kayıtlı deneme sınavı bulunmamaktadır. Yeni sınavlar eklendiğinde burada görünecektir.',
          'practice.search_empty_title': 'Aramana uygun sınav bulunamadı',
          'practice.search_empty_body_empty':
              'Sistemde kayıtlı deneme sınavı bulunmamaktadır. Yeni sınavlar eklendiğinde burada görünecektir.',
          'practice.search_empty_body_query':
              'Farklı bir anahtar kelime deneyin.',
          'practice.results_title': 'Deneme Sonuçlarım',
          'practice.saved_empty': 'Kaydedilen sınav bulunmuyor.',
          'practice.preview_no_questions':
              'Bu sınav için soru bulunamadı. Lütfen sınav içeriğini kontrol edin veya yeni sorular ekleyin.',
          'practice.preview_no_results':
              'Bu sınav için sonuç bulunamadı. Lütfen yanıtlarınızı kontrol edin veya sınavı tekrar çözün.',
          'practice.lesson_header': 'Dersler',
          'practice.answers_load_failed': 'Yanıtlar yüklenemedi.',
          'practice.lesson_results_load_failed':
              'Ders sonuçları yüklenemedi.',
          'practice.results_empty_title': 'Henüz Sınava Girmediniz',
          'practice.results_empty_body':
              'Henüz herhangi bir deneme sınavına katılmadınız. Sınavlara katıldığınızda sonuçlarınız burada görünecektir.',
          'practice.published_empty':
              'Henüz yayınladığınız bir online sınav yok.',
          'practice.user_session_missing': 'Kullanıcı oturumu bulunamadı.',
          'practice.school_info_failed': 'Okul bilgisi alınamadı.',
          'practice.load_failed': 'Veriler yüklenemedi.',
          'practice.slider_management': 'Slider Yönetimi',
          'practice.create_disabled_title': 'Sarı Rozet ve Üstüne Özel',
          'practice.create_disabled_body':
              'Online sınav oluşturmak için sarı rozet veya üstü doğrulanmış hesaba sahip olmanız gerekmektedir.',
          'practice.preview_title': 'Sınav Detayı',
          'practice.report_exam': 'Sınavı Bildir',
          'practice.user_load_failed':
              'Kullanıcı bilgileri yüklenemedi.',
          'practice.user_load_failed_body':
              'Kullanıcı bilgileri yüklenemedi. Lütfen tekrar deneyin veya sınav sahibini kontrol edin.',
          'practice.invalidity_load_failed':
              'Geçersizlik durumu yüklenemedi.',
          'practice.cover_load_failed': 'Kapak resmi yüklenemedi.',
          'practice.no_description': 'Bu sınav için açıklama eklenmemiş.',
          'practice.exam_info': 'Sınav Bilgileri',
          'practice.exam_type': 'Sınav Türü',
          'practice.exam_suffix': '@type Sınavı',
          'practice.exam_datetime': 'Sınav Tarihi ve Saati',
          'practice.exam_duration': 'Sınav Süresi',
          'practice.duration_minutes': '@minutes dk',
          'practice.application_count': 'Başvuru',
          'practice.people_count': '@count kişi',
          'practice.owner': 'Sınav sahibi',
          'practice.apply_now': 'Hemen Başvur',
          'practice.applied_short': 'Başvuru Yapıldı',
          'practice.closed_starts_in':
              'Başvuruya kapandı.\n@minutes dk sonra başlayacak.',
          'practice.started': 'Sınav Başladı',
          'practice.start_now': 'Hemen Başla',
          'practice.finished_short': 'Sınav Bitti',
          'practice.application_closed_title': 'Başvuruya Kapanmıştır!',
          'practice.application_closed_body':
              'Başvurular sınav tarihinden 15 dk önce kapanacaktır.',
          'practice.not_applied_title': 'Başvuru Yapmadın!',
          'practice.not_applied_body':
              'Başvuru yapılmayan sınavlara katılamazsın. Sadece başvuru yapanlar katılabilir.',
          'practice.not_allowed_title': 'Sınava Giremezsiniz!',
          'practice.not_allowed_body':
              'Bu sınava giriş hakkınız bulunmuyor. Daha önce bu sınavda geçersiz sayıldınız. Sınav sonlanmadan sınava bir daha giremezsiniz!',
          'practice.finished_title': 'Sınav Bitti!',
          'practice.finished_body':
              'Bir sonraki sınavlara başvurabilirsiniz. Bu sınav sonlanmıştır.',
          'practice.result_unavailable': 'Sonuç hesaplanamadı.',
          'practice.result_summary':
              'Doğru: @correct   •   Yanlış: @wrong   •   Boş: @blank   •   Net: @net',
          'practice.congrats_title': 'Tebrikler!',
          'practice.removed_title': 'Sınavdan Atıldınız!',
          'practice.removed_body':
              'Bir çok kez seni uyardık! Maalesef sınav kurallarına uymadığınız için sınavdan atıldınız ve sınavınız geçersiz sayıldı',
          'practice.applied_title': 'Başvurunuz Alınmıştır!',
          'practice.applied_body':
              'Başvurunuz başarıyla alınmıştır. Şu anda yapılacak başka bir işlem bulunmamaktadır',
          'practice.apply_completed_title': 'Başvurun Tamamlandı!',
          'practice.apply_completed_body':
              'Sınavdan önce size bildirim göndererek gerekli hatırlatmaları yapacağız. Başarılar diliyoruz!',
          'practice.apply_failed': 'Başvuru işlemi başarısız.',
          'practice.application_check_failed':
              'Başvuru kontrolü başarısız.',
          'practice.question_image_failed': 'Soru resmi yüklenemedi.',
          'practice.exam_started_title': 'Sınav Başlamıştır!',
          'practice.exam_started_body':
              'Sınava gösterdiğiniz özen ve çabanın başarıya giden yolu açacağına inanıyoruz. Bol şans ve başarılar dileriz!',
          'practice.rules_title': 'Sınav Kuralları',
          'practice.rule_1':
              'Lütfen telefonunuzun internet bağlantısını kapatınız. Sınavınız tamamlandığında, internetinizi yeniden açarak cevaplarınızı gönderebileceğiniz ekranı görüntüleyebilirsiniz.',
          'practice.rule_2':
              'Sınavdan çıkmak isterseniz, tüm cevaplarınız geçersiz sayılacaktır ve puanınız kaydedilmeyecektir. Bu işlemi onaylamadan önce dikkatlice düşünmeniz önerilir.',
          'practice.rule_3':
              'Uygulamayı arka plana aldığınızda sınavınız geçersiz sayılacaktır. Bu yüzden uygulamayı arka plana almamaya özen gösteriniz.',
          'practice.start_exam': 'Sınav\'a Başla',
          'practice.finish_exam': 'Sınavı Bitir',
          'practice.background_warning':
              'Uygulamayı arka plana almanız gibi kritik durumlarda, sınavınız geçersiz sayılacaktır. Lütfen dikkatli olun ve kurallara uygun hareket edin.',
          'practice.questions_load_failed': 'Sorular yüklenemedi.',
          'practice.answers_save_failed': 'Yanıtlar kaydedilemedi.',
          'past_questions.no_results': 'Her hangi bir sonuç yok',
          'past_questions.title': 'Denemeler',
          'past_questions.mock_fallback': 'Deneme',
          'past_questions.search_empty': 'Aramaya uygun deneme bulunamadı.',
          'past_questions.results_suffix': '@title Sonuçlarım',
          'past_questions.local_result_summary':
              '@count soru çözüldü. Sonuç local olarak tutuluyor; bu ekranda sadece net özeti gösteriliyor.',
          'past_questions.mock_label': 'Deneme @index',
          'past_questions.question_count': '@count Soru',
          'past_questions.net_label': 'Net',
          'past_questions.tests_by_year': '@type @year Testleri',
          'past_questions.languages_title': '@type Dilleri',
          'past_questions.tests_by_type': '@type Testleri',
          'past_questions.select_exam': 'Sınav Seç',
          'past_questions.questions_title': 'Sorular',
          'past_questions.continue_solving': 'Soru Çözmeye Devam Et',
          'past_questions.oabt_short': 'ÖABT',
          'past_questions.exam_type.associate': 'Ön Lisans',
          'past_questions.exam_type.undergraduate': 'Lisans',
          'past_questions.exam_type.middle_school': 'Orta Öğretim',
          'past_questions.branch.general_ability_culture': 'GK - GY',
          'past_questions.branch.group_a': 'A Grubu',
          'past_questions.branch.education_sciences': 'Eğitim Bilimleri',
          'past_questions.branch.field_knowledge': 'Alan Bilgisi',
          'past_questions.sessions_by_year': '@year Yılı Oturumlar',
          'past_questions.teaching.title': 'Öğretmenlikler',
          'past_questions.teaching.suffix': 'öğretmenliği',
          'past_questions.teaching.primary_math_short': 'İ. Matematik',
          'past_questions.teaching.high_school_math_short': 'L. Matematik',
          'past_questions.teaching.german': 'Almanca öğretmenliği',
          'past_questions.teaching.physical_education':
              'Beden eğitim öğretmenliği',
          'past_questions.teaching.biology': 'Biyoloji öğretmenliği',
          'past_questions.teaching.geography': 'Coğrafya öğretmenliği',
          'past_questions.teaching.religious_culture':
              'Din kültürü öğretmenliği',
          'past_questions.teaching.literature': 'Edebiyat öğretmenliği',
          'past_questions.teaching.science': 'Fen bilimleri öğretmenliği',
          'past_questions.teaching.physics': 'Fizik öğretmenliği',
          'past_questions.teaching.chemistry': 'Kimya öğretmenliği',
          'past_questions.teaching.high_school_math': 'Lise matematik',
          'past_questions.teaching.preschool': 'Okul öncesi',
          'past_questions.teaching.guidance': 'Rehberlik',
          'past_questions.teaching.social_studies':
              'Sosyal bilgiler öğretmenliği',
          'past_questions.teaching.classroom': 'Sınıf öğretmenliği',
          'past_questions.teaching.history': 'Tarih öğretmenliği',
          'past_questions.teaching.turkish': 'Türkçe öğretmenliği',
          'past_questions.teaching.primary_math': 'İlköğretim matematik',
          'past_questions.teaching.imam_hatip': 'İmam hatip',
          'past_questions.teaching.english': 'İngilizce öğretmenliği',
          'settings.about': 'Hakkında',
          'settings.policies': 'Politikalar',
          'settings.contact_us': 'Bize Yazın',
          'settings.my_approval_results': 'Onay Sonuçlarım',
          'settings.admin_ads': 'Yönetim / Reklam Merkezi',
          'ads_center.title': 'Reklam Merkezi',
          'ads_center.tab_dashboard': 'Dashboard',
          'ads_center.tab_campaigns': 'Kampanyalar',
          'ads_center.tab_editor': 'Editor',
          'ads_center.tab_creatives': 'Kreatif',
          'ads_center.tab_monitor': 'Monitor',
          'ads_center.tab_preview': 'Preview',
          'ads_center.admin_only': 'Bu alan sadece admin erişimine açıktır.',
          'ads_center.summary': 'Özet',
          'ads_center.total_campaigns': 'Toplam Kampanya',
          'ads_center.active': 'Aktif',
          'ads_center.paused': 'Duraklatıldı',
          'ads_center.feature_flags': 'Feature Flags',
          'ads_center.status': 'Status',
          'ads_center.placement': 'Placement',
          'ads_center.include_test_campaigns': 'Test kampanyaları dahil',
          'ads_center.new_campaign': 'Yeni Kampanya',
          'ads_center.no_campaigns': 'Kampanya bulunamadı.',
          'ads_center.untitled_campaign': '(isimsiz kampanya)',
          'ads_center.budget': 'Bütçe',
          'ads_center.activate': 'Aktif Et',
          'ads_center.pause': 'Duraklat',
          'ads_center.no_delivery_logs': 'Delivery log bulunamadı.',
          'ads_center.decision_detail': 'Karar Detayı',
          'ads_center.no_creatives': 'Kreatif bulunamadı.',
          'ads_center.untitled_creative': '(başlıksız kreatif)',
          'ads_center.reject_note': 'Red Notu',
          'ads_center.approve_note': 'Onay Notu',
          'ads_center.review_note_hint': 'İnceleme notu',
          'ads_center.delivery_simulation': 'Delivery Simulation',
          'ads_center.user_id': 'User ID',
          'ads_center.country': 'Country',
          'ads_center.city': 'City',
          'ads_center.age': 'Age',
          'ads_center.run_simulation': 'Simülasyonu Çalıştır',
          'ads_center.eligible_ad_found': 'Uygun reklam bulundu',
          'ads_center.no_eligible_ad': 'Uygun reklam bulunamadı',
          'ads_center.reasons': 'Nedenler',
          'ads_center.create_campaign': 'Kampanya Oluştur',
          'ads_center.update_campaign': 'Kampanyayı Güncelle',
          'ads_center.save_creative': 'Kreatif Kaydet',
          'ads_center.campaign_saved_title': 'Kampanya Kaydedildi',
          'ads_center.campaign_saved_body': 'Kampanya kimliği: {id}',
          'ads_center.save_campaign_first':
              'Lütfen önce kampanyayı kaydedin.',
          'ads_center.creative_saved_title': 'Kreatif Kaydedildi',
          'ads_center.creative_saved_body':
              'Reklam kreatifi başarıyla kaydedildi.',
          'ads_center.permission_denied':
              'Ads Center verilerine erişim reddedildi (permission-denied).',
          'settings.admin_moderation': 'Yönetim / Moderasyon',
          'settings.admin_reports': 'Yönetim / Reports',
          'settings.admin_badges': 'Yönetim / Rozet Yönetimi',
          'settings.admin_tasks': 'Yönetim / Admin Görevleri',
          'settings.admin_approvals': 'Yönetim / Admin Onayları',
          'settings.admin_push': 'Yönetim / Push Gönder',
          'settings.admin_story_music': 'Yönetim / Hikaye Müzikleri',
          'settings.admin_support': 'Yönetim / Kullanıcı Destek',
          'settings.system_diag_menu': 'Sistem ve Tanı Menüsü',
          'settings.diagnostics.data_usage': 'Veri Tüketimi',
          'settings.diagnostics.network': 'Ağ',
          'settings.diagnostics.connected': 'Bağlı',
          'settings.diagnostics.monthly_total': 'Aylık Toplam',
          'settings.diagnostics.monthly_limit': 'Aylık Limit',
          'settings.diagnostics.remaining': 'Kalan',
          'settings.diagnostics.limit_usage': 'Limit Kullanımı',
          'settings.diagnostics.wifi_usage': 'Wi-Fi Tüketimi',
          'settings.diagnostics.cellular_usage': 'Mobil Tüketim',
          'settings.diagnostics.time_ranges': 'Zaman Aralıkları',
          'settings.diagnostics.this_month_actual': 'Bu Ay (Gerçek)',
          'settings.diagnostics.hourly_average': 'Ortalama Saatlik',
          'settings.diagnostics.since_login_estimated':
              'Son Girişten Beri (Yaklaşık)',
          'settings.diagnostics.details': 'Detay',
          'settings.diagnostics.cache': 'Cache',
          'settings.diagnostics.saved_media_count': 'Kayıtlı Medya Sayısı',
          'settings.diagnostics.occupied_space': 'Kaplanan Alan',
          'settings.diagnostics.offline_queue': 'Offline Kuyruk',
          'settings.diagnostics.pending': 'Bekleyen',
          'settings.diagnostics.dead_letter': 'Dead-letter',
          'settings.diagnostics.status': 'Durum',
          'settings.diagnostics.syncing': 'Senkronize ediliyor',
          'settings.diagnostics.idle': 'Boşta',
          'settings.diagnostics.processed_total': 'İşlenen (toplam)',
          'settings.diagnostics.failed_total': 'Hata (toplam)',
          'settings.diagnostics.last_sync': 'Son Senkron',
          'settings.diagnostics.login_date': 'Giriş Tarihi',
          'settings.diagnostics.login_time': 'Giriş Saati',
          'settings.diagnostics.app_health_panel': 'Uygulama Sağlık Paneli',
          'settings.diagnostics.video_cache_detail': 'Video Cache Detayı',
          'settings.diagnostics.quick_actions': 'Hızlı Aksiyonlar',
          'settings.diagnostics.offline_queue_detail':
              'Offline Kuyruk Detayı',
          'settings.diagnostics.last_error_summary': 'Son Hata Özeti',
          'settings.diagnostics.error_report': 'Hata Raporu',
          'settings.diagnostics.saved_videos': 'Kayıtlı Video',
          'settings.diagnostics.saved_segments': 'Kayıtlı Segment',
          'settings.diagnostics.disk_usage': 'Disk Kullanımı',
          'settings.diagnostics.unknown': 'Bilinmiyor',
          'settings.diagnostics.cache_traffic': 'Cache Trafiği',
          'settings.diagnostics.hit_rate': 'Hit Oranı',
          'settings.diagnostics.hit': 'Hit',
          'settings.diagnostics.miss': 'Miss',
          'settings.diagnostics.cache_served': 'Cache Servis',
          'settings.diagnostics.downloaded_from_network':
              'Ağdan İndirilen',
          'settings.diagnostics.prefetch': 'Prefetch',
          'settings.diagnostics.queue': 'Kuyruk',
          'settings.diagnostics.active_downloads': 'Aktif İndirme',
          'settings.diagnostics.paused': 'Duraklatılmış',
          'settings.diagnostics.active': 'Aktif',
          'settings.diagnostics.reset_data_counters':
              'Veri Sayaçlarını Sıfırla',
          'settings.diagnostics.data_counters_reset':
              'Veri sayaçları sıfırlandı',
          'settings.diagnostics.sync_offline_queue_now':
              'Offline Kuyruğu Şimdi Senkronla',
          'settings.diagnostics.offline_queue_sync_triggered':
              'Offline kuyruk senkron tetiklendi',
          'settings.diagnostics.retry_dead_letter': 'Dead-letter Yeniden Dene',
          'settings.diagnostics.dead_letter_queued':
              'Dead-letter işlemleri kuyruğa alındı',
          'settings.diagnostics.clear_dead_letter': 'Dead-letter Temizle',
          'settings.diagnostics.dead_letter_cleared':
              'Dead-letter kuyruğu temizlendi',
          'settings.diagnostics.pause_prefetch': 'Prefetch Duraklat',
          'settings.diagnostics.prefetch_paused': 'Prefetch duraklatıldı',
          'settings.diagnostics.service_not_ready':
              'Prefetch servisi hazır değil',
          'settings.diagnostics.resume_prefetch': 'Prefetch Devam Et',
          'settings.diagnostics.prefetch_resumed':
              'Prefetch devam ediyor',
          'settings.diagnostics.online': 'Online',
          'settings.diagnostics.sync': 'Sync',
          'settings.diagnostics.processed': 'Processed',
          'settings.diagnostics.failed': 'Failed',
          'settings.diagnostics.pending_first8': 'Pending (ilk 8)',
          'settings.diagnostics.dead_letter_first8':
              'Dead-letter (ilk 8)',
          'settings.diagnostics.sync_now': 'Şimdi Senkronla',
          'settings.diagnostics.dead_letter_retry': 'Dead-letter Retry',
          'settings.diagnostics.dead_letter_clear': 'Dead-letter Clear',
          'settings.diagnostics.no_recorded_error':
              'Kayıtlı hata bulunmuyor.',
          'settings.diagnostics.error_code': 'Kod',
          'settings.diagnostics.error_category': 'Kategori',
          'settings.diagnostics.error_severity': 'Seviye',
          'settings.diagnostics.error_retryable': 'Tekrar Denenebilir',
          'settings.diagnostics.error_message': 'Mesaj',
          'settings.diagnostics.error_time': 'Zaman',
          'settings.sign_out': 'Oturumu Kapat',
          'settings.sign_out_title': 'Çıkış Yap',
          'settings.sign_out_message':
              'Çıkış yapmak istediğinizden emin misiniz?',
          'language.title': 'Dil',
          'language.subtitle': 'Uygulama dilini seç.',
          'language.note':
              'Bazı ekranlar kademeli olarak çevrilecektir. Seçimin hemen uygulanır.',
          'language.option.tr': 'Türkçe',
          'language.option.en': 'İngilizce',
          'language.option.de': 'Almanca',
          'language.option.fr': 'Fransızca',
          'language.option.it': 'İtalyanca',
          'language.option.ru': 'Rusça',
          'language.option.ar': 'Arapça',
          'login.tagline': '"Hikayeleriniz, burada birleşiyor."',
          'login.device_accounts': 'Cihazdaki hesaplar',
          'login.last_used': 'Son kullanılan',
          'login.saved_account': 'Kayıtlı hesap',
          'login.sign_in': 'Giriş Yap',
          'login.create_account': 'Hesap Oluştur',
          'login.policies': 'Sözleşmeler ve Politikalar',
          'login.identifier_hint': 'Kullanıcı adı veya e-posta adresiniz',
          'login.password_hint': 'Şifreniz',
          'login.reset': 'Sıfırla',
          'common.back': 'Geri',
          'common.continue': 'Devam',
          'common.all': 'Tümü',
          'common.videos': 'Videolar',
          'common.photos': 'Fotoğraflar',
          'common.no_results': 'Sonuç bulunamadı',
          'common.success': 'Başarılı',
          'common.warning': 'Uyarı',
          'common.delete': 'Sil',
          'common.search': 'Ara',
          'common.call': 'Ara',
          'common.view': 'Görüntüle',
          'common.create': 'Oluştur',
          'common.applications': 'Başvurular',
          'common.liked': 'Beğenilenler',
          'common.saved': 'Kaydedilenler',
          'common.unknown_category': 'Bilinmeyen Kategori',
          'common.clear': 'Temizle',
          'common.share': 'Paylaş',
          'common.show_more': 'Daha Fazla Göster',
          'common.show_less': 'Daha Az Göster',
          'common.hide': 'Gizle',
          'common.push': 'Push',
          'common.quote': 'Alıntıla',
          'common.user': 'Kullanıcı',
          'common.close': 'Kapat',
          'common.retry': 'Tekrar Dene',
          'login.selected_account_password':
              '{username} seçildi. Giriş bilgilerini tamamlayıp devam edebilirsin.',
          'login.selected_account_phone':
              '{username} telefon ile kayıtlı görünüyor. Bu hesap için manuel yeniden giriş yapman gerekiyor.',
          'login.selected_account_manual':
              '{username} için manuel yeniden giriş yapman gerekiyor.',
          'login.reset_password_title': 'Şifreni Sıfırla',
          'login.reset_password_help':
              'Mail adresinizi girerek hesabınızı bulmamızda yardımcı olun. Hesabınızda kayıt olan telefon numaranıza bir doğrulama kodu göndereceğiz',
          'login.email_label': 'E-posta Adresi',
          'login.email_hint': 'E-posta adresinizi girin',
          'login.get_code': 'Kodu Al',
          'login.resend_code': 'Tekrar Gönder',
          'login.verification_code': 'Doğrulama Kodu',
          'login.verification_code_hint': '6 haneli doğrulama kodu',
          'signup.step': 'Adım {current}/3',
          'signup.create_account_title': 'Hesabınızı Oluşturun',
          'signup.policy_intro': 'Hesap oluşturarak ve devam ederek ',
          'signup.policy_outro':
              ' metinlerini kabul ediyorum.',
          'signup.policy_short':
              'Sözleşmeler ve Politikaları kabul ediyorum.',
          'signup.policy_notice':
              'Bu onay, hesap oluşturma akışının bir parçası olarak kayda alınabilir.',
          'signup.email': 'E-Posta',
          'signup.username': 'Kullanıcı Adı',
          'signup.username_help':
              'Kullanıcı adı size özel, özgün ve yanıltıcı olmayan şekilde oluşturulmalıdır. Türkçe karakterler otomatik dönüştürülür.',
          'signup.password': 'Şifre',
          'signup.password_help':
              'Şifre (En az bir harf, bir sayı, bir noktalama; min 6 karakter)',
          'signup.personal_info': 'Kişisel Bilgiler',
          'signup.first_name': 'Ad',
          'signup.last_name_optional': 'Soyad (Opsiyonel)',
          'signup.next': 'İleri',
          'signup.verification_title': 'Doğrulama',
          'signup.verification_message':
              '+90{phone} telefon numaranıza bir doğrulama kodu gönderdik. Bu doğrulama kodunu girerek devam edebilirsiniz.',
          'signup.code_hint': '6 haneli kod',
          'signup.required_acceptance_title': 'Onay Gerekli',
          'signup.required_acceptance_body':
              'Devam etmek için üyelik sözleşmesi ve politika metinlerini kabul etmelisiniz.',
          'signup.invalid_email': 'Lütfen geçerli bir e-posta girin.',
          'signup.username_min': 'Kullanıcı adı en az 8 karakter olmalı.',
          'signup.weak_password_title': 'Zayıf Şifre',
          'signup.weak_password_body':
              'Şifre en az bir harf, bir sayı ve bir noktalama içermeli (min 6 karakter).',
          'signup.unavailable_title': 'Kullanılamaz',
          'signup.email_taken': 'Bu e-posta zaten kullanımda.',
          'signup.username_taken': 'Bu kullanıcı adı zaten kullanımda.',
          'signup.check_failed_title': 'Kontrol Edilemedi',
          'signup.check_failed_body':
              'Kayıt uygunluğu şu anda kontrol edilemiyor. Lütfen tekrar deneyin.',
          'signup.limit_title': 'Limit Aşıldı',
          'signup.limit_body':
              'Bu telefon numarası için en fazla 5 hesap oluşturulabilir.',
          'signup.username_taken_title': 'Kullanıcı adı kullanımda',
          'signup.username_taken_body': 'Lütfen farklı bir kullanıcı adı seç.',
          'signup.failed_title': 'Kayıt tamamlanamadı',
          'signup.failed_body':
              'Hesap oluşturma sırasında bir hata oluştu. Lütfen tekrar deneyin.',
          'signup.missing_info_title': 'Eksik Bilgi',
          'signup.phone_name_rule':
              'Ad en az 3 karakter olmalı ve telefon 5 ile başlayan 10 hane olmalı.',
          'signup.phone_invalid_title': 'Geçersiz Telefon',
          'signup.phone_invalid_body':
              'Lütfen 5 ile başlayan 10 haneli telefon numarası girin.',
          'signup.code_invalid_title': 'Geçersiz Kod',
          'signup.code_invalid_body':
              'Lütfen 6 haneli doğrulama kodunu girin.',
          'signup.verify_failed_title': 'Doğrulama Başarısız',
          'signup.code_expired': 'Kodun süresi doldu. Lütfen yeni kod isteyin.',
          'signup.email_or_username_taken':
              'Bu e-posta veya kullanıcı adı zaten kullanımda.',
          'signup.code_not_found': 'Doğrulama kodu bulunamadı. Yeniden kod alın.',
          'signup.code_wrong': 'Doğrulama kodu hatalı.',
          'signup.too_many_attempts':
              'Çok fazla hatalı deneme yapıldı. Yeni kod isteyin.',
          'signup.code_no_longer_valid':
              'Kod artık geçerli değil. Yeni kod alın.',
          'signup.verify_retry':
              'Kod doğrulanamadı. Lütfen tekrar deneyin.',
          'signup.account_create_failed_title': 'Hesap oluşturulamadı',
          'signup.email_in_use': 'Bu e-posta adresi zaten kullanımda.',
          'signup.invalid_email_auth': 'E-posta adresi geçersiz.',
          'signup.password_too_weak':
              'Şifre çok zayıf. Daha güçlü bir şifre deneyin.',
          'signup.email_password_disabled':
              'E-posta/şifre kayıt yöntemi kapalı.',
          'signup.network_failed': 'İnternet bağlantısı kurulamadı.',
          'signup.operation_failed': 'Kayıt işlemi başarısız.',
          'notifications.title': 'Bildirimler',
          'notifications.instant': 'Anlık Bildirimler',
          'notifications.categories': 'Kategoriler',
          'notifications.device_notice':
              'Kilit ekranında bildirimleri görmek için cihaz ayarlarından bildirim iznini açık tut.',
          'notifications.device_settings': 'Cihaz ayarlarına git',
          'notifications.pause_all': 'Tümünü durdur',
          'notifications.pause_all_desc':
              'Bildirimleri geçici olarak tamamen sessize al.',
          'notifications.sleep_mode': 'Uyku modu',
          'notifications.sleep_mode_desc':
              'Rahatsız edilmek istemediğinde bildirimleri sakinleştir.',
          'notifications.messages_only': 'Sadece mesajlar',
          'notifications.messages_only_desc':
              'Açıkken yalnızca mesaj bildirimleri görünür.',
          'notifications.posts_comments': 'Gönderiler ve yorumlar',
          'notifications.posts_comments_desc':
              'Gönderi etkileşimleri, yorumlar ve duyurular.',
          'notifications.comments': 'Yorumlar',
          'notifications.comments_desc': 'Gönderine yapılan yorumlar.',
          'comments.delete_message':
              'Bu yorumu silmek istediğinizden emin misiniz?',
          'comments.delete_failed': 'Yorum silinemedi.',
          'comments.title': 'Yorumlar',
          'comments.empty': 'İlk yorumu sen yap...',
          'comments.reply': 'Yanıtla',
          'comments.replying_to': '@nickname kullanıcısına yanıt',
          'comments.sending': 'Gönderiliyor',
          'comments.community_violation_title':
              'Topluluk Kurallarına Aykırı',
          'comments.community_violation_body':
              'Kullandığınız dil, topluluk kurallarımıza uymamaktadır. Lütfen saygılı bir dil kullanınız.',
          'post_sharers.empty': 'Henüz kimse bu gönderiyi paylaşmamış',
          'notifications.post_activity': 'Gönderi etkileşimleri',
          'notifications.post_activity_desc':
              'Beğeniler, paylaşımlar ve gönderi pushları.',
          'notifications.follows': 'Takipler',
          'notifications.follows_desc':
              'Yeni takipçiler ve takip hareketleri.',
          'notifications.follow_notifs': 'Takip bildirimleri',
          'notifications.follow_notifs_desc':
              'Seni takip eden kullanıcılar ve takip hareketleri.',
          'notifications.messages': 'Mesajlar',
          'notifications.messages_desc':
              'Sohbet ve direkt mesaj bildirimleri.',
          'notifications.direct_messages': 'Mesajlar',
          'notifications.direct_messages_desc':
              'Birebir sohbetler ve gelen yeni mesajlar.',
          'notifications.opportunities': 'İlanlar ve başvurular',
          'notifications.opportunities_desc':
              'İş ve özel ders ilanlarına gelen başvurular.',
          'notifications.job_apps': 'İş ilanı başvuruları',
          'notifications.job_apps_desc':
              'İş ilanına yapılan yeni başvurular.',
          'notifications.tutoring_apps': 'Özel ders başvuruları',
          'notifications.tutoring_apps_desc':
              'Özel ders ilanına yapılan başvurular.',
          'notifications.application_status': 'Başvuru durumu',
          'notifications.application_status_desc':
              'Özel ders başvuru sonucu ve durum güncellemeleri.',
          'notifications.marking_read': 'Okundu işaretleniyor...',
          'notifications.mark_all_read': 'Tümünü okundu yap',
          'notifications.delete_all': 'Tümünü Sil',
          'notifications.tab_follow': 'Takip',
          'notifications.tab_comment': 'Yorum',
          'notifications.tab_mentions': 'Bahsedenler',
          'notifications.tab_listings': 'İlan',
          'notifications.empty_filtered': 'Bu filtrede bildirim yok',
          'notifications.empty': 'Bildiriminiz yok',
          'notifications.new': 'Yeni',
          'notifications.today': 'Gündem',
          'notifications.yesterday': 'Dün',
          'notifications.older': 'Daha eski',
          'notifications.count_items': '{count} adet',
          'notifications.and_more': '{base} ve {count} bildirim daha',
          'notification.item.default_interaction':
              'senin gönderinle etkileşime geçti.',
          'notification.hint.profile': 'Profil',
          'notification.hint.chat': 'Sohbet',
          'notification.hint.listing_named': 'İlan: {label}',
          'notification.hint.listing': 'İlan',
          'notification.hint.tutoring': 'Özel ders ilanı',
          'notification.hint.comments': 'Yorumlar',
          'notification.hint.post': 'Gönderi',
          'notification.desc.like': 'gönderini beğendi',
          'notification.desc.comment': 'gönderine yorum yaptı',
          'notification.desc.reshare': 'gönderini yeniden paylaştı',
          'notification.desc.share': 'gönderini paylaştı',
          'notification.desc.follow': 'seni takip etmeye başladı',
          'notification.desc.message': 'sana mesaj gönderdi',
          'notification.desc.job_application': 'ilanına başvuru yaptı',
          'notification.desc.tutoring_application':
              'özel ders ilanına başvuru yaptı',
          'notification.desc.tutoring_status':
              'özel ders başvuru durumunu güncelledi',
          'support.title': 'Bize Yazın',
          'support.card_title': 'Destek Mesajı',
          'support.direct_admin': 'Mesajın doğrudan admine iletilir.',
          'support.topic': 'Konu',
          'support.topic.account': 'Hesap',
          'support.topic.payment': 'Ödeme',
          'support.topic.technical': 'Teknik Sorun',
          'support.topic.content': 'İçerik Şikayeti',
          'support.topic.suggestion': 'Öneri',
          'support.message_hint': 'Sorununu veya talebini yaz...',
          'support.send': 'Mesajı Gönder',
          'support.empty_title': 'Eksik Bilgilendirme',
          'support.empty_body': 'Lütfen bir mesaj yaz.',
          'support.sent_title': 'Gönderildi',
          'support.sent_body': 'Mesajın admine iletildi.',
          'support.error_title': 'Hata',
          'support.error_body': 'Mesaj gönderilemedi:',
          'liked_posts.no_posts': 'Gönderi yok',
          'saved_posts.posts_tab': 'Gönderi',
          'saved_posts.series_tab': 'Dizi',
          'saved_posts.series_badge': 'DİZİ',
          'saved_posts.no_saved_posts': 'Kaydedilen gönderi yok',
          'saved_posts.no_saved_series': 'Kaydedilen dizi yok',
          'blocked_users.empty': 'Hiç kimseyi engellemedin',
          'blocked_users.unblock': 'Engeli Kaldır',
          'blocked_users.unblock_confirm_title': 'Engeli Kaldır',
          'blocked_users.unblock_confirm_body':
              '{nickname} kullanıcısının engelini kaldırmak istediğinizden emin misin?',
          'blocked_users.unblock_success': '{nickname} engelden çıkarıldı.',
          'blocked_users.unblock_failed': 'Engel kaldırılamadı.',
          'profile_contact.title': 'İletişim',
          'profile_contact.call': 'Arama',
          'profile_contact.email': 'E-Posta',
          'editor_email.title': 'E-posta Onayı',
          'editor_email.email_hint': 'Hesap e-posta adresiniz',
          'editor_email.send_code': 'Onay Kodu Gönder',
          'editor_email.resend_in': 'Yeniden gönderim için {seconds}s',
          'editor_email.note':
              'Bu onay güvenlik amaçlıdır. Onaylamasanız da uygulamayı kullanmaya devam edebilirsiniz.',
          'editor_email.code_hint': '6 haneli onay kodu',
          'editor_email.verify_confirm': 'Kodu Doğrula ve Onayla',
          'editor_email.wait': 'Lütfen {seconds} saniye bekleyin.',
          'editor_email.session_missing':
              'Oturum bulunamadı. Lütfen tekrar giriş yapın.',
          'editor_email.email_missing': 'Hesabınızda e-posta bulunamadı.',
          'editor_email.code_sent':
              'Onay kodu e-posta adresinize gönderildi.',
          'editor_email.code_send_failed': 'Onay kodu gönderilemedi.',
          'editor_email.enter_code':
              'Lütfen 6 haneli onay kodunu girin.',
          'editor_email.verified': 'E-posta adresiniz onaylandı.',
          'editor_email.verify_failed': 'E-posta onaylanamadı.',
          'editor_phone.title': 'Telefon Numarası',
          'editor_phone.phone_hint': 'Telefon Numarası',
          'editor_phone.send_approval': 'Onay E-postası Gönder',
          'editor_phone.resend_in': 'Yeniden gönderim için {seconds}s',
          'editor_phone.code_hint': '6 haneli onay kodu',
          'editor_phone.verify_update': 'Kodu Doğrula ve Güncelle',
          'editor_phone.wait': 'Lütfen {seconds} saniye bekleyin.',
          'editor_phone.invalid_phone':
              'Lütfen 5 ile başlayan 10 haneli telefon numarası girin.',
          'editor_phone.session_missing':
              'Oturum bulunamadı. Lütfen tekrar giriş yapın.',
          'editor_phone.email_missing':
              'Hesabınızda doğrulanacak e-posta bulunamadı.',
          'editor_phone.code_sent':
              'Onay kodu e-posta adresinize gönderildi.',
          'editor_phone.code_send_failed': 'Onay kodu gönderilemedi.',
          'editor_phone.enter_code':
              'Lütfen 6 haneli onay kodunu girin.',
          'editor_phone.update_failed': 'Telefon numarası güncellenemedi.',
          'editor_phone.updated': 'Telefon numaranız güncellendi.',
          'address.title': 'Adres',
          'address.hint': 'İşletme & Ofis Adresi',
          'biography.title': 'Biyografi',
          'biography.hint': 'Kendini anlat..',
          'job_selector.title': 'Meslek & Kategori',
          'job_selector.subtitle':
              'Kategorin, profilinin keşfedilmesini kolaylaştırır.',
          'job_selector.search_hint': 'Ara',
          'legacy_language.title': 'Uygulama Dili',
          'policy_detail.last_updated': 'Son güncelleme: {date}',
          'statistics.title': 'İstatistikler',
          'statistics.you': 'Siz',
          'statistics.notice':
              'İstatistiksel verileriniz, 30 günlük aktivitelerinize göre düzenli olarak güncellenmektedir.',
          'statistics.post_views_pct': 'Gönderi Görüntülemesi Yüzdesi',
          'statistics.follower_growth_pct': 'Takipçi Artışı Yüzdeliği',
          'statistics.profile_visits_30d': 'Profil Ziyareti (30 Gün)',
          'statistics.post_views': 'Gönderi Görüntüleme',
          'statistics.post_count': 'Gönderi Sayısı',
          'statistics.story_count': 'Hikaye Sayısı',
          'statistics.follower_growth': 'Takipçi Artışı',
          'interests.personalize_feed': 'Akışını kişiselleştir',
          'interests.selection_range':
              'En az {min}, en fazla {max} ilgi alanı seç.',
          'interests.selected_count': '{selected}/{max} seçildi',
          'interests.ready': 'Hazır',
          'interests.search_hint': 'İlgi alanı ara',
          'interests.limit_title': 'Seçim Sınırı',
          'interests.limit_body':
              'En fazla {max} ilgi alanı seçebilirsiniz.',
          'interests.min_title': 'Eksik Seçim',
          'interests.min_body':
              'En az {min} ilgi alanı seçmelisiniz.',
          'view_changer.title': 'Görünüm',
          'view_changer.classic': 'Klasik Görünüm',
          'view_changer.modern': 'Modern Görünüm',
          'social_links.title': 'Bağlantılar ({count})',
          'social_links.add': 'Ekle',
          'social_links.add_title': 'Bağlantı Ekle',
          'social_links.label_title': 'Başlık',
          'social_links.username_hint': 'Kullanıcı adı',
          'social_links.remove_title': 'Bağlantıyı Kaldır',
          'social_links.remove_message':
              'Bu bağlantıyı kaldırmak istediğinizden emin misiniz?',
          'social_links.save_permission_error':
              'İzin hatası: bağlantı kaydetmeye yetki yok.',
          'social_links.save_failed': 'Bir sorun oluştu.',
          'pasaj.closed': 'Pasaj şu anda kapalı',
          'pasaj.common.slider_admin': 'Slider Yönetimi',
          'pasaj.common.my_results': 'Sonuçlarım',
          'pasaj.common.published': 'Yayınladıklarım',
          'pasaj.common.my_applications': 'Başvurularım',
          'pasaj.common.post_listing': 'İlan Ver',
          'pasaj.common.all_turkiye': 'Tüm Türkiye',
          'pasaj.job_finder.tab.explore': 'Keşfet',
          'pasaj.job_finder.tab.create': 'İlan Ver',
          'pasaj.job_finder.tab.applications': 'Başvurularım',
          'pasaj.job_finder.tab.career_profile': 'Kariyer Profili',
          'pasaj.tabs.scholarships': 'Burslar',
          'pasaj.tabs.market': 'Mabil Pazar',
          'pasaj.tabs.question_bank': 'Soru Bankası',
          'pasaj.tabs.practice_exams': 'Denemeler',
          'pasaj.tabs.online_exam': 'Online Sınav',
          'pasaj.tabs.answer_key': 'Cevap Anahtarı',
          'pasaj.tabs.tutoring': 'Özel Ders',
          'pasaj.tabs.job_finder': 'İş Veren',
          'pasaj.question_bank.solve_later': 'Sonra Çöz',
          'pasaj.answer_key.join': 'Katıl',
          'answer_key.published': 'Yayınladıklarım',
          'answer_key.my_results': 'Sonuçlarım',
          'answer_key.title': 'Cevap Anahtarı',
          'answer_key.book_detail': 'Kitap Detayı',
          'answer_key.book_info': 'Kitap Bilgileri',
          'answer_key.exam_type': 'Sınav Türü',
          'answer_key.publish_date': 'Basım Tarihi',
          'answer_key.answer_keys': 'Cevap Anahtarları',
          'answer_key.no_answer_keys':
              'Bu kitap için henüz cevap anahtarı bulunmuyor.',
          'answer_key.report_book': 'Kitabı Bildir',
          'answer_key.saved_empty': 'Kaydedilen kitap yok.',
          'answer_key.new_create': 'Yeni Oluştur',
          'answer_key.create_optical_form': 'Optik Form\nOluştur',
          'answer_key.create_booklet_answer_key':
              'Kitap Cevap Anahtarı\nOluştur',
          'answer_key.create_optical_form_single': 'Optik Form Oluştur',
          'answer_key.give_exam_name': 'Sınavınıza bir ad verin',
          'answer_key.join_exam_title': 'Sınava Katıl',
          'answer_key.exam_id_hint': 'Sınav ID',
          'answer_key.book': 'Kitap',
          'answer_key.create_book': 'Kitap Oluştur',
          'answer_key.optical_form': 'Optik Form',
          'answer_key.search_min_chars': 'Aramak için en az 2 karakter yaz.',
          'answer_key.delete_book': 'Kitabı Sil',
          'answer_key.delete_book_confirm':
              'Bu kitabı silmek istediğinizden emin misiniz?',
          'answer_key.cover_select_short': 'Kapak Fotoğrafı\nSeç',
          'answer_key.cover_updated': 'Kapak Güncellendi',
          'answer_key.cover_updated_body':
              'Kapak görseli başarıyla yüklendi.',
          'answer_key.cover_update_failed':
              'Kapak görseli yüklenirken bir sorun oluştu.',
          'answer_key.answered_suffix': '@time cevaplandı',
          'answer_key.full_name_hint': 'Ad Soyad',
          'answer_key.student_number_hint': 'Öğrenci Numaranız',
          'answer_key.book_title_hint': 'Başlık (Ör: Türkçe Soru Bankası)',
          'answer_key.publisher_hint': 'Yayın Evi',
          'answer_key.publish_year_hint': 'Basım Yılı',
          'answer_key.answer_list_hint': 'Cevap Anahtar Listesi',
          'answer_key.questions_prepared': '@count soru hazırlandı',
          'answer_key.add_answer_key': 'Cevap Anahtarı Ekle',
          'answer_key.share_owner_only':
              'Sadece admin ve ilan sahibi paylaşabilir.',
          'answer_key.book_answer_key_desc': 'cevap anahtarı',
          'pasaj.tutoring.nearby_listings': 'Bölgemdeki İlanlar',
          'pasaj.job_finder.title': 'İş Veren',
          'pasaj.job_finder.search_hint': 'Ne tür iş arıyorsun ?',
          'pasaj.job_finder.nearby_listings': 'Sana En Yakın İlanlar',
          'pasaj.job_finder.no_search_result':
              'Aramana uygun ilan bulunamadı',
          'pasaj.job_finder.no_city_listing':
              'Şehrinde bir ilan bulunmuyor',
          'pasaj.job_finder.sort_high_salary': 'Yüksek Maaş',
          'pasaj.job_finder.sort_low_salary': 'Düşük Maaş',
          'pasaj.job_finder.sort_nearest': 'En Yakın',
          'pasaj.job_finder.career_profile': 'Kariyer Profili',
          'pasaj.job_finder.detail_title': 'İş Detayı',
          'pasaj.job_finder.no_description':
              'Bu ilan için açıklama eklenmemiş.',
          'pasaj.job_finder.job_info': 'İş Tanımı',
          'pasaj.job_finder.listing_info': 'İlan Bilgileri',
          'pasaj.job_finder.application_count': 'Başvuru Sayısı',
          'pasaj.job_finder.work_type': 'Çalışma',
          'pasaj.job_finder.work_days': 'Çalışma Günleri',
          'pasaj.job_finder.work_hours': 'Çalışma Saatleri',
          'pasaj.job_finder.personnel_count': 'Alınacak Personel Sayısı',
          'pasaj.job_finder.benefits': 'Ek İmkanlar',
          'pasaj.job_finder.passive': 'Pasif',
          'pasaj.job_finder.salary_not_specified': 'Belirtilmedi',
          'pasaj.job_finder.edit_listing': 'Düzenle',
          'pasaj.job_finder.applications': 'Başvurular',
          'pasaj.job_finder.unpublish_title': 'İlanı Yayından Kaldır',
          'pasaj.job_finder.unpublish_body':
              'Bu ilanı yayından kaldırmak istediğinizden emin misiniz?',
          'pasaj.job_finder.unpublished': 'İlan yayından kaldırıldı.',
          'pasaj.job_finder.unpublish_failed': 'İlan kaldırılamadı: {error}',
          'pasaj.job_finder.already_applied':
              'Bu ilana zaten başvuru yaptınız.',
          'pasaj.job_finder.cv_required': 'Özgeçmiş Gerekli',
          'pasaj.job_finder.cv_required_body':
              'İş başvurusu yapabilmek için özgeçmişinizi doldurmanız gerekiyor.',
          'pasaj.job_finder.create_cv': 'Özgeçmiş Oluştur',
          'pasaj.job_finder.applied': 'Başvuru Yapıldı',
          'pasaj.job_finder.apply': 'Başvur',
          'pasaj.job_finder.application_cancel_title':
              'Başvuru İptali',
          'pasaj.job_finder.application_cancel_body':
              'Başvurunuzu iptal etmek istediğinizden emin misiniz?',
          'pasaj.job_finder.application_cancelled':
              'Başvurunuz iptal edildi.',
          'pasaj.job_finder.cancel_application': 'Başvuru İptal',
          'pasaj.job_finder.create_add_title': 'İlan Ekle',
          'pasaj.job_finder.create_edit_title': 'İlan Düzenle',
          'pasaj.job_finder.create.basic_info': 'Temel Bilgiler',
          'pasaj.job_finder.create.company_name': 'Firma Adı',
          'pasaj.job_finder.create.location': 'Konum',
          'pasaj.job_finder.create.job_desc': 'İş Tanımı',
          'pasaj.job_finder.create.listing_title': 'İlan Başlığı',
          'pasaj.job_finder.create.work_type': 'Çalışma Türü',
          'pasaj.job_finder.create.work_days': 'Çalışma Günleri',
          'pasaj.job_finder.create.work_hours': 'Çalışma Saatleri',
          'pasaj.job_finder.create.start': 'Başlangıç',
          'pasaj.job_finder.create.end': 'Bitiş',
          'pasaj.job_finder.create.profession': 'Meslek',
          'pasaj.job_finder.create.benefits': 'Ek İmkanlar',
          'pasaj.job_finder.create.personnel_count':
              'Alınacak Personel Sayısı',
          'pasaj.job_finder.create.salary_range': 'Maaş Aralığı',
          'pasaj.job_finder.create.min_salary': 'Min Ücret',
          'pasaj.job_finder.create.max_salary': 'Max Ücret',
          'pasaj.job_finder.create.pick_gallery': 'Galeriden Seç',
          'pasaj.job_finder.create.take_photo': 'Kameradan Çek',
          'pasaj.job_finder.create.missing_field': 'Eksik alan',
          'pasaj.job_finder.create.logo_required':
              'Firma logosu seçmeden devam edemezsiniz',
          'pasaj.job_finder.create.company_required':
              'Firma ismini girmeden devam edemezsiniz',
          'pasaj.job_finder.create.city_district_required':
              'Şehir ve ilçe seçmeden devam edemezsiniz',
          'pasaj.job_finder.create.address_required':
              'Mevcut konumunuzu kullanarak firma adresinizi belirtiniz',
          'pasaj.job_finder.create.work_type_required':
              'Çalışma türü seçmeden devam edemezsiniz',
          'pasaj.job_finder.create.profession_required':
              'Meslek seçmeden devam edemezsiniz',
          'pasaj.job_finder.create.description_required':
              'İş tanımını açıklamak zorundasınız',
          'pasaj.job_finder.create.benefits_required':
              'En az bir ek imkan seçmek zorundasın',
          'pasaj.job_finder.create.min_salary_required':
              'Minimum maaş alanını doldurmalısınız',
          'pasaj.job_finder.create.max_salary_required':
              'Maksimum maaş alanını doldurmalısınız',
          'pasaj.job_finder.create.invalid_salary_range':
              'Maksimum maaş, minimum maaştan düşük olamaz',
          'pasaj.job_finder.create.crop_use': 'Kırp ve Kullan',
          'pasaj.job_finder.create.select_district': 'İlçe Seç',
          'pasaj.job_finder.image_security_failed':
              'Görsel güvenlik kontrolü tamamlanamadı',
          'pasaj.job_finder.image_nsfw_detected':
              'Uygunsuz görsel tespit edildi',
          'pasaj.job_finder.day.monday': 'Pazartesi',
          'pasaj.job_finder.day.tuesday': 'Salı',
          'pasaj.job_finder.day.wednesday': 'Çarşamba',
          'pasaj.job_finder.day.thursday': 'Perşembe',
          'pasaj.job_finder.day.friday': 'Cuma',
          'pasaj.job_finder.day.saturday': 'Cumartesi',
          'pasaj.job_finder.day.sunday': 'Pazar',
          'pasaj.job_finder.benefit.meal': 'Yemek',
          'pasaj.job_finder.benefit.road_fee': 'Yol Ücreti',
          'pasaj.job_finder.benefit.shuttle': 'Servis',
          'pasaj.job_finder.benefit.bonus': 'Prim',
          'pasaj.job_finder.benefit.private_health':
              'Özel Sağlık Sigortası',
          'pasaj.job_finder.benefit.retirement':
              'Bireysel Emeklilik',
          'pasaj.job_finder.benefit.flexible_hours':
              'Esnek Çalışma Saatleri',
          'pasaj.job_finder.benefit.remote_work': 'Uzaktan Çalışma',
          'pasaj.job_finder.my_applications': 'Başvurularım',
          'pasaj.job_finder.no_applications':
              'Henüz başvuru yapmadınız',
          'pasaj.job_finder.default_job_title': 'İş İlanı',
          'pasaj.job_finder.default_company': 'Firma',
          'pasaj.job_finder.cancel_apply_title': 'Başvuruyu İptal Et',
          'pasaj.job_finder.cancel_apply_body':
              'Bu başvuruyu iptal etmek istediğinize emin misiniz?',
          'pasaj.job_finder.saved_jobs': 'Kaydedilenler',
          'pasaj.job_finder.no_saved_jobs': 'Kaydedilen ilan yok.',
          'pasaj.job_finder.my_ads': 'İlanlarım',
          'pasaj.job_finder.published_tab': 'Yayında',
          'pasaj.job_finder.expired_tab': 'Süresi Doldu',
          'pasaj.job_finder.no_my_ads': 'İlan Bulunamadı',
          'pasaj.job_finder.finding_platform': 'İş Arıyorum Platformu',
          'pasaj.job_finder.finding_how':
              'İş Arıyorum Platformu Nasıl Çalışır ?',
          'pasaj.job_finder.finding_body':
              'Özgeçmişiniz, onayınız doğrultusunda işverenlerle paylaşılacaktır. İşverenler, ilan yayınlamadan önce ihtiyaç duydukları pozisyonlara uygun adayları sistemimiz üzerinden inceleyebilir. Böylece hem işverenler aradıkları çalışanlara daha hızlı ulaşabilir hem de siz iş arayanlar daha kısa sürede iş fırsatlarına erişebilirsiniz. Amacımız, işe alım sürecini her iki taraf için de daha hızlı ve etkili hale getirmektir.',
          'pasaj.job_finder.looking_for_job': 'İş Arıyorum',
          'pasaj.job_finder.professional_profile': 'Profesyonel Profil',
          'pasaj.job_finder.experience': 'İş Deneyimi',
          'pasaj.job_finder.education': 'Eğitim',
          'pasaj.job_finder.languages': 'Diller',
          'pasaj.job_finder.skills': 'Beceriler',
          'pasaj.job_finder.edit_cv': 'CV Düzenle',
          'pasaj.job_finder.no_cv_title': 'Henüz bir CV oluşturmadınız',
          'pasaj.job_finder.no_cv_body':
              'CV oluşturarak iş başvurularınızı hızlandırın',
          'pasaj.job_finder.applicants': 'Başvuranlar',
          'pasaj.job_finder.no_applicants': 'Henüz başvuru yok',
          'pasaj.job_finder.unknown_user': 'Bilinmeyen Kullanıcı',
          'pasaj.job_finder.view_cv': 'CV Görüntüle',
          'pasaj.job_finder.review': 'İncele',
          'pasaj.job_finder.accept': 'Kabul Et',
          'pasaj.job_finder.reject': 'Reddet',
          'pasaj.job_finder.cv_not_found_title': 'CV Bulunamadı',
          'pasaj.job_finder.cv_not_found_body':
              'Bu kullanıcı için kayıtlı bir CV bulunamadı.',
          'pasaj.job_finder.status.pending': 'Bekliyor',
          'pasaj.job_finder.status.reviewing': 'İnceleniyor',
          'pasaj.job_finder.status.accepted': 'Kabul Edildi',
          'pasaj.job_finder.status.rejected': 'Reddedildi',
          'pasaj.job_finder.status_updated':
              'Başvuru durumu güncellendi.',
          'pasaj.job_finder.status_update_failed':
              'Başvuru durumu güncellenemedi.',
          'pasaj.job_finder.relogin_required':
              'İşlem için tekrar giriş yapın.',
          'pasaj.job_finder.save_failed': 'Kaydetme işlemi başarısız.',
          'pasaj.job_finder.share_auth_required':
              'Sadece admin ve ilan sahibi paylaşabilir.',
          'pasaj.job_finder.review_relogin_required':
              'Değerlendirme için tekrar giriş yapın.',
          'pasaj.job_finder.review_own_forbidden':
              'Kendi ilanınızı değerlendiremezsiniz.',
          'pasaj.job_finder.review_saved':
              'Değerlendirmeniz kaydedildi.',
          'pasaj.job_finder.review_save_failed':
              'Değerlendirme kaydedilemedi.',
          'pasaj.job_finder.review_deleted':
              'Değerlendirmeniz kaldırıldı.',
          'pasaj.job_finder.review_delete_failed':
              'Değerlendirme kaldırılamadı.',
          'pasaj.job_finder.open_in_maps': 'Haritalarda Aç',
          'pasaj.job_finder.open_google_maps':
              'Google Haritalar\'da Aç',
          'pasaj.job_finder.open_apple_maps':
              'Apple Haritalar\'da Aç',
          'pasaj.job_finder.open_yandex_maps':
              'Yandex Haritalar\'da Aç',
          'pasaj.job_finder.map_load_failed': 'Harita yüklenemedi',
          'pasaj.job_finder.open_maps_help':
              'Konumu haritalarda açmak için dokun.',
          'pasaj.job_finder.application_sent': 'Başvurun gönderildi.',
          'pasaj.job_finder.application_failed':
              'Başvuru sırasında bir sorun oluştu.',
          'pasaj.job_finder.listing_not_found': 'İlan bulunamadı',
          'pasaj.job_finder.reactivated':
              'İlan tekrar yayına alındı.',
          'pasaj.job_finder.sort_title': 'Sıralama',
          'pasaj.job_finder.sort_newest': 'En Yeni',
          'pasaj.job_finder.sort_nearest_me': 'Bana En Yakın',
          'pasaj.job_finder.sort_most_viewed': 'En Çok Görüntülenen',
          'pasaj.job_finder.clear_filters': 'Filtreleri Temizle',
          'pasaj.job_finder.select_city': 'Şehir Seç',
          'pasaj.job_finder.work_type.full_time': 'Tam Zamanlı',
          'pasaj.job_finder.work_type.part_time': 'Yarı Zamanlı',
          'pasaj.job_finder.work_type.remote': 'Uzaktan',
          'pasaj.job_finder.work_type.hybrid': 'Hibrit',
          'pasaj.market.title': 'Market',
          'pasaj.market.contact_phone': 'Telefon',
          'pasaj.market.contact_message': 'Mesaj',
          'pasaj.market.min_price': 'Min {value}',
          'pasaj.market.max_price': 'Max {value}',
          'pasaj.market.sort_price_asc': 'Fiyat Artan',
          'pasaj.market.sort_price_desc': 'Fiyat Azalan',
          'pasaj.market.all_listings': 'Tüm İlanlar',
          'pasaj.market.main_categories': 'Ana kategoriler',
          'pasaj.market.category_search_hint':
              'Ana kategori, alt kategori, marka ara',
          'pasaj.market.call_now': 'Hemen Ara',
          'pasaj.market.inspect': 'İncele',
          'pasaj.market.empty_filtered': 'Bu filtrede ilan bulunamadı.',
          'pasaj.market.add_listing': 'İlan Ekle',
          'pasaj.market.my_listings': 'İlanlarım',
          'pasaj.market.saved_items': 'Beğendiklerim',
          'pasaj.market.my_offers': 'Tekliflerim',
          'pasaj.market.menu.create': 'İlan Ekle',
          'pasaj.market.menu.my_items': 'İlanlarım',
          'pasaj.market.menu.saved': 'Beğendiklerim',
          'pasaj.market.menu.offers': 'Tekliflerim',
          'pasaj.market.menu.categories': 'Kategoriler',
          'pasaj.market.menu.nearby': 'Yakınımdakiler',
          'pasaj.market.category.electronics': 'Elektronik',
          'pasaj.market.category.phone': 'Telefon',
          'pasaj.market.category.computer': 'Bilgisayar',
          'pasaj.market.category.gaming_electronics': 'Oyun Elektroniği',
          'pasaj.market.category.clothing': 'Giyim',
          'pasaj.market.category.home_living': 'Ev & Yaşam',
          'pasaj.market.category.sports': 'Spor',
          'pasaj.market.category.real_estate': 'Emlak',
          'pasaj.market.detail_title': 'İlan Detayı',
          'pasaj.market.report_listing': 'İlanı Bildir',
          'pasaj.market.report_reason': 'Lütfen bir neden seç.',
          'pasaj.market.no_description':
              'Bu ilan için açıklama eklenmemiş.',
          'pasaj.market.listing_info': 'İlan Bilgileri',
          'pasaj.market.phone_and_message': 'Telefon + Mesaj',
          'pasaj.market.message_only': 'Sadece Mesaj',
          'pasaj.market.saved_count': 'Kaydeden',
          'pasaj.market.offer_count': 'Teklif',
          'pasaj.market.default_seller': 'Turq Kullanıcı',
          'pasaj.market.owner_hint':
              'Bu ilan sana ait. Buradan düzenleyebilir veya paylaşabilirsin.',
          'pasaj.market.messages': 'Mesajlar',
          'pasaj.market.offers': 'Teklifler',
          'pasaj.market.related_listings': 'Benzer İlanlar',
          'pasaj.market.no_related':
              'Bu kategori için başka ilan bulunamadı.',
          'pasaj.market.report_received_title': 'Talebiniz Bize Ulaştı!',
          'pasaj.market.report_received_body':
              'İlan inceleme altına alındı. Teşekkür ederiz.',
          'pasaj.market.report_failed': 'İlan bildirimi gönderilemedi.',
          'pasaj.market.invalid_offer': 'Geçerli bir teklif seç.',
          'pasaj.market.offer_sent': 'Teklif gönderildi.',
          'pasaj.market.offer_own_forbidden':
              'Kendi ilanına teklif veremezsin.',
          'pasaj.market.offer_daily_limit':
              'Bir günde en fazla 20 teklif yapabilirsin.',
          'pasaj.market.offer_failed': 'Teklif gönderilemedi.',
          'pasaj.market.custom_offer': 'Teklifini Kendin Belirle',
          'pasaj.market.discount': '%{value} indirim',
          'pasaj.market.reviews': 'Değerlendirmeler',
          'pasaj.market.rate': 'Değerlendir',
          'pasaj.market.review_edit': 'Düzenle',
          'pasaj.market.no_reviews': 'Henüz değerlendirme yok.',
          'pasaj.market.sign_in_to_review':
              'Değerlendirme yapmak için giriş yapmalısın.',
          'pasaj.market.review_comment_hint': 'Yorumunuzu yazın',
          'pasaj.market.select_rating': 'Lütfen bir puan seçin.',
          'pasaj.market.review_saved': 'Değerlendirmeniz kaydedildi.',
          'pasaj.market.review_updated':
              'Değerlendirmeniz güncellendi.',
          'pasaj.market.review_own_forbidden':
              'Kendi ilanını değerlendiremezsin.',
          'pasaj.market.review_failed': 'Değerlendirme gönderilemedi.',
          'pasaj.market.review_deleted': 'Değerlendirmeniz kaldırıldı.',
          'pasaj.market.review_delete_failed':
              'Değerlendirme kaldırılamadı.',
          'pasaj.market.location_missing': 'Konum belirtilmedi',
          'pasaj.market.status.sold': 'Satıldı',
          'pasaj.market.status.draft': 'Taslak',
          'pasaj.market.status.archived': 'Arşiv',
          'pasaj.market.status.reserved': 'Rezerve',
          'pasaj.market.status.active': 'Aktif',
          'pasaj.market.create.images': 'Görseller',
          'pasaj.market.create.basic_info': 'Temel Bilgiler',
          'pasaj.market.create.pick_category': 'Bir kategori seçmelisin.',
          'pasaj.market.create.title_required': 'Başlık gerekli.',
          'pasaj.market.create.title_hint': 'Başlık',
          'pasaj.market.create.description_hint': 'Açıklama',
          'pasaj.market.create.price_hint': 'Fiyat (TL)',
          'pasaj.market.create.location': 'Konum',
          'pasaj.market.create.category': 'Kategori',
          'pasaj.market.create.features': 'İlan Özellikleri',
          'pasaj.market.create.contact_preference':
              'İletişim Tercihi',
          'pasaj.market.create.fields_after_category':
              'Kategori seçimlerini tamamlayınca bu alanlar açılır.',
          'pasaj.market.create.no_extra_fields':
              'Bu kategori için ek alan tanımlı değil.',
          'pasaj.market.create.main_category': 'Ana kategori',
          'pasaj.market.create.main_category_search':
              'Ana kategori, alt kategori, marka ara',
          'pasaj.market.create.no_subcategory':
              'Bu ana kategori altında seçim yapılabilir alt kategori yok.',
          'pasaj.market.create.subcategory': 'Alt kategori',
          'pasaj.market.create.subgroup': 'Alt grup',
          'pasaj.market.create.product_type': 'Ürün tipi',
          'pasaj.market.create.level': '{value}. kademe',
          'pasaj.market.create.select_image':
              'Görsel Seç ({current}/{max})',
          'pasaj.market.create.cover': 'Kapak',
          'pasaj.market.empty_my_listings': 'Bu durumda ilan bulunamadı.',
          'pasaj.market.status_update_failed':
              'İlan durumu güncellenemedi.',
          'pasaj.market.marked_sold': 'İlan satıldı olarak işaretlendi.',
          'pasaj.market.marked_active': 'İlan aktif duruma alındı.',
          'pasaj.market.saved_empty': 'Beğenilen ilan bulunamadı.',
          'pasaj.market.removed_saved': 'Beğenilenlerden kaldırıldı.',
          'pasaj.market.unsave_failed': 'Kayıt kaldırılamadı.',
          'pasaj.market.offers_title': 'Tekliflerim',
          'pasaj.market.sent_tab': 'Verdiğim',
          'pasaj.market.received_tab': 'Aldığım',
          'pasaj.market.sent_offer': 'Verdiğim teklif',
          'pasaj.market.received_offer': 'Aldığım teklif',
          'pasaj.market.offer_empty': '{subtitle} bulunamadı.',
          'pasaj.market.offer_accepted': 'Teklif kabul edildi.',
          'pasaj.market.offer_rejected': 'Teklif reddedildi.',
          'pasaj.market.offer_already_processed':
              'Bu teklif daha önce işleme alınmış.',
          'pasaj.market.offer_update_failed': 'Teklif güncellenemedi.',
          'pasaj.market.listing_unavailable':
              'Bu ilana şu anda erişilemiyor.',
          'pasaj.market.filter.title': 'Filtreler',
          'pasaj.market.filter.all_cities': 'Tüm Şehirler',
          'pasaj.market.filter.search_city': 'Şehir ara',
          'pasaj.market.filter.price_range': 'Fiyat Aralığı',
          'pasaj.market.filter.min': 'Min',
          'pasaj.market.filter.max': 'Max',
          'pasaj.market.filter.sort': 'Sıralama',
          'pasaj.market.filter.newest': 'Yeni',
          'pasaj.market.filter.ascending': 'Artan',
          'pasaj.market.filter.descending': 'Azalan',
          'pasaj.market.filter.apply': 'Uygula',
          'pasaj.market.search_hint': 'İlan ara',
          'pasaj.market.search.no_results_body':
              'Aramana uygun ilan bulunmuyor.',
          'pasaj.market.search.result_count': '{count} sonuç',
          'pasaj.market.search.start_title': 'İlan aramaya başla',
          'pasaj.market.search.start_body':
              'Son aramaların burada görünecek.',
          'pasaj.market.search.recent': 'Son Aramalar',
          'pasaj.market.sign_in_required_title': 'Giriş Gerekli',
          'pasaj.market.sign_in_to_save': 'Kaydetmek için giriş yapmalısın.',
          'pasaj.market.saved_success': 'İlan kaydedildi.',
          'pasaj.market.unsaved': 'Kayıt kaldırıldı.',
          'pasaj.market.save_failed': 'Kaydetme işlemi tamamlanamadı.',
          'pasaj.market.coming_soon_title': 'Yakında',
          'pasaj.market.coming_soon_body': '{title} yakında eklenecek.',
          'pasaj.market.permission_required_title': 'İzin Gerekli',
          'pasaj.market.nearby_permission_required':
              'Yakınındaki ilanlar için konum izni gerekli.',
          'pasaj.market.location_not_found_title': 'Konum Bulunamadı',
          'pasaj.market.city_not_found': 'Şehir bilgisi alınamadı.',
          'pasaj.market.limited_results_title': 'Sınırlı Sonuç',
          'pasaj.market.no_city_results': '{city} için ilan bulunamadı.',
          'pasaj.market.nearby_ready':
              '{city} için yakınındaki ilanlar gösteriliyor.',
          'pasaj.market.nearby_failed':
              'Yakınındaki ilanlar yüklenemedi.',
          'pasaj.market.limit_title': 'Sınır',
          'pasaj.market.image_limit':
              'En fazla {max} görsel ekleyebilirsin.',
          'pasaj.market.create.need_image':
              'Yayınlamak için en az bir görsel ekle.',
          'pasaj.market.create.invalid_price':
              'Geçerli bir fiyat gir.',
          'pasaj.market.create.city_district_required_short':
              'Şehir ve ilçe seçimi gerekli.',
          'pasaj.market.create.field_required':
              '{field} alanı gerekli.',
          'pasaj.market.user_session_not_found':
              'Kullanıcı oturumu bulunamadı.',
          'pasaj.market.create.save_failed':
              'İlan kaydedilemedi: {error}',
          'pasaj.market.image_security_failed':
              'Görsel güvenlik kontrolü tamamlanamadı',
          'pasaj.market.image_nsfw_detected':
              'Uygunsuz görsel tespit edildi',
          'pasaj.market.create.add_title': 'İlan Ekle',
          'pasaj.market.create.edit_title': 'İlan Düzenle',
          'pasaj.market.create.update_draft': 'Taslak Güncelle',
          'pasaj.market.status.pending': 'Bekliyor',
          'pasaj.market.status.accepted': 'Kabul Edildi',
          'pasaj.market.status.rejected': 'Reddedildi',
          'pasaj.market.status.cancelled': 'İptal Edildi',
          'account_center.header_title': 'Profiller ve giriş bilgileri',
          'account_center.accounts': 'Hesaplar',
          'account_center.no_accounts':
              'Henüz bu cihaza eklenmiş bir hesap yok.',
          'account_center.add_account': 'Hesap ekle',
          'account_center.personal_details': 'Kişisel detaylar',
          'account_center.security': 'Güvenlik',
          'account_center.active_account_title': 'Aktif Hesap',
          'account_center.active_account_body': '@{username} zaten aktif.',
          'account_center.reauth_title': 'Tekrar Giriş Gerekli',
          'account_center.reauth_body':
              '@{username} hesabı için şifrenle yeniden giriş yapman gerekiyor.',
          'account_center.switch_failed_title': 'Geçiş yapılamadı',
          'account_center.switch_failed_body':
              'Bu hesap için önce bir kez normal giriş yapılması gerekiyor.',
          'account_center.remove_active_forbidden':
              'Aktif hesabı burada silemezsin. Önce başka hesaba geç.',
          'account_center.remove_account_title': 'Hesabı Kaldır',
          'account_center.remove_account_body':
              '@{username} hesabını bu cihazdaki kayıtlı hesaplardan kaldırmak istiyor musun?',
          'account_center.account_removed': '@{username} kaldırıldı.',
          'account_center.single_device_title':
              'Yeni girişte diğer telefonlardan çıkış yap',
          'account_center.single_device_desc':
              'Bu ayar açıksa başka bir telefondan giriş yapıldığında bu cihazdaki oturum kapanır. Yeniden giriş için şifre gerekir.',
          'account_center.single_device_enabled':
              'Yeni cihazdan girişte diğer telefonlardan çıkış yapılacak.',
          'account_center.single_device_disabled':
              'Hesap aynı anda birden fazla telefonda açık kalabilir.',
          'account_center.no_personal_detail':
              'Henüz gösterilecek bir kişisel detay yok.',
          'account_center.contact_details': 'İletişim Bilgileri',
          'account_center.contact_info': 'İletişim bilgileri',
          'account_center.email': 'E-posta',
          'account_center.phone': 'Telefon',
          'account_center.email_missing': 'E-posta eklenmedi',
          'account_center.phone_missing': 'Telefon eklenmedi',
          'account_center.verified': 'Onaylı',
          'account_center.verify': 'Onayla',
          'account_center.unverified': 'Onaysız',
          'about_profile.title': 'Bu Hesap Hakkında',
          'about_profile.description':
              'Topluluğumuzun güvenilirliğini artırmak için TurqApp\'taki hesaplarla ilgili bilgileri şeffaf bir şekilde paylaşıyoruz.',
          'about_profile.joined_on': '{date} tarihinde katıldı',
          'policies.center_title': 'Politika Merkezi',
          'policies.center_desc':
              'Sözleşme, gizlilik, topluluk ve güvenlik metinleri burada yer alır.',
          'policies.last_updated': 'Son güncelleme: {date}',
          'permissions.title': 'Cihaz İzinleri',
          'permissions.preferences': 'Tercihlerin',
          'permissions.offline_space': 'Çevrimdışı İzleme Alanı',
          'permissions.offline_space_desc':
              'Seçtiğiniz GB kadar içerik cihazınıza indirilir ve internet bağlantısı olmadan izlenebilir. Alan doldukça eski videolar otomatik olarak silinir.',
          'permissions.allowed': 'İzin verildi',
          'permissions.denied': 'İzin verilmedi',
          'permissions.enable': 'İzinleri aç',
          'permissions.enable_location': 'Konum Servisleri\'ni Aç',
          'permissions.checking': 'Kontrol ediliyor...',
          'permissions.dialog.update_device_settings':
              'Cihaz ayarlarını güncelle',
          'permissions.dialog.update_body':
              'Cihaz ayarlarını aç, "{title}" iznini dilediğin zaman güncelleyebilirsin.',
          'permissions.dialog.open_settings': 'Cihaz ayarlarını aç',
          'permissions.dialog.not_now': 'Şimdi değil',
          'permissions.quota.media_cache': 'Medya cache',
          'permissions.quota.image_cache': 'Görsel cache',
          'permissions.quota.metadata': 'Metadata',
          'permissions.quota.reserve': 'Yedek alan',
          'permissions.quota.os_safety': 'OS güvenlik payı',
          'permissions.quota.plan_distribution': '{gb} GB plan dağılımı',
          'permissions.quota.soft_stop': 'Stream cache soft stop',
          'permissions.quota.hard_stop': 'Stream cache hard stop',
          'permissions.quota.recent_window':
              'Yakın video koruma penceresi: {count} içerik',
          'permissions.quota.active_stream': 'Aktif stream kullanım',
          'permissions.quota.soft_remaining': 'Soft stop kalan',
          'permissions.quota.hard_remaining': 'Hard stop kalan',
          'permissions.playback.title': 'Veri ve Playback Tercihleri',
          'permissions.playback.help':
              'Sistem cache planına göre çalışır; burada sadece Wi-Fi ve mobil veri davranışının ne kadar korumacı olacağını seçersin.',
          'permissions.playback.limit_cellular':
              'Mobil veride cache ile sınırla',
          'permissions.playback.limit_cellular_desc':
              'Açıksa mobil veride yeni segment çekmek yerine önce eldeki cache kullanılır.',
          'permissions.playback.cellular_mode': 'Mobil veri playback modu',
          'permissions.playback.cellular_mode_desc':
              'Cellular guard altında ne kadar agresif prefetch ve kalite kullanılacağını belirler.',
          'permissions.playback.wifi_mode': 'Wi-Fi playback modu',
          'permissions.playback.wifi_mode_desc':
              'Wi-Fi full sırasında startup ve ahead window davranışının ne kadar geniş olacağını belirler.',
          'permissions.detail.set_preferences': 'Tercihlerini belirle',
          'permissions.detail.preference_body':
              'TurqApp\'ın {access} izin verip vermeyeceğine karar verebilirsin. Tercihini daha sonra dilediğin zaman değiştirebilirsin. {title} uygulamanın bazı özelliklerini iyileştirir.',
          'permissions.detail.device_setting': 'Cihaz ayarın:',
          'permissions.detail.other_option': 'Diğer seçenek',
          'permissions.detail.allowed_desc':
              'TurqApp\'a {access} izin verilmiş.',
          'permissions.detail.denied_desc':
              'TurqApp\'a {access} izin verilmemiş.',
          'permissions.detail.go_device_settings':
              'İzinlerini güncellemek için cihaz ayarlarına git.',
          'permissions.item.camera.title': 'Kamera',
          'permissions.item.camera.access': 'kamerasına',
          'permissions.item.camera.help_text':
              'Cihazınızın kamerasını nasıl kullanırız?',
          'permissions.item.camera.help_sheet_title':
              'Cihazının kamerasını nasıl kullanırız?',
          'permissions.item.camera.help_sheet_body':
              'TurqApp, fotoğraf çekmek, video kaydetmek ve görsel/işitsel efektleri önizlemek gibi özellikleri kullanman için kamera erişimini kullanır.',
          'permissions.item.camera.help_sheet_body2':
              'Kameranı nasıl kullandığımız hakkında daha fazla bilgiyi Gizlilik Merkezi\'nden alabilirsin.',
          'permissions.item.camera.help_sheet_link': 'Gizlilik Merkezi',
          'permissions.item.contacts.title': 'Kişiler',
          'permissions.item.contacts.access': 'kişilerine',
          'permissions.item.contacts.help_text':
              'Cihazınızın kişilerini nasıl kullanırız?',
          'permissions.item.contacts.help_sheet_title':
              'Cihazının kişilerini nasıl kullanırız?',
          'permissions.item.contacts.help_sheet_body':
              'TurqApp, tanıdığın kişilerle daha kolay bağlantı kurmana yardımcı olmak ve kişi önerilerini iyileştirmek için bu bilgileri kullanır.',
          'permissions.item.contacts.help_sheet_link': 'Daha fazla bilgi al',
          'permissions.item.location.title': 'Konum Servisleri',
          'permissions.item.location.access': 'konumuna',
          'permissions.item.location.help_text':
              'Cihazınızın konumunu nasıl kullanırız?',
          'permissions.item.location.help_sheet_title':
              'Cihazının konumunu nasıl kullanırız?',
          'permissions.item.location.help_sheet_body':
              'TurqApp, yakınındaki yerleri keşfetmek, gönderi/hikayelerde konum etiketlemek ve güvenlik özelliklerini iyileştirmek için konum bilgisini kullanır.',
          'permissions.item.location.help_sheet_body2':
              'Konum bilgilerini nasıl kullandığımız hakkında daha fazla bilgiyi Gizlilik Merkezi\'nden alabilirsin.',
          'permissions.item.location.help_sheet_link': 'Gizlilik Merkezi',
          'permissions.item.microphone.title': 'Mikrofon',
          'permissions.item.microphone.access': 'mikrofonuna',
          'permissions.item.microphone.help_text':
              'Cihazınızın mikrofonunu nasıl kullanırız?',
          'permissions.item.microphone.help_sheet_title':
              'Cihazının mikrofonunu nasıl kullanırız?',
          'permissions.item.microphone.help_sheet_body':
              'TurqApp, video kaydında ses almak ve efektleri önizlemek gibi özellikler için mikrofon erişimini kullanır.',
          'permissions.item.microphone.help_sheet_body2':
              'Mikrofonu nasıl kullandığımız hakkında daha fazla bilgiyi Gizlilik Merkezi\'nden alabilirsin.',
          'permissions.item.microphone.help_sheet_link':
              'Gizlilik Merkezi',
          'permissions.item.notifications.title': 'Bildirimler',
          'permissions.item.notifications.access':
              'anlık bildirim göndermesine',
          'permissions.item.notifications.help_text':
              'Cihazınızın bildirimlerini nasıl kullanırız?',
          'permissions.item.notifications.help_sheet_title':
              'Cihazının bildirimlerini nasıl kullanırız?',
          'permissions.item.notifications.help_sheet_body':
              'TurqApp, hesabında yeni hareketler olduğunda anlık bildirim göndermek için bildirim iznini kullanır.',
          'permissions.item.notifications.help_sheet_body2':
              'Bildirimleri nasıl kullandığımız hakkında daha fazla bilgiyi Şeffaflık Merkezi\'nden alabilirsin.',
          'permissions.item.notifications.help_sheet_link':
              'Şeffaflık Merkezi',
          'permissions.item.photos.title': 'Fotoğraflar',
          'permissions.item.photos.access':
              'fotoğraf ve videolarına erişmesine',
          'permissions.item.photos.help_text':
              'Cihazınızın fotoğraflarını nasıl kullanırız?',
          'permissions.item.photos.help_sheet_title':
              'Cihazının fotoğraflarını nasıl kullanırız?',
          'permissions.item.photos.help_sheet_body':
              'TurqApp, galerinden fotoğraf/video seçip paylaşabilmen ve düzenleme araçlarını kullanabilmen için fotoğraf erişimini kullanır.',
          'admin.no_access': 'Bu alan sadece admin erişimine açıktır.',
          'admin.support.title': 'Kullanıcı Destek',
          'admin.support.close_message': 'Mesajı Kapat',
          'admin.support.answer_message': 'Mesajı Yanıtla',
          'admin.support.note': 'Admin notu',
          'admin.support.empty': 'Henüz destek mesajı yok.',
          'admin.support.updated_title': 'Güncellendi',
          'admin.support.updated_body': 'Destek mesajı güncellendi.',
          'admin.support.open': 'Açık',
          'admin.support.answered': 'Yanıtlandı',
          'admin.support.closed': 'Kapatıldı',
          'admin.support.mark_answered': 'Yanıtlandı',
          'admin.support.close': 'Kapat',
          'admin.approvals.title': 'Admin Onayları',
          'admin.approvals.empty': 'Bekleyen admin onayı yok.',
          'admin.approvals.default_title': 'Admin Onayı',
          'admin.approvals.created_by': 'Oluşturan',
          'admin.approvals.rejection_reason': 'Red nedeni',
          'admin.approvals.approve': 'Onayla',
          'admin.approvals.reject': 'Reddet',
          'admin.approvals.approved': 'Onaylandı',
          'admin.approvals.rejected': 'Reddedildi',
          'admin.approvals.pending': 'Bekliyor',
          'admin.approvals.approved_body': 'İşlem onaylandı.',
          'admin.approvals.rejected_body': 'İşlem reddedildi.',
          'admin.approvals.approve_failed': 'Onay işlemi tamamlanamadı:',
          'admin.approvals.reject_failed': 'İşlem reddedilemedi:',
          'admin.my_approvals.title': 'Onay Sonuçlarım',
          'admin.my_approvals.load_failed': 'Onay kayıtları alınamadı.',
          'admin.my_approvals.empty': 'Henüz bir onay talebin yok.',
          'admin.my_approvals.default_title': 'Onay Talebi',
          'admin.my_approvals.requested': 'Talep',
          'admin.my_approvals.result': 'Sonuç',
          'admin.tasks.title': 'Admin Görevleri',
          'admin.tasks.editor_title': 'Kullanıcı adına göre görev ata',
          'admin.tasks.editor_help':
              'Kullanıcı adını yaz, kişiyi yükle ve görev kutularını işaretleyip kaydet. Bu ekran görev dağıtımını tek yerden takip etmek için kullanılır.',
          'admin.tasks.username': 'Kullanıcı adı',
          'admin.tasks.username_hint': '@kullaniciadi',
          'admin.tasks.load': 'Yükle',
          'admin.tasks.task_list': 'Görevler',
          'admin.tasks.saving': 'Kaydediliyor',
          'admin.tasks.save': 'Görevleri Kaydet',
          'admin.tasks.clear': 'Temizle',
          'admin.tasks.assignments': 'Görev Atamaları',
          'admin.tasks.assignments_help':
              'Burada tüm admin görev dağılımını tek listede görürüz. Bir karta dokununca üstte düzenlemeye gelir.',
          'admin.tasks.no_assignments': 'Henüz görev ataması yok.',
          'admin.tasks.missing_info': 'Eksik Bilgi',
          'admin.tasks.username_required': 'Kullanıcı adı zorunludur.',
          'admin.tasks.not_found': 'Bulunamadı',
          'admin.tasks.user_not_found':
              'Bu kullanıcı adı ile kullanıcı bulunamadı.',
          'admin.tasks.load_failed': 'Kullanıcı yüklenemedi:',
          'admin.tasks.load_user_first': 'Önce kullanıcıyı yükle.',
          'admin.tasks.assignment_removed':
              '@{nickname} için görev ataması kaldırıldı.',
          'admin.tasks.saved':
              '@{nickname} için görevler kaydedildi.',
          'admin.tasks.save_failed': 'Görevler kaydedilemedi:',
          'admin.tasks.cleared':
              '@{nickname} için görevler temizlendi.',
          'admin.tasks.clear_failed': 'Görevler temizlenemedi:',
          'admin.tasks.updated_at': 'Güncelleme',
          'admin.task.moderation.title': 'Moderasyon',
          'admin.task.moderation.desc':
              'Flag, rapor ve içerik eşiklerini yönetir.',
          'admin.task.reports.title': 'Raporlar',
          'admin.task.reports.desc':
              'Kullanıcı ve içerik raporlarını inceler.',
          'admin.task.badges.title': 'Rozet Yönetimi',
          'admin.task.badges.desc':
              'Rozet başvurularını inceler ve rozet verir.',
          'admin.task.approvals.title': 'Onay / Başvurular',
          'admin.task.approvals.desc':
              'Rozet ve benzeri başvuru-onay kuyruklarını takip eder.',
          'admin.task.user_bans.title': 'Ban Yönetimi',
          'admin.task.user_bans.desc':
              'Kullanıcı banlarını uygular veya kaldırır.',
          'admin.task.admin_push.title': 'Admin Push',
          'admin.task.admin_push.desc':
              'Toplu bildirim ve sistem duyurularını gönderir.',
          'admin.task.ads_center.title': 'Reklam Merkezi',
          'admin.task.ads_center.desc':
              'Reklam ve kampanya operasyonlarını yönetir.',
          'admin.task.story_music.title': 'Hikaye Müzikleri',
          'admin.task.story_music.desc':
              'Hikaye müziği kataloglarını yönetir.',
          'admin.task.pasaj.title': 'Pasaj Operasyonu',
          'admin.task.pasaj.desc':
              'Pasaj tarafındaki içerik ve akışları takip eder.',
          'admin.task.support.title': 'Kullanıcı Destek',
          'admin.task.support.desc':
              'Kullanıcı taleplerini ve geri bildirimleri takip eder.',
          'admin.moderation.title': 'Moderasyon',
          'admin.moderation.config_updated':
              'Config güncellendi. Eşik: {threshold}',
          'admin.moderation.config_failed': 'Config güncellenemedi',
          'admin.moderation.threshold_posts':
              'Eşik Değeri Aşan Postlar (≥ {threshold})',
          'admin.moderation.list_failed': 'Moderasyon listesi alınamadı.',
          'admin.moderation.no_threshold_posts':
              'Eşiği aşan post bulunmuyor.',
          'admin.moderation.no_text': 'Metin yok',
          'admin.moderation.provisioning': 'Kuruluyor...',
          'admin.moderation.ensure_config': 'Config Kur/Yenile',
          'admin.moderation.user_ban_title': 'Kullanıcı Ban Yönetimi',
          'admin.moderation.user_ban_help':
              '1. ihlal: 1 ay, 2. ihlal: 3 ay, 3. ihlal: kalıcı yasak. Geçici cezada kullanıcı sadece gezebilir, beğeni bırakabilir ve yeniden paylaşım yapabilir.',
          'admin.moderation.ban_reason': 'Ban nedeni',
          'admin.moderation.apply_next_penalty': 'Sonraki Cezayı Uygula',
          'admin.moderation.active_bans': 'Aktif Banlar',
          'admin.moderation.ban_list_failed': 'Ban listesi alınamadı.',
          'admin.moderation.no_active_bans': 'Aktif banlı kullanıcı yok.',
          'admin.moderation.permanent': 'Kalıcı',
          'admin.moderation.expired': 'Süresi Doldu',
          'admin.moderation.level': 'Seviye {level}',
          'admin.moderation.strike_status':
              'Strike: {count} • Durum: {status}',
          'admin.moderation.ends_at': 'Bitiş: {date}',
          'admin.moderation.next_penalty': 'Bir Sonraki Ceza',
          'admin.moderation.clear_ban': 'Banı Kaldır',
          'admin.moderation.clear_ban_approval': 'Ban kaldırma onayı',
          'admin.moderation.ban_approval': 'Ban işlemi onayı',
          'admin.moderation.clear_ban_summary':
              '@{nickname} için ban kaldırma talebi oluşturuldu.',
          'admin.moderation.advance_penalty_summary':
              '@{nickname} için sonraki ceza talebi oluşturuldu.',
          'admin.moderation.sent_for_approval':
              'İşlem admin onay kuyruğuna gönderildi.',
          'admin.moderation.ban_removed': '@{nickname} için ban kaldırıldı.',
          'admin.moderation.permanent_applied':
              '@{nickname} için kalıcı yasak uygulandı.',
          'admin.moderation.level_applied':
              '@{nickname} için seviye {level} ceza uygulandı.',
          'admin.moderation.action_failed': 'Ban işlemi tamamlanamadı.',
          'admin.badges.title': 'Rozet Yönetimi',
          'admin.badges.manage_by_username': 'Kullanıcı adı ile rozet yönet',
          'admin.badges.manage_help':
              'Kullanıcı adını gir, rozeti seç ve kaydet. `Rozetsiz` seçimi mevcut rozeti kaldırır.',
          'admin.badges.no_badge': 'Rozetsiz',
          'admin.badges.badge_label': 'Rozet',
          'admin.badges.save_badge': 'Rozeti Kaydet',
          'admin.badges.remove_selected_desc':
              'Seçilen kullanıcının mevcut rozeti kaldırılır.',
          'admin.badges.change_approval_title': 'Rozet değişikliği onayı',
          'admin.badges.remove_badge_summary':
              '@{nickname} için rozet kaldırma talebi oluşturuldu.',
          'admin.badges.give_badge_summary':
              '@{nickname} için {badge} rozeti verme talebi oluşturuldu.',
          'admin.badges.sent_for_approval':
              'İşlem admin onay kuyruğuna gönderildi.',
          'admin.badges.badge_removed': '@{nickname} için rozet kaldırıldı.',
          'admin.badges.badge_saved':
              '@{nickname} için {badge} rozeti kaydedildi.',
          'admin.badges.permission_required':
              'Bu işlem için admin yetkisi gerekli.',
          'admin.badges.invalid_input': 'Girilen bilgi geçersiz.',
          'admin.badges.multiple_users':
              'Bu kullanıcı adı için birden fazla kullanıcı bulundu.',
          'admin.badges.save_failed': 'Rozet kaydedilemedi.',
          'admin.badges.applications_title': 'Rozet Başvuruları',
          'admin.badges.applications_help':
              'Başvurular ayarlardan gelir. Sosyal medya ve TurqApp profil linkleri aşağıda açılır.',
          'admin.badges.no_applications': 'Henüz başvuru yok.',
          'admin.badges.no_badge_selected': 'Rozet seçilmedi',
          'admin.badges.status': 'Durum: {status}',
          'admin.badges.approve_and_assign': 'Onayla ve Rozet Ver',
          'admin.badges.application_approval_title':
              'Rozet başvurusu onayı',
          'admin.badges.application_approval_summary':
              '@{nickname} için {badge} rozeti onaya gönderildi.',
          'admin.badges.application_sent_for_approval':
              'Başvuru admin onay kuyruğuna gönderildi.',
          'admin.badges.application_approved':
              'Rozet verildi ve başvuru onaylandı.',
          'admin.badges.application_approve_failed':
              'Başvuru onaylanamadı.',
          'admin.badges.last_action': 'Son işlem',
          'admin.push.title': 'Push Gönder',
          'admin.push.permission_title': 'Yetki',
          'admin.push.permission_body':
              'Bildirim göndermek için yönetici yetkisi gereklidir.',
          'admin.push.select_job': 'Meslek Seç',
          'admin.push.required_title_body':
              'Başlık ve mesaj alanları zorunludur.',
          'admin.push.invalid_range_title': 'Hatalı Aralık',
          'admin.push.invalid_range_body':
              'Minimum yaş, maksimum yaştan büyük olamaz.',
          'admin.push.no_results_title': 'Sonuç Bulunamadı',
          'admin.push.no_results_body':
              'Seçilen filtrelere uygun kullanıcı bulunamadı.',
          'admin.push.target': 'Hedef',
          'admin.push.user_count': 'kullanıcı',
          'admin.push.type': 'Tür',
          'admin.push.job': 'Meslek',
          'admin.push.location': 'Konum',
          'admin.push.gender': 'Cinsiyet',
          'admin.push.age': 'Yaş',
          'admin.push.started_title': 'Gönderim Başlatıldı',
          'admin.push.started_body':
              '{count} kullanıcı için bildirim kuyruğa alındı.',
          'admin.push.send_failed': 'Bildirim gönderimi tamamlanamadı',
          'admin.push.help':
              'Başlık ve mesaj zorunlu. Filtreleri boş bırakırsan herkese gider.',
          'admin.push.title_field': 'Başlık',
          'admin.push.message_field': 'Mesaj',
          'admin.push.optional_filters': 'Opsiyonel Filtreler',
          'admin.push.target_uid': 'Hedef UID (tek kullanıcı)',
          'admin.push.people': 'kişi',
          'admin.push.location_hint': 'Konum (city / il / ilce)',
          'admin.push.min_age': 'Min Yaş',
          'admin.push.max_age': 'Max Yaş',
          'admin.push.saved_reports': 'Kalıcı Raporlar',
          'admin.push.no_reports': 'Henüz rapor yok.',
          'admin.push.report_title': 'Başlık',
          'admin.push.report_message': 'Mesaj',
          'admin.push.report_filters': 'Filtre',
          'admin.push.delete_report': 'Raporu Sil',
          'admin.push.send': 'Gönder',
          'admin.reports.title': 'Reports',
          'admin.reports.data_failed': 'Reports verisi alınamadı.',
          'admin.reports.empty': 'Henüz report aggregate oluşmadı.',
          'admin.reports.config_help':
              'Varsayılan kategori eşiği: 5\nEşik aşımı: içerik otomatik yayından kaldırılır\nAdmin aksiyonu: tekrar yayınla veya kapalı tut',
          'admin.reports.config_updated': 'adminConfig/reports güncellendi.',
          'admin.reports.config_failed': 'Reports config güncellenemedi',
          'admin.reports.restored': 'İçerik tekrar yayına alındı.',
          'admin.reports.kept_hidden': 'İçerik kapalı tutuldu.',
          'admin.reports.action_failed': 'Admin işlemi başarısız',
          'admin.reports.total_status': 'Toplam: {count} • Durum: {status}',
          'admin.reports.category_counts': 'Kategori Sayaçları',
          'admin.reports.report_reasons': 'Neden Şikayet Edildi',
          'admin.reports.no_category_data': 'Kategori verisi yok.',
          'admin.reports.no_detail_reports': 'Henüz detay report kaydı yok.',
          'admin.reports.no_reason': 'Sebep yok',
          'admin.reports.restore': 'Yayına Al',
          'admin.reports.processing': 'İşleniyor...',
          'admin.reports.keep_hidden': 'Kapalı Tut',
          'admin.story_music.title': 'Hikaye Müzikleri',
          'admin.story_music.cover_uploaded': 'Kapak görseli yüklendi',
          'admin.story_music.cover_upload_failed':
              'Kapak görseli yüklenemedi',
          'admin.story_music.title_url_required':
              'Başlık ve müzik URL zorunlu',
          'admin.story_music.track_added': 'Parça eklendi',
          'admin.story_music.track_updated': 'Parça güncellendi',
          'admin.story_music.save_failed': 'Parça kaydedilemedi',
          'admin.story_music.track_deleted': 'Parça silindi',
          'admin.story_music.delete_failed': 'Parça silinemedi',
          'admin.story_music.preview_failed': 'Önizleme oynatılamadı',
          'admin.story_music.new_track': 'Yeni Parça',
          'admin.story_music.edit_track': 'Parçayı Düzenle',
          'admin.story_music.artist': 'Sanatçı',
          'admin.story_music.audio_url': 'Müzik URL',
          'admin.story_music.cover_url': 'Kapak URL',
          'admin.story_music.category': 'Kategori',
          'admin.story_music.order': 'Sıra',
          'admin.story_music.upload_cover': 'Kapak Yükle',
          'admin.story_music.active': 'Aktif',
          'admin.story_music.save_track': 'Parçayı Kaydet',
          'admin.story_music.save_update': 'Güncellemeyi Kaydet',
          'admin.story_music.no_tracks': 'Henüz parça yok',
          'admin.story_music.untitled': 'İsimsiz Parça',
          'admin.story_music.order_usage':
              'Sıra {order} • Kullanım {count}',
          'common.cancel': 'Vazgeç',
          'common.save': 'Kaydet',
          'common.add': 'Ekle',
          'common.done': 'Bitti',
          'common.select': 'Seç',
          'common.remove': 'Kaldır',
          'common.not_listed': 'Listede Yok',
          'common.unspecified': 'Belirtilmemiş',
          'common.yes': 'Evet',
          'common.no': 'Hayır',
          'common.selected_count': '@count seçildi',
          'following.followers_tab': 'Takip Edenler {count}',
          'following.following_tab': 'Takip Edilenler {count}',
          'following.none': 'Henüz kullanıcı yok',
          'following.follow': 'Takip Et',
          'following.following': 'Takip Ediyorsun',
          'following.unfollow_title': 'Takipten Çık',
          'following.unfollow_body':
              '@{nickname} kullanıcısını takipten çıkmak istediğinizden emin misiniz?',
          'following.update_failed': 'Takip durumu güncellenemedi.',
          'following.limit_title': 'Takip Limiti',
          'following.limit_body': 'Günlük daha fazla kişi takip edilemiyor.',
          'profile.highlight_remove_title': 'Öne Çıkartılanı Kaldır',
          'profile.highlight_remove_body':
              'Bu öne çıkartılanı kaldırmak istediğinizden emin misiniz?',
          'profile.link_remove_title': 'Bağlantıyı Kaldır',
          'profile.link_remove_body':
              'Bu bağlantıyı kaldırmak istediğinizden emin misiniz?',
          'profile.edit': 'Düzenle',
          'profile.statistics': 'İstatistikler',
          'profile.posts': 'Gönderi',
          'profile.followers': 'Takipçi',
          'profile.following': 'Takip',
          'profile.likes': 'Beğeni',
          'profile.listings': 'İlan',
          'profile.copy_profile_link': 'Profil linkini kopyala',
          'profile.profile_share_title': 'TurqApp Profili',
          'profile.private_account_title': 'Gizli hesap',
          'profile.private_story_follow_required':
              'Hikayeleri görmek için önce takip etmeniz gerekir.',
          'profile.unfollow_title': 'Takipten Çık',
          'profile.unfollow_body':
              '@{nickname} kullanıcısını takipten çıkmak istediğinizden emin misiniz ?',
          'profile.unfollow_confirm': 'Takipten Çık',
          'profile.following_status': 'Takiptesin',
          'profile.follow_button': 'Takip Et',
          'profile.contact_options': 'İletişim Seçenekleri',
          'profile.unblock': 'Engeli Kaldır',
          'profile.remove_highlight_title': 'Öne Çıkarılanı Kaldır',
          'profile.remove_highlight_body':
              'Bu öne çıkarılanı kaldırmak istediğinizden emin misiniz?',
          'profile.remove_highlight_confirm': 'Kaldır',
          'story.highlight_no_stories': 'Öne çıkarılanda hikaye yok.',
          'story.highlight_missing_stories':
              'Bu öne çıkarılandaki hikayeler artık mevcut değil.',
          'story.highlight_open_failed':
              'Öne çıkarılan açılamadı. Lütfen tekrar deneyin.',
          'story.highlights_title': 'Öne Çıkarılanlar',
          'story.highlights_subtitle':
              'Bu hikayeyi profilinde sabit bir koleksiyona ekle.',
          'story.highlights_collections': 'Koleksiyonların',
          'story.highlights_story_count': '@count hikaye',
          'story.highlights_first_create': 'İlk koleksiyonunu oluştur',
          'story.highlights_first_create_body':
              'Bu hikaye için bir başlık belirle. Sonra profilinde sabit görünsün.',
          'story.highlights_new': 'Yeni öne çıkarılan oluştur',
          'story.highlights_title_hint': 'Başlık girin...',
          'story.highlights_create_failed':
              'Öne çıkarılan oluşturulamadı. Lütfen tekrar deneyin.',
          'story.add_sticker': 'Sticker Ekle',
          'story.text_title': 'Metin',
          'story.write_text': 'Metin yaz...',
          'story.sticker_link': 'Bağlantı',
          'story.sticker_hashtag': 'Konu etiketi',
          'story.sticker_countdown': 'Geri sayım',
          'story.sticker_add_yours': 'Sen de ekle',
          'story.sticker_question': 'Soru',
          'story.sticker_mention': 'Bahsetme',
          'story.sticker_gif': 'GIF',
          'story.sticker_text': 'Metin',
          'story.sticker_topic_label': 'Konu etiketi',
          'story.sticker_countdown_label': 'Geri sayım başlığı',
          'story.sticker_title_label': 'Başlık',
          'story.sticker_question_label': 'Soru',
          'story.sticker_user_label': 'Kullanıcı',
          'story.link_add': 'Bağlantı Ekle',
          'story.link_text_label': 'Bağlantı metni',
          'story.link_text_hint': 'Haberi oku',
          'story.video_audio_title': 'Video Sesleri',
          'story.music_mute_videos_message':
              'Müzik eklemek üzeresiniz. Videoların sesini kapatmak ister misiniz?',
          'story.music_mute_videos_yes': 'Evet, Kapat',
          'social_profile.private_follow_to_see_posts':
              'Gönderileri görmek için takip et.',
          'social_profile.blocked_user': 'Bu kullanıcıyı engellediniz',
          'profile.no_posts': 'Gönderi Yok',
          'profile.no_photos': 'Fotoğraf Yok',
          'profile.no_videos': 'Video Yok',
          'profile.no_reshares': 'Yeniden paylaşım yok',
          'profile.no_quotes': 'Henüz alıntı yok',
          'profile.reshare_users_tab': 'Yeniden Paylaşanlar',
          'profile.quote_users_tab': 'Alıntılayanlar',
          'profile.no_listings': 'İlan Yok',
          'profile.post_about_title': 'Gönderi hakkında',
          'profile.post_about_body':
              'Bu gönderi için ne yapmak istiyorsunuz?',
          'profile.archive': 'Arşivle',
          'profile.review': 'İncele',
          'profile.location_missing': 'Konum belirtilmedi',
          'profile.status_sold': 'Satıldı',
          'profile.status_passive': 'Pasif',
          'profile.status_active': 'Aktif',
          'profile.remove_reshare_title': 'Gönderiyi kaldır',
          'profile.remove_reshare_body':
              'Bu gönderiyi yeniden paylaşılan gönderiler arasından silmek istediğinizden emin misiniz?',
          'profile.scheduled_post_title': 'İz Bırak Gönderi',
          'profile.scheduled_post_body':
              'Bu gönderi için ne yapmak istersiniz?',
          'profile.scheduled_subscribe_title': 'İz Bırak',
          'profile.scheduled_subscribe_body':
              'Yayın tarihinde bildirim alacaksınız.',
          'profile.scheduled_none': 'İz bırak gönderisi yok',
          'common.edit': 'Düzenle',
          'common.update': 'Güncelle',
          'common.change': 'Değiştir',
          'common.publish': 'Yayınla',
          'common.loading': 'Yükleniyor...',
          'common.now': 'simdi',
          'common.info': 'Bilgi',
          'common.error': 'Hata',
          'common.ok': 'Tamam',
          'common.apply': 'Uygula',
          'common.reset': 'Sıfırla',
          'common.select_city': 'Şehir Seç',
          'common.select_district': 'İlçe Seç',
          'common.download': 'İndir',
          'app.name': 'TurqApp',
          'common.copy': 'Kopyala',
          'common.copy_link': 'Linki Kopyala',
          'common.copied': 'Kopyalandı',
          'common.link_copied': 'Bağlantı linki panoya kopyalandı',
          'common.archive': 'Arşivle',
          'common.unarchive': 'Arşivden Çıkart',
          'common.report': 'Şikayet Et',
          'report.reported_user': 'Şikayet Edilecek Kullanıcı',
          'report.what_issue': 'Ne tür bir sorun bildiriyorsun?',
          'report.thanks_title':
              'TurqApp\'i herkes için daha iyi bir hâle getirmemize katkıda bulunduğunuz için teşekkür ederiz!',
          'report.thanks_body':
              'Vakitinizin değerli olduğunu biliyoruz. Bize vakit ayırdığınız için teşekkür ederiz.',
          'report.how_it_works_title': 'Nasıl ilerliyoruz?',
          'report.how_it_works_body':
              'Bildirimin bize ulaştı. Bildirilen profili akıştan gizleyeceğiz.',
          'report.whats_next_title': 'Şimdi sırada ne var?',
          'report.whats_next_body':
              'Ekibimiz bu profili bir kaç gün içersinde inceleyecek. Bir kural ihlali tespit ettiği taktirde bu hesap kısıtlanacaktır. Eğer bir ihlal tespit edilemez ise bir çok kez geçersiz şikayetler ilettiyseniz, hesabınız kısıtlanacaktır.',
          'report.optional_block_title': 'Eğer isterseniz?',
          'report.optional_block_body':
              'Bu profili engelleyebilirsiniz. Engellemeniz durumunda, bu kullanıcı bir daha akışınızda hiçbir şekilde görünmeyecektir.',
          'report.block_user_button': '@nickname kullanıcısını engelle',
          'report.blocked_user_label': '@nickname engellendi!',
          'report.block_user_info':
              '@nickname adlı kullanıcını seni takip etmesini, mesaj göndermesini engelle. Herkese açık gönderilerini görebilir ancak seninle etkileşim kuramaz. Bununla birlikte @nickname kişisinin gönderilerini göremezsin.',
          'report.select_reason_title': 'Şikayet Nedeni Seç',
          'report.select_reason_body':
              'Devam etmek için bir neden seçmelisin.',
          'report.submitted_title': 'Talebiniz Bize Ulaştı!',
          'report.submitted_body':
              '@nickname kullanıcısını inceleme altına alacağız. Talebinizden dolayı teşekkür ederiz',
          'report.submitting': 'Gönderiliyor...',
          'report.done': 'Bitti',
          'report.reason.impersonation.title':
              'Taklit / Sahte Hesap / Kimlik Kullanımı',
          'report.reason.impersonation.desc':
              'Bu hesap veya içerik, kimlik taklidi, sahte hesap kullanımı ya da başka bir kişiyi izinsiz temsil etme şüphesi taşıyor.',
          'report.reason.copyright.title':
              'Telif / İzinsiz İçerik Kullanımı',
          'report.reason.copyright.desc':
              'Bu içerik telif hakkıyla korunan materyalleri izinsiz kullanıyor veya fikri mülkiyet ihlali içeriyor olabilir.',
          'report.reason.harassment.title':
              'Taciz / Hedef Gösterme / Zorbalık',
          'report.reason.harassment.desc':
              'Bu içerik bir kişiyi rahatsız etme, aşağılamaya çalışma, hedef gösterme ya da sistematik zorbalık içeriği taşıyor.',
          'report.reason.hate_speech.title': 'Nefret Söylemi',
          'report.reason.hate_speech.desc':
              'Bu içerik bir gruba veya kişiye karşı nefret, ayrımcılık ya da aşağılayıcı söylem içeriyor.',
          'report.reason.nudity.title': 'Çıplaklık / Cinsel İçerik',
          'report.reason.nudity.desc':
              'Bu içerik çıplaklık, müstehcenlik ya da açık cinsel içerik barındırıyor olabilir.',
          'report.reason.violence.title': 'Şiddet / Tehdit',
          'report.reason.violence.desc':
              'Bu içerik fiziksel şiddet, tehdit, korkutma ya da zarar verme çağrısı içeriyor olabilir.',
          'report.reason.spam.title': 'Spam / Alakasız Tekrar İçerik',
          'report.reason.spam.desc':
              'Bu içerik tekrar eden, alakasız, yanıltıcı ya da rahatsız edici biçimde spam niteliği taşıyor.',
          'report.reason.scam.title': 'Dolandırıcılık / Yanıltma',
          'report.reason.scam.desc':
              'Bu içerik para, bilgi ya da güven istismarı amacıyla yanıltıcı veya dolandırıcılık içerikli olabilir.',
          'report.reason.misinformation.title':
              'Yanlış Bilgi / Manipülasyon',
          'report.reason.misinformation.desc':
              'Bu içerik gerçeği çarpıtan, yanlış bilgi yayan ya da manipülatif yönlendirme yapan unsurlar içeriyor olabilir.',
          'report.reason.illegal_content.title': 'Yasa Dışı İçerik',
          'report.reason.illegal_content.desc':
              'Bu içerik yasa dışı faaliyet, suç teşviki ya da hukuka aykırı materyal içeriyor olabilir.',
          'report.reason.child_safety.title':
              'Çocuk Güvenliği İhlali',
          'report.reason.child_safety.desc':
              'Bu içerik çocuk güvenliğini tehlikeye atıyor ya da çocuklara uygun olmayan zararlı unsurlar taşıyor olabilir.',
          'report.reason.self_harm.title':
              'Kendine Zarar Verme / İntihar Teşviki',
          'report.reason.self_harm.desc':
              'Bu içerik kendine zarar verme, intihar teşviki ya da bu yönde yönlendirme içeriyor olabilir.',
          'report.reason.privacy_violation.title': 'Gizlilik İhlali',
          'report.reason.privacy_violation.desc':
              'Bu içerik kişisel verilerin izinsiz paylaşımı, doxxing ya da mahremiyet ihlali içeriyor olabilir.',
          'report.reason.fake_engagement.title':
              'Sahte Etkileşim / Bot / Manipülatif Büyütme',
          'report.reason.fake_engagement.desc':
              'Bu içerik sahte beğeni, bot etkileşimi ya da yapay büyütme amaçlı manipülatif davranış içeriyor olabilir.',
          'report.reason.other.title': 'Diğer',
          'report.reason.other.desc':
              'Yukarıdaki seçeneklerin dışında kalan, ayrıca incelenmesini istediğiniz başka bir ihlal nedeni bulunuyor.',
          'common.undo': 'Geri Al',
          'common.edited': 'düzenlendi',
          'common.delete_post_title': 'Gönderiyi Sil',
          'common.delete_post_message':
              'Bu gönderiyi silmek istediğinizden emin misiniz?',
          'common.delete_post_confirm': 'Gönderiyi Sil',
          'common.post_share_title': 'TurqApp Gönderisi',
          'common.send': 'Gönder',
          'common.block': 'Engelle',
          'common.unknown_user': 'Bilinmeyen Kullanıcı',
          'common.unknown_company': 'Bilinmeyen Firma',
          'common.verified': 'Onaylı',
          'common.verify': 'Onayla',
          'common.message': 'Mesaj',
          'common.phone': 'Telefon',
          'common.description': 'Açıklama',
          'common.location': 'Konum',
          'common.category': 'Kategori',
          'common.status': 'Durum',
          'common.features': 'Özellikler',
          'common.contact': 'İletişim',
          'common.city': 'Şehir',
          'comments.input_hint': 'Bunun hakkında ne düşünüyorsun?',
          'explore.tab.trending': 'Gündem',
          'explore.tab.for_you': 'Sana Özel',
          'explore.tab.series': 'Dizi',
          'explore.trending_rank': '@index - Türkiye tarihinde gündemde',
          'explore.no_results': 'Sonuç bulunamadı',
          'explore.no_series': 'Dizi bulunamadı',
          'feed.empty_city': 'Şehrinde henüz gönderi yok',
          'feed.empty_following': 'Takip ettiklerinden henüz gönderi yok',
          'post_likes.title': 'Beğenme',
          'post_likes.empty': 'Henüz beğeni yok',
          'post_state.hidden_title': 'Gönderi Gizlendi',
          'post_state.hidden_body':
              'Bu gönderi gizlendi. Bunun gibi gönderileri akışında daha altlarda göreceksin.',
          'post_state.archived_title': 'Gönderi Arşivlendi',
          'post_state.archived_body':
              'Bu gönderiyi arşivlediniz.\nArtık kimseye bu gönderi gözükmeyecektir.',
          'post_state.deleted_title': 'Gönderi Sildiniz',
          'post_state.deleted_body': 'Bu gönderi artık yayında değil.',
          'post.share_title': 'TurqApp Gönderisi',
          'post.archive': 'Arşivle',
          'post.unarchive': 'Arşivden Çıkart',
          'post.like_failed': 'Beğeni işlemi tamamlanamadı.',
          'post.save_failed': 'Kaydetme işlemi tamamlanamadı.',
          'post.reshare_failed': 'Yeniden paylaşma işlemi tamamlanamadı.',
          'post.report_success': 'Gönderi şikayet edildi.',
          'post.report_failed': 'Şikayet işlemi tamamlanamadı.',
          'post.hide_failed': 'Gizleme işlemi tamamlanamadı.',
          'post.reshare_action': 'Yeniden paylaş',
          'post.reshare_undo': 'Yeniden paylaşmayı geri al',
          'post.reshared_you': 'yeniden paylaştın',
          'post.reshared_by': '@name yeniden paylaştı',
          'short.next_post': 'Sonraki Gönderiye Geç',
          'short.publish_as_post': 'Gönderi olarak yayınla',
          'short.add_to_story': 'Hikayene ekle',
          'short.shared_as_post_by': 'Gönderi olarak paylaşanlar',
          'story.seens_title': 'Görüntüleme (@count)',
          'story.likes_title': 'Beğeniler (@count)',
          'story.no_likes': 'Kimse hikayeni beğenmedi',
          'story.no_seens': 'Kimse hikayeni görüntülemedi',
          'story.comments_title': 'Yorumlar (@count)',
          'story.share_title': '@name hikayesi',
          'story.share_desc': 'TurqApp üzerinde hikayeyi görüntüle',
          'story.drawing_title': 'Çizim Ekle',
          'story.brush_color': 'Fırça Rengi',
          'story.no_comments': 'Kimse yorum yapmadı',
          'story.add_comment_for': '@nickname için yorum ekle..',
          'story.comment_placeholder': 'Hikayeye yorum yaz..',
          'story.gif_load_failed': 'GIF yüklenemedi',
          'story.create_title': 'Hikaye Oluştur',
          'story.no_user': 'Oturum açılmış kullanıcı yok',
          'story.empty_elements': 'Hikayeye en az bir element ekleyin',
          'story.past_time_invalid': 'Geçmiş bir zaman seçilemez',
          'story.no_elements_saved': 'Hiçbir element kaydedilemedi',
          'story.save_failed': 'Hikaye kaydedilemedi: @error',
          'admin_push.queue_title': 'Push',
          'admin_push.queue_body_count':
              '@count kullanıcıya push kuyruğa alındı',
          'admin_push.queue_body': 'Push kuyruğa alındı',
          'admin_push.failed_body': 'Push gönderilemedi.',
          'story.delete_message': 'Bu hikaye silinsin mi?',
          'story.permanent_delete': 'Kalıcı Sil',
          'story.permanent_delete_message':
              'Bu hikaye kalıcı olarak silinsin mi?',
          'story.comment_delete_message':
              'Bu yorumu silmek istediğinizden emin misiniz ?',
          'story.deleted_stories.title': 'Hikayeler',
          'story.deleted_stories.tab_deleted': 'Silinmis',
          'story.deleted_stories.tab_expired': 'Suresi Bitmis',
          'story.deleted_stories.empty': 'Silinmis hikaye bulunmuyor',
          'story.deleted_stories.snackbar_title': 'Hikaye',
          'story.deleted_stories.reposted': 'Hikaye tekrar paylasildi',
          'story.deleted_stories.deleted_forever':
              'Hikaye kalici olarak silindi',
          'story.deleted_stories.deleted_at': 'Silindi: @time',
          'story_music.title': 'Muzik',
          'story_music.search_hint': 'Müzik ara',
          'story_music.no_active_stories': 'Bu muzikle aktif hikaye yok',
          'story_music.untitled': 'Isimsiz Parca',
          'story_music.active_story_count': '@count aktif hikaye',
          'story_music.minutes_ago': '@count dk',
          'story_music.hours_ago': '@count sa',
          'story_music.days_ago': '@count g',
          'chat.attach_photos': 'Fotograflar',
          'chat.list_title': 'Sohbetler',
          'chat.tab_all': 'Tumu',
          'chat.tab_unread': 'Okunmamis',
          'chat.tab_archive': 'Arsiv',
          'chat.empty_title': 'Henuz sohbetin yok',
          'chat.empty_body':
              'Mesajlastiginda konusmalarin burada listelenecek.',
          'chat.action_failed':
              'Islem tamamlanamadi, yetki veya kayit sorunu var',
          'chat.attach_videos': 'Videolar',
          'chat.attach_location': 'Konum',
          'chat.message_hint': 'Mesaj',
          'chat.no_starred_messages': 'Yildizli mesaj yok',
          'chat.profile_stats':
              '@followers takipci · @following takip · @posts gonderi',
          'chat.selected_messages': '@count mesaj secildi',
          'chat.today': 'Bugun',
          'chat.yesterday': 'Dun',
          'chat.typing': 'yaziyor...',
          'chat.gif': 'GIF',
          'chat.ready_to_send': 'Gonderilmeye hazir',
          'chat.editing_message': 'Mesaj duzenleniyor',
          'chat.video': 'Video',
          'chat.audio': 'Ses',
          'chat.location': 'Konum',
          'chat.post': 'Gonderi',
          'chat.person': 'Kisi',
          'chat.reply': 'Yanit',
          'chat.recording_timer': 'Kayit yapiliyor... @time',
          'chat.fetching_address': 'Adres aliniyor...',
          'chat.add_star': 'Yildiz Ekle',
          'chat.remove_star': 'Yildizi Kaldir',
          'chat.you': 'Siz',
          'chat.hide_photos': 'Fotograflari gizle',
          'chat.unsent_message': 'Mesaj geri alindi',
          'chat.reply_prompt': 'Yanitlayin',
          'chat.open_in_maps': 'Haritalarda Ac',
          'chat.open_in_google_maps': 'Google Haritalar da Ac',
          'chat.open_in_apple_maps': 'Apple Haritalar da Ac',
          'chat.open_in_yandex_maps': 'Yandex Haritalar da Ac',
          'chat.contact_info': 'Kisi Bilgisi',
          'chat.save_to_contacts': 'Rehbere Kaydet',
          'chat.call': 'Telefon Et',
          'chat.delete_message_title': 'Mesaji Sil',
          'chat.delete_message_body':
              'Bu mesaji silmek istediginizden emin misiniz?',
          'chat.delete_for_me': 'Sadece Benden Sil',
          'chat.delete_for_everyone': 'Mesaji Herkesten Sil',
          'chat.delete_photo_title': 'Fotografi Sil',
          'chat.delete_photo_body':
              'Bu fotografi silmek istediginizden emin misiniz?',
          'chat.delete_photo_confirm': 'Fotografi Sil',
          'chat.messages_delete_failed': 'Mesajlar silinemedi',
          'chat.image_upload_failed': 'Resim yuklenemedi',
          'chat.image_upload_failed_with_error': 'Resim yuklenemedi: @error',
          'chat.video_upload_failed': 'Video yuklenirken bir hata olustu',
          'chat.microphone_permission_required': 'Izin Gerekli',
          'chat.microphone_permission_denied': 'Mikrofon izni verilmedi',
          'chat.voice_record_start_failed': 'Ses kaydi baslatilamadi',
          'chat.voice_message_upload_failed':
              'Sesli mesaj yuklenirken bir hata olustu',
          'chat.message_send_failed':
              'Mesaj gonderilemedi. Lutfen tekrar dene.',
          'chat.shared_post_from': '@nickname in gonderisini gonderdi',
          'chat.notif_video': 'Bir video gonderdi',
          'chat.notif_audio': 'Sesli mesaj gonderdi',
          'chat.notif_images': '@count adet resim gonderdi',
          'chat.notif_post': 'Bir gonderi paylasti',
          'chat.notif_location': 'Bir konum gonderdi',
          'chat.notif_contact': 'Bir rehber bilgisi paylasti',
          'chat.notif_gif': 'Bir GIF gonderdi',
          'chat.reply_target_missing': 'Yanitlanan mesaj bulunamadi',
          'chat.forward_target_missing': 'İletilecek sohbet bulunamadı',
          'chat.forwarded_title': 'Iletildi',
          'chat.forwarded_body': 'Mesaj secilen sohbete iletildi',
          'chat.tap_to_chat': 'Sohbet etmek icin dokun.',
          'chat.photo': 'Fotograf',
          'chat.message_label': 'Mesaj',
          'chat.marked_unread': 'Sohbet okunmadi olarak isaretlendi',
          'chat.limit_title': 'Limit',
          'chat.pin_limit': 'En fazla 5 sohbet sabitlenebilir',
          'chat.action_completed': 'Islem tamamlandi',
          'chat.muted': 'Sohbet sessize alindi',
          'chat.unmuted': 'Sohbet sesi acildi',
          'chat.archived': 'Sohbet arsive tasindi',
          'chat.unarchived': 'Sohbet arsivden cikarildi',
          'chat.delete_title': 'Sohbeti Sil',
          'chat.delete_message':
              'Bu sohbeti silmek istediginizden emin misiniz?',
          'chat.delete_confirm': 'Sohbeti Sil',
          'chat.deleted_title': 'Sohbet Silindi',
          'chat.deleted_body': 'Secilen sohbet basariyla silindi',
          'chat.unmute': 'Sesi ac',
          'chat.mute': 'Sessize al',
          'chat.mark_unread': 'Okunmadi olarak isaretle',
          'chat.pin': 'Sabitle',
          'chat.unpin': 'Sabitten kaldir',
          'chat.muted_label': 'Sessiz',
          'training.comments_title': 'Yorumlar',
          'training.no_comments': 'Henuz yorum yok.',
          'training.reply': 'Yanitla',
          'training.hide_replies': 'Yanitlari gizle',
          'training.view_replies': '@count yaniti gor',
          'training.unknown_user': 'Bilinmeyen Kullanici',
          'training.edit': 'Duzenle',
          'training.report': 'Sikayet Et',
          'training.reply_to_user': '@name kisine yanit',
          'training.cancel': 'Iptal',
          'training.edit_comment_hint': 'Yorumu duzenle',
          'training.write_hint': 'Yaz..',
          'training.pick_from_gallery': 'Galeriden Sec',
          'training.take_photo': 'Fotograf Cek',
          'training.time_now': 'az once',
          'training.time_min': '@count dk once',
          'training.time_hour': '@count saat once',
          'training.time_day': '@count gun once',
          'training.time_week': '@count hafta once',
          'training.photo_pick_failed': 'Fotograf secilirken bir hata olustu!',
          'training.photo_upload_failed':
              'Fotograf yuklenirken bir hata olustu!',
          'training.question_bank_title': 'Soru Bankasi',
          'training.questions_loading': 'Sorular Yukleniyor...',
          'training.solve_later_empty':
              'Sonra çözülecek soru bulunamadı!',
          'training.remove_solve_later': 'Sonra Çözden Kaldır',
          'training.search_no_match': 'Aramaya uygun soru bulunamadı.',
          'training.no_questions': 'Soru bulunamadi!',
          'training.answer_first': 'Once soruyu cevaplayin!',
          'training.share': 'Paylas',
          'training.correct_ratio': '%@value Doğru',
          'training.wrong_ratio': '%@value Yanlış',
          'training.complaint_select_one':
              'Lütfen en az bir bildiri seçeneği seçin!',
          'training.complaint_thanks':
              'Bilgilendirmeniz için teşekkürler.',
          'training.complaint_submit_failed':
              'Bildiriminiz gönderilirken bir hata oluştu.',
          'training.no_questions_in_category':
              'Bu kategoride soru bulunamadi',
          'training.saved_load_failed':
              'Kaydedilen sorular yuklenirken hata olustu',
          'training.view_update_failed':
              'Goruntuleme guncellenirken hata olustu',
          'training.saved_removed':
              'Soru Sonra Coz listesinden kaldirildi!',
          'training.saved_added': 'Soru Sonra Coz listesine eklendi!',
          'training.saved_remove_failed':
              'Sonra Coz kaldirma sirasinda hata olustu.',
          'training.saved_update_failed':
              'Sonra Coz guncellenirken hata olustu.',
          'training.like_removed': 'Begeni kaldirildi!',
          'training.liked': 'Soru begenildi!',
          'training.like_remove_failed':
              'Begeni kaldirma sirasinda hata olustu.',
          'training.like_add_failed': 'Begeni eklenirken hata olustu.',
          'training.share_failed': 'Paylasim baslatilamadi',
          'training.share_question_link_title':
              '@exam - @lesson @number. Soru',
          'training.share_question_title':
              'TurqApp - @exam @lesson Sorusu',
          'training.share_question_desc': 'TurqApp Soru Bankasi sorusu',
          'training.leaderboard_empty': 'Henüz puan tablosu oluşmadı.',
          'training.leaderboard_empty_body':
              "Listeye girmek için Soru Bankası'nda soru çöz.",
          'education.past_exam_create_title': 'Çıkmış Sınav Oluştur',
          'education.start_creating': 'Oluşturmaya Başla',
          'education.exam_types': 'Sınav Türleri',
          'education.question_count_hint': 'Soru Sayısı',
          'education.change_main_category': 'Ana Kategori Değiştir',
          'training.answer_locked':
              'Bu sorunun cevabini degistiremezsiniz!',
          'training.answer_saved':
              'Bu sorunun cevabi daha once kaydedilmis.',
          'training.answer_save_failed':
              'Cevap kaydedilirken hata olustu',
          'training.no_more_questions':
              'Bu kategoride baska soru kalmadi!',
          'training.settings_opening': 'Ayarlar ekrani aciliyor!',
          'training.fetch_more_failed':
              'Daha fazla soru cekilirken hata olustu',
          'training.comments_load_failed':
              'Yorumlar yuklenirken bir hata olustu. Lutfen tekrar deneyin!',
          'training.comment_or_photo_required':
              'Yorum veya fotograf eklemelisiniz!',
          'training.reply_or_photo_required':
              'Yanit veya fotograf eklemelisiniz!',
          'training.comment_added': 'Yorumunuz eklendi!',
          'training.comment_add_failed':
              'Yorum eklenirken bir hata olustu. Lutfen tekrar deneyin!',
          'training.reply_added': 'Yanitiniz eklendi!',
          'training.reply_add_failed':
              'Yanit eklenirken bir hata olustu. Lutfen tekrar deneyin!',
          'training.comment_deleted': 'Yorumunuz silindi!',
          'training.comment_delete_failed':
              'Yorum silinirken bir hata olustu. Lutfen tekrar deneyin!',
          'training.reply_deleted': 'Yanitiniz silindi!',
          'training.reply_delete_failed':
              'Yanit silinirken bir hata olustu. Lutfen tekrar deneyin!',
          'training.comment_updated': 'Yorumunuz guncellendi!',
          'training.comment_update_failed':
              'Yorum duzenlenirken bir hata olustu. Lutfen tekrar deneyin!',
          'training.reply_updated': 'Yanitiniz guncellendi!',
          'training.reply_update_failed':
              'Yanit duzenlenirken bir hata olustu. Lutfen tekrar deneyin!',
          'training.like_failed':
              'Begeni islemi sirasinda bir hata olustu. Lutfen tekrar deneyin!',
          'training.upload_failed_title': 'Yukleme Basarisiz!',
          'training.upload_failed_body':
              'Bu icerik su anda islenemiyor. Lutfen baska bir icerik deneyin.',
          'common.accept': 'Kabul Et',
          'common.reject': 'Reddet',
          'common.open_profile': 'Profili Ac',
          'tutoring.title': 'Ozel Ders',
          'tutoring.search_hint': 'Ne tur ders ariyorsun ?',
          'tutoring.my_applications': 'Basvurularim',
          'tutoring.create_listing': 'Ilan Ver',
          'tutoring.my_listings': 'Ilanlarim',
          'tutoring.saved': 'Kaydedilenler',
          'tutoring.slider_admin': 'Slider Yonetimi',
          'tutoring.review_title': 'Degerlendirme Yap',
          'tutoring.review_hint': 'Yorumunuzu yazin (opsiyonel)',
          'tutoring.review_select_rating': 'Lutfen bir puan secin.',
          'tutoring.review_saved': 'Degerlendirmeniz kaydedildi.',
          'tutoring.applicants_title': 'Basvuranlar',
          'tutoring.no_applications': 'Henuz basvuru yok',
          'tutoring.application_label': 'Ozel ders basvurusu',
          'tutoring.my_applications_empty':
              'Henuz ozel ders basvurusu yapmadiniz',
          'tutoring.instructor_fallback': 'Egitmen',
          'tutoring.cancel_application_title': 'Basvuruyu Iptal Et',
          'tutoring.cancel_application_body':
              'Bu basvuruyu iptal etmek istediginize emin misiniz?',
          'tutoring.cancel_application_action': 'Iptal Et',
          'tutoring.my_listings_title': 'Ilanlarim',
          'tutoring.published': 'Yayinda',
          'tutoring.expired': 'Suresi Doldu',
          'tutoring.active_listings_empty':
              'Aktif ozel ders ilani bulunmuyor.',
          'tutoring.expired_listings_empty':
              'Suresi dolmus ozel ders ilani bulunmuyor.',
          'tutoring.user_id_missing': 'Kullanici kimligi bulunamadi.',
          'tutoring.load_failed': 'Ilanlar yuklenirken hata olustu: {error}',
          'tutoring.reactivated_title': 'Ilan Yenilendi',
          'tutoring.reactivated_body': 'Ilan tekrar yayina alindi.',
          'tutoring.user_load_failed':
              'Kullanici bilgileri yuklenirken hata olustu: {error}',
          'tutoring.location_missing': 'Konum Bulunamadi',
          'tutoring.no_listings_in_region':
              'Bu bolgede ders ilani bulunmuyor.',
          'tutoring.no_lessons_in_category':
              '{category} alaninda ders bulunamadi.',
          'tutoring.search_empty': 'Aramana uygun ilan bulunamadı',
          'tutoring.search_empty_info': 'Eşleşen özel ders bulunmuyor!',
          'tutoring.similar_listings': 'Benzer Ilanlar',
          'tutoring.open_listing': 'Ilana Git',
          'tutoring.report_listing': 'Ilani Bildir',
          'tutoring.saved_empty': 'Kaydedilen ilan yok.',
          'tutoring.detail_description': 'Açıklama',
          'tutoring.detail_no_description':
              'Bu ilan için açıklama eklenmemiş.',
          'tutoring.detail_lesson_info': 'Ders Bilgileri',
          'tutoring.detail_branch': 'Branş',
          'tutoring.detail_price': 'Ücret',
          'tutoring.detail_contact': 'İletişim',
          'tutoring.detail_phone_and_message': 'Telefon + Mesaj',
          'tutoring.detail_message_only': 'Sadece Mesaj',
          'tutoring.detail_gender_preference': 'Cinsiyet Tercihi',
          'tutoring.detail_availability': 'Müsaitlik',
          'tutoring.detail_listing_info': 'İlan Bilgileri',
          'tutoring.detail_instructor': 'Eğitmen',
          'tutoring.detail_not_specified': 'Belirtilmedi',
          'tutoring.detail_city': 'Şehir',
          'tutoring.detail_views': 'Görüntülenme',
          'tutoring.detail_status': 'Durum',
          'tutoring.detail_status_passive': 'Pasif',
          'tutoring.detail_status_active': 'Aktif',
          'tutoring.detail_location': 'Konum',
          'tutoring.create.city_select': 'Şehir Seç',
          'tutoring.create.district_select': 'İlçe Seç',
          'tutoring.create.nsfw_check_failed':
              'NSFW görsel kontrolü başarısız.',
          'tutoring.create.nsfw_detected':
              'Uygunsuz görsel tespit edildi.',
          'tutoring.create.fill_required': 'Boş alanları doldurunuz!',
          'tutoring.create.published': 'Özel ders ilanı paylaşıldı!',
          'tutoring.create.publish_failed':
              'İlan paylaşılırken bir hata oluştu.',
          'tutoring.create.updated': 'İlan güncellendi!',
          'tutoring.create.no_changes': 'Değişiklik yapılmadı!',
          'tutoring.create.update_failed':
              'İlan güncellenirken bir hata oluştu.',
          'tutoring.call_disabled': 'Bu ilanda arama izni kapalı.',
          'tutoring.message': 'Mesaj',
          'tutoring.messages': 'Mesajlar',
          'tutoring.phone_missing': 'Eğitmenin telefon bilgisi bulunamadı.',
          'tutoring.phone_open_failed': 'Telefon uygulaması açılamadı.',
          'tutoring.unpublish_title': 'İlanı Kaldır',
          'tutoring.unpublish_body':
              'Bu özel ders ilanını yayından kaldırmak istediğinizden emin misiniz?',
          'tutoring.unpublished': 'İlan yayından kaldırıldı.',
          'tutoring.apply_login_required': 'Başvuru için tekrar giriş yapın.',
          'tutoring.application_sent': 'Başvurun gönderildi.',
          'tutoring.application_failed':
              'Başvuru sırasında bir sorun oluştu.',
          'tutoring.delete_success': 'İlan silindi!',
          'tutoring.delete_failed': 'İlan silinirken bir hata oluştu.',
          'tutoring.filter_title': 'Filtreler',
          'tutoring.gender_title': 'Cinsiyet',
          'tutoring.sort_title': 'Siralama',
          'tutoring.lesson_place_title': 'Ders Yeri',
          'tutoring.service_location_title': 'Hizmet Verilen Yer',
          'tutoring.gender.male': 'Erkek',
          'tutoring.gender.female': 'Kadin',
          'tutoring.gender.any': 'Farketmez',
          'tutoring.sort.latest': 'En Yeni',
          'tutoring.sort.nearest': 'Bana En Yakin',
          'tutoring.sort.most_viewed': 'En Cok Goruntulenen',
          'tutoring.lesson_place.student_home': 'Ogrencinin Evi',
          'tutoring.lesson_place.teacher_home': 'Ogretmenin Evi',
          'tutoring.lesson_place.either_home':
              'Ogrencinin veya Ogretmenin Evi',
          'tutoring.lesson_place.remote': 'Uzaktan Egitim',
          'tutoring.lesson_place.lesson_area': 'Ders Verme Alani',
          'tutoring.branch.summer_school': 'Yaz Okulu',
          'tutoring.branch.secondary_education': 'Orta Ogretim',
          'tutoring.branch.primary_education': 'Ilk Ogretim',
          'tutoring.branch.foreign_language': 'Yabanci Dil',
          'tutoring.branch.software': 'Yazilim',
          'tutoring.branch.driving': 'Direksiyon',
          'tutoring.branch.sports': 'Spor',
          'tutoring.branch.art': 'Sanat',
          'tutoring.branch.music': 'Muzik',
          'tutoring.branch.theatre': 'Tiyatro',
          'tutoring.branch.personal_development': 'Kisisel Gelisim',
          'tutoring.branch.vocational': 'Mesleki',
          'tutoring.branch.special_education': 'Ozel Egitim',
          'tutoring.branch.children': 'Cocuk',
          'tutoring.branch.diction': 'Diksiyon',
          'tutoring.branch.photography': 'Fotografcilik',
          'tutoring.branch': 'Branş',
          'scholarship.applications_title': 'Başvurular (@count)',
          'scholarship.no_applications': 'Henüz başvuru bulunmamaktadır',
          'scholarship.my_listings': 'Burs İlanlarım',
          'scholarship.no_my_listings': 'Burs İlanınız Bulunmamaktadır!',
          'scholarship.applications_suffix': '@title BURS BAŞVURULARI',
          'scholarship.my_applications_title': 'Burs Başvurularım',
          'scholarship.no_user_applications':
              'Burs başvurunuz bulunmamaktadır!',
          'scholarship.saved_empty': 'Kaydedilen burs bulunamadı.',
          'scholarship.liked_empty': 'Beğenilen burs bulunamadı.',
          'scholarship.remove_saved': 'Kaydedilenlerden Kaldır',
          'scholarship.remove_liked': 'Beğenilenlerden Kaldır',
          'scholarship.remove_saved_confirm':
              'Bu bursu kaydedilenlerden kaldırmak istediğinize emin misiniz?',
          'scholarship.remove_liked_confirm':
              'Bu bursu beğenilenlerden kaldırmak istediğinize emin misiniz?',
          'scholarship.removed_saved':
              'Burs kaydedilenlerden kaldırıldı.',
          'scholarship.removed_liked':
              'Burs beğenilenlerden kaldırıldı.',
          'scholarship.list_title': 'Burslar (@count)',
          'scholarship.search_results_title': 'Arama Sonuçları (@count)',
          'scholarship.empty_title': 'Henüz burs yok',
          'scholarship.empty_body': 'Yeni burslar yakında eklenecek',
          'scholarship.no_results_for':
              '"@query" için sonuç bulunamadı',
          'scholarship.search_hint_body':
              'İpucu: Farklı anahtar kelimeler deneyin',
          'scholarship.search_tip_header': 'Şunlara göre arayabilirsiniz:',
          'scholarship.load_more_failed': 'Daha fazla burs yüklenemedi.',
          'scholarship.like_failed': 'Beğeni işlemi başarısız.',
          'scholarship.bookmark_failed': 'Kaydetme işlemi başarısız.',
          'scholarship.share_owner_only':
              'Sadece admin ve ilan sahibi paylaşabilir.',
          'scholarship.share_missing_id': 'Paylaşım için burs ID bulunamadı.',
          'scholarship.share_failed': 'Paylaşım başarısız.',
          'scholarship.share_fallback_desc': 'TurqApp burs ilanı',
          'scholarship.share_detail_title': 'TurqApp Eğitim - Burs Detayı',
          'scholarship.providers_title': 'Burs Verenler',
          'scholarship.providers_empty': 'Burs veren bulunamadı.',
          'scholarship.providers_load_failed':
              'Burs verenler yüklenemedi.',
          'scholarship.applications_load_failed': 'Başvurular yüklenemedi.',
          'scholarship.applicant_load_failed':
              'Veriler yüklenirken bir hata oluştu.',
          'scholarship.withdraw_application': 'Başvurunu Geri Al',
          'scholarship.withdraw_confirm_title': 'Dikkat!',
          'scholarship.withdraw_confirm_body':
              'Başvurunu geri almak istediğinden emin misin?',
          'scholarship.withdraw_success': 'Burs başvurunuz geri alındı.',
          'scholarship.withdraw_failed': 'Başvuru geri alınamadı.',
          'scholarship.session_missing': 'Kullanıcı oturumu açık değil.',
          'scholarship.create_title': 'Burs Oluştur',
          'scholarship.edit_title': 'Burs Düzenle',
          'scholarship.preview_title': 'Burs Önizleme',
          'scholarship.visual_info': 'Görsel Bilgiler',
          'scholarship.basic_info': 'Temel Bilgiler',
          'scholarship.application_info': 'Başvuru Bilgileri',
          'scholarship.extra_info': 'Ek Bilgiler',
          'scholarship.title_label': 'Burs Başlığı',
          'scholarship.provider_label': 'Burs Veren',
          'scholarship.website_label': 'Web Sitesi',
          'scholarship.description_help':
              'Burs açıklamasını tek parça ve anlaşılır şekilde yazınız.',
          'scholarship.no_description': 'Açıklama yok',
          'scholarship.conditions_label': 'Başvuru Koşulları',
          'scholarship.required_docs_label': 'Gerekli Belgeler',
          'scholarship.award_months_label': 'Burs Verilecek Aylar',
          'scholarship.application_place_label': 'Başvuru Yapılacak Yer',
          'scholarship.application_place_turqapp': 'TurqApp',
          'scholarship.application_place_website': 'Burs Web Sitesi',
          'scholarship.application_website_label': 'Burs Web Sitesi',
          'scholarship.application_dates_label': 'Burs Başvuru Tarihleri',
          'scholarship.detail_missing': 'Hata: Burs verisi bulunamadı.',
          'scholarship.detail_title': 'Burs Detayı',
          'scholarship.delete_title': 'Bursu Sil',
          'scholarship.delete_confirm':
              'Bu bursu silmek istediğinizden emin misiniz?',
          'scholarship.applications_heading': '@title burs başvuruları',
          'scholarship.applicant.personal_section': 'Kişisel Bilgiler',
          'scholarship.applicant.education_section': 'Eğitim Bilgileri',
          'scholarship.applicant.family_section': 'Aile Bilgileri',
          'scholarship.applicant.full_name': 'Ad Soyad',
          'scholarship.applicant.email': 'Mail Adresi',
          'scholarship.applicant.phone': 'Telefon Numarası',
          'scholarship.applicant.phone_open_failed':
              'Telefon araması başlatılamadı',
          'scholarship.applicant.email_open_failed':
              'E-posta istemcisi açılamadı',
          'chat.sign_in_required': 'Mesaj göndermek için giriş yapmalısın.',
          'chat.cannot_message_self_listing':
              'Kendi ilanına mesaj gönderemezsin.',
          'scholarship.applicant.country': 'Ülke',
          'scholarship.applicant.registry_city': 'Nüfus İl',
          'scholarship.applicant.registry_district': 'Nüfus İlçe',
          'scholarship.applicant.birth_date': 'Doğum Tarihi',
          'scholarship.applicant.marital_status': 'Medeni Hal',
          'scholarship.applicant.gender': 'Cinsiyet',
          'scholarship.applicant.disability_report': 'Engelli Raporu',
          'scholarship.applicant.employment_status': 'Çalışma Durumu',
          'scholarship.applicant.education_level': 'Eğitim Düzeyi',
          'scholarship.applicant.university': 'Üniversite',
          'scholarship.applicant.faculty': 'Fakülte',
          'scholarship.applicant.department': 'Bölüm',
          'scholarship.applicant.father_alive': 'Baba Hayatta mı?',
          'scholarship.applicant.father_name': 'Baba Adı',
          'scholarship.applicant.father_surname': 'Baba Soyadı',
          'scholarship.applicant.father_phone': 'Baba Telefon',
          'scholarship.applicant.father_job': 'Baba Meslek',
          'scholarship.applicant.father_income': 'Baba Gelir',
          'scholarship.applicant.mother_alive': 'Anne Hayatta mı?',
          'scholarship.applicant.mother_name': 'Anne Adı',
          'scholarship.applicant.mother_surname': 'Anne Soyadı',
          'scholarship.applicant.mother_phone': 'Anne Telefon',
          'scholarship.applicant.mother_job': 'Anne Meslek',
          'scholarship.applicant.mother_income': 'Anne Gelir',
          'scholarship.applicant.home_ownership': 'Ev Mülkiyeti',
          'scholarship.applicant.residence_city': 'İkamet Şehir',
          'scholarship.applicant.residence_district': 'İkamet İlçe',
          'scholarship.dormitory_name_hint': 'Yurt Adı',
          'family_info.title': 'Aile Bilgileri',
          'family_info.reset_menu': 'Aile Bilgilerini Sıfırla',
          'family_info.reset_title': 'Aile Bilgilerini Sıfırla',
          'family_info.reset_body':
              'Tüm aile bilgileriniz silinecektir. Bu işlem geri alınamaz. Emin misiniz?',
          'family_info.select_father_alive':
              'Baba hayatta mı? seçimini yapınız',
          'family_info.select_mother_alive':
              'Anne hayatta mı? seçimini yapınız',
          'family_info.father_name_surname': 'Baba Ad - Soyad',
          'family_info.mother_name_surname': 'Anne Ad - Soyad',
          'family_info.select_job': 'Meslek Seç',
          'family_info.father_salary': 'Baba Net Maaş',
          'family_info.mother_salary': 'Anne Net Maaş',
          'family_info.father_phone': 'Baba İletişim Numarası',
          'family_info.mother_phone': 'Anne İletişim Numarası',
          'family_info.salary_hint': 'Net Maaş',
          'family_info.family_size': 'Aile Sayısı',
          'family_info.family_size_hint': 'Ailede (Siz Dahil) Yaşayan Sayısı',
          'family_info.residence_info': 'İkametgâh Bilgisi',
          'family_info.father_salary_missing': 'Baba maaş bilgisi',
          'family_info.father_phone_missing': 'Baba telefon numarası',
          'family_info.father_phone_invalid':
              'Baba telefon numarası 10 haneli olmalıdır',
          'family_info.mother_salary_missing': 'Anne maaş bilgisi',
          'family_info.mother_phone_missing': 'Anne telefon numarası',
          'family_info.mother_phone_invalid':
              'Anne telefon numarası 10 haneli olmalıdır',
          'family_info.saved': 'Aile bilgileriniz kaydedildi.',
          'family_info.save_failed':
              'Bilgiler kaydedilemedi. Lütfen tekrar deneyin.',
          'family_info.reset_success': 'Aile bilgileri sıfırlandı.',
          'family_info.reset_failed':
              'Bilgiler sıfırlanamadı. Lütfen tekrar deneyin.',
          'family_info.home_owned': 'Kendinize Ait Ev',
          'family_info.home_relative': 'Yakınınıza Ait Ev',
          'family_info.home_lodging': 'Lojman',
          'family_info.home_rent': 'Kira',
          'personal_info.title': 'Kişisel Bilgiler',
          'personal_info.reset_menu': 'Bilgilerimi Sıfırla',
          'personal_info.reset_title': 'Emin misiniz?',
          'personal_info.reset_body':
              'Kişisel bilgileriniz sıfırlanacak. Bu işlem geri alınamaz.',
          'personal_info.reset_success': 'Kişisel bilgileriniz sıfırlandı.',
          'personal_info.registry_info': 'Nüfusa Kayıtlı İl - İlçe',
          'personal_info.birth_date_title': 'Doğum Tarihiniz',
          'personal_info.select_birth_date': 'Doğum Tarihi Seç',
          'personal_info.select_marital_status': 'Medeni Hal Seç',
          'personal_info.select_gender': 'Cinsiyet Seç',
          'personal_info.select_disability': 'Engel Durumu Seç',
          'personal_info.select_employment': 'Çalışma Durumu Seç',
          'personal_info.select_field': '@field Seç',
          'personal_info.city_load_failed': 'Şehir ve ilçe verileri yüklenemedi.',
          'personal_info.user_data_missing':
              'Kullanıcı verisi bulunamadı. Yeni kayıt oluşturabilirsiniz.',
          'personal_info.load_failed': 'Veriler yüklenemedi.',
          'personal_info.select_country_error': 'Lütfen ülkeyi seçin.',
          'personal_info.fill_city_district':
              'Lütfen şehir ve ilçe bilgilerini doldurun.',
          'personal_info.saved': 'Kişisel bilgileriniz kaydedildi.',
          'personal_info.save_failed': 'Bilgiler kaydedilemedi.',
          'personal_info.marital_single': 'Bekar',
          'personal_info.marital_married': 'Evli',
          'personal_info.marital_divorced': 'Boşanmış',
          'personal_info.gender_male': 'Erkek',
          'personal_info.gender_female': 'Kadın',
          'personal_info.disability_yes': 'Var',
          'personal_info.disability_no': 'Yok',
          'personal_info.working_yes': 'Çalışıyor',
          'personal_info.working_no': 'Çalışmıyor',
          'education_info.title': 'Eğitim Bilgileri',
          'education_info.reset_menu': 'Eğitim Bilgilerimi Sıfırla',
          'education_info.reset_title': 'Emin misiniz?',
          'education_info.reset_body':
              'Eğitim bilgileriniz sıfırlanacak. Bu işlem geri alınamaz.',
          'education_info.reset_success': 'Eğitim bilgileriniz sıfırlandı.',
          'education_info.select_level': 'Lütfen bir eğitim seviyesi seçin!',
          'education_info.middle_school': 'Okul',
          'education_info.high_school': 'Lise',
          'education_info.class_level': 'Sınıf',
          'education_info.level_middle_school': 'Ortaokul',
          'education_info.level_high_school': 'Lise',
          'education_info.level_associate': 'Önlisans',
          'education_info.level_bachelor': 'Lisans',
          'education_info.level_masters': 'Yüksek Lisans',
          'education_info.level_doctorate': 'Doktora',
          'education_info.class_grade': '@grade. Sınıf',
          'education_info.select_field': '@field Seç',
          'education_info.initial_load_failed':
              'Başlangıç verileri yüklenemedi.',
          'education_info.countries_load_failed': 'Ülkeler yüklenemedi.',
          'education_info.city_data_failed': 'İl-ilçe verileri yüklenemedi.',
          'education_info.middle_schools_failed': 'Okul verileri yüklenemedi.',
          'education_info.high_schools_failed': 'Lise verileri yüklenemedi.',
          'education_info.higher_education_failed':
              'Yükseköğretim verileri yüklenemedi.',
          'education_info.saved_data_failed':
              'Kayıtlı veriler yüklenemedi.',
          'education_info.level_load_failed': 'Seviye verileri yüklenemedi.',
          'education_info.select_city_error': 'Lütfen bir il seçin.',
          'education_info.select_district_error': 'Lütfen bir ilçe seçin.',
          'education_info.select_middle_school_error':
              'Lütfen bir ortaokul seçin.',
          'education_info.select_high_school_error':
              'Lütfen bir lise seçin.',
          'education_info.select_class_level_error':
              'Lütfen bir sınıf seviyesi seçin.',
          'education_info.select_university_error':
              'Lütfen bir üniversite seçin.',
          'education_info.select_faculty_error':
              'Lütfen bir fakülte seçin.',
          'education_info.select_department_error':
              'Lütfen bir bölüm seçin.',
          'education_info.saved': 'Eğitim bilgileriniz kaydedildi.',
          'education_info.save_failed': 'Kayıt başarısız.',
          'bank_info.title': 'Banka Bilgileri',
          'bank_info.reset_menu': 'Banka Bilgilerimi Sıfırla',
          'bank_info.reset_title': 'Emin misiniz?',
          'bank_info.reset_body':
              'Banka bilgileriniz sıfırlanacak. Bu işlem geri alınamaz.',
          'bank_info.reset_success': 'Banka bilgileriniz sıfırlandı.',
          'bank_info.fast_title': 'Kolay Adres (FAST)',
          'bank_info.fast_email': 'E-Posta',
          'bank_info.fast_phone': 'Telefon',
          'bank_info.fast_iban': 'IBAN',
          'bank_info.bank_label': 'Banka',
          'bank_info.select_bank': 'Banka Seç',
          'bank_info.select_fast_type': 'Kolay Adres Tipi Seç',
          'bank_info.load_failed': 'Veri yüklenemedi.',
          'bank_info.missing_value':
              'IBAN bilgisini tamamlamadan devam edemeyiz.',
          'bank_info.missing_bank':
              'Ödeme alacağınız banka seçmediniz. Bursunuz onaylanması durumunda bu bilgi paylaşılacaktır.',
          'bank_info.invalid_email': 'Lütfen geçerli bir e-posta adresi girin.',
          'bank_info.saved': 'Banka bilgileri kaydedildi.',
          'bank_info.save_failed': 'Bilgiler kaydedilemedi.',
          'dormitory.title': 'Yurt Bilgileri',
          'dormitory.reset_menu': 'Yurt Bilgilerimi Sıfırla',
          'dormitory.reset_title': 'Emin misiniz?',
          'dormitory.reset_body':
              'Yurt bilgileriniz sıfırlanacak. Bu işlem geri alınamaz.',
          'dormitory.reset_success': 'Yurt bilgileriniz sıfırlandı.',
          'dormitory.current_info': 'Mevcut Yurt Bilgisi',
          'dormitory.select_admin_type': 'İdari Seç',
          'dormitory.admin_public': 'Devlet',
          'dormitory.admin_private': 'Özel',
          'dormitory.select_dormitory': 'Yurt Seç',
          'dormitory.not_found_for_filters':
              'Bu şehir ve idari tür için yurt bulunamadı',
          'dormitory.saved': 'Yurt bilgileriniz kaydedildi.',
          'dormitory.save_failed': 'Veri kaydedilemedi.',
          'dormitory.select_or_enter':
              'Lütfen bir yurt seçin veya yurt adı girin',
          'scholarship.application_start_date':
              'Burs Başvuru Başlangıç Tarihi',
          'scholarship.application_end_date':
              'Burs Başvuru Bitiş Tarihi',
          'scholarship.select_from_list': 'Listeden Seç',
          'scholarship.image_missing': 'Görsel Bulunamadı',
          'scholarship.amount_label': 'Tutar',
          'scholarship.student_count_label': 'Öğrenci Sayısı',
          'scholarship.repayable_label': 'Geri Ödemeli',
          'scholarship.duplicate_status_label': 'Mükerrer Durumu',
          'scholarship.education_audience_label': 'Eğitim Kitlesi',
          'scholarship.target_audience_label': 'Hedef Kitle',
          'scholarship.country_label': 'Ülke',
          'scholarship.cities_label': 'Şehirler',
          'scholarship.universities_label': 'Üniversiteler',
          'scholarship.published_at': 'İlan Yayınlanma Tarihi',
          'scholarship.show_less': 'Daha az göster',
          'scholarship.show_all': 'Tümünü Göster',
          'scholarship.more_universities': '+@count üniversite daha',
          'scholarship.other_info': 'Diğer Bilgiler',
          'scholarship.application_how': 'Başvuru Nasıl Yapılacak?',
          'scholarship.application_via_turqapp_prefix':
              'Başvurular TurqApp üzerinden ',
          'scholarship.application_received_status': 'ALINMAKTADIR.',
          'scholarship.application_not_received_status': 'ALINMAMAKTADIR.',
          'scholarship.edit_button': 'Bursu Düzenle',
          'scholarship.website_open_failed':
              'Web sitesi açılamadı. Lütfen geçerli bir URL girin.',
          'scholarship.checking_info': 'Bilgiler kontrol ediliyor',
          'scholarship.user_data_missing':
              'Kullanıcı verisi bulunamadı. Lütfen bilgilerinizi doldurun.',
          'scholarship.check_info_failed':
              'Bilgiler kontrol edilirken hata oluştu.',
          'scholarship.application_check_failed':
              'Başvuru durumu kontrol edilirken hata oluştu.',
          'scholarship.login_required': 'Lütfen oturum açın.',
          'scholarship.profile_missing':
              'Bu burs için profil bilgisi bulunmamaktadır.',
          'scholarship.applied_success': 'Burs başvurunuz alınmıştır.',
          'scholarship.apply_failed': 'Başvuru kaydedilemedi.',
          'scholarship.follow_limit_title': 'Takip Limiti',
          'scholarship.follow_limit_body':
              'Günlük daha fazla kişi takip edilemiyor.',
          'scholarship.follow_failed': 'Takip işlemi başarısız.',
          'scholarship.invalid': 'Geçersiz burs.',
          'scholarship.delete_success': 'Burs başarıyla silindi.',
          'scholarship.delete_failed': 'Burs silinirken bir hata oluştu.',
          'scholarship.cancel_success': 'Burs başvurunuz iptal edildi.',
          'scholarship.cancel_failed': 'Başvuru iptal edilemedi.',
          'scholarship.info_missing_title': 'Bilgilerin Eksik',
          'scholarship.info_missing_body':
              'Kişisel, Okul ve Aile bilgilerini doldurmadan burslara başvuru yapamazsınız!',
          'scholarship.update_my_info': 'Bilgilerimi Güncelle',
          'scholarship.closed': 'Başvuru Kapandı',
          'scholarship.applied': 'Başvuru Yaptın',
          'scholarship.cancel_apply_title': 'Başvuruyu İptal Et',
          'scholarship.cancel_apply_body':
              'Bu burs başvurusunu iptal etmek istediğinizden emin misiniz?',
          'scholarship.cancel_apply_button': 'İptal Et',
          'scholarship.amount_hint': 'Miktar',
          'scholarship.student_count_hint': 'ör: 4',
          'scholarship.amount_student_count_notice':
              '\'Miktar\' ve \'Öğrenci Sayısı\' bilgileri başvuru sayfasında görüntülenmemektedir.',
          'scholarship.degree_type_label': 'Lisans Türü',
          'scholarship.degree_type_select': 'Lisans Türü Seç',
          'scholarship.select_country': 'Ülke Seç',
          'scholarship.select_country_first': 'Lütfen önce bir ülke seçin.',
          'scholarship.select_city_first': 'Lütfen önce bir il seçin.',
          'scholarship.select_university': 'Üniversite Seç',
          'scholarship.selected_universities': 'Seçilen Üniversiteler:',
          'scholarship.logo_label': 'Logo Seç',
          'scholarship.logo_pick': 'Logo Seçin',
          'scholarship.custom_design_optional': 'Tasarımınız (Opsiyonel)',
          'scholarship.custom_image_pick': 'Görsel Seçin',
          'scholarship.template_select': 'Şablon Seç',
          'scholarship.file_copy_failed': 'Dosya kopyalanamadı.',
          'scholarship.data_load_failed': 'Burs verisi yüklenemedi.',
          'scholarship.city_data_failed': 'İl-ilçe verisi yüklenemedi.',
          'scholarship.university_data_failed':
              'Üniversite verisi yüklenemedi.',
          'scholarship.file_missing': 'Seçilen dosya bulunamadı.',
          'scholarship.image_convert_failed':
              'Görsel WebP formatına dönüştürülemedi.',
          'scholarship.image_upload_failed':
              'Görsel yüklenirken bir hata oluştu.',
          'scholarship.template_convert_failed':
              'Şablon görseli WebP formatına dönüştürülemedi.',
          'scholarship.template_capture_failed':
              'Şablon görüntüsü yakalanamadı.',
          'scholarship.published_success': 'Burs başarıyla paylaşıldı!',
          'scholarship.publish_failed':
              'Burs paylaşılırken bir hata oluştu.',
          'scholarship.updated_success': 'Burs başarıyla güncellendi!',
          'scholarship.update_failed':
              'Burs güncellenirken bir hata oluştu.',
          'search_permission.title': 'Arama İzni',
          'scholarship.duplicate_status.can_receive': 'Alabilir',
          'scholarship.duplicate_status.cannot_receive_except_kyk':
              'Alamaz (KYK Hariç)',
          'scholarship.target.population': 'Nüfusa Göre',
          'scholarship.target.residence': 'İkamete Göre',
          'scholarship.target.all_turkiye': 'Tüm Türkiye',
          'scholarship.info.personal': 'Kişisel',
          'scholarship.info.school': 'Okul',
          'scholarship.info.family': 'Aile',
          'scholarship.info.dormitory': 'Yurt',
          'scholarship.education.all': 'Hepsi',
          'scholarship.education.middle_school': 'Ortaokul',
          'scholarship.education.high_school': 'Lise',
          'scholarship.education.undergraduate': 'Lisans',
          'scholarship.degree.associate': 'Ön Lisans',
          'scholarship.degree.bachelor': 'Lisans',
          'scholarship.degree.master': 'Yüksek Lisans',
          'scholarship.degree.phd': 'Doktora',
          'single_post.title': 'Gönderiler',
          'edit_post.updating': 'Lütfen Bekle. Gönderiniz güncelleniyor',
          'common.district': 'İlçe',
          'common.price': 'Fiyat',
          'common.views': 'Görüntülenme',
          'common.company': 'Şirket',
          'common.salary': 'Ücret',
          'common.address': 'Adres',
          'common.language': 'Dil',
          'profile_photo.camera': 'Kameradan Çek',
          'profile_photo.gallery': 'Galeriden Seç',
          'edit_profile.title': 'Profil Bilgileri',
          'edit_profile.personal_info': 'Kişisel Bilgiler',
          'edit_profile.other_info': 'Diğer Bilgiler',
          'edit_profile.first_name_hint': 'Adınız',
          'edit_profile.last_name_hint': 'Soyadınız',
          'edit_profile.privacy': 'Hesap Gizliliği',
          'edit_profile.links': 'Bağlantılar',
          'edit_profile.contact_info': 'İletişim Bilgileri',
          'edit_profile.address_info': 'Adres Bilgileri',
          'edit_profile.career_profile': 'Kariyer Profili',
          'personal_info.select_country_title': 'Ülke Seç',
          'personal_info.select_marital_status_title': 'Medeni Hal Seç',
          'personal_info.select_gender_title': 'Cinsiyet Seç',
          'personal_info.select_disability_title': 'Engel Durumu Seç',
          'personal_info.select_work_status_title': 'Çalışma Durumu Seç',
          'edit_profile.update_success': 'Profil bilgilerin güncellendi!',
          'edit_profile.update_failed': 'Güncelleme hatası: {error}',
          'edit_profile.remove_photo_title': 'Profil Fotoğrafını Kaldır',
          'edit_profile.remove_photo_message':
              'Profil fotoğrafın kaldırılacak ve varsayılan avatar kullanılacak. Emin misin?',
          'edit_profile.photo_removed': 'Profil fotoğrafın kaldırıldı.',
          'edit_profile.photo_remove_failed':
              'Profil fotoğrafı kaldırılırken bir hata oluştu.',
          'edit_profile.crop_use': 'Kırp ve Kullan',
          'edit_profile.delete_account': 'Hesabını Sil',
          'edit_profile.upload_failed_title': 'Yükleme Başarısız!',
          'edit_profile.upload_failed_body':
              'Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.',
          'delete_account.title': 'Hesabını Sil',
          'delete_account.confirm_title': 'Hesap Silme Onayı',
          'delete_account.confirm_body':
              'Hesabınızı silmeden önce güvenlik için kayıtlı e-posta adresinize onay kodu gönderiyoruz.',
          'delete_account.code_hint': '6 haneli onay kodu',
          'delete_account.resend': 'Tekrar Gönder',
          'delete_account.send_code': 'Kod Gönder',
          'delete_account.validity_notice':
              'Kodun geçerlilik süresi 1 saattir. Silme talebiniz {days} gün sonra kalıcı olarak işlenir.',
          'delete_account.processing': 'İşleniyor...',
          'delete_account.delete_my_account': 'Hesabımı Sil',
          'delete_account.no_email_title': 'Uyarı',
          'delete_account.no_email_body':
              'Bu hesapta e-posta yok. Silme talebini direkt başlatabilirsiniz.',
          'delete_account.session_missing':
              'Oturum bulunamadı. Tekrar giriş yapın.',
          'delete_account.code_sent_title': 'Kod Gönderildi',
          'delete_account.code_sent_body':
              'Silme onay kodu e-posta adresinize gönderildi.',
          'delete_account.send_failed': 'Kod gönderilemedi.',
          'delete_account.invalid_code_title': 'Geçersiz Kod',
          'delete_account.invalid_code_body': 'Lütfen 6 haneli kod girin.',
          'delete_account.verify_failed': 'Kod doğrulanamadı.',
          'delete_account.request_received_title': 'Talep Alındı',
          'delete_account.request_received_body':
              'Hesabınız {days} gün sonunda kalıcı olarak silinecektir.',
          'delete_account.request_failed':
              'Hesabınız silinirken bir sorun oluştu. Lütfen daha sonra tekrar deneyin.',
          'editor_nickname.title': 'Kullanıcı Adı',
          'editor_nickname.hint': 'Kullanıcı Adı Oluştur',
          'editor_nickname.verified_locked':
              'Onaylı kullanıcılar, kullanıcı adını değiştiremez',
          'editor_nickname.mimic_warning':
              'Gerçek kişileri taklit eden kullanıcı adları, topluluğumuzu korumak adına Turqapp tarafından değiştirilebilir.',
          'editor_nickname.tr_char_info':
              'Türkçe karakterler otomatik dönüştürülür. (ç→c, ğ→g, ı→i, ö→o, ş→s, ü→u)',
          'editor_nickname.min_length': 'En az 8 karakter olmalı',
          'editor_nickname.current_name': 'Mevcut kullanıcı adın',
          'editor_nickname.edit_prompt': 'Değişiklik yapmak için düzenle',
          'editor_nickname.checking': 'Kontrol ediliyor…',
          'editor_nickname.taken': 'Bu kullanıcı adı alınmış',
          'editor_nickname.available': 'Kullanılabilir',
          'editor_nickname.unavailable': 'Kontrol edilemedi',
          'editor_nickname.cooldown_limit':
              'İlk 1 saatte en fazla 3 kez değiştirilebilir',
          'editor_nickname.change_after_days':
              'Kullanıcı adı tekrar değiştirilebilir: {days}g {hours}s sonra',
          'editor_nickname.change_after_hours':
              'Kullanıcı adı tekrar değiştirilebilir: {hours}s sonra',
          'editor_nickname.error_min_length':
              'Kullanıcı adı en az 8 karakter olmalıdır.',
          'editor_nickname.error_taken':
              'Bu kullanıcı adı zaten alınmış.',
          'editor_nickname.error_grace_limit':
              'İlk 1 saatte en fazla 3 kez değiştirebilirsin.',
          'editor_nickname.error_cooldown':
              'Kullanıcı adı 15 gün dolmadan tekrar değiştirilemez.',
          'editor_nickname.error_update_failed':
              'Kullanıcı adı güncellenemedi.',
          'cv.title': 'Kariyer Profili',
          'cv.personal_info': 'Kişisel Bilgiler',
          'cv.education_info': 'Eğitim Bilgileri',
          'cv.other_info': 'Diğer Bilgiler',
          'cv.profile_title': 'Kariyer Profili',
          'cv.profile_body':
              'Profil fotoğrafı ve temel bilgilerle kariyer profilinizi daha güçlü gösterin.',
          'cv.first_name_hint': 'Adınız',
          'cv.last_name_hint': 'Soyadınız',
          'cv.email_hint': 'Mail Adresi',
          'cv.phone_hint': 'Telefon Numarası',
          'cv.about_hint': 'Kendiniz hakkında kısa bilgi verin',
          'cv.add_school': 'Yeni okul ekle',
          'cv.add_school_title': 'Yeni Okul Ekle',
          'cv.edit_school_title': 'Okul Düzenle',
          'cv.school_name': 'Okul Adı',
          'cv.department': 'Bölüm',
          'cv.graduation_year': 'Mezuniyet Yılı',
          'cv.currently_studying': 'Devam Ediyorum',
          'cv.missing_school_name': 'Okul adı boş bırakılamaz',
          'cv.invalid_year': 'Geçerli bir yıl girin',
          'cv.skills': 'Beceriler',
          'cv.add_skill_title': 'Yeni Beceri Ekle',
          'cv.skill_name_empty': 'Beceri adı boş bırakılamaz',
          'cv.skill_exists': 'Bu beceri zaten eklenmiş',
          'cv.skill_hint': 'Beceri (ör. Flutter, Photoshop)',
          'cv.add_language': 'Dil Ekle',
          'cv.add_new_language': 'Yeni dil ekle',
          'cv.add_language_title': 'Yeni Dil Ekle',
          'cv.edit_language_title': 'Dil Düzenle',
          'cv.language.english': 'İngilizce',
          'cv.language.german': 'Almanca',
          'cv.language.french': 'Fransızca',
          'cv.language.spanish': 'İspanyolca',
          'cv.language.arabic': 'Arapça',
          'cv.language.turkish': 'Türkçe',
          'cv.language.russian': 'Rusça',
          'cv.language.italian': 'İtalyanca',
          'cv.language.korean': 'Korece',
          'cv.level': 'Seviye',
          'cv.add_experience': 'İş Deneyimi Ekle',
          'cv.add_new_experience': 'Yeni iş deneyimi ekle',
          'cv.add_experience_title': 'Yeni İş Deneyimi Ekle',
          'cv.edit_experience_title': 'Deneyim Düzenle',
          'cv.company_name': 'Firma Adı',
          'cv.position': 'Pozisyon',
          'cv.description_optional': 'Görev Tanımı (opsiyonel)',
          'cv.start_year': 'Başlangıç',
          'cv.end_year': 'Ayrılış',
          'cv.currently_working': 'Hâlen çalışıyorum',
          'cv.ongoing': 'Devam Ediyor',
          'cv.missing_company_position': 'Firma adı ve pozisyon zorunludur',
          'cv.invalid_start_year': 'Geçerli bir başlangıç yılı girin',
          'cv.invalid_end_year': 'Geçerli bir ayrılış yılı girin',
          'cv.add_reference': 'Referans Ekle',
          'cv.add_new_reference': 'Yeni referans ekle',
          'cv.add_reference_title': 'Yeni Referans Ekle',
          'cv.edit_reference_title': 'Referans Düzenle',
          'cv.name_surname': 'Ad Soyad',
          'cv.phone_example': 'Telefon (ör, 05xx..)',
          'cv.missing_name_surname': 'Ad soyad boş bırakılamaz',
          'cv.save': 'Kaydet',
          'cv.created_title': 'CV Oluşturuldu!',
          'cv.created_body':
              'Şimdi iş başvurusu yaparken daha hızlı bir şekilde başvurabilirsin',
          'cv.save_failed': 'CV kaydedilemedi. Tekrar deneyin.',
          'cv.not_signed_in': 'Oturum açık değil.',
          'cv.photo_inappropriate':
              'Profil fotoğrafı uygunsuz içerik içeriyor.',
          'cv.photo_upload_failed': 'Profil fotoğrafı yüklenemedi.',
          'cv.missing_field': 'Eksik Alan',
          'cv.invalid_format': 'Hatalı Format',
          'cv.missing_first_name': 'İsim girmeden kaydedemezsiniz',
          'cv.missing_last_name': 'Soyisim girmeden kaydedemezsiniz',
          'cv.missing_email': 'Mail adresi girmeden kaydedemezsiniz',
          'cv.invalid_email': 'Geçerli bir e-posta adresi girin',
          'cv.missing_phone': 'Telefon numarası girmeden kaydedemezsiniz',
          'cv.invalid_phone': 'Geçerli bir telefon numarası girin',
          'cv.missing_about':
              'Kendiniz hakkında kısa bilgi vermek zorundasınız',
          'cv.missing_school':
              'En az bir okul bilgisi girmeden kaydedemezsiniz',
          'qr.title': 'Kişisel QR Kod',
          'qr.profile_subject': 'TurqApp Profili',
          'qr.profile_desc': 'TurqApp profilini görüntüle',
          'qr.link_copied_title': 'Link Kopyalandı',
          'qr.link_copied_body': 'Profil linki panoya kopyalandı',
          'qr.permission_required': 'İzin Gerekli',
          'qr.gallery_permission_body':
              'Kaydetmek için galeri erişim izni vermelisiniz.',
          'qr.data_failed': 'QR kod verisi oluşturulamadı.',
          'qr.saved': 'QR kodu galeriye kaydedildi.',
          'qr.save_failed': 'QR kod kaydedilemedi.',
          'qr.download_failed': 'İndirme sırasında hata oluştu.',
          'post_creator.title_new': 'Gönderi Hazırla',
          'post_creator.title_edit': 'Gönderi Düzenle',
          'post_creator.text_hint': 'Gönderi metni',
          'post_creator.publish': 'Yayınla',
          'post_creator.uploading': 'Yükleniyor...',
          'post_creator.saving': 'Kaydediliyor...',
          'post_creator.placeholder': 'Ne var ne yok ?',
          'post_creator.processing_wait': 'Lütfen bekle. Video işleniyor...',
          'post_creator.video_processing': 'Video İşleniyor',
          'post_creator.look.original': 'Orijinal',
          'post_creator.look.clear': 'Temiz',
          'post_creator.look.cinema': 'Sinematik',
          'post_creator.look.vibe': 'Canlı',
          'post_creator.comments.everyone': 'Herkes',
          'post_creator.comments.verified': 'Onaylı hesaplar',
          'post_creator.comments.following': 'Takip ettiğin hesaplar',
          'post_creator.comments.closed': 'Yoruma kapalı',
          'post_creator.comments.title': 'Kimler yanıtlayabilir?',
          'post_creator.comments.subtitle':
              'Bu gönderiyi kimlerin yanıtlayabileceğini seç.',
          'post_creator.reshare.everyone': 'Herkes',
          'post_creator.reshare.verified': 'Onaylı hesaplar',
          'post_creator.reshare.following': 'Takip ettiğin hesaplar',
          'post_creator.reshare.closed': 'Yeniden paylaş kapalı',
          'post_creator.schedule.remove_title': 'Planlamayı Kaldır',
          'post_creator.schedule.remove_message':
              'Zamanlanmış paylaşımı kaldırmak istiyor musun? Gönderi hemen paylaşılacak.',
          'post_creator.cover_title': 'Kapak Fotoğrafı Seç',
          'post_creator.cover_selected': 'Kapak seçildi',
          'post_creator.use_address': 'Bu adresi kullan',
          'post_creator.poll_title': 'Anket',
          'post_creator.poll_time_options': 'Zaman Seçenekleri',
          'post_creator.poll_option': 'Seçenek {index}',
          'post_creator.poll_add_option': '+ Bir seçenek daha ekle',
          'post_creator.poll_min_options': 'En az iki seçenek zorunlu.',
          'post_creator.poll_requirement':
              'Anket için açıklama veya görsel/video gerekli.',
          'post_creator.validation_failed':
              'Gönderi doğrulaması başarısız',
          'post_creator.firestore_save_failed': 'Firestore kaydetme başarısız',
          'post_creator.upload_failed_title': 'Yükleme Başarısız',
          'post_creator.upload_failed_message':
              'İçerik güvenlik kontrolü tamamlanamadı.',
          'post_creator.image_rejected': 'Bu görsel yüklenemiyor.',
          'post_creator.video_rejected': 'Bu video yüklenemiyor.',
          'post_creator.no_internet': 'İnternet bağlantısı bulunamadı',
          'post_creator.draft_save_failed': 'Taslak kaydetme başarısız',
          'post_creator.reshare_privacy_title': 'Yeniden Paylaş Gizliliği',
          'post_creator.reshare_everyone_desc':
              'Herkes yeniden paylaşabilir.',
          'post_creator.reshare_followers_desc':
              'Sadece takipçilerim yeniden paylaşabilir.',
          'post_creator.reshare_closed_desc': 'Paylaşıma kapalı.',
          'post_creator.schedule_title': 'İz Bırak Yayın Tarihi',
          'post_creator.publish_item': 'Gönderi {index}',
          'post_creator.preparing_posts': 'Gönderiler hazırlanıyor...',
          'post_creator.uploading_media': 'Medya dosyaları yükleniyor...',
          'post_creator.saving_to_database': 'Veritabanına kaydediliyor...',
          'post_creator.video_nsfw_check_failed':
              'NSFW video kontrolü başarısız',
          'post_creator.post_counter_failed': 'Post sayacı güncellenemedi',
          'post_creator.edit_target_missing':
              'Düzenlenecek gönderi bulunamadı',
          'post_creator.edit_content_missing':
              'Düzenleme içeriği bulunamadı',
          'post_creator.edit_updated': 'Gönderi güncellendi',
          'post_creator.edit_update_failed': 'Gönderi güncellenemedi',
          'post_creator.upload_failed_generic': 'Gönderi yükleme başarısız',
          'post_creator.queue_already_added':
              'Bu medya zaten yükleme kuyruğunda.',
          'post_creator.queue_added_complete':
              'Gönderiler kuyruğa eklendi! Arka planda yüklenecek.',
          'post_creator.queue_title': 'Yükleme Kuyruğu',
          'post_creator.queue_added_body':
              'Gönderiler arka plan kuyruğuna eklendi',
          'post_creator.queue_add_failed': 'Kuyruk ekleme başarısız',
          'post_creator.photo_with_video_forbidden':
              'Video seçiliyken fotoğraf ekleyemezsiniz. En fazla 1 video seçilebilir.',
          'post_creator.max_photo_count':
              'Maksimum {count} fotoğraf seçilebilir.',
          'post_creator.max_photo_add':
              'Maksimum {count} fotoğraf ekleyebilirsiniz. Mevcut: {current}, Eklenmek istenen: {adding}',
          'post_creator.photo_validation_prefix': 'Fotoğraf {index}: {error}',
          'post_creator.photos_compression_failed':
              'Fotoğraflar eklendi ancak sıkıştırma başarısız oldu.',
          'post_creator.warning_title': 'Uyarı',
          'post_creator.success_title': 'Başarılı!',
          'post_creator.photo_added': 'Fotoğraf eklendi. {saved}',
          'post_creator.photo_added_no_compress':
              'Fotoğraf eklendi ancak sıkıştırma başarısız oldu.',
          'post_creator.max_video_count':
              'En fazla {count} video seçebilirsiniz.',
          'post_creator.no_post_uploaded': 'Hiçbir gönderi yüklenemedi',
          'post_creator.image_upload_failed': 'Resim {index} yüklenemedi',
          'post_creator.video_reduce_failed':
              'Video 35MB altına indirilemedi. 35MB altı direkt, 60MB üstü desteklenmez.',
          'post_creator.video_upload_failed': 'Video yüklenemedi',
          'post_creator.post_upload_failed': 'Gönderi {index} yüklenemedi',
          'post_creator.upload_success': 'Gönderiler başarıyla yayınlandı!',
          'post_creator.upload_error': 'Gönderi yüklenirken hata oluştu.',
          'post_creator.upload_process_failed': 'Yükleme işlemi başarısız',
          'post_creator.critical_error': 'Kritik hata oluştu.',
        },
        'en_US': {
          'settings.title': 'Settings',
          'settings.account': 'Account',
          'settings.content': 'Content',
          'settings.app': 'App',
          'settings.security_support': 'Security and Support',
          'settings.my_tasks': 'My Tasks',
          'settings.system_diagnostics': 'System and Diagnostics',
          'settings.session': 'Session',
          'settings.language': 'Language',
          'settings.edit_profile': 'Edit Profile',
          'settings.badge_application': 'My Badge Application',
          'settings.badge_renew': 'Renew Badge',
          'settings.become_verified': 'Become Verified',
          'become_verified.intro':
              'Verification badges are used in our mobile app to identify different user groups and highlight their reliability.',
          'become_verified.annual_renewal': 'Must be renewed every year.',
          'become_verified.footer':
              'Our badges aim to help our community interact in a safe and transparent environment.\n\nFor more information about profile verification, you can contact the TurqApp support team.',
          'become_verified.feature_ads': 'Ads',
          'become_verified.feature_limited_ads': 'Limited Ads',
          'become_verified.feature_post_boost': 'Post Boost',
          'become_verified.feature_highest': 'Highest',
          'become_verified.feature_video_download': 'Video Download',
          'become_verified.feature_long_video': 'Long-form Video Publishing',
          'become_verified.feature_statistics': 'Statistics',
          'become_verified.feature_username': 'Username',
          'become_verified.feature_verification_mark': 'Verification Mark',
          'become_verified.feature_account_protection':
              'Enhanced Account Protection',
          'become_verified.feature_channel_creation': 'Channel Creation',
          'become_verified.feature_priority_support': 'Advanced Support',
          'become_verified.feature_scheduled_video': 'Scheduled Video',
          'become_verified.feature_unlimited_listings':
              'Unlimited Listing Creation',
          'become_verified.feature_unlimited_links':
              'Unlimited Link Addition',
          'become_verified.feature_assistant': 'Become an Assistant',
          'become_verified.feature_scheduled_content':
              'Scheduled Content Sharing',
          'become_verified.feature_character_limit': 'Character Limit',
          'become_verified.feature_character_limit_value': '1000 Characters',
          'become_verified.loss_title': 'Loss of Verification Badge',
          'become_verified.loss_body':
              'If our team reviews your account and decides it still meets our requirements, the verification mark may be shown again. TurqApp may also remove the badge from accounts found to violate TurqApp rules.',
          'become_verified.step_social_accounts':
              '1. Your Social Media Accounts',
          'become_verified.step_requested_username':
              '2. Requested Username',
          'become_verified.requested_username_hint': 'Requested username',
          'become_verified.step_social_confirmation':
              '3. Social Media Confirmation',
          'become_verified.social_confirmation_body':
              'You can send your requested username together with your current TurqApp username via one of the accounts below from a social media account that belongs to you.',
          'become_verified.consent':
              'I confirm that the information I entered belongs to me and that I accept the application review process.',
          'become_verified.step_barcode':
              '5. E-Government Student Certificate Barcode No',
          'become_verified.barcode_hint': '20-digit barcode number',
          'become_verified.submit': 'Apply',
          'become_verified.received_title': 'Application Received',
          'become_verified.received_body':
              'Your application has been queued. We will notify you when the review is completed positively.',
          'become_verified.received_note':
              'Review time may vary depending on workload. You will be informed through the app once it is finalized.',
          'become_verified.session_missing': 'Session not found.',
          'become_verified.already_received':
              'Your application has already been received.',
          'become_verified.submit_failed':
              'Application could not be saved.',
          'become_verified.badge_blue': 'Blue',
          'become_verified.badge_red': 'Red',
          'become_verified.badge_yellow': 'Yellow',
          'become_verified.badge_turquoise': 'Turquoise',
          'become_verified.badge_gray': 'Gray',
          'become_verified.badge_black': 'Black',
          'become_verified.badge_blue_desc':
              'Designed for individual users.\nIt indicates that the profile is verified and trustworthy.',
          'become_verified.badge_red_desc':
              'Designed for students and teachers.\nIt represents an identity verified in the field of education.',
          'become_verified.badge_yellow_desc':
              'Given to companies and commercial organizations.\nIt indicates that the institution is an official business.',
          'become_verified.badge_turquoise_desc':
              'Given to non-governmental organizations.\nIt indicates that the organizations are official and trustworthy.',
          'become_verified.badge_gray_desc':
              'Defined specifically for public institutions, state bodies and officials.\nIt symbolizes official status and reliability.',
          'become_verified.badge_black_desc':
              'Designed for our content moderator users.\nIt represents an identity that blocks users and removes content.',
          'settings.blocked_users': 'Blocked Users',
          'settings.interests': 'Interests',
          'settings.account_center': 'Account Center',
          'settings.career_profile': 'Career Profile',
          'settings.saved_posts': 'Saved Posts',
          'settings.archive': 'Archive',
          'settings.liked_posts': 'Liked Posts',
          'settings.notifications': 'Notifications',
          'settings.permissions': 'Permissions',
          'settings.pasaj': 'Pasaj',
          'settings.pasaj.practice_exam': 'Practice Exam',
          'education.previous_questions': 'Practice Tests',
          'tests.results_title': 'Results',
          'tests.results_empty':
              'No results found.\nThere is no answer or question data for this test.',
          'tests.correct': 'Correct',
          'tests.wrong': 'Wrong',
          'tests.blank': 'Blank',
          'tests.net': 'Net',
          'tests.score': 'Score',
          'tests.question_number': 'Question @index',
          'tests.solve_no_questions':
              'Question not found.\nQuestions for this test could not be loaded.',
          'tests.finish_test': 'Finish Test',
          'tests.my_results_empty':
              'No results found.\nYou have not solved any tests before.',
          'tests.saved_empty': 'There are no saved tests.',
          'tests.result_answer_missing':
              'No results found.\nThere is no answer data for this test.',
          'tests.type_test': '@type Test',
          'tests.description_test': '@description Test',
          'tests.solve_count': 'You solved it @count times',
          'tests.create_title': 'Create Test',
          'tests.edit_title': 'Edit Test',
          'tests.create_data_missing':
              'Data not found.\nApp links or test questions could not be loaded.',
          'tests.create_upload_failed':
              'This content cannot be processed right now. Please try a different one.',
          'tests.select_branch': 'Select Branch',
          'tests.select_language': 'Select Language',
          'tests.cover_select': 'Select Cover Image',
          'tests.cover_load_failed':
              'Cover image could not be loaded. Please try again.',
          'tests.create_description_hint':
              '9th Grade Exponential Expressions and Radical Expressions',
          'tests.details': 'Exam Details',
          'tests.question_counts': 'Question Counts',
          'tests.question_count': 'Question Count',
          'tests.date': 'Exam Date',
          'tests.time': 'Exam Time',
          'tests.duration': 'Exam Duration',
          'tests.questions_data_failed':
              'Lesson information could not be loaded. Please check the exam type or try again.',
          'tests.creating': 'Creating Exam...',
          'tests.image_pick_failed': 'Image could not be selected.',
          'tests.image_invalid': 'The selected image is not suitable.',
          'tests.image_analyze_failed':
              'Image analysis could not be completed.',
          'tests.image_upload_failed_short': 'Image could not be uploaded.',
          'tests.save_failed': 'Exam could not be saved.',
          'tests.results_load_failed': 'Exam results could not be loaded.',
          'tests.exams_load_failed': 'Exams could not be loaded.',
          'tests.prepare_questions': 'Prepare Questions',
          'tests.no_questions_for_lesson':
              'No questions were found for this lesson. Please add questions or check the exam type.',
          'tests.no_questions_at_all':
              'No questions were found. Please add questions or check the exam type.',
          'tests.complete': 'Complete',
          'tests.questions_create_failed': 'Questions could not be created.',
          'tests.complete_failed': 'Exam could not be completed.',
          'tests.not_found_in_type':
              'No exams were found in the @type type. Please create a new exam or choose a different type.',
          'tests.share_status': 'For everyone: @status',
          'tests.status.open': 'Open',
          'tests.status.closed': 'Closed',
          'tests.share_public_info':
              'In accordance with digital ethics, copyrighted tests should not be shared.\nPlease use and publish tests that everyone can solve and that do not contain copyrighted content.',
          'tests.share_private_info':
              'This test can only be shared with your own students. Only students who enter the ID value provided by you can access and solve the published test.',
          'tests.test_id': 'Test ID: @id',
          'tests.test_type': 'Test Type',
          'tests.subjects': 'Subjects',
          'tests.exam_prep': 'Exam Preparation',
          'tests.foreign_language': 'Foreign Language',
          'tests.delete_test': 'Delete Test',
          'tests.prepare_test': 'Prepare Test',
          'tests.join_title': 'Join Test',
          'tests.search_title': 'Search Test',
          'tests.search_id_hint': 'Search Test ID',
          'tests.join_help':
              'You can start the test by entering the Test ID shared with you by your teacher.',
          'tests.join_not_found':
              'Test not found.\nNo test matched the entered Test ID.',
          'tests.join_button': 'Join Test',
          'tests.no_shared': 'There are no shared tests.',
          'tests.my_tests_title': 'My Tests',
          'tests.my_tests_empty':
              'No results found.\nYou have not created any tests before.',
          'tests.completed_title': 'You Finished the Test!',
          'tests.completed_body':
              'You can check your score and correct/incorrect ratios on My Results.',
          'tests.completed_short': 'You completed the test!',
          'tests.action_select': 'Select Action',
          'tests.action_select_body':
              'If you want to take action on this test, choose one of the options below.',
          'tests.copy_test_id': 'Copy Test ID',
          'tests.solve_title': 'Solve Test',
          'tests.delete_confirm':
              'Are you sure you want to delete this test?',
          'tests.id_copied': 'Test ID copied to clipboard',
          'tests.share_test_id_text':
              '@type Test\n\nDownload TurqApp now to join the test. Your required Test ID is @id\n\nGet the app now:\n\nAppStore: @appStore\nPlay Store: @playStore\n\nTo join the test, enter the Test ID from the Tests screen in the student area and start solving right away.',
          'tests.type.middle_school': 'Middle School',
          'tests.type.high_school': 'High School',
          'tests.type.prep': 'Preparation',
          'tests.type.language': 'Language',
          'tests.type.branch': 'Branch',
          'tests.lesson.turkish': 'Turkish',
          'tests.lesson.literature': 'Literature',
          'tests.lesson.math': 'Mathematics',
          'tests.lesson.geometry': 'Geometry',
          'tests.lesson.physics': 'Physics',
          'tests.lesson.chemistry': 'Chemistry',
          'tests.lesson.biology': 'Biology',
          'tests.lesson.history': 'History',
          'tests.lesson.geography': 'Geography',
          'tests.lesson.philosophy': 'Philosophy',
          'tests.lesson.psychology': 'Psychology',
          'tests.lesson.sociology': 'Sociology',
          'tests.lesson.logic': 'Logic',
          'tests.lesson.religion': 'Religious Culture',
          'tests.lesson.science': 'Science',
          'tests.lesson.revolution_history': 'Revolution History',
          'tests.lesson.foreign_language': 'Foreign Language',
          'tests.lesson.basic_math': 'Basic Mathematics',
          'tests.lesson.social_sciences': 'Social Sciences',
          'tests.lesson.literature_social_1':
              'Literature - Social Sciences 1',
          'tests.lesson.social_sciences_2': 'Social Sciences 2',
          'tests.lesson.general_ability': 'General Ability',
          'tests.lesson.general_culture': 'General Culture',
          'tests.language.english': 'English',
          'tests.language.german': 'German',
          'tests.language.arabic': 'Arabic',
          'tests.language.french': 'French',
          'tests.language.russian': 'Russian',
          'tests.lesson_based_title': '@type Tests',
          'tests.none_in_category': 'There are no tests',
          'tests.add_question': 'Add Question',
          'tests.no_questions_added':
              'No questions found.\nNo questions have been added for this test yet.',
          'tests.level_easy': 'Easy',
          'tests.title': 'Tests',
          'tests.report_title': 'About the Test',
          'tests.report_wrong_answers':
              'The test contains wrong answers',
          'tests.report_wrong_section':
              'The test is in the wrong section',
          'tests.question_content_failed':
              'Question content could not be loaded.\nPlease try again.',
          'tests.capture_and_upload': 'Capture and Upload',
          'tests.capture_and_upload_body':
              'Take a photo of the question, choose the correct answer, and prepare it easily!',
          'tests.select_from_gallery': 'Select from Gallery',
          'tests.upload_from_camera': 'Upload from Camera',
          'tests.nsfw_check_failed':
              'Image safety check could not be completed.',
          'tests.nsfw_detected': 'Inappropriate image detected.',
          'practice.title': 'Online Exam',
          'practice.search_title': 'Search Practice Exam',
          'practice.empty_title': 'No Practice Exams Yet',
          'practice.empty_body':
              'There are currently no practice exams in the system. New exams will appear here when they are added.',
          'practice.search_empty_title': 'No exam matched your search',
          'practice.search_empty_body_empty':
              'There are currently no practice exams in the system. New exams will appear here when they are added.',
          'practice.search_empty_body_query':
              'Try a different keyword.',
          'practice.results_title': 'My Practice Results',
          'practice.saved_empty': 'There are no saved practice exams.',
          'practice.preview_no_questions':
              'No questions were found for this exam. Please check the exam content or add new questions.',
          'practice.preview_no_results':
              'No results were found for this exam. Please check your answers or solve the exam again.',
          'practice.lesson_header': 'Lessons',
          'practice.answers_load_failed': 'Answers could not be loaded.',
          'practice.lesson_results_load_failed':
              'Lesson results could not be loaded.',
          'practice.results_empty_title': 'You Have Not Taken an Exam Yet',
          'practice.results_empty_body':
              'You have not joined any practice exam yet. Your results will appear here after you participate.',
          'practice.published_empty':
              'You have not published an online exam yet.',
          'practice.user_session_missing': 'User session not found.',
          'practice.school_info_failed':
              'School information could not be loaded.',
          'practice.load_failed': 'Data could not be loaded.',
          'practice.slider_management': 'Slider Management',
          'practice.create_disabled_title':
              'Only for Yellow Badge and Above',
          'practice.create_disabled_body':
              'To create an online exam, you need a verified account with a yellow badge or higher.',
          'practice.preview_title': 'Exam Details',
          'practice.report_exam': 'Report Exam',
          'practice.user_load_failed':
              'User information could not be loaded.',
          'practice.user_load_failed_body':
              'User information could not be loaded. Please try again or check the exam owner.',
          'practice.invalidity_load_failed':
              'Invalidity status could not be loaded.',
          'practice.cover_load_failed': 'Cover image could not be loaded.',
          'practice.no_description':
              'No description was added for this exam.',
          'practice.exam_info': 'Exam Information',
          'practice.exam_type': 'Exam Type',
          'practice.exam_suffix': '@type Exam',
          'practice.exam_datetime': 'Exam Date and Time',
          'practice.exam_duration': 'Exam Duration',
          'practice.duration_minutes': '@minutes min',
          'practice.application_count': 'Applications',
          'practice.people_count': '@count people',
          'practice.owner': 'Exam owner',
          'practice.apply_now': 'Apply Now',
          'practice.applied_short': 'Applied',
          'practice.closed_starts_in':
              'Applications closed.\nStarts in @minutes min.',
          'practice.started': 'Exam Started',
          'practice.start_now': 'Start Now',
          'practice.finished_short': 'Exam Ended',
          'practice.not_started': 'Exam Not Started',
          'practice.application_closed_title': 'Applications Closed!',
          'practice.application_closed_body':
              'Applications close 15 minutes before the exam starts.',
          'practice.not_applied_title': 'You Did Not Apply!',
          'practice.not_applied_body':
              'You cannot join exams you did not apply for. Only applicants can participate.',
          'practice.not_allowed_title':
              'You Cannot Enter the Exam!',
          'practice.not_allowed_body':
              'You do not have access to this exam. You were previously invalidated in this exam and cannot re-enter before it ends.',
          'practice.finished_title': 'Exam Ended!',
          'practice.finished_body':
              'You can apply to the next exams. This exam has ended.',
          'practice.result_unavailable':
              'Result could not be calculated.',
          'practice.result_summary':
              'Correct: @correct   •   Wrong: @wrong   •   Blank: @blank   •   Net: @net',
          'practice.congrats_title': 'Congratulations!',
          'practice.removed_title':
              'You Were Removed From the Exam!',
          'practice.removed_body':
              'We warned you several times. Unfortunately, because you did not follow the exam rules, you were removed and your exam was marked invalid.',
          'practice.applied_title':
              'Your Application Has Been Received!',
          'practice.applied_body':
              'Your application was received successfully. There is nothing else you need to do right now.',
          'practice.apply_completed_title':
              'Your Application Is Complete!',
          'practice.apply_completed_body':
              'We will send you reminders before the exam. We wish you success!',
          'practice.apply_failed': 'Application failed.',
          'practice.application_check_failed':
              'Application check failed.',
          'practice.question_image_failed':
              'Question image could not be loaded.',
          'practice.exam_started_title': 'The Exam Has Started!',
          'practice.exam_started_body':
              'We believe your care and effort in this exam will pave the way to success. Good luck!',
          'practice.rules_title': 'Exam Rules',
          'practice.rule_1':
              'Please turn off your phone\'s internet connection. When your exam is complete, you can turn it back on to submit your answers.',
          'practice.rule_2':
              'If you leave the exam, all your answers will be considered invalid and your score will not be saved. Please think carefully before confirming this action.',
          'practice.rule_3':
              'If you send the app to the background, your exam will be considered invalid. Please make sure not to background the app.',
          'practice.start_exam': 'Start Exam',
          'practice.finish_exam': 'Finish Exam',
          'practice.background_warning':
              'In critical situations such as putting the app in the background, your exam will be considered invalid. Please be careful and follow the rules.',
          'practice.questions_load_failed':
              'Questions could not be loaded.',
          'practice.answers_save_failed':
              'Answers could not be saved.',
          'past_questions.no_results': 'There are no results.',
          'past_questions.title': 'Practice Exams',
          'past_questions.mock_fallback': 'Mock',
          'past_questions.search_empty': 'No practice exam matches your search.',
          'past_questions.results_suffix': '@title Results',
          'past_questions.local_result_summary':
              '@count questions were solved. The result is stored locally; only the net summary is shown on this screen.',
          'past_questions.mock_label': 'Mock @index',
          'past_questions.question_count': '@count Questions',
          'past_questions.net_label': 'Net',
          'past_questions.tests_by_year': '@type @year Tests',
          'past_questions.languages_title': '@type Languages',
          'past_questions.tests_by_type': '@type Tests',
          'past_questions.select_exam': 'Select Exam',
          'past_questions.questions_title': 'Questions',
          'past_questions.continue_solving': 'Continue Solving Questions',
          'past_questions.oabt_short': 'ÖABT',
          'past_questions.exam_type.associate': 'Associate Degree',
          'past_questions.exam_type.undergraduate': 'Undergraduate',
          'past_questions.exam_type.middle_school': 'Secondary Education',
          'past_questions.branch.general_ability_culture':
              'General Ability and General Culture',
          'past_questions.branch.group_a': 'Group A',
          'past_questions.branch.education_sciences': 'Educational Sciences',
          'past_questions.branch.field_knowledge': 'Field Knowledge',
          'past_questions.sessions_by_year': '@year Sessions',
          'past_questions.teaching.title': 'Teaching Branches',
          'past_questions.teaching.suffix': 'teaching',
          'past_questions.teaching.primary_math_short': 'P. Math',
          'past_questions.teaching.high_school_math_short': 'H. Math',
          'past_questions.teaching.german': 'German teaching',
          'past_questions.teaching.physical_education':
              'Physical education teaching',
          'past_questions.teaching.biology': 'Biology teaching',
          'past_questions.teaching.geography': 'Geography teaching',
          'past_questions.teaching.religious_culture':
              'Religious culture teaching',
          'past_questions.teaching.literature': 'Literature teaching',
          'past_questions.teaching.science': 'Science teaching',
          'past_questions.teaching.physics': 'Physics teaching',
          'past_questions.teaching.chemistry': 'Chemistry teaching',
          'past_questions.teaching.high_school_math': 'High school math',
          'past_questions.teaching.preschool': 'Preschool',
          'past_questions.teaching.guidance': 'Guidance',
          'past_questions.teaching.social_studies': 'Social studies teaching',
          'past_questions.teaching.classroom': 'Classroom teaching',
          'past_questions.teaching.history': 'History teaching',
          'past_questions.teaching.turkish': 'Turkish teaching',
          'past_questions.teaching.primary_math': 'Primary math',
          'past_questions.teaching.imam_hatip': 'Imam Hatip',
          'past_questions.teaching.english': 'English teaching',
          'settings.about': 'About',
          'settings.policies': 'Policies',
          'settings.contact_us': 'Contact Us',
          'settings.my_approval_results': 'My Approval Results',
          'settings.admin_ads': 'Admin / Ads Center',
          'ads_center.title': 'Ads Center',
          'ads_center.tab_dashboard': 'Dashboard',
          'ads_center.tab_campaigns': 'Campaigns',
          'ads_center.tab_editor': 'Editor',
          'ads_center.tab_creatives': 'Creatives',
          'ads_center.tab_monitor': 'Monitor',
          'ads_center.tab_preview': 'Preview',
          'ads_center.admin_only': 'This area is only accessible to admins.',
          'ads_center.summary': 'Summary',
          'ads_center.total_campaigns': 'Total Campaigns',
          'ads_center.active': 'Active',
          'ads_center.paused': 'Paused',
          'ads_center.feature_flags': 'Feature Flags',
          'ads_center.status': 'Status',
          'ads_center.placement': 'Placement',
          'ads_center.include_test_campaigns': 'Include test campaigns',
          'ads_center.new_campaign': 'New Campaign',
          'ads_center.no_campaigns': 'No campaigns found.',
          'ads_center.untitled_campaign': '(untitled campaign)',
          'ads_center.budget': 'Budget',
          'ads_center.activate': 'Activate',
          'ads_center.pause': 'Pause',
          'ads_center.no_delivery_logs': 'No delivery logs found.',
          'ads_center.decision_detail': 'Decision Detail',
          'ads_center.no_creatives': 'No creatives found.',
          'ads_center.untitled_creative': '(untitled creative)',
          'ads_center.reject_note': 'Reject Note',
          'ads_center.approve_note': 'Approve Note',
          'ads_center.review_note_hint': 'Review note',
          'ads_center.delivery_simulation': 'Delivery Simulation',
          'ads_center.user_id': 'User ID',
          'ads_center.country': 'Country',
          'ads_center.city': 'City',
          'ads_center.age': 'Age',
          'ads_center.run_simulation': 'Run Simulation',
          'ads_center.eligible_ad_found': 'Eligible ad found',
          'ads_center.no_eligible_ad': 'No eligible ad found',
          'ads_center.reasons': 'Reasons',
          'ads_center.create_campaign': 'Create Campaign',
          'ads_center.update_campaign': 'Update Campaign',
          'ads_center.save_creative': 'Save Creative',
          'ads_center.campaign_saved_title': 'Campaign Saved',
          'ads_center.campaign_saved_body': 'Campaign ID: {id}',
          'ads_center.save_campaign_first': 'Please save the campaign first.',
          'ads_center.creative_saved_title': 'Creative Saved',
          'ads_center.creative_saved_body':
              'The ad creative was saved successfully.',
          'ads_center.permission_denied':
              'Access to Ads Center data was denied (permission-denied).',
          'settings.admin_moderation': 'Admin / Moderation',
          'settings.admin_reports': 'Admin / Reports',
          'settings.admin_badges': 'Admin / Badge Management',
          'settings.admin_tasks': 'Admin / Task Assignments',
          'settings.admin_approvals': 'Admin / Approvals',
          'settings.admin_push': 'Admin / Send Push',
          'settings.admin_story_music': 'Admin / Story Music',
          'settings.admin_support': 'Admin / User Support',
          'settings.system_diag_menu': 'System and Diagnostics Menu',
          'settings.diagnostics.data_usage': 'Data Usage',
          'settings.diagnostics.network': 'Network',
          'settings.diagnostics.connected': 'Connected',
          'settings.diagnostics.monthly_total': 'Monthly Total',
          'settings.diagnostics.monthly_limit': 'Monthly Limit',
          'settings.diagnostics.remaining': 'Remaining',
          'settings.diagnostics.limit_usage': 'Limit Usage',
          'settings.diagnostics.wifi_usage': 'Wi-Fi Usage',
          'settings.diagnostics.cellular_usage': 'Cellular Usage',
          'settings.diagnostics.time_ranges': 'Time Ranges',
          'settings.diagnostics.this_month_actual': 'This Month (Actual)',
          'settings.diagnostics.hourly_average': 'Hourly Average',
          'settings.diagnostics.since_login_estimated':
              'Since Last Sign-In (Estimated)',
          'settings.diagnostics.details': 'Details',
          'settings.diagnostics.cache': 'Cache',
          'settings.diagnostics.saved_media_count': 'Saved Media Count',
          'settings.diagnostics.occupied_space': 'Occupied Space',
          'settings.diagnostics.offline_queue': 'Offline Queue',
          'settings.diagnostics.pending': 'Pending',
          'settings.diagnostics.dead_letter': 'Dead-letter',
          'settings.diagnostics.status': 'Status',
          'settings.diagnostics.syncing': 'Syncing',
          'settings.diagnostics.idle': 'Idle',
          'settings.diagnostics.processed_total': 'Processed (total)',
          'settings.diagnostics.failed_total': 'Failed (total)',
          'settings.diagnostics.last_sync': 'Last Sync',
          'settings.diagnostics.login_date': 'Login Date',
          'settings.diagnostics.login_time': 'Login Time',
          'settings.diagnostics.app_health_panel': 'App Health Dashboard',
          'settings.diagnostics.video_cache_detail': 'Video Cache Details',
          'settings.diagnostics.quick_actions': 'Quick Actions',
          'settings.diagnostics.offline_queue_detail':
              'Offline Queue Details',
          'settings.diagnostics.last_error_summary': 'Last Error Summary',
          'settings.diagnostics.error_report': 'Error Report',
          'settings.diagnostics.saved_videos': 'Saved Videos',
          'settings.diagnostics.saved_segments': 'Saved Segments',
          'settings.diagnostics.disk_usage': 'Disk Usage',
          'settings.diagnostics.unknown': 'Unknown',
          'settings.diagnostics.cache_traffic': 'Cache Traffic',
          'settings.diagnostics.hit_rate': 'Hit Rate',
          'settings.diagnostics.hit': 'Hit',
          'settings.diagnostics.miss': 'Miss',
          'settings.diagnostics.cache_served': 'Served from Cache',
          'settings.diagnostics.downloaded_from_network':
              'Downloaded from Network',
          'settings.diagnostics.prefetch': 'Prefetch',
          'settings.diagnostics.queue': 'Queue',
          'settings.diagnostics.active_downloads': 'Active Downloads',
          'settings.diagnostics.paused': 'Paused',
          'settings.diagnostics.active': 'Active',
          'settings.diagnostics.reset_data_counters': 'Reset Data Counters',
          'settings.diagnostics.data_counters_reset':
              'Data counters were reset',
          'settings.diagnostics.sync_offline_queue_now':
              'Sync Offline Queue Now',
          'settings.diagnostics.offline_queue_sync_triggered':
              'Offline queue sync triggered',
          'settings.diagnostics.retry_dead_letter': 'Retry Dead-letter',
          'settings.diagnostics.dead_letter_queued':
              'Dead-letter items were queued',
          'settings.diagnostics.clear_dead_letter': 'Clear Dead-letter',
          'settings.diagnostics.dead_letter_cleared':
              'Dead-letter queue cleared',
          'settings.diagnostics.pause_prefetch': 'Pause Prefetch',
          'settings.diagnostics.prefetch_paused': 'Prefetch paused',
          'settings.diagnostics.service_not_ready':
              'Prefetch service is not ready',
          'settings.diagnostics.resume_prefetch': 'Resume Prefetch',
          'settings.diagnostics.prefetch_resumed':
              'Prefetch resumed',
          'settings.diagnostics.online': 'Online',
          'settings.diagnostics.sync': 'Sync',
          'settings.diagnostics.processed': 'Processed',
          'settings.diagnostics.failed': 'Failed',
          'settings.diagnostics.pending_first8': 'Pending (first 8)',
          'settings.diagnostics.dead_letter_first8':
              'Dead-letter (first 8)',
          'settings.diagnostics.sync_now': 'Sync Now',
          'settings.diagnostics.dead_letter_retry': 'Dead-letter Retry',
          'settings.diagnostics.dead_letter_clear': 'Dead-letter Clear',
          'settings.diagnostics.no_recorded_error': 'No recorded errors.',
          'settings.diagnostics.error_code': 'Code',
          'settings.diagnostics.error_category': 'Category',
          'settings.diagnostics.error_severity': 'Severity',
          'settings.diagnostics.error_retryable': 'Retryable',
          'settings.diagnostics.error_message': 'Message',
          'settings.diagnostics.error_time': 'Time',
          'settings.sign_out': 'Sign Out',
          'settings.sign_out_title': 'Sign Out',
          'settings.sign_out_message':
              'Are you sure you want to sign out?',
          'language.title': 'Language',
          'language.subtitle': 'Choose the app language.',
          'language.note':
              'Some screens will be translated gradually. Your selection applies immediately.',
          'language.option.tr': 'Turkish',
          'language.option.en': 'English',
          'language.option.de': 'German',
          'language.option.fr': 'French',
          'language.option.it': 'Italian',
          'language.option.ru': 'Russian',
          'language.option.ar': 'Arabic',
          'login.tagline': '"Your stories come together here."',
          'login.device_accounts': 'Accounts on this device',
          'login.last_used': 'Last used',
          'login.saved_account': 'Saved account',
          'login.sign_in': 'Sign In',
          'login.create_account': 'Create Account',
          'login.policies': 'Terms and Policies',
          'login.identifier_hint': 'Username or email address',
          'login.password_hint': 'Your password',
          'login.reset': 'Reset',
          'common.back': 'Back',
          'common.continue': 'Continue',
          'common.all': 'All',
          'common.videos': 'Videos',
          'common.photos': 'Photos',
          'common.no_results': 'No results found',
          'common.success': 'Success',
          'common.warning': 'Warning',
          'common.delete': 'Delete',
          'common.search': 'Search',
          'common.call': 'Call',
          'common.view': 'View',
          'common.create': 'Create',
          'common.applications': 'Applications',
          'common.liked': 'Liked',
          'common.saved': 'Saved',
          'common.unknown_category': 'Unknown Category',
          'common.clear': 'Clear',
          'common.share': 'Share',
          'common.show_more': 'Show More',
          'common.show_less': 'Show Less',
          'common.hide': 'Hide',
          'common.push': 'Push',
          'common.quote': 'Quote',
          'common.user': 'User',
          'common.close': 'Close',
          'common.retry': 'Retry',
          'login.selected_account_password':
              '{username} selected. Complete your sign-in details to continue.',
          'login.selected_account_phone':
              '{username} is registered with a phone number. You need to sign in manually for this account.',
          'login.selected_account_manual':
              'You need to sign in manually for {username}.',
          'login.reset_password_title': 'Reset Your Password',
          'login.reset_password_help':
              'Enter your email address so we can find your account. We will send a verification code to the phone number registered on your account.',
          'login.email_label': 'Email Address',
          'login.email_hint': 'Enter your email address',
          'login.get_code': 'Get Code',
          'login.resend_code': 'Resend',
          'login.verification_code': 'Verification Code',
          'login.verification_code_hint': '6-digit verification code',
          'signup.step': 'Step {current}/3',
          'signup.create_account_title': 'Create Your Account',
          'signup.policy_intro': 'By creating an account and continuing, I accept the ',
          'signup.policy_outro': ' texts.',
          'signup.policy_short':
              'I accept the Agreements and Policies.',
          'signup.policy_notice':
              'This consent may be recorded as part of the account creation flow.',
          'signup.email': 'Email',
          'signup.username': 'Username',
          'signup.username_help':
              'Your username should be unique, clear, and not misleading. Turkish characters are converted automatically.',
          'signup.password': 'Password',
          'signup.password_help':
              'Password (At least one letter, one number, one punctuation mark; min 6 characters)',
          'signup.personal_info': 'Personal Information',
          'signup.first_name': 'First Name',
          'signup.last_name_optional': 'Last Name (Optional)',
          'signup.next': 'Next',
          'signup.verification_title': 'Verification',
          'signup.verification_message':
              'We sent a verification code to +90{phone}. Enter the code to continue.',
          'signup.code_hint': '6-digit code',
          'signup.required_acceptance_title': 'Approval Required',
          'signup.required_acceptance_body':
              'You must accept the membership agreement and policy texts to continue.',
          'signup.invalid_email': 'Please enter a valid email address.',
          'signup.username_min': 'Username must be at least 8 characters.',
          'signup.weak_password_title': 'Weak Password',
          'signup.weak_password_body':
              'Password must include at least one letter, one number, and one punctuation mark (min 6 characters).',
          'signup.unavailable_title': 'Unavailable',
          'signup.email_taken': 'This email is already in use.',
          'signup.username_taken': 'This username is already taken.',
          'signup.check_failed_title': 'Check Failed',
          'signup.check_failed_body':
              'Registration eligibility cannot be checked right now. Please try again.',
          'signup.limit_title': 'Limit Reached',
          'signup.limit_body':
              'A maximum of 5 accounts can be created for this phone number.',
          'signup.username_taken_title': 'Username already in use',
          'signup.username_taken_body': 'Please choose a different username.',
          'signup.failed_title': 'Registration could not be completed',
          'signup.failed_body':
              'An error occurred while creating the account. Please try again.',
          'signup.missing_info_title': 'Missing Information',
          'signup.phone_name_rule':
              'First name must be at least 3 characters and the phone number must be 10 digits starting with 5.',
          'signup.phone_invalid_title': 'Invalid Phone',
          'signup.phone_invalid_body':
              'Please enter a 10-digit phone number starting with 5.',
          'signup.code_invalid_title': 'Invalid Code',
          'signup.code_invalid_body': 'Please enter the 6-digit verification code.',
          'signup.verify_failed_title': 'Verification Failed',
          'signup.code_expired': 'The code has expired. Please request a new one.',
          'signup.email_or_username_taken':
              'This email or username is already in use.',
          'signup.code_not_found': 'Verification code not found. Request a new code.',
          'signup.code_wrong': 'The verification code is incorrect.',
          'signup.too_many_attempts':
              'Too many failed attempts. Please request a new code.',
          'signup.code_no_longer_valid':
              'The code is no longer valid. Request a new code.',
          'signup.verify_retry':
              'The code could not be verified. Please try again.',
          'signup.account_create_failed_title': 'Account could not be created',
          'signup.email_in_use': 'This email address is already in use.',
          'signup.invalid_email_auth': 'Email address is invalid.',
          'signup.password_too_weak':
              'Password is too weak. Please try a stronger password.',
          'signup.email_password_disabled':
              'Email/password sign-up is disabled.',
          'signup.network_failed': 'Could not connect to the internet.',
          'signup.operation_failed': 'Registration failed.',
          'notifications.title': 'Notifications',
          'notifications.instant': 'Instant Notifications',
          'notifications.categories': 'Categories',
          'notifications.device_notice':
              'Keep notification permission enabled in device settings to see notifications on the lock screen.',
          'notifications.device_settings': 'Open device settings',
          'notifications.pause_all': 'Pause all',
          'notifications.pause_all_desc':
              'Temporarily silence all notifications.',
          'notifications.sleep_mode': 'Sleep mode',
          'notifications.sleep_mode_desc':
              'Soften notifications when you do not want to be disturbed.',
          'notifications.messages_only': 'Messages only',
          'notifications.messages_only_desc':
              'When enabled, only message notifications are shown.',
          'notifications.posts_comments': 'Posts and comments',
          'notifications.posts_comments_desc':
              'Post interactions, comments, and announcements.',
          'notifications.comments': 'Comments',
          'notifications.comments_desc': 'Comments made on your post.',
          'comments.delete_message':
              'Are you sure you want to delete this comment?',
          'comments.delete_failed': 'Comment could not be deleted.',
          'comments.title': 'Comments',
          'comments.empty': 'Be the first to comment...',
          'comments.reply': 'Reply',
          'comments.replying_to': 'Replying to @nickname',
          'comments.sending': 'Sending',
          'comments.community_violation_title': 'Against Community Rules',
          'comments.community_violation_body':
              'The language you used does not comply with our community rules. Please use respectful language.',
          'post_sharers.empty': 'No one has shared this post yet',
          'notifications.post_activity': 'Post activity',
          'notifications.post_activity_desc':
              'Likes, reshares, and post pushes.',
          'notifications.follows': 'Follows',
          'notifications.follows_desc':
              'New followers and follow activity.',
          'notifications.follow_notifs': 'Follow notifications',
          'notifications.follow_notifs_desc':
              'Users who follow you and follow activity.',
          'notifications.messages': 'Messages',
          'notifications.messages_desc':
              'Chat and direct message notifications.',
          'notifications.direct_messages': 'Messages',
          'notifications.direct_messages_desc':
              'One-to-one chats and incoming new messages.',
          'notifications.opportunities': 'Listings and applications',
          'notifications.opportunities_desc':
              'Applications for job and tutoring listings.',
          'notifications.job_apps': 'Job listing applications',
          'notifications.job_apps_desc':
              'New applications for your job listing.',
          'notifications.tutoring_apps': 'Tutoring applications',
          'notifications.tutoring_apps_desc':
              'Applications for your tutoring listing.',
          'notifications.application_status': 'Application status',
          'notifications.application_status_desc':
              'Tutoring application results and status updates.',
          'notifications.marking_read': 'Marking as read...',
          'notifications.mark_all_read': 'Mark all as read',
          'notifications.delete_all': 'Delete all',
          'notifications.tab_follow': 'Follow',
          'notifications.tab_comment': 'Comment',
          'notifications.tab_mentions': 'Mentions',
          'notifications.tab_listings': 'Listings',
          'notifications.empty_filtered': 'No notifications in this filter',
          'notifications.empty': 'You have no notifications',
          'notifications.new': 'New',
          'notifications.today': 'Today',
          'notifications.yesterday': 'Yesterday',
          'notifications.older': 'Older',
          'notifications.count_items': '{count} items',
          'notifications.and_more': '{base} and {count} more notifications',
          'notification.item.default_interaction':
              'interacted with your post.',
          'notification.hint.profile': 'Profile',
          'notification.hint.chat': 'Chat',
          'notification.hint.listing_named': 'Listing: {label}',
          'notification.hint.listing': 'Listing',
          'notification.hint.tutoring': 'Tutoring listing',
          'notification.hint.comments': 'Comments',
          'notification.hint.post': 'Post',
          'notification.desc.like': 'liked your post',
          'notification.desc.comment': 'commented on your post',
          'notification.desc.reshare': 'reshared your post',
          'notification.desc.share': 'shared your post',
          'notification.desc.follow': 'started following you',
          'notification.desc.message': 'sent you a message',
          'notification.desc.job_application': 'applied to your listing',
          'notification.desc.tutoring_application':
              'applied to your tutoring listing',
          'notification.desc.tutoring_status':
              'updated the tutoring application status',
          'support.title': 'Contact Us',
          'support.card_title': 'Support Message',
          'support.direct_admin': 'Your message is sent directly to the admin.',
          'support.topic': 'Topic',
          'support.topic.account': 'Account',
          'support.topic.payment': 'Payment',
          'support.topic.technical': 'Technical Issue',
          'support.topic.content': 'Content Complaint',
          'support.topic.suggestion': 'Suggestion',
          'support.message_hint': 'Write your issue or request...',
          'support.send': 'Send Message',
          'support.empty_title': 'Missing Information',
          'support.empty_body': 'Please write a message.',
          'support.sent_title': 'Sent',
          'support.sent_body': 'Your message has been sent to the admin.',
          'support.error_title': 'Error',
          'support.error_body': 'Message could not be sent:',
          'liked_posts.no_posts': 'No posts',
          'saved_posts.posts_tab': 'Posts',
          'saved_posts.series_tab': 'Series',
          'saved_posts.series_badge': 'SERIES',
          'saved_posts.no_saved_posts': 'No saved posts',
          'saved_posts.no_saved_series': 'No saved series',
          'blocked_users.empty': 'You have not blocked anyone',
          'blocked_users.unblock': 'Remove Block',
          'blocked_users.unblock_confirm_title': 'Remove Block',
          'blocked_users.unblock_confirm_body':
              'Are you sure you want to remove the block for {nickname}?',
          'blocked_users.unblock_success':
              '{nickname} has been removed from blocked users.',
          'blocked_users.unblock_failed': 'Block could not be removed.',
          'profile_contact.title': 'Contact',
          'profile_contact.call': 'Call',
          'profile_contact.email': 'Email',
          'editor_email.title': 'Email Verification',
          'editor_email.email_hint': 'Your account email address',
          'editor_email.send_code': 'Send Verification Code',
          'editor_email.resend_in': 'Resend available in {seconds}s',
          'editor_email.note':
              'This verification is for security purposes. You can continue using the app even if you do not verify it.',
          'editor_email.code_hint': '6-digit verification code',
          'editor_email.verify_confirm': 'Verify Code and Confirm',
          'editor_email.wait': 'Please wait {seconds} seconds.',
          'editor_email.session_missing':
              'Session not found. Please sign in again.',
          'editor_email.email_missing':
              'No email address was found on your account.',
          'editor_email.code_sent':
              'The verification code was sent to your email address.',
          'editor_email.code_send_failed':
              'The verification code could not be sent.',
          'editor_email.enter_code':
              'Please enter the 6-digit verification code.',
          'editor_email.verified': 'Your email address has been verified.',
          'editor_email.verify_failed':
              'Email address could not be verified.',
          'editor_phone.title': 'Phone Number',
          'editor_phone.phone_hint': 'Phone Number',
          'editor_phone.send_approval': 'Send Approval Email',
          'editor_phone.resend_in': 'Resend available in {seconds}s',
          'editor_phone.code_hint': '6-digit verification code',
          'editor_phone.verify_update': 'Verify Code and Update',
          'editor_phone.wait': 'Please wait {seconds} seconds.',
          'editor_phone.invalid_phone':
              'Please enter a 10-digit phone number starting with 5.',
          'editor_phone.session_missing':
              'Session not found. Please sign in again.',
          'editor_phone.email_missing':
              'No email address available to verify this change.',
          'editor_phone.code_sent':
              'The verification code was sent to your email address.',
          'editor_phone.code_send_failed':
              'The verification code could not be sent.',
          'editor_phone.enter_code':
              'Please enter the 6-digit verification code.',
          'editor_phone.update_failed':
              'Phone number could not be updated.',
          'editor_phone.updated': 'Your phone number has been updated.',
          'address.title': 'Address',
          'address.hint': 'Business & Office Address',
          'biography.title': 'Biography',
          'biography.hint': 'Tell us about yourself..',
          'job_selector.title': 'Profession & Category',
          'job_selector.subtitle':
              'Your category makes your profile easier to discover.',
          'job_selector.search_hint': 'Search',
          'legacy_language.title': 'App Language',
          'policy_detail.last_updated': 'Last updated: {date}',
          'statistics.title': 'Statistics',
          'statistics.you': 'You',
          'statistics.notice':
              'Your statistics are updated regularly based on your activity over the last 30 days.',
          'statistics.post_views_pct': 'Post View Percentage',
          'statistics.follower_growth_pct': 'Follower Growth Percentage',
          'statistics.profile_visits_30d': 'Profile Visits (30 Days)',
          'statistics.post_views': 'Post Views',
          'statistics.post_count': 'Post Count',
          'statistics.story_count': 'Story Count',
          'statistics.follower_growth': 'Follower Growth',
          'interests.personalize_feed': 'Personalize your feed',
          'interests.selection_range':
              'Select at least {min} and at most {max} interests.',
          'interests.selected_count': '{selected}/{max} selected',
          'interests.ready': 'Ready',
          'interests.search_hint': 'Search interests',
          'interests.limit_title': 'Selection Limit',
          'interests.limit_body':
              'You can select up to {max} interests.',
          'interests.min_title': 'Incomplete Selection',
          'interests.min_body':
              'You must select at least {min} interests.',
          'view_changer.title': 'View',
          'view_changer.classic': 'Classic View',
          'view_changer.modern': 'Modern View',
          'social_links.title': 'Links ({count})',
          'social_links.add': 'Add',
          'social_links.add_title': 'Add Link',
          'social_links.label_title': 'Title',
          'social_links.username_hint': 'Username',
          'social_links.remove_title': 'Remove Link',
          'social_links.remove_message':
              'Are you sure you want to remove this link?',
          'social_links.save_permission_error':
              'Permission error: you are not allowed to save links.',
          'social_links.save_failed': 'Something went wrong.',
          'pasaj.closed': 'Pasaj is currently closed',
          'pasaj.common.slider_admin': 'Slider Management',
          'pasaj.common.my_results': 'My Results',
          'pasaj.common.published': 'Published',
          'pasaj.common.my_applications': 'My Applications',
          'pasaj.common.post_listing': 'Post Listing',
          'pasaj.common.all_turkiye': 'All Turkey',
          'pasaj.job_finder.tab.explore': 'Explore',
          'pasaj.job_finder.tab.create': 'Create Listing',
          'pasaj.job_finder.tab.applications': 'My Applications',
          'pasaj.job_finder.tab.career_profile': 'Career Profile',
          'pasaj.tabs.scholarships': 'Scholarships',
          'pasaj.tabs.market': 'Mabil Market',
          'pasaj.tabs.question_bank': 'Question Bank',
          'pasaj.tabs.practice_exams': 'Practice Exams',
          'pasaj.tabs.online_exam': 'Online Exam',
          'pasaj.tabs.answer_key': 'Answer Key',
          'pasaj.tabs.tutoring': 'Private Tutoring',
          'pasaj.tabs.job_finder': 'Employers',
          'pasaj.question_bank.solve_later': 'Solve Later',
          'pasaj.answer_key.join': 'Join',
          'answer_key.published': 'Published',
          'answer_key.my_results': 'My Results',
          'answer_key.title': 'Answer Key',
          'answer_key.book_detail': 'Book Detail',
          'answer_key.book_info': 'Book Information',
          'answer_key.exam_type': 'Exam Type',
          'answer_key.publish_date': 'Publication Date',
          'answer_key.answer_keys': 'Answer Keys',
          'answer_key.no_answer_keys':
              'There is no answer key for this book yet.',
          'answer_key.report_book': 'Report Book',
          'answer_key.saved_empty': 'There are no saved books.',
          'answer_key.new_create': 'Create New',
          'answer_key.create_optical_form': 'Create\nOptical Form',
          'answer_key.create_booklet_answer_key':
              'Create\nBook Answer Key',
          'answer_key.create_optical_form_single': 'Create Optical Form',
          'answer_key.give_exam_name': 'Give your exam a name',
          'answer_key.join_exam_title': 'Join Exam',
          'answer_key.exam_id_hint': 'Exam ID',
          'answer_key.book': 'Book',
          'answer_key.create_book': 'Create Book',
          'answer_key.optical_form': 'Optical Form',
          'answer_key.search_min_chars':
              'Type at least 2 characters to search.',
          'answer_key.delete_book': 'Delete Book',
          'answer_key.delete_book_confirm':
              'Are you sure you want to delete this book?',
          'answer_key.cover_select_short': 'Select Cover\nImage',
          'answer_key.cover_updated': 'Cover Updated',
          'answer_key.cover_updated_body':
              'Cover image uploaded successfully.',
          'answer_key.cover_update_failed':
              'There was a problem uploading the cover image.',
        'answer_key.answered_suffix': 'Answered @time ago',
        'answer_key.full_name_hint': 'Full Name',
        'answer_key.student_number_hint': 'Your Student Number',
        'answer_key.book_title_hint': 'Title (Ex: Turkish Question Bank)',
        'answer_key.publisher_hint': 'Publisher',
        'answer_key.publish_year_hint': 'Publication Year',
        'answer_key.answer_list_hint': 'Answer Key List',
        'answer_key.questions_prepared': '@count questions prepared',
        'answer_key.add_answer_key': 'Add Answer Key',
        'answer_key.share_owner_only':
            'Only admins and the listing owner can share.',
          'answer_key.book_answer_key_desc': 'answer key',
          'pasaj.tutoring.nearby_listings': 'Listings Near Me',
          'pasaj.job_finder.title': 'Employers',
          'pasaj.job_finder.search_hint': 'What kind of job are you looking for?',
          'pasaj.job_finder.nearby_listings': 'Listings Closest to You',
          'pasaj.job_finder.no_search_result':
              'No listings matched your search',
          'pasaj.job_finder.no_city_listing':
              'There are no listings in your city',
          'pasaj.job_finder.sort_high_salary': 'Highest Salary',
          'pasaj.job_finder.sort_low_salary': 'Lowest Salary',
          'pasaj.job_finder.sort_nearest': 'Nearest',
          'pasaj.job_finder.career_profile': 'Career Profile',
          'pasaj.job_finder.detail_title': 'Job Details',
          'pasaj.job_finder.no_description':
              'No description has been added for this listing.',
          'pasaj.job_finder.job_info': 'Job Information',
          'pasaj.job_finder.listing_info': 'Listing Information',
          'pasaj.job_finder.application_count': 'Application Count',
          'pasaj.job_finder.work_type': 'Work Type',
          'pasaj.job_finder.work_days': 'Work Days',
          'pasaj.job_finder.work_hours': 'Work Hours',
          'pasaj.job_finder.personnel_count': 'Personnel Count',
          'pasaj.job_finder.benefits': 'Benefits',
          'pasaj.job_finder.passive': 'Passive',
          'pasaj.job_finder.salary_not_specified': 'Not specified',
          'pasaj.job_finder.edit_listing': 'Edit',
          'pasaj.job_finder.applications': 'Applications',
          'pasaj.job_finder.unpublish_title': 'Remove Listing',
          'pasaj.job_finder.unpublish_body':
              'Are you sure you want to remove this listing from publication?',
          'pasaj.job_finder.unpublished':
              'The listing has been removed from publication.',
          'pasaj.job_finder.unpublish_failed':
              'The listing could not be removed: {error}',
          'pasaj.job_finder.already_applied':
              'You have already applied to this listing.',
          'pasaj.job_finder.cv_required': 'CV Required',
          'pasaj.job_finder.cv_required_body':
              'You need to complete your CV before applying for a job.',
          'pasaj.job_finder.create_cv': 'Create CV',
          'pasaj.job_finder.applied': 'Applied',
          'pasaj.job_finder.apply': 'Apply',
          'pasaj.job_finder.application_cancel_title':
              'Cancel Application',
          'pasaj.job_finder.application_cancel_body':
              'Are you sure you want to cancel your application?',
          'pasaj.job_finder.application_cancelled':
              'Your application has been cancelled.',
          'pasaj.job_finder.cancel_application': 'Cancel Application',
          'pasaj.job_finder.create_add_title': 'Add Listing',
          'pasaj.job_finder.create_edit_title': 'Edit Listing',
          'pasaj.job_finder.create.basic_info': 'Basic Information',
          'pasaj.job_finder.create.company_name': 'Company Name',
          'pasaj.job_finder.create.location': 'Location',
          'pasaj.job_finder.create.job_desc': 'Job Description',
          'pasaj.job_finder.create.listing_title': 'Listing Title',
          'pasaj.job_finder.create.work_type': 'Work Type',
          'pasaj.job_finder.create.work_days': 'Work Days',
          'pasaj.job_finder.create.work_hours': 'Work Hours',
          'pasaj.job_finder.create.start': 'Start',
          'pasaj.job_finder.create.end': 'End',
          'pasaj.job_finder.create.profession': 'Profession',
          'pasaj.job_finder.create.benefits': 'Benefits',
          'pasaj.job_finder.create.personnel_count': 'Personnel Count',
          'pasaj.job_finder.create.salary_range': 'Salary Range',
          'pasaj.job_finder.create.min_salary': 'Min Salary',
          'pasaj.job_finder.create.max_salary': 'Max Salary',
          'pasaj.job_finder.create.pick_gallery': 'Choose from Gallery',
          'pasaj.job_finder.create.take_photo': 'Take Photo',
          'pasaj.job_finder.create.missing_field': 'Missing field',
          'pasaj.job_finder.create.logo_required':
              'You cannot continue without selecting a company logo',
          'pasaj.job_finder.create.company_required':
              'You cannot continue without entering the company name',
          'pasaj.job_finder.create.city_district_required':
              'You cannot continue without selecting city and district',
          'pasaj.job_finder.create.address_required':
              'Please specify your company address using your current location',
          'pasaj.job_finder.create.work_type_required':
              'You cannot continue without selecting a work type',
          'pasaj.job_finder.create.profession_required':
              'You cannot continue without selecting a profession',
          'pasaj.job_finder.create.description_required':
              'You must describe the job',
          'pasaj.job_finder.create.benefits_required':
              'You must select at least one benefit',
          'pasaj.job_finder.create.min_salary_required':
              'You must fill in the minimum salary field',
          'pasaj.job_finder.create.max_salary_required':
              'You must fill in the maximum salary field',
          'pasaj.job_finder.create.invalid_salary_range':
              'Maximum salary cannot be lower than minimum salary',
          'pasaj.job_finder.create.crop_use': 'Crop and Use',
          'pasaj.job_finder.create.select_district': 'Select District',
          'pasaj.job_finder.image_security_failed':
              'Image security check could not be completed',
          'pasaj.job_finder.image_nsfw_detected':
              'Inappropriate image detected',
          'pasaj.job_finder.day.monday': 'Monday',
          'pasaj.job_finder.day.tuesday': 'Tuesday',
          'pasaj.job_finder.day.wednesday': 'Wednesday',
          'pasaj.job_finder.day.thursday': 'Thursday',
          'pasaj.job_finder.day.friday': 'Friday',
          'pasaj.job_finder.day.saturday': 'Saturday',
          'pasaj.job_finder.day.sunday': 'Sunday',
          'pasaj.job_finder.benefit.meal': 'Meal',
          'pasaj.job_finder.benefit.road_fee': 'Road allowance',
          'pasaj.job_finder.benefit.shuttle': 'Shuttle',
          'pasaj.job_finder.benefit.bonus': 'Bonus',
          'pasaj.job_finder.benefit.private_health':
              'Private health insurance',
          'pasaj.job_finder.benefit.retirement':
              'Private pension',
          'pasaj.job_finder.benefit.flexible_hours':
              'Flexible working hours',
          'pasaj.job_finder.benefit.remote_work': 'Remote work',
          'pasaj.job_finder.my_applications': 'My Applications',
          'pasaj.job_finder.no_applications':
              'You have not applied yet',
          'pasaj.job_finder.default_job_title': 'Job Listing',
          'pasaj.job_finder.default_company': 'Company',
          'pasaj.job_finder.cancel_apply_title': 'Cancel Application',
          'pasaj.job_finder.cancel_apply_body':
              'Are you sure you want to cancel this application?',
          'pasaj.job_finder.saved_jobs': 'Saved',
          'pasaj.job_finder.no_saved_jobs': 'No saved listings.',
          'pasaj.job_finder.my_ads': 'My Listings',
          'pasaj.job_finder.published_tab': 'Published',
          'pasaj.job_finder.expired_tab': 'Expired',
          'pasaj.job_finder.no_my_ads': 'No listings found',
          'pasaj.job_finder.finding_platform': 'Job Search Platform',
          'pasaj.job_finder.finding_how':
              'How Does the Job Search Platform Work?',
          'pasaj.job_finder.finding_body':
              'Your resume will be shared with employers with your approval. Before publishing a listing, employers can review candidates who match the roles they need through our system. This helps employers reach the right employees faster and helps job seekers access opportunities sooner. Our goal is to make the hiring process faster and more effective for both sides.',
          'pasaj.job_finder.looking_for_job': 'Looking for a Job',
          'pasaj.job_finder.professional_profile': 'Professional Profile',
          'pasaj.job_finder.experience': 'Work Experience',
          'pasaj.job_finder.education': 'Education',
          'pasaj.job_finder.languages': 'Languages',
          'pasaj.job_finder.skills': 'Skills',
          'pasaj.job_finder.edit_cv': 'Edit Resume',
          'pasaj.job_finder.no_cv_title': 'You have not created a resume yet',
          'pasaj.job_finder.no_cv_body':
              'Create a resume to speed up your job applications',
          'pasaj.job_finder.applicants': 'Applicants',
          'pasaj.job_finder.no_applicants': 'No applications yet',
          'pasaj.job_finder.unknown_user': 'Unknown User',
          'pasaj.job_finder.view_cv': 'View Resume',
          'pasaj.job_finder.review': 'Review',
          'pasaj.job_finder.accept': 'Accept',
          'pasaj.job_finder.reject': 'Reject',
          'pasaj.job_finder.cv_not_found_title': 'Resume Not Found',
          'pasaj.job_finder.cv_not_found_body':
              'There is no saved resume for this user.',
          'pasaj.job_finder.status.pending': 'Pending',
          'pasaj.job_finder.status.reviewing': 'Reviewing',
          'pasaj.job_finder.status.accepted': 'Accepted',
          'pasaj.job_finder.status.rejected': 'Rejected',
          'pasaj.job_finder.status_updated':
              'Application status updated.',
          'pasaj.job_finder.status_update_failed':
              'Application status could not be updated.',
          'pasaj.job_finder.relogin_required':
              'Please sign in again to continue.',
          'pasaj.job_finder.save_failed': 'Saving could not be completed.',
          'pasaj.job_finder.share_auth_required':
              'Only admins and listing owners can share.',
          'pasaj.job_finder.review_relogin_required':
              'Please sign in again to leave a review.',
          'pasaj.job_finder.review_own_forbidden':
              'You cannot review your own listing.',
          'pasaj.job_finder.review_saved': 'Your review has been saved.',
          'pasaj.job_finder.review_save_failed':
              'Your review could not be saved.',
          'pasaj.job_finder.review_deleted':
              'Your review has been removed.',
          'pasaj.job_finder.review_delete_failed':
              'Your review could not be removed.',
          'pasaj.job_finder.open_in_maps': 'Open in maps',
          'pasaj.job_finder.open_google_maps': 'Open in Google Maps',
          'pasaj.job_finder.open_apple_maps': 'Open in Apple Maps',
          'pasaj.job_finder.open_yandex_maps': 'Open in Yandex Maps',
          'pasaj.job_finder.map_load_failed': 'Map could not be loaded',
          'pasaj.job_finder.open_maps_help':
              'Tap to open the location in maps.',
          'pasaj.job_finder.application_sent':
              'Your application has been sent.',
          'pasaj.job_finder.application_failed':
              'There was a problem while sending your application.',
          'pasaj.job_finder.listing_not_found': 'Listing not found',
          'pasaj.job_finder.reactivated':
              'The listing has been republished.',
          'pasaj.job_finder.sort_title': 'Sort',
          'pasaj.job_finder.sort_newest': 'Newest',
          'pasaj.job_finder.sort_nearest_me': 'Nearest to Me',
          'pasaj.job_finder.sort_most_viewed': 'Most Viewed',
          'pasaj.job_finder.clear_filters': 'Clear Filters',
          'pasaj.job_finder.select_city': 'Select City',
          'pasaj.job_finder.work_type.full_time': 'Full Time',
          'pasaj.job_finder.work_type.part_time': 'Part Time',
          'pasaj.job_finder.work_type.remote': 'Remote',
          'pasaj.job_finder.work_type.hybrid': 'Hybrid',
          'pasaj.market.title': 'Market',
          'pasaj.market.contact_phone': 'Phone',
          'pasaj.market.contact_message': 'Message',
          'pasaj.market.min_price': 'Min {value}',
          'pasaj.market.max_price': 'Max {value}',
          'pasaj.market.sort_price_asc': 'Price Low to High',
          'pasaj.market.sort_price_desc': 'Price High to Low',
          'pasaj.market.all_listings': 'All Listings',
          'pasaj.market.main_categories': 'Main categories',
          'pasaj.market.category_search_hint':
              'Search main category, subcategory, brand',
          'pasaj.market.call_now': 'Call Now',
          'pasaj.market.inspect': 'Inspect',
          'pasaj.market.empty_filtered':
              'No listings were found for this filter.',
          'pasaj.market.add_listing': 'Add Listing',
          'pasaj.market.my_listings': 'My Listings',
          'pasaj.market.saved_items': 'Saved Items',
          'pasaj.market.my_offers': 'My Offers',
          'pasaj.market.menu.create': 'Add Listing',
          'pasaj.market.menu.my_items': 'My Listings',
          'pasaj.market.menu.saved': 'Liked Items',
          'pasaj.market.menu.offers': 'My Offers',
          'pasaj.market.menu.categories': 'Categories',
          'pasaj.market.menu.nearby': 'Nearby',
          'pasaj.market.category.electronics': 'Electronics',
          'pasaj.market.category.phone': 'Phone',
          'pasaj.market.category.computer': 'Computer',
          'pasaj.market.category.gaming_electronics': 'Gaming Electronics',
          'pasaj.market.category.clothing': 'Clothing',
          'pasaj.market.category.home_living': 'Home & Living',
          'pasaj.market.category.sports': 'Sports',
          'pasaj.market.category.real_estate': 'Real Estate',
          'pasaj.market.detail_title': 'Listing Details',
          'pasaj.market.report_listing': 'Report Listing',
          'pasaj.market.report_reason': 'Please choose a reason.',
          'pasaj.market.no_description':
              'No description has been added for this listing.',
          'pasaj.market.listing_info': 'Listing Information',
          'pasaj.market.phone_and_message': 'Phone + Message',
          'pasaj.market.message_only': 'Message Only',
          'pasaj.market.saved_count': 'Saved by',
          'pasaj.market.offer_count': 'Offers',
          'pasaj.market.default_seller': 'Turq User',
          'pasaj.market.owner_hint':
              'This listing belongs to you. You can edit or share it here.',
          'pasaj.market.messages': 'Messages',
          'pasaj.market.offers': 'Offers',
          'pasaj.market.related_listings': 'Similar Listings',
          'pasaj.market.no_related':
              'No other listings were found for this category.',
          'pasaj.market.report_received_title': 'Your Request Was Received!',
          'pasaj.market.report_received_body':
              'The listing has been placed under review. Thank you.',
          'pasaj.market.report_failed':
              'The listing report could not be sent.',
          'pasaj.market.invalid_offer': 'Choose a valid offer.',
          'pasaj.market.offer_sent': 'Offer sent.',
          'pasaj.market.offer_own_forbidden':
              'You cannot make an offer on your own listing.',
          'pasaj.market.offer_daily_limit':
              'You can make at most 20 offers per day.',
          'pasaj.market.offer_failed': 'Offer could not be sent.',
          'pasaj.market.custom_offer': 'Set Your Own Offer',
          'pasaj.market.discount': '{value}% discount',
          'pasaj.market.reviews': 'Reviews',
          'pasaj.market.rate': 'Rate',
          'pasaj.market.review_edit': 'Edit',
          'pasaj.market.no_reviews': 'There are no reviews yet.',
          'pasaj.market.sign_in_to_review':
              'You must sign in to leave a review.',
          'pasaj.market.review_comment_hint': 'Write your comment',
          'pasaj.market.select_rating': 'Please select a rating.',
          'pasaj.market.review_saved': 'Your review has been saved.',
          'pasaj.market.review_updated': 'Your review has been updated.',
          'pasaj.market.review_own_forbidden':
              'You cannot review your own listing.',
          'pasaj.market.review_failed': 'Review could not be submitted.',
          'pasaj.market.review_deleted': 'Your review has been removed.',
          'pasaj.market.review_delete_failed':
              'The review could not be removed.',
          'pasaj.market.location_missing': 'Location not specified',
          'pasaj.market.status.sold': 'Sold',
          'pasaj.market.status.draft': 'Draft',
          'pasaj.market.status.archived': 'Archived',
          'pasaj.market.status.reserved': 'Reserved',
          'pasaj.market.status.active': 'Active',
          'pasaj.market.create.images': 'Images',
          'pasaj.market.create.basic_info': 'Basic Information',
          'pasaj.market.create.pick_category': 'You must choose a category.',
          'pasaj.market.create.title_required': 'Title is required.',
          'pasaj.market.create.title_hint': 'Title',
          'pasaj.market.create.description_hint': 'Description',
          'pasaj.market.create.price_hint': 'Price (TRY)',
          'pasaj.market.create.location': 'Location',
          'pasaj.market.create.category': 'Category',
          'pasaj.market.create.features': 'Listing Features',
          'pasaj.market.create.contact_preference':
              'Contact Preference',
          'pasaj.market.create.fields_after_category':
              'These fields will open after you complete category selection.',
          'pasaj.market.create.no_extra_fields':
              'No extra fields are defined for this category.',
          'pasaj.market.create.main_category': 'Main category',
          'pasaj.market.create.main_category_search':
              'Search main category, subcategory, brand',
          'pasaj.market.create.no_subcategory':
              'There are no selectable subcategories under this main category.',
          'pasaj.market.create.subcategory': 'Subcategory',
          'pasaj.market.create.subgroup': 'Subgroup',
          'pasaj.market.create.product_type': 'Product type',
          'pasaj.market.create.level': 'Level {value}',
          'pasaj.market.create.select_image':
              'Select Image ({current}/{max})',
          'pasaj.market.create.cover': 'Cover',
          'pasaj.market.empty_my_listings':
              'No listings were found for this state.',
          'pasaj.market.status_update_failed':
              'Listing status could not be updated.',
          'pasaj.market.marked_sold':
              'The listing was marked as sold.',
          'pasaj.market.marked_active':
              'The listing was set to active.',
          'pasaj.market.saved_empty': 'No liked listings found.',
          'pasaj.market.removed_saved':
              'Removed from liked listings.',
          'pasaj.market.unsave_failed':
              'The saved item could not be removed.',
          'pasaj.market.offers_title': 'My Offers',
          'pasaj.market.sent_tab': 'Sent',
          'pasaj.market.received_tab': 'Received',
          'pasaj.market.sent_offer': 'Offer sent',
          'pasaj.market.received_offer': 'Offer received',
          'pasaj.market.offer_empty': 'No {subtitle} found.',
          'pasaj.market.offer_accepted': 'Offer accepted.',
          'pasaj.market.offer_rejected': 'Offer rejected.',
          'pasaj.market.offer_already_processed':
              'This offer has already been processed.',
          'pasaj.market.offer_update_failed':
              'The offer could not be updated.',
          'pasaj.market.listing_unavailable':
              'This listing is not accessible right now.',
          'pasaj.market.filter.title': 'Filters',
          'pasaj.market.filter.all_cities': 'All Cities',
          'pasaj.market.filter.search_city': 'Search city',
          'pasaj.market.filter.price_range': 'Price Range',
          'pasaj.market.filter.min': 'Min',
          'pasaj.market.filter.max': 'Max',
          'pasaj.market.filter.sort': 'Sort',
          'pasaj.market.filter.newest': 'Newest',
          'pasaj.market.filter.ascending': 'Ascending',
          'pasaj.market.filter.descending': 'Descending',
          'pasaj.market.filter.apply': 'Apply',
          'pasaj.market.search_hint': 'Search listing',
          'pasaj.market.search.no_results_body':
              'No listings match your search.',
          'pasaj.market.search.result_count': '{count} results',
          'pasaj.market.search.start_title': 'Start searching listings',
          'pasaj.market.search.start_body':
              'Your recent searches will appear here.',
          'pasaj.market.search.recent': 'Recent Searches',
          'pasaj.market.sign_in_required_title': 'Sign-in Required',
          'pasaj.market.sign_in_to_save':
              'You need to sign in to save listings.',
          'pasaj.market.saved_success': 'Listing saved.',
          'pasaj.market.unsaved': 'Saved item removed.',
          'pasaj.market.save_failed':
              'The save action could not be completed.',
          'pasaj.market.coming_soon_title': 'Coming Soon',
          'pasaj.market.coming_soon_body':
              '{title} will be added soon.',
          'pasaj.market.permission_required_title':
              'Permission Required',
          'pasaj.market.nearby_permission_required':
              'Location permission is required for nearby listings.',
          'pasaj.market.location_not_found_title':
              'Location Not Found',
          'pasaj.market.city_not_found':
              'City information could not be retrieved.',
          'pasaj.market.limited_results_title': 'Limited Results',
          'pasaj.market.no_city_results':
              'No listings were found for {city}.',
          'pasaj.market.nearby_ready':
              'Nearby listings for {city} are now shown.',
          'pasaj.market.nearby_failed':
              'Nearby listings could not be loaded.',
          'pasaj.market.limit_title': 'Limit',
          'pasaj.market.image_limit':
              'You can add up to {max} images.',
          'pasaj.market.create.need_image':
              'Add at least one image to publish.',
          'pasaj.market.create.invalid_price':
              'Enter a valid price.',
          'pasaj.market.create.city_district_required_short':
              'City and district selection is required.',
          'pasaj.market.create.field_required':
              '{field} field is required.',
          'pasaj.market.user_session_not_found':
              'User session could not be found.',
          'pasaj.market.create.save_failed':
              'Listing could not be saved: {error}',
          'pasaj.market.image_security_failed':
              'Image safety check could not be completed',
          'pasaj.market.image_nsfw_detected':
              'Inappropriate image detected',
          'pasaj.market.create.add_title': 'Add Listing',
          'pasaj.market.create.edit_title': 'Edit Listing',
          'pasaj.market.create.update_draft': 'Update Draft',
          'pasaj.market.status.pending': 'Pending',
          'pasaj.market.status.accepted': 'Accepted',
          'pasaj.market.status.rejected': 'Rejected',
          'pasaj.market.status.cancelled': 'Cancelled',
          'account_center.header_title': 'Profiles and sign-in details',
          'account_center.accounts': 'Accounts',
          'account_center.no_accounts':
              'There are no accounts added to this device yet.',
          'account_center.add_account': 'Add account',
          'account_center.personal_details': 'Personal details',
          'account_center.security': 'Security',
          'account_center.active_account_title': 'Active Account',
          'account_center.active_account_body':
              '@{username} is already active.',
          'account_center.reauth_title': 'Re-authentication Required',
          'account_center.reauth_body':
              'You need to sign in again with your password for @{username}.',
          'account_center.switch_failed_title': 'Switch failed',
          'account_center.switch_failed_body':
              'You need to sign in normally once for this account first.',
          'account_center.remove_active_forbidden':
              'You cannot remove the active account here. Switch to another account first.',
          'account_center.remove_account_title': 'Remove Account',
          'account_center.remove_account_body':
              'Do you want to remove @{username} from the saved accounts on this device?',
          'account_center.account_removed': '@{username} was removed.',
          'account_center.single_device_title':
              'Sign out other phones on new sign-in',
          'account_center.single_device_desc':
              'If this setting is enabled, signing in from another phone will close the session on this device. A password will be required to sign in again.',
          'account_center.single_device_enabled':
              'Other phones will be signed out on a new device sign-in.',
          'account_center.single_device_disabled':
              'The account can stay signed in on multiple phones at the same time.',
          'account_center.no_personal_detail':
              'There are no personal details to show yet.',
          'account_center.contact_details': 'Contact Details',
          'account_center.contact_info': 'Contact information',
          'account_center.email': 'Email',
          'account_center.phone': 'Phone',
          'account_center.email_missing': 'No email added',
          'account_center.phone_missing': 'No phone added',
          'account_center.verified': 'Verified',
          'account_center.verify': 'Verify',
          'account_center.unverified': 'Unverified',
          'about_profile.title': 'About This Account',
          'about_profile.description':
              'We share information about accounts on TurqApp transparently to improve the trust of our community.',
          'about_profile.joined_on': 'Joined on {date}',
          'policies.center_title': 'Policy Center',
          'policies.center_desc':
              'Agreement, privacy, community and safety texts are available here.',
          'policies.last_updated': 'Last updated: {date}',
          'admin.no_access': 'This area is only available to admins.',
          'admin.support.title': 'User Support',
          'admin.support.close_message': 'Close Message',
          'admin.support.answer_message': 'Reply to Message',
          'admin.support.note': 'Admin note',
          'admin.support.empty': 'There are no support messages yet.',
          'admin.support.updated_title': 'Updated',
          'admin.support.updated_body': 'Support message updated.',
          'admin.support.open': 'Open',
          'admin.support.answered': 'Answered',
          'admin.support.closed': 'Closed',
          'admin.support.mark_answered': 'Answered',
          'admin.support.close': 'Close',
          'admin.approvals.title': 'Admin Approvals',
          'admin.approvals.empty': 'There are no pending admin approvals.',
          'admin.approvals.default_title': 'Admin Approval',
          'admin.approvals.created_by': 'Created by',
          'admin.approvals.rejection_reason': 'Rejection reason',
          'admin.approvals.approve': 'Approve',
          'admin.approvals.reject': 'Reject',
          'admin.approvals.approved': 'Approved',
          'admin.approvals.rejected': 'Rejected',
          'admin.approvals.pending': 'Pending',
          'admin.approvals.approved_body': 'The action was approved.',
          'admin.approvals.rejected_body': 'The action was rejected.',
          'admin.approvals.approve_failed': 'Approval could not be completed:',
          'admin.approvals.reject_failed': 'Reject failed:',
          'admin.my_approvals.title': 'My Approval Results',
          'admin.my_approvals.load_failed':
              'Approval records could not be loaded.',
          'admin.my_approvals.empty':
              'You do not have any approval requests yet.',
          'admin.my_approvals.default_title': 'Approval Request',
          'admin.my_approvals.requested': 'Requested',
          'admin.my_approvals.result': 'Result',
          'admin.tasks.title': 'Admin Tasks',
          'admin.tasks.editor_title': 'Assign tasks by username',
          'admin.tasks.editor_help':
              'Enter the username, load the user, then check the task boxes and save. This screen is used to track task distribution from a single place.',
          'admin.tasks.username': 'Username',
          'admin.tasks.username_hint': '@username',
          'admin.tasks.load': 'Load',
          'admin.tasks.task_list': 'Tasks',
          'admin.tasks.saving': 'Saving',
          'admin.tasks.save': 'Save Tasks',
          'admin.tasks.clear': 'Clear',
          'admin.tasks.assignments': 'Task Assignments',
          'admin.tasks.assignments_help':
              'This section shows the entire admin task distribution in one list. Tap a card to edit it above.',
          'admin.tasks.no_assignments': 'There are no task assignments yet.',
          'admin.tasks.missing_info': 'Missing Information',
          'admin.tasks.username_required': 'Username is required.',
          'admin.tasks.not_found': 'Not Found',
          'admin.tasks.user_not_found':
              'No user was found with this username.',
          'admin.tasks.load_failed': 'User could not be loaded:',
          'admin.tasks.load_user_first': 'Load the user first.',
          'admin.tasks.assignment_removed':
              'Task assignment removed for @{nickname}.',
          'admin.tasks.saved': 'Tasks saved for @{nickname}.',
          'admin.tasks.save_failed': 'Tasks could not be saved:',
          'admin.tasks.cleared': 'Tasks cleared for @{nickname}.',
          'admin.tasks.clear_failed': 'Tasks could not be cleared:',
          'admin.tasks.updated_at': 'Updated',
          'admin.task.moderation.title': 'Moderation',
          'admin.task.moderation.desc':
              'Manages flags, reports, and content thresholds.',
          'admin.task.reports.title': 'Reports',
          'admin.task.reports.desc':
              'Reviews user and content reports.',
          'admin.task.badges.title': 'Badge Management',
          'admin.task.badges.desc':
              'Reviews badge applications and grants badges.',
          'admin.task.approvals.title': 'Approvals / Requests',
          'admin.task.approvals.desc':
              'Tracks badge and similar approval queues.',
          'admin.task.user_bans.title': 'Ban Management',
          'admin.task.user_bans.desc':
              'Applies or removes user bans.',
          'admin.task.admin_push.title': 'Admin Push',
          'admin.task.admin_push.desc':
              'Sends bulk notifications and system announcements.',
          'admin.task.ads_center.title': 'Ads Center',
          'admin.task.ads_center.desc':
              'Manages advertising and campaign operations.',
          'admin.task.story_music.title': 'Story Music',
          'admin.task.story_music.desc':
              'Manages story music catalogs.',
          'admin.task.pasaj.title': 'Pasaj Operations',
          'admin.task.pasaj.desc':
              'Tracks content and flows on the Pasaj side.',
          'admin.task.support.title': 'User Support',
          'admin.task.support.desc':
              'Tracks user requests and feedback.',
          'admin.moderation.title': 'Moderation',
          'admin.moderation.config_updated':
              'Config updated. Threshold: {threshold}',
          'admin.moderation.config_failed': 'Config could not be updated',
          'admin.moderation.threshold_posts':
              'Posts Above Threshold (≥ {threshold})',
          'admin.moderation.list_failed':
              'Moderation list could not be loaded.',
          'admin.moderation.no_threshold_posts':
              'No posts exceed the threshold.',
          'admin.moderation.no_text': 'No text',
          'admin.moderation.provisioning': 'Setting up...',
          'admin.moderation.ensure_config': 'Setup/Refresh Config',
          'admin.moderation.user_ban_title': 'User Ban Management',
          'admin.moderation.user_ban_help':
              '1st violation: 1 month, 2nd violation: 3 months, 3rd violation: permanent ban. During temporary restriction the user can only browse, like and reshare.',
          'admin.moderation.ban_reason': 'Ban reason',
          'admin.moderation.apply_next_penalty': 'Apply Next Penalty',
          'admin.moderation.active_bans': 'Active Bans',
          'admin.moderation.ban_list_failed':
              'Ban list could not be loaded.',
          'admin.moderation.no_active_bans': 'No actively banned users.',
          'admin.moderation.permanent': 'Permanent',
          'admin.moderation.expired': 'Expired',
          'admin.moderation.level': 'Level {level}',
          'admin.moderation.strike_status':
              'Strike: {count} • Status: {status}',
          'admin.moderation.ends_at': 'Ends: {date}',
          'admin.moderation.next_penalty': 'Next Penalty',
          'admin.moderation.clear_ban': 'Remove Ban',
          'admin.moderation.clear_ban_approval': 'Ban removal approval',
          'admin.moderation.ban_approval': 'Ban action approval',
          'admin.moderation.clear_ban_summary':
              'A ban removal request was created for @{nickname}.',
          'admin.moderation.advance_penalty_summary':
              'A next-penalty request was created for @{nickname}.',
          'admin.moderation.sent_for_approval':
              'Action sent to the admin approval queue.',
          'admin.moderation.ban_removed':
              'Ban removed for @{nickname}.',
          'admin.moderation.permanent_applied':
              'Permanent ban applied for @{nickname}.',
          'admin.moderation.level_applied':
              'Level {level} penalty applied for @{nickname}.',
          'admin.moderation.action_failed':
              'Ban action could not be completed.',
          'admin.badges.title': 'Badge Management',
          'admin.badges.manage_by_username': 'Manage badge by username',
          'admin.badges.manage_help':
              'Enter the username, choose the badge and save. Selecting `No badge` removes the current badge.',
          'admin.badges.no_badge': 'No badge',
          'admin.badges.badge_label': 'Badge',
          'admin.badges.save_badge': 'Save Badge',
          'admin.badges.remove_selected_desc':
              'Removes the current badge from the selected user.',
          'admin.badges.change_approval_title': 'Badge change approval',
          'admin.badges.remove_badge_summary':
              'A badge removal request was created for @{nickname}.',
          'admin.badges.give_badge_summary':
              'A request to assign the {badge} badge was created for @{nickname}.',
          'admin.badges.sent_for_approval':
              'Action sent to the admin approval queue.',
          'admin.badges.badge_removed':
              'Badge removed for @{nickname}.',
          'admin.badges.badge_saved':
              '{badge} badge saved for @{nickname}.',
          'admin.badges.permission_required':
              'Admin permission is required for this action.',
          'admin.badges.invalid_input': 'The provided information is invalid.',
          'admin.badges.multiple_users':
              'Multiple users were found for this username.',
          'admin.badges.save_failed': 'Badge could not be saved.',
          'admin.badges.applications_title': 'Badge Applications',
          'admin.badges.applications_help':
              'Applications come from settings. Social media and TurqApp profile links open below.',
          'admin.badges.no_applications': 'There are no applications yet.',
          'admin.badges.no_badge_selected': 'No badge selected',
          'admin.badges.status': 'Status: {status}',
          'admin.badges.approve_and_assign': 'Approve and Assign Badge',
          'admin.badges.application_approval_title':
              'Badge application approval',
          'admin.badges.application_approval_summary':
              'The {badge} badge for @{nickname} was sent for approval.',
          'admin.badges.application_sent_for_approval':
              'Application sent to the admin approval queue.',
          'admin.badges.application_approved':
              'Badge assigned and application approved.',
          'admin.badges.application_approve_failed':
              'The application could not be approved.',
          'admin.badges.last_action': 'Last action',
          'admin.push.title': 'Send Push',
          'admin.push.permission_title': 'Permission',
          'admin.push.permission_body':
              'Administrator permission is required to send notifications.',
          'admin.push.select_job': 'Select Job',
          'admin.push.required_title_body':
              'Title and message fields are required.',
          'admin.push.invalid_range_title': 'Invalid Range',
          'admin.push.invalid_range_body':
              'Minimum age cannot be greater than maximum age.',
          'admin.push.no_results_title': 'No Results',
          'admin.push.no_results_body':
              'No users matched the selected filters.',
          'admin.push.target': 'Target',
          'admin.push.user_count': 'users',
          'admin.push.type': 'Type',
          'admin.push.job': 'Job',
          'admin.push.location': 'Location',
          'admin.push.gender': 'Gender',
          'admin.push.age': 'Age',
          'admin.push.started_title': 'Dispatch Started',
          'admin.push.started_body':
              'Notification queued for {count} users.',
          'admin.push.send_failed':
              'Notification dispatch could not be completed',
          'admin.push.help':
              'Title and message are required. If you leave filters empty, it goes to everyone.',
          'admin.push.title_field': 'Title',
          'admin.push.message_field': 'Message',
          'admin.push.optional_filters': 'Optional Filters',
          'admin.push.target_uid': 'Target UID (single user)',
          'admin.push.people': 'people',
          'admin.push.location_hint': 'Location (city / province / district)',
          'admin.push.min_age': 'Min Age',
          'admin.push.max_age': 'Max Age',
          'admin.push.saved_reports': 'Saved Reports',
          'admin.push.no_reports': 'There are no reports yet.',
          'admin.push.report_title': 'Title',
          'admin.push.report_message': 'Message',
          'admin.push.report_filters': 'Filters',
          'admin.push.delete_report': 'Delete Report',
          'admin.push.send': 'Send',
          'admin.reports.title': 'Reports',
          'admin.reports.data_failed': 'Reports data could not be loaded.',
          'admin.reports.empty':
              'There are no report aggregates yet.',
          'admin.reports.config_help':
              'Default category threshold: 5\nThreshold breach: content is automatically removed from publication\nAdmin action: republish or keep hidden',
          'admin.reports.config_updated': 'adminConfig/reports updated.',
          'admin.reports.config_failed':
              'Reports config could not be updated',
          'admin.reports.restored': 'Content was restored to publication.',
          'admin.reports.kept_hidden': 'Content was kept hidden.',
          'admin.reports.action_failed': 'Admin action failed',
          'admin.reports.total_status': 'Total: {count} • Status: {status}',
          'admin.reports.category_counts': 'Category Counters',
          'admin.reports.report_reasons': 'Reported Reasons',
          'admin.reports.no_category_data': 'No category data.',
          'admin.reports.no_detail_reports':
              'There are no detailed report records yet.',
          'admin.reports.no_reason': 'No reason',
          'admin.reports.restore': 'Republish',
          'admin.reports.processing': 'Processing...',
          'admin.reports.keep_hidden': 'Keep Hidden',
          'admin.story_music.title': 'Story Music',
          'admin.story_music.cover_uploaded': 'Cover image uploaded',
          'admin.story_music.cover_upload_failed':
              'Cover image could not be uploaded',
          'admin.story_music.title_url_required':
              'Title and music URL are required',
          'admin.story_music.track_added': 'Track added',
          'admin.story_music.track_updated': 'Track updated',
          'admin.story_music.save_failed': 'Track could not be saved',
          'admin.story_music.track_deleted': 'Track deleted',
          'admin.story_music.delete_failed': 'Track could not be deleted',
          'admin.story_music.preview_failed': 'Preview could not be played',
          'admin.story_music.new_track': 'New Track',
          'admin.story_music.edit_track': 'Edit Track',
          'admin.story_music.artist': 'Artist',
          'admin.story_music.audio_url': 'Music URL',
          'admin.story_music.cover_url': 'Cover URL',
          'admin.story_music.category': 'Category',
          'admin.story_music.order': 'Order',
          'admin.story_music.upload_cover': 'Upload Cover',
          'admin.story_music.active': 'Active',
          'admin.story_music.save_track': 'Save Track',
          'admin.story_music.save_update': 'Save Update',
          'admin.story_music.no_tracks': 'There are no tracks yet',
          'admin.story_music.untitled': 'Untitled Track',
          'admin.story_music.order_usage':
              'Order {order} • Usage {count}',
          'common.cancel': 'Cancel',
          'common.save': 'Save',
          'common.done': 'Done',
          'common.select': 'Select',
          'common.remove': 'Remove',
          'common.unspecified': 'Not specified',
          'common.yes': 'Yes',
          'common.no': 'No',
          'common.selected_count': '@count selected',
          'following.followers_tab': 'Followers {count}',
          'following.following_tab': 'Following {count}',
          'following.none': 'No users yet',
          'following.follow': 'Follow',
          'following.following': 'Following',
          'following.unfollow_title': 'Unfollow',
          'following.unfollow_body':
              'Are you sure you want to unfollow @{nickname}?',
          'following.update_failed': 'Follow status could not be updated.',
          'following.limit_title': 'Follow Limit',
          'following.limit_body':
              'You cannot follow more people today.',
          'profile.highlight_remove_title': 'Remove Highlight',
          'profile.highlight_remove_body':
              'Are you sure you want to remove this highlight?',
          'profile.link_remove_title': 'Remove Link',
          'profile.link_remove_body':
              'Are you sure you want to remove this link?',
          'profile.edit': 'Edit',
          'profile.statistics': 'Statistics',
          'profile.posts': 'Posts',
          'profile.followers': 'Followers',
          'profile.following': 'Following',
          'profile.likes': 'Likes',
          'profile.listings': 'Listings',
          'profile.copy_profile_link': 'Copy profile link',
          'profile.profile_share_title': 'TurqApp Profile',
          'profile.private_account_title': 'Private account',
          'profile.private_story_follow_required':
              'You need to follow this account first to view stories.',
          'profile.unfollow_title': 'Unfollow',
          'profile.unfollow_body':
              'Are you sure you want to unfollow @{nickname}?',
          'profile.unfollow_confirm': 'Unfollow',
          'profile.following_status': 'Following',
          'profile.follow_button': 'Follow',
          'profile.contact_options': 'Contact Options',
          'profile.unblock': 'Unblock',
          'profile.remove_highlight_title': 'Remove Highlight',
          'profile.remove_highlight_body':
              'Are you sure you want to remove this highlight?',
          'profile.remove_highlight_confirm': 'Remove',
          'story.highlight_no_stories': 'There are no stories in this highlight.',
          'story.highlight_missing_stories':
              'The stories in this highlight are no longer available.',
          'story.highlight_open_failed':
              'The highlight could not be opened. Please try again.',
          'story.highlights_title': 'Highlights',
          'story.highlights_subtitle':
              'Add this story to a fixed collection on your profile.',
          'story.highlights_collections': 'Your collections',
          'story.highlights_story_count': '@count stories',
          'story.highlights_first_create': 'Create your first collection',
          'story.highlights_first_create_body':
              'Set a title for this story so it appears fixed on your profile.',
          'story.highlights_new': 'Create new highlight',
          'story.highlights_title_hint': 'Enter a title...',
          'story.highlights_create_failed':
              'The highlight could not be created. Please try again.',
          'story.add_sticker': 'Add Sticker',
          'story.text_title': 'Text',
          'story.write_text': 'Write text...',
          'story.sticker_link': 'Link',
          'story.sticker_hashtag': 'Hashtag',
          'story.sticker_countdown': 'Countdown',
          'story.sticker_add_yours': 'Add Yours',
          'story.sticker_question': 'Question',
          'story.sticker_mention': 'Mention',
          'story.sticker_gif': 'GIF',
          'story.sticker_text': 'Text',
          'story.sticker_topic_label': 'Hashtag',
          'story.sticker_countdown_label': 'Countdown title',
          'story.sticker_title_label': 'Title',
          'story.sticker_question_label': 'Question',
          'story.sticker_user_label': 'User',
          'story.link_add': 'Add Link',
          'story.link_text_label': 'Link text',
          'story.link_text_hint': 'Read the news',
          'story.video_audio_title': 'Video Audio',
          'story.music_mute_videos_message':
              'You are about to add music. Do you want to mute the videos?',
          'story.music_mute_videos_yes': 'Yes, mute',
          'social_profile.private_follow_to_see_posts':
              'Follow this account to view posts.',
          'social_profile.blocked_user': 'You blocked this user',
          'profile.no_posts': 'No Posts',
          'profile.no_photos': 'No Photos',
          'profile.no_videos': 'No Videos',
          'profile.no_reshares': 'No reshares',
          'profile.no_quotes': 'No quotes yet',
          'profile.reshare_users_tab': 'Resharers',
          'profile.quote_users_tab': 'Quoters',
          'profile.no_listings': 'No listings',
          'profile.post_about_title': 'About the post',
          'profile.post_about_body':
              'What would you like to do with this post?',
          'profile.archive': 'Archive',
          'profile.review': 'Review',
          'profile.location_missing': 'Location not specified',
          'profile.status_sold': 'Sold',
          'profile.status_passive': 'Passive',
          'profile.status_active': 'Active',
          'profile.remove_reshare_title': 'Remove post',
          'profile.remove_reshare_body':
              'Are you sure you want to remove this post from reshared posts?',
          'profile.scheduled_post_title': 'Scheduled Post',
          'profile.scheduled_post_body':
              'What would you like to do with this post?',
          'profile.scheduled_subscribe_title': 'Follow Release',
          'profile.scheduled_subscribe_body':
              'You will receive a notification on the publish date.',
          'profile.scheduled_none': 'No scheduled posts',
          'common.edit': 'Edit',
          'common.update': 'Update',
          'common.change': 'Change',
          'common.publish': 'Publish',
          'common.loading': 'Loading...',
          'common.now': 'now',
          'common.info': 'Info',
          'common.error': 'Error',
          'common.ok': 'OK',
          'common.apply': 'Apply',
          'common.reset': 'Reset',
          'common.add': 'Add',
          'common.select_city': 'Select City',
          'common.select_district': 'Select District',
          'common.not_listed': 'Not Listed',
          'common.download': 'Download',
          'app.name': 'TurqApp',
          'common.copy': 'Copy',
          'common.copy_link': 'Copy Link',
          'common.copied': 'Copied',
          'common.link_copied': 'The link has been copied to the clipboard',
          'common.archive': 'Archive',
          'common.unarchive': 'Remove from archive',
          'common.report': 'Report',
          'report.reported_user': 'Reported user',
          'report.what_issue': 'What kind of issue are you reporting?',
          'report.thanks_title':
              'Thank you for helping us make TurqApp better for everyone!',
          'report.thanks_body':
              'We know your time is valuable. Thank you for taking the time to help us.',
          'report.how_it_works_title': 'How does this work?',
          'report.how_it_works_body':
              'Your report has reached us. We will hide the reported profile from your feed.',
          'report.whats_next_title': 'What happens next?',
          'report.whats_next_body':
              'Our team will review this profile within a few days. If a violation is found, the account will be restricted. If no violation is found and you have submitted repeated invalid reports, your account may be restricted.',
          'report.optional_block_title': 'If you want',
          'report.optional_block_body':
              'You can block this profile. If you do, this user will no longer appear in your feed at all.',
          'report.block_user_button': 'Block @nickname',
          'report.blocked_user_label': '@nickname has been blocked!',
          'report.block_user_info':
              'Prevent @nickname from following you or sending messages. They can still see your public posts but cannot interact with you. You will also stop seeing @nickname\'s posts.',
          'report.select_reason_title': 'Select Report Reason',
          'report.select_reason_body':
              'You need to choose a reason to continue.',
          'report.submitted_title': 'Your request has reached us!',
          'report.submitted_body':
              'We will review @nickname. Thank you for your report.',
          'report.submitting': 'Sending...',
          'report.done': 'Done',
          'report.reason.impersonation.title':
              'Impersonation / Fake Account / Identity Misuse',
          'report.reason.impersonation.desc':
              'This account or content may be impersonating someone else, using a fake identity, or representing another person without permission.',
          'report.reason.copyright.title':
              'Copyright / Unauthorized Content Use',
          'report.reason.copyright.desc':
              'This content may use copyrighted material without permission or include intellectual property infringement.',
          'report.reason.harassment.title':
              'Harassment / Targeting / Bullying',
          'report.reason.harassment.desc':
              'This content appears to harass, humiliate, target, or systematically bully a person.',
          'report.reason.hate_speech.title': 'Hate Speech',
          'report.reason.hate_speech.desc':
              'This content may include hate, discrimination, or degrading language toward a group or person.',
          'report.reason.nudity.title': 'Nudity / Sexual Content',
          'report.reason.nudity.desc':
              'This content may include nudity, obscenity, or explicit sexual material.',
          'report.reason.violence.title': 'Violence / Threat',
          'report.reason.violence.desc':
              'This content may include physical violence, threats, intimidation, or calls to harm.',
          'report.reason.spam.title': 'Spam / Repetitive Irrelevant Content',
          'report.reason.spam.desc':
              'This content appears repetitive, irrelevant, misleading, or disruptive in a spam-like way.',
          'report.reason.scam.title': 'Scam / Deception',
          'report.reason.scam.desc':
              'This content may be deceptive or fraudulent in order to abuse trust, money, or information.',
          'report.reason.misinformation.title':
              'Misinformation / Manipulation',
          'report.reason.misinformation.desc':
              'This content may distort facts, spread misinformation, or manipulate people.',
          'report.reason.illegal_content.title': 'Illegal Content',
          'report.reason.illegal_content.desc':
              'This content may involve illegal activity, criminal promotion, or unlawful material.',
          'report.reason.child_safety.title': 'Child Safety Violation',
          'report.reason.child_safety.desc':
              'This content may endanger child safety or contain harmful elements unsuitable for children.',
          'report.reason.self_harm.title':
              'Self-harm / Suicide Encouragement',
          'report.reason.self_harm.desc':
              'This content may promote self-harm, suicide, or harmful self-directed behavior.',
          'report.reason.privacy_violation.title': 'Privacy Violation',
          'report.reason.privacy_violation.desc':
              'This content may include unauthorized sharing of personal data, doxxing, or a privacy breach.',
          'report.reason.fake_engagement.title':
              'Fake Engagement / Bot / Manipulative Growth',
          'report.reason.fake_engagement.desc':
              'This content may involve fake likes, bot activity, or manipulative artificial growth.',
          'report.reason.other.title': 'Other',
          'report.reason.other.desc':
              'There may be another violation not covered above that you would like us to review.',
          'common.undo': 'Undo',
          'common.edited': 'edited',
          'common.delete_post_title': 'Delete Post',
          'common.delete_post_message':
              'Are you sure you want to delete this post?',
          'common.delete_post_confirm': 'Delete Post',
          'common.post_share_title': 'TurqApp Post',
          'common.send': 'Send',
          'common.block': 'Block',
          'common.unknown_user': 'Unknown User',
          'common.unknown_company': 'Unknown Company',
          'common.verified': 'Verified',
          'common.verify': 'Verify',
          'common.message': 'Message',
          'common.phone': 'Phone',
          'common.description': 'Description',
          'common.location': 'Location',
          'common.category': 'Category',
          'common.status': 'Status',
          'common.features': 'Features',
          'common.contact': 'Contact',
          'common.city': 'City',
          'comments.input_hint': 'What do you think about this?',
          'explore.tab.trending': 'Trending',
          'explore.tab.for_you': 'For You',
          'explore.tab.series': 'Series',
          'explore.trending_rank': '@index - trending in Turkey history',
          'explore.no_results': 'No results found',
          'explore.no_series': 'No series found',
          'feed.empty_city': 'There are no posts in your city yet',
          'feed.empty_following': 'No posts yet from the people you follow',
          'post_likes.title': 'Likes',
          'post_likes.empty': 'There are no likes yet',
          'post_state.hidden_title': 'Post Hidden',
          'post_state.hidden_body':
              'This post has been hidden. You will see similar posts lower in your feed.',
          'post_state.archived_title': 'Post Archived',
          'post_state.archived_body':
              'You archived this post.\nThis post will no longer be visible to anyone.',
          'post_state.deleted_title': 'Post Deleted',
          'post_state.deleted_body': 'This post is no longer live.',
          'post.share_title': 'TurqApp Post',
          'post.archive': 'Archive',
          'post.unarchive': 'Remove from archive',
          'post.like_failed': 'Like action could not be completed.',
          'post.save_failed': 'Save action could not be completed.',
          'post.reshare_failed': 'Reshare action could not be completed.',
          'post.report_success': 'Post reported.',
          'post.report_failed': 'Report action could not be completed.',
          'post.hide_failed': 'The hide action could not be completed.',
          'post.reshare_action': 'Reshare',
          'post.reshare_undo': 'Undo reshare',
          'post.reshared_you': 'you reshared this',
          'post.reshared_by': '@name reshared this',
          'short.next_post': 'Go to next post',
          'short.publish_as_post': 'Publish as post',
          'short.add_to_story': 'Add to your story',
          'short.shared_as_post_by': 'Shared as posts by',
          'story.seens_title': 'Views (@count)',
          'story.likes_title': 'Likes (@count)',
          'story.no_likes': 'No one liked your story',
          'story.no_seens': 'No one has viewed your story yet',
          'story.comments_title': 'Comments (@count)',
          'story.share_title': '@name story',
          'story.share_desc': 'View the story on TurqApp',
          'story.drawing_title': 'Add Drawing',
          'story.brush_color': 'Brush Color',
          'story.no_comments': 'No one has commented yet',
          'story.add_comment_for': 'Add a comment for @nickname..',
          'story.comment_placeholder': 'Write a comment on the story..',
          'story.gif_load_failed': 'GIF could not be loaded',
          'story.create_title': 'Create Story',
          'story.no_user': 'No signed-in user found',
          'story.empty_elements': 'Add at least one element to the story',
          'story.past_time_invalid': 'A past time cannot be selected',
          'story.no_elements_saved': 'No elements could be saved',
          'story.save_failed': 'Story could not be saved: @error',
          'admin_push.queue_title': 'Push',
          'admin_push.queue_body_count': 'Push queued for @count users',
          'admin_push.queue_body': 'Push queued',
          'admin_push.failed_body': 'Push could not be sent.',
          'story.delete_message': 'Delete this story?',
          'story.permanent_delete': 'Delete Permanently',
          'story.permanent_delete_message':
              'Delete this story permanently?',
          'story.comment_delete_message':
              'Are you sure you want to delete this comment?',
          'story.deleted_stories.title': 'Stories',
          'story.deleted_stories.tab_deleted': 'Deleted',
          'story.deleted_stories.tab_expired': 'Expired',
          'story.deleted_stories.empty': 'There are no deleted stories',
          'story.deleted_stories.snackbar_title': 'Story',
          'story.deleted_stories.reposted': 'Story reposted',
          'story.deleted_stories.deleted_forever':
              'Story deleted permanently',
          'story.deleted_stories.deleted_at': 'Deleted: @time',
          'story_music.title': 'Music',
          'story_music.search_hint': 'Search music',
          'story_music.no_active_stories':
              'There are no active stories with this music',
          'story_music.untitled': 'Untitled Track',
          'story_music.active_story_count': '@count active stories',
          'story_music.minutes_ago': '@count min',
          'story_music.hours_ago': '@count hr',
          'story_music.days_ago': '@count d',
          'chat.attach_photos': 'Photos',
          'chat.list_title': 'Chats',
          'chat.tab_all': 'All',
          'chat.tab_unread': 'Unread',
          'chat.tab_archive': 'Archive',
          'chat.empty_title': 'You have no chats yet',
          'chat.empty_body':
              'When you start messaging, your conversations will appear here.',
          'chat.action_failed':
              'The action could not be completed due to a permission or record issue',
          'chat.attach_videos': 'Videos',
          'chat.attach_location': 'Location',
          'chat.message_hint': 'Message',
          'chat.no_starred_messages': 'No starred messages',
          'chat.profile_stats':
              '@followers followers · @following following · @posts posts',
          'chat.selected_messages': '@count messages selected',
          'chat.today': 'Today',
          'chat.yesterday': 'Yesterday',
          'chat.typing': 'typing...',
          'chat.gif': 'GIF',
          'chat.ready_to_send': 'Ready to send',
          'chat.editing_message': 'Editing message',
          'chat.video': 'Video',
          'chat.audio': 'Audio',
          'chat.location': 'Location',
          'chat.post': 'Post',
          'chat.person': 'Person',
          'chat.reply': 'Reply',
          'chat.recording_timer': 'Recording... @time',
          'chat.fetching_address': 'Fetching address...',
          'chat.add_star': 'Add Star',
          'chat.remove_star': 'Remove Star',
          'chat.you': 'You',
          'chat.hide_photos': 'Hide photos',
          'chat.unsent_message': 'Message unsent',
          'chat.reply_prompt': 'Reply',
          'chat.open_in_maps': 'Open in Maps',
          'chat.open_in_google_maps': 'Open in Google Maps',
          'chat.open_in_apple_maps': 'Open in Apple Maps',
          'chat.open_in_yandex_maps': 'Open in Yandex Maps',
          'chat.contact_info': 'Contact Info',
          'chat.save_to_contacts': 'Save to Contacts',
          'chat.call': 'Call',
          'chat.delete_message_title': 'Delete Message',
          'chat.delete_message_body':
              'Are you sure you want to delete this message?',
          'chat.delete_for_me': 'Delete for Me',
          'chat.delete_for_everyone': 'Delete for Everyone',
          'chat.delete_photo_title': 'Delete Photo',
          'chat.delete_photo_body':
              'Are you sure you want to delete this photo?',
          'chat.delete_photo_confirm': 'Delete Photo',
          'chat.messages_delete_failed': 'Messages could not be deleted',
          'chat.image_upload_failed': 'Image upload failed',
          'chat.image_upload_failed_with_error': 'Image upload failed: @error',
          'chat.video_upload_failed': 'An error occurred while uploading video',
          'chat.microphone_permission_required': 'Permission Required',
          'chat.microphone_permission_denied':
              'Microphone permission was not granted',
          'chat.voice_record_start_failed':
              'Voice recording could not be started',
          'chat.voice_message_upload_failed':
              'An error occurred while uploading the voice message',
          'chat.message_send_failed':
              'Message could not be sent. Please try again.',
          'chat.shared_post_from': 'Sent @nickname s post',
          'chat.notif_video': 'Sent a video',
          'chat.notif_audio': 'Sent a voice message',
          'chat.notif_images': 'Sent @count images',
          'chat.notif_post': 'Shared a post',
          'chat.notif_location': 'Sent a location',
          'chat.notif_contact': 'Shared a contact',
          'chat.notif_gif': 'Sent a GIF',
          'chat.reply_target_missing': 'The replied message could not be found',
          'chat.forward_target_missing': 'No chat found to forward to',
          'chat.forwarded_title': 'Forwarded',
          'chat.forwarded_body': 'The message was forwarded to the selected chat',
          'chat.tap_to_chat': 'Tap to start chatting.',
          'chat.photo': 'Photo',
          'chat.message_label': 'Message',
          'chat.marked_unread': 'Chat marked as unread',
          'chat.limit_title': 'Limit',
          'chat.pin_limit': 'You can pin up to 5 chats',
          'chat.action_completed': 'Action completed',
          'chat.muted': 'Chat muted',
          'chat.unmuted': 'Chat unmuted',
          'chat.archived': 'Chat moved to archive',
          'chat.unarchived': 'Chat removed from archive',
          'chat.delete_title': 'Delete Chat',
          'chat.delete_message':
              'Are you sure you want to delete this chat?',
          'chat.delete_confirm': 'Delete Chat',
          'chat.deleted_title': 'Chat Deleted',
          'chat.deleted_body': 'The selected chat was deleted successfully',
          'chat.unmute': 'Unmute',
          'chat.mute': 'Mute',
          'chat.mark_unread': 'Mark as unread',
          'chat.pin': 'Pin',
          'chat.unpin': 'Unpin',
          'chat.muted_label': 'Muted',
          'training.comments_title': 'Comments',
          'training.no_comments': 'No comments yet.',
          'training.reply': 'Reply',
          'training.hide_replies': 'Hide replies',
          'training.view_replies': 'View @count replies',
          'training.unknown_user': 'Unknown User',
          'training.edit': 'Edit',
          'training.report': 'Report',
          'training.reply_to_user': 'Reply to @name',
          'training.cancel': 'Cancel',
          'training.edit_comment_hint': 'Edit comment',
          'training.write_hint': 'Write..',
          'training.pick_from_gallery': 'Choose from Gallery',
          'training.take_photo': 'Take Photo',
          'training.time_now': 'just now',
          'training.time_min': '@count min ago',
          'training.time_hour': '@count h ago',
          'training.time_day': '@count d ago',
          'training.time_week': '@count w ago',
          'training.photo_pick_failed':
              'An error occurred while selecting the photo!',
          'training.photo_upload_failed':
              'An error occurred while uploading the photo!',
          'training.question_bank_title': 'Question Bank',
          'training.questions_loading': 'Loading Questions...',
          'training.solve_later_empty': 'No questions to solve later were found!',
          'training.remove_solve_later': 'Remove from Solve Later',
          'training.search_no_match': 'No question matched your search.',
          'training.no_questions': 'No questions found!',
          'training.answer_first': 'Answer the question first!',
          'training.share': 'Share',
          'training.correct_ratio': '%@value Correct',
          'training.wrong_ratio': '%@value Wrong',
          'training.complaint_select_one':
              'Please select at least one complaint option.',
          'training.complaint_thanks':
              'Thank you for your report.',
          'training.complaint_submit_failed':
              'There was a problem while sending your report.',
          'training.no_questions_in_category':
              'No questions were found in this category.',
          'training.saved_load_failed':
              'An error occurred while loading saved questions.',
          'training.view_update_failed':
              'An error occurred while updating the view.',
          'training.saved_removed':
              'Question removed from Solve Later list!',
          'training.saved_added': 'Question added to Solve Later list!',
          'training.saved_remove_failed':
              'An error occurred while removing Solve Later.',
          'training.saved_update_failed':
              'An error occurred while updating Solve Later.',
          'training.like_removed': 'Like removed!',
          'training.liked': 'Question liked!',
          'training.like_remove_failed':
              'An error occurred while removing the like.',
          'training.like_add_failed':
              'An error occurred while adding the like.',
          'training.share_failed': 'Sharing could not be started',
          'training.share_question_link_title':
              '@exam - @lesson Question @number',
          'training.share_question_title':
              'TurqApp - @exam @lesson Question',
          'training.share_question_desc': 'TurqApp question bank question',
          'training.leaderboard_empty': 'No leaderboard has been created yet.',
          'training.leaderboard_empty_body':
              'Solve questions in the Question Bank to enter the leaderboard.',
          'education.past_exam_create_title': 'Create Past Exam',
          'education.start_creating': 'Start Creating',
          'education.exam_types': 'Exam Types',
          'education.question_count_hint': 'Question Count',
          'education.change_main_category': 'Change Main Category',
          'training.answer_locked':
              'You cannot change the answer to this question!',
          'training.answer_saved':
              'This question answer has already been saved.',
          'training.answer_save_failed':
              'An error occurred while saving the answer',
          'training.no_more_questions':
              'There are no more questions in this category!',
          'training.settings_opening': 'Opening settings screen!',
          'training.fetch_more_failed':
              'An error occurred while fetching more questions',
          'training.comments_load_failed':
              'An error occurred while loading comments. Please try again!',
          'training.comment_or_photo_required':
              'You need to add a comment or a photo!',
          'training.reply_or_photo_required':
              'You need to add a reply or a photo!',
          'training.comment_added': 'Your comment has been added!',
          'training.comment_add_failed':
              'An error occurred while adding the comment. Please try again!',
          'training.reply_added': 'Your reply has been added!',
          'training.reply_add_failed':
              'An error occurred while adding the reply. Please try again!',
          'training.comment_deleted': 'Your comment has been deleted!',
          'training.comment_delete_failed':
              'An error occurred while deleting the comment. Please try again!',
          'training.reply_deleted': 'Your reply has been deleted!',
          'training.reply_delete_failed':
              'An error occurred while deleting the reply. Please try again!',
          'training.comment_updated': 'Your comment has been updated!',
          'training.comment_update_failed':
              'An error occurred while editing the comment. Please try again!',
          'training.reply_updated': 'Your reply has been updated!',
          'training.reply_update_failed':
              'An error occurred while editing the reply. Please try again!',
          'training.like_failed':
              'An error occurred during the like action. Please try again!',
          'training.upload_failed_title': 'Upload Failed!',
          'training.upload_failed_body':
              'This content cannot be processed right now. Please try different content.',
          'common.accept': 'Accept',
          'common.reject': 'Reject',
          'common.open_profile': 'Open Profile',
          'tutoring.title': 'Tutoring',
          'tutoring.search_hint': 'What kind of lesson are you looking for?',
          'tutoring.my_applications': 'My Applications',
          'tutoring.create_listing': 'Create Listing',
          'tutoring.my_listings': 'My Listings',
          'tutoring.saved': 'Saved',
          'tutoring.slider_admin': 'Slider Admin',
          'tutoring.review_title': 'Leave a Review',
          'tutoring.review_hint': 'Write your comment (optional)',
          'tutoring.review_select_rating': 'Please select a rating.',
          'tutoring.review_saved': 'Your review has been saved.',
          'tutoring.applicants_title': 'Applicants',
          'tutoring.no_applications': 'There are no applications yet',
          'tutoring.application_label': 'Tutoring application',
          'tutoring.my_applications_empty':
              'You have not made any tutoring applications yet',
          'tutoring.instructor_fallback': 'Instructor',
          'tutoring.cancel_application_title': 'Cancel Application',
          'tutoring.cancel_application_body':
              'Are you sure you want to cancel this application?',
          'tutoring.cancel_application_action': 'Cancel Application',
          'tutoring.my_listings_title': 'My Listings',
          'tutoring.published': 'Published',
          'tutoring.expired': 'Expired',
          'tutoring.active_listings_empty':
              'There are no active tutoring listings.',
          'tutoring.expired_listings_empty':
              'There are no expired tutoring listings.',
          'tutoring.user_id_missing': 'User identity could not be found.',
          'tutoring.load_failed':
              'An error occurred while loading listings: {error}',
          'tutoring.reactivated_title': 'Listing Reactivated',
          'tutoring.reactivated_body':
              'The listing has been published again.',
          'tutoring.user_load_failed':
              'An error occurred while loading user information: {error}',
          'tutoring.location_missing': 'Location Not Found',
          'tutoring.no_listings_in_region':
              'There are no tutoring listings in this area.',
          'tutoring.no_lessons_in_category':
              'There are no lessons in the {category} category.',
          'tutoring.search_empty': 'No listing matched your search.',
          'tutoring.search_empty_info': 'No matching tutoring listing found!',
          'tutoring.similar_listings': 'Similar Listings',
          'tutoring.open_listing': 'Open Listing',
          'tutoring.report_listing': 'Report Listing',
          'tutoring.saved_empty': 'No saved listings.',
          'tutoring.detail_description': 'Description',
          'tutoring.detail_no_description':
              'No description has been added for this listing.',
          'tutoring.detail_lesson_info': 'Lesson Details',
          'tutoring.detail_branch': 'Branch',
          'tutoring.detail_price': 'Price',
          'tutoring.detail_contact': 'Contact',
          'tutoring.detail_phone_and_message': 'Phone + Message',
          'tutoring.detail_message_only': 'Message Only',
          'tutoring.detail_gender_preference': 'Gender Preference',
          'tutoring.detail_availability': 'Availability',
          'tutoring.detail_listing_info': 'Listing Details',
          'tutoring.detail_instructor': 'Instructor',
          'tutoring.detail_not_specified': 'Not specified',
          'tutoring.detail_city': 'City',
          'tutoring.detail_views': 'Views',
          'tutoring.detail_status': 'Status',
          'tutoring.detail_status_passive': 'Passive',
          'tutoring.detail_status_active': 'Active',
          'tutoring.detail_location': 'Location',
          'tutoring.create.city_select': 'Select City',
          'tutoring.create.district_select': 'Select District',
          'tutoring.create.nsfw_check_failed':
              'NSFW image check failed.',
          'tutoring.create.nsfw_detected': 'Inappropriate image detected.',
          'tutoring.create.fill_required':
              'Please fill in all required fields!',
          'tutoring.create.published': 'Tutoring listing has been published!',
          'tutoring.create.publish_failed':
              'An error occurred while publishing the listing.',
          'tutoring.create.updated': 'Listing updated!',
          'tutoring.create.no_changes': 'No changes were made!',
          'tutoring.create.update_failed':
              'An error occurred while updating the listing.',
          'tutoring.call_disabled': 'Calling is disabled for this listing.',
          'tutoring.message': 'Message',
          'tutoring.messages': 'Messages',
          'tutoring.phone_missing':
              'The tutor''s phone information could not be found.',
          'tutoring.phone_open_failed':
              'The phone app could not be opened.',
          'tutoring.unpublish_title': 'Remove Listing',
          'tutoring.unpublish_body':
              'Are you sure you want to remove this tutoring listing from publication?',
          'tutoring.unpublished': 'Listing removed from publication.',
          'tutoring.apply_login_required':
              'Please sign in again to apply.',
          'tutoring.application_sent': 'Your application has been sent.',
          'tutoring.application_failed':
              'There was a problem during the application.',
          'tutoring.delete_success': 'Listing deleted!',
          'tutoring.delete_failed':
              'An error occurred while deleting the listing.',
          'tutoring.filter_title': 'Filters',
          'tutoring.gender_title': 'Gender',
          'tutoring.sort_title': 'Sorting',
          'tutoring.lesson_place_title': 'Lesson Place',
          'tutoring.service_location_title': 'Service Location',
          'tutoring.gender.male': 'Male',
          'tutoring.gender.female': 'Female',
          'tutoring.gender.any': 'Any',
          'tutoring.sort.latest': 'Latest',
          'tutoring.sort.nearest': 'Nearest to Me',
          'tutoring.sort.most_viewed': 'Most Viewed',
          'tutoring.lesson_place.student_home': 'Student Home',
          'tutoring.lesson_place.teacher_home': 'Teacher Home',
          'tutoring.lesson_place.either_home': 'Student or Teacher Home',
          'tutoring.lesson_place.remote': 'Remote Education',
          'tutoring.lesson_place.lesson_area': 'Lesson Area',
          'tutoring.branch.summer_school': 'Summer School',
          'tutoring.branch.secondary_education': 'Secondary Education',
          'tutoring.branch.primary_education': 'Primary Education',
          'tutoring.branch.foreign_language': 'Foreign Language',
          'tutoring.branch.software': 'Software',
          'tutoring.branch.driving': 'Driving',
          'tutoring.branch.sports': 'Sports',
          'tutoring.branch.art': 'Art',
          'tutoring.branch.music': 'Music',
          'tutoring.branch.theatre': 'Theatre',
          'tutoring.branch.personal_development': 'Personal Development',
          'tutoring.branch.vocational': 'Vocational',
          'tutoring.branch.special_education': 'Special Education',
          'tutoring.branch.children': 'Children',
          'tutoring.branch.diction': 'Diction',
          'tutoring.branch.photography': 'Photography',
          'tutoring.branch': 'Branch',
          'scholarship.applications_title': 'Applications (@count)',
          'scholarship.no_applications': 'There are no applications yet',
          'scholarship.my_listings': 'My Scholarship Listings',
          'scholarship.no_my_listings': 'You do not have any scholarship listings!',
          'scholarship.applications_suffix': '@title SCHOLARSHIP APPLICATIONS',
          'scholarship.my_applications_title': 'My Scholarship Applications',
          'scholarship.no_user_applications':
              'You do not have any scholarship applications!',
          'scholarship.saved_empty': 'No saved scholarships found.',
          'scholarship.liked_empty': 'No liked scholarships found.',
          'scholarship.remove_saved': 'Remove from Saved',
          'scholarship.remove_liked': 'Remove from Liked',
          'scholarship.remove_saved_confirm':
              'Are you sure you want to remove this scholarship from saved items?',
          'scholarship.remove_liked_confirm':
              'Are you sure you want to remove this scholarship from liked items?',
          'scholarship.removed_saved':
              'Scholarship removed from saved items.',
          'scholarship.removed_liked':
              'Scholarship removed from liked items.',
          'scholarship.list_title': 'Scholarships (@count)',
          'scholarship.search_results_title': 'Search Results (@count)',
          'scholarship.empty_title': 'No scholarships yet',
          'scholarship.empty_body': 'New scholarships will be added soon',
          'scholarship.no_results_for': 'No results found for "@query"',
          'scholarship.search_hint_body': 'Tip: Try different keywords',
          'scholarship.search_tip_header': 'You can search by:',
          'scholarship.load_more_failed':
              'More scholarships could not be loaded.',
          'scholarship.like_failed': 'Like action failed.',
          'scholarship.bookmark_failed': 'Save action failed.',
          'scholarship.share_owner_only':
              'Only admins and the listing owner can share.',
          'scholarship.share_missing_id':
              'Scholarship ID was not found for sharing.',
          'scholarship.share_failed': 'Sharing failed.',
          'scholarship.share_fallback_desc': 'TurqApp scholarship listing',
          'scholarship.share_detail_title':
              'TurqApp Education - Scholarship Detail',
          'scholarship.providers_title': 'Scholarship Providers',
          'scholarship.providers_empty':
              'No scholarship providers were found.',
          'scholarship.providers_load_failed':
              'Scholarship providers could not be loaded.',
          'scholarship.applications_load_failed':
              'Applications could not be loaded.',
          'scholarship.applicant_load_failed':
              'An error occurred while loading the data.',
          'scholarship.withdraw_application': 'Withdraw Application',
          'scholarship.withdraw_confirm_title': 'Attention!',
          'scholarship.withdraw_confirm_body':
              'Are you sure you want to withdraw your application?',
          'scholarship.withdraw_success':
              'Your scholarship application has been withdrawn.',
          'scholarship.withdraw_failed':
              'The application could not be withdrawn.',
          'scholarship.session_missing': 'User session is not active.',
          'scholarship.create_title': 'Create Scholarship',
          'scholarship.edit_title': 'Edit Scholarship',
          'scholarship.preview_title': 'Scholarship Preview',
          'scholarship.visual_info': 'Visual Information',
          'scholarship.basic_info': 'Basic Information',
          'scholarship.application_info': 'Application Information',
          'scholarship.extra_info': 'Additional Information',
          'scholarship.title_label': 'Scholarship Title',
          'scholarship.provider_label': 'Scholarship Provider',
          'scholarship.website_label': 'Website',
          'scholarship.description_help':
              'Please write the scholarship description in one clear section.',
          'scholarship.no_description': 'No description',
          'scholarship.conditions_label': 'Application Requirements',
          'scholarship.required_docs_label': 'Required Documents',
          'scholarship.award_months_label': 'Scholarship Award Months',
          'scholarship.application_place_label': 'Application Destination',
          'scholarship.application_place_turqapp': 'TurqApp',
          'scholarship.application_place_website': 'Scholarship Website',
          'scholarship.application_website_label': 'Scholarship Website',
          'scholarship.application_dates_label': 'Application Dates',
          'scholarship.detail_missing': 'Error: Scholarship data not found.',
          'scholarship.detail_title': 'Scholarship Detail',
          'scholarship.delete_title': 'Delete Scholarship',
          'scholarship.delete_confirm':
              'Are you sure you want to delete this scholarship?',
          'scholarship.applications_heading': '@title scholarship applications',
          'scholarship.applicant.personal_section': 'Personal Information',
          'scholarship.applicant.education_section': 'Education Information',
          'scholarship.applicant.family_section': 'Family Information',
          'scholarship.applicant.full_name': 'Full Name',
          'scholarship.applicant.email': 'Email Address',
          'scholarship.applicant.phone': 'Phone Number',
          'scholarship.applicant.phone_open_failed':
              'Phone call could not be started',
          'scholarship.applicant.email_open_failed':
              'Email client could not be opened',
          'chat.sign_in_required':
              'You need to sign in to send a message.',
          'chat.cannot_message_self_listing':
              'You cannot message your own listing.',
          'scholarship.applicant.country': 'Country',
          'scholarship.applicant.registry_city': 'Registry City',
          'scholarship.applicant.registry_district': 'Registry District',
          'scholarship.applicant.birth_date': 'Birth Date',
          'scholarship.applicant.marital_status': 'Marital Status',
          'scholarship.applicant.gender': 'Gender',
          'scholarship.applicant.disability_report': 'Disability Report',
          'scholarship.applicant.employment_status': 'Employment Status',
          'scholarship.applicant.education_level': 'Education Level',
          'scholarship.applicant.university': 'University',
          'scholarship.applicant.faculty': 'Faculty',
          'scholarship.applicant.department': 'Department',
          'scholarship.applicant.father_alive': 'Is Father Alive?',
          'scholarship.applicant.father_name': 'Father Name',
          'scholarship.applicant.father_surname': 'Father Surname',
          'scholarship.applicant.father_phone': 'Father Phone',
          'scholarship.applicant.father_job': 'Father Job',
          'scholarship.applicant.father_income': 'Father Income',
          'scholarship.applicant.mother_alive': 'Is Mother Alive?',
          'scholarship.applicant.mother_name': 'Mother Name',
          'scholarship.applicant.mother_surname': 'Mother Surname',
          'scholarship.applicant.mother_phone': 'Mother Phone',
          'scholarship.applicant.mother_job': 'Mother Job',
          'scholarship.applicant.mother_income': 'Mother Income',
          'scholarship.applicant.home_ownership': 'Home Ownership',
          'scholarship.applicant.residence_city': 'Residence City',
          'scholarship.applicant.residence_district': 'Residence District',
          'family_info.title': 'Family Information',
          'family_info.reset_menu': 'Reset Family Information',
          'family_info.reset_title': 'Reset Family Information',
          'family_info.reset_body':
              'All your family information will be deleted. This action cannot be undone. Are you sure?',
          'family_info.select_father_alive': 'Please select whether your father is alive',
          'family_info.select_mother_alive': 'Please select whether your mother is alive',
          'family_info.father_name_surname': 'Father Name - Surname',
          'family_info.mother_name_surname': 'Mother Name - Surname',
          'family_info.select_job': 'Select Occupation',
          'family_info.father_salary': 'Father Net Salary',
          'family_info.mother_salary': 'Mother Net Salary',
          'family_info.father_phone': 'Father Contact Number',
          'family_info.mother_phone': 'Mother Contact Number',
          'family_info.salary_hint': 'Net Salary',
          'family_info.family_size': 'Family Size',
          'family_info.family_size_hint': 'Number of Household Members (Including You)',
          'family_info.residence_info': 'Residence Information',
          'family_info.father_salary_missing': 'Father salary information',
          'family_info.father_phone_missing': 'Father phone number',
          'family_info.father_phone_invalid':
              'Father phone number must be 10 digits',
          'family_info.mother_salary_missing': 'Mother salary information',
          'family_info.mother_phone_missing': 'Mother phone number',
          'family_info.mother_phone_invalid':
              'Mother phone number must be 10 digits',
          'family_info.saved': 'Your family information has been saved.',
          'family_info.save_failed':
              'Information could not be saved. Please try again.',
          'family_info.reset_success': 'Family information has been reset.',
          'family_info.reset_failed':
              'Information could not be reset. Please try again.',
          'family_info.home_owned': 'Own Home',
          'family_info.home_relative': 'Relative\'s Home',
          'family_info.home_lodging': 'Lodging',
          'family_info.home_rent': 'Rent',
          'personal_info.title': 'Personal Information',
          'personal_info.reset_menu': 'Reset My Information',
          'personal_info.reset_title': 'Are you sure?',
          'personal_info.reset_body':
              'Your personal information will be reset. This action cannot be undone.',
          'personal_info.reset_success': 'Your personal information has been reset.',
          'personal_info.registry_info': 'Registered City - District',
          'personal_info.birth_date_title': 'Your Birth Date',
          'personal_info.select_birth_date': 'Select Birth Date',
          'personal_info.select_marital_status': 'Select Marital Status',
          'personal_info.select_gender': 'Select Gender',
          'personal_info.select_disability': 'Select Disability Status',
          'personal_info.select_employment': 'Select Employment Status',
          'personal_info.select_field': 'Select @field',
          'personal_info.city_load_failed': 'City and district data could not be loaded.',
          'personal_info.user_data_missing':
              'User data could not be found. You can create a new record.',
          'personal_info.load_failed': 'Data could not be loaded.',
          'personal_info.select_country_error': 'Please select a country.',
          'personal_info.fill_city_district':
              'Please fill in the city and district information.',
          'personal_info.saved': 'Your personal information has been saved.',
          'personal_info.save_failed': 'Information could not be saved.',
          'personal_info.marital_single': 'Single',
          'personal_info.marital_married': 'Married',
          'personal_info.marital_divorced': 'Divorced',
          'personal_info.gender_male': 'Male',
          'personal_info.gender_female': 'Female',
          'personal_info.disability_yes': 'Yes',
          'personal_info.disability_no': 'No',
          'personal_info.working_yes': 'Working',
          'personal_info.working_no': 'Not Working',
          'education_info.title': 'Education Information',
          'education_info.reset_menu': 'Reset My Education Information',
          'education_info.reset_title': 'Are you sure?',
          'education_info.reset_body':
              'Your education information will be reset. This action cannot be undone.',
          'education_info.reset_success':
              'Your education information has been reset.',
          'education_info.select_level':
              'Please select an education level first!',
          'education_info.middle_school': 'School',
          'education_info.high_school': 'High School',
          'education_info.class_level': 'Class',
          'education_info.level_middle_school': 'Middle School',
          'education_info.level_high_school': 'High School',
          'education_info.level_associate': 'Associate',
          'education_info.level_bachelor': 'Bachelor',
          'education_info.level_masters': 'Master\'s',
          'education_info.level_doctorate': 'Doctorate',
          'education_info.class_grade': 'Grade @grade',
          'education_info.select_field': 'Select @field',
          'education_info.initial_load_failed':
              'Initial data could not be loaded.',
          'education_info.countries_load_failed':
              'Countries could not be loaded.',
          'education_info.city_data_failed':
              'City and district data could not be loaded.',
          'education_info.middle_schools_failed':
              'School data could not be loaded.',
          'education_info.high_schools_failed':
              'High school data could not be loaded.',
          'education_info.higher_education_failed':
              'Higher education data could not be loaded.',
          'education_info.saved_data_failed':
              'Saved data could not be loaded.',
          'education_info.level_load_failed':
              'Level data could not be loaded.',
          'education_info.select_city_error': 'Please select a city.',
          'education_info.select_district_error': 'Please select a district.',
          'education_info.select_middle_school_error':
              'Please select a middle school.',
          'education_info.select_high_school_error':
              'Please select a high school.',
          'education_info.select_class_level_error':
              'Please select a class level.',
          'education_info.select_university_error':
              'Please select a university.',
          'education_info.select_faculty_error':
              'Please select a faculty.',
          'education_info.select_department_error':
              'Please select a department.',
          'education_info.saved': 'Your education information has been saved.',
          'education_info.save_failed': 'Save failed.',
          'bank_info.title': 'Bank Information',
          'bank_info.reset_menu': 'Reset My Bank Information',
          'bank_info.reset_title': 'Are you sure?',
          'bank_info.reset_body':
              'Your bank information will be reset. This action cannot be undone.',
          'bank_info.reset_success': 'Your bank information has been reset.',
          'bank_info.fast_title': 'Easy Address (FAST)',
          'bank_info.fast_email': 'Email',
          'bank_info.fast_phone': 'Phone',
          'bank_info.fast_iban': 'IBAN',
          'bank_info.bank_label': 'Bank',
          'bank_info.select_bank': 'Select Bank',
          'bank_info.select_fast_type': 'Select Easy Address Type',
          'bank_info.load_failed': 'Data could not be loaded.',
          'bank_info.missing_value':
              'We cannot continue without completing the IBAN information.',
          'bank_info.missing_bank':
              'You have not selected the bank where you will receive payment. This information will be shared if your scholarship is approved.',
          'bank_info.invalid_email':
              'Please enter a valid email address.',
          'bank_info.saved': 'Bank information has been saved.',
          'bank_info.save_failed': 'Information could not be saved.',
          'dormitory.title': 'Dormitory Information',
          'dormitory.reset_menu': 'Reset My Dormitory Information',
          'dormitory.reset_title': 'Are you sure?',
          'dormitory.reset_body':
              'Your dormitory information will be reset. This action cannot be undone.',
          'dormitory.reset_success':
              'Your dormitory information has been reset.',
          'dormitory.current_info': 'Current Dormitory Information',
          'dormitory.select_admin_type': 'Select Administration Type',
          'dormitory.admin_public': 'Public',
          'dormitory.admin_private': 'Private',
          'dormitory.select_dormitory': 'Select Dormitory',
          'dormitory.not_found_for_filters':
              'No dormitory was found for this city and administration type',
          'dormitory.saved': 'Your dormitory information has been saved.',
          'dormitory.save_failed': 'Data could not be saved.',
          'dormitory.select_or_enter':
              'Please select a dormitory or enter a dormitory name',
          'scholarship.application_start_date': 'Application Start Date',
          'scholarship.application_end_date': 'Application End Date',
          'scholarship.select_from_list': 'Select from list',
          'scholarship.image_missing': 'No image found',
          'scholarship.amount_label': 'Amount',
          'scholarship.student_count_label': 'Student Count',
          'scholarship.repayable_label': 'Repayable',
          'scholarship.duplicate_status_label': 'Duplicate Status',
          'scholarship.education_audience_label': 'Education Audience',
          'scholarship.target_audience_label': 'Target Audience',
          'scholarship.country_label': 'Country',
          'scholarship.cities_label': 'Cities',
          'scholarship.universities_label': 'Universities',
          'scholarship.published_at': 'Listing Publish Date',
          'scholarship.show_less': 'Show less',
          'scholarship.show_all': 'Show all',
          'scholarship.more_universities': '+@count more universities',
          'scholarship.other_info': 'Other Information',
          'scholarship.application_how': 'How to Apply?',
          'scholarship.application_via_turqapp_prefix':
              'Applications through TurqApp are ',
          'scholarship.application_received_status': 'ACCEPTED.',
          'scholarship.application_not_received_status': 'NOT ACCEPTED.',
          'scholarship.edit_button': 'Edit Scholarship',
          'scholarship.website_open_failed':
              'Website could not be opened. Please enter a valid URL.',
          'scholarship.checking_info': 'Checking information',
          'scholarship.user_data_missing':
              'User data could not be found. Please complete your information.',
          'scholarship.check_info_failed':
              'An error occurred while checking the information.',
          'scholarship.application_check_failed':
              'An error occurred while checking the application status.',
          'scholarship.login_required': 'Please sign in.',
          'scholarship.profile_missing':
              'No profile information is available for this scholarship.',
          'scholarship.applied_success':
              'Your scholarship application has been received.',
          'scholarship.apply_failed': 'Application could not be saved.',
          'scholarship.follow_limit_title': 'Follow Limit',
          'scholarship.follow_limit_body':
              'You cannot follow more people today.',
          'scholarship.follow_failed': 'Follow action failed.',
          'scholarship.invalid': 'Invalid scholarship.',
          'scholarship.delete_success': 'Scholarship deleted successfully.',
          'scholarship.delete_failed':
              'An error occurred while deleting the scholarship.',
          'scholarship.cancel_success':
              'Your scholarship application has been canceled.',
          'scholarship.cancel_failed': 'Application could not be canceled.',
          'scholarship.info_missing_title': 'Missing Information',
          'scholarship.info_missing_body':
              'You cannot apply for scholarships without completing your personal, school and family information.',
          'scholarship.update_my_info': 'Update My Information',
          'scholarship.closed': 'Applications Closed',
          'scholarship.applied': 'Applied',
          'scholarship.cancel_apply_title': 'Cancel Application',
          'scholarship.cancel_apply_body':
              'Are you sure you want to cancel this scholarship application?',
          'scholarship.cancel_apply_button': 'Cancel Application',
          'scholarship.amount_hint': 'Amount',
          'scholarship.student_count_hint': 'e.g. 4',
          'scholarship.amount_student_count_notice':
              'The amount and student count are not shown on the application page.',
          'scholarship.degree_type_label': 'Degree Type',
          'scholarship.degree_type_select': 'Select Degree Type',
          'scholarship.select_country': 'Select Country',
          'scholarship.select_country_first':
              'Please select a country first.',
          'scholarship.select_city_first': 'Please select a city first.',
          'scholarship.select_university': 'Select University',
          'scholarship.selected_universities': 'Selected Universities:',
          'scholarship.logo_label': 'Select Logo',
          'scholarship.logo_pick': 'Select Logo',
          'scholarship.custom_design_optional': 'Your Design (Optional)',
          'scholarship.custom_image_pick': 'Select Image',
          'scholarship.template_select': 'Select Template',
          'scholarship.file_copy_failed': 'The file could not be copied.',
          'scholarship.data_load_failed':
              'Scholarship data could not be loaded.',
          'scholarship.city_data_failed':
              'City and district data could not be loaded.',
          'scholarship.university_data_failed':
              'University data could not be loaded.',
          'scholarship.file_missing': 'The selected file could not be found.',
          'scholarship.image_convert_failed':
              'The image could not be converted to WebP format.',
          'scholarship.image_upload_failed':
              'An error occurred while uploading the image.',
          'scholarship.template_convert_failed':
              'The template image could not be converted to WebP format.',
          'scholarship.template_capture_failed':
              'The template image could not be captured.',
          'scholarship.published_success':
              'Scholarship has been published successfully!',
          'scholarship.publish_failed':
              'An error occurred while publishing the scholarship.',
          'scholarship.updated_success':
              'Scholarship has been updated successfully!',
          'scholarship.update_failed':
              'An error occurred while updating the scholarship.',
          'search_permission.title': 'Search Permission',
          'scholarship.duplicate_status.can_receive': 'Can Receive',
          'scholarship.duplicate_status.cannot_receive_except_kyk':
              'Cannot Receive (Except KYK)',
          'scholarship.target.population': 'By Population',
          'scholarship.target.residence': 'By Residence',
          'scholarship.target.all_turkiye': 'All Turkey',
          'scholarship.info.personal': 'Personal',
          'scholarship.info.school': 'School',
          'scholarship.info.family': 'Family',
          'scholarship.info.dormitory': 'Dormitory',
          'scholarship.education.all': 'All',
          'scholarship.education.middle_school': 'Middle School',
          'scholarship.education.high_school': 'High School',
          'scholarship.education.undergraduate': 'Undergraduate',
          'scholarship.degree.associate': 'Associate Degree',
          'scholarship.degree.bachelor': 'Bachelor',
          'scholarship.degree.master': 'Master',
          'scholarship.degree.phd': 'PhD',
          'single_post.title': 'Posts',
          'edit_post.updating': 'Please wait. Your post is being updated',
          'common.district': 'District',
          'common.price': 'Price',
          'common.views': 'Views',
          'common.company': 'Company',
          'common.salary': 'Salary',
          'common.address': 'Address',
          'common.language': 'Language',
          'profile_photo.camera': 'Take Photo',
          'profile_photo.gallery': 'Choose from Gallery',
          'edit_profile.title': 'Profile Information',
          'edit_profile.personal_info': 'Personal Information',
          'edit_profile.other_info': 'Other Information',
          'edit_profile.first_name_hint': 'First name',
          'edit_profile.last_name_hint': 'Last name',
          'edit_profile.privacy': 'Account Privacy',
          'edit_profile.links': 'Links',
          'edit_profile.contact_info': 'Contact Information',
          'edit_profile.address_info': 'Address Information',
          'edit_profile.career_profile': 'Career Profile',
          'personal_info.select_country_title': 'Select Country',
          'personal_info.select_marital_status_title':
              'Select Marital Status',
          'personal_info.select_gender_title': 'Select Gender',
          'personal_info.select_disability_title':
              'Select Disability Status',
          'personal_info.select_work_status_title':
              'Select Employment Status',
          'edit_profile.update_success': 'Your profile information has been updated!',
          'edit_profile.update_failed': 'Update error: {error}',
          'edit_profile.remove_photo_title': 'Remove Profile Photo',
          'edit_profile.remove_photo_message':
              'Your profile photo will be removed and the default avatar will be used. Are you sure?',
          'edit_profile.photo_removed': 'Your profile photo has been removed.',
          'edit_profile.photo_remove_failed':
              'An error occurred while removing the profile photo.',
          'edit_profile.crop_use': 'Crop and Use',
          'edit_profile.delete_account': 'Delete Account',
          'edit_profile.upload_failed_title': 'Upload Failed!',
          'edit_profile.upload_failed_body':
              'This content cannot be processed right now. Please try different content.',
          'delete_account.title': 'Delete Account',
          'delete_account.confirm_title': 'Account Deletion Confirmation',
          'delete_account.confirm_body':
              'Before deleting your account, we send a verification code to your registered email address for security.',
          'delete_account.code_hint': '6-digit verification code',
          'delete_account.resend': 'Resend',
          'delete_account.send_code': 'Send Code',
          'delete_account.validity_notice':
              'The code is valid for 1 hour. Your deletion request will be processed permanently after {days} days.',
          'delete_account.processing': 'Processing...',
          'delete_account.delete_my_account': 'Delete My Account',
          'delete_account.no_email_title': 'Warning',
          'delete_account.no_email_body':
              'There is no email on this account. You can start the deletion request directly.',
          'delete_account.session_missing':
              'Session not found. Please sign in again.',
          'delete_account.code_sent_title': 'Code Sent',
          'delete_account.code_sent_body':
              'The deletion confirmation code was sent to your email address.',
          'delete_account.send_failed': 'Code could not be sent.',
          'delete_account.invalid_code_title': 'Invalid Code',
          'delete_account.invalid_code_body':
              'Please enter the 6-digit code.',
          'delete_account.verify_failed': 'Code could not be verified.',
          'delete_account.request_received_title': 'Request Received',
          'delete_account.request_received_body':
              'Your account will be permanently deleted after {days} days.',
          'delete_account.request_failed':
              'There was a problem deleting your account. Please try again later.',
          'editor_nickname.title': 'Username',
          'editor_nickname.hint': 'Create Username',
          'editor_nickname.verified_locked':
              'Verified users cannot change their username',
          'editor_nickname.mimic_warning':
              'Usernames that impersonate real people may be changed by TurqApp to protect our community.',
          'editor_nickname.tr_char_info':
              'Turkish characters are converted automatically. (ç→c, ğ→g, ı→i, ö→o, ş→s, ü→u)',
          'editor_nickname.min_length': 'Must be at least 8 characters',
          'editor_nickname.current_name': 'Your current username',
          'editor_nickname.edit_prompt': 'Edit to make a change',
          'editor_nickname.checking': 'Checking…',
          'editor_nickname.taken': 'This username is taken',
          'editor_nickname.available': 'Available',
          'editor_nickname.unavailable': 'Could not be checked',
          'editor_nickname.cooldown_limit':
              'It can only be changed 3 times in the first hour',
          'editor_nickname.change_after_days':
              'Username can be changed again after {days}d {hours}h',
          'editor_nickname.change_after_hours':
              'Username can be changed again after {hours}h',
          'editor_nickname.error_min_length':
              'Username must be at least 8 characters.',
          'editor_nickname.error_taken':
              'This username is already taken.',
          'editor_nickname.error_grace_limit':
              'You can only change it 3 times in the first hour.',
          'editor_nickname.error_cooldown':
              'Username cannot be changed again before 15 days.',
          'editor_nickname.error_update_failed':
              'Username could not be updated.',
          'cv.title': 'Career Profile',
          'cv.personal_info': 'Personal Information',
          'cv.education_info': 'Education Information',
          'cv.other_info': 'Other Information',
          'cv.profile_title': 'Career Profile',
          'cv.profile_body':
              'Make your career profile stronger with a profile photo and basic information.',
          'cv.first_name_hint': 'First name',
          'cv.last_name_hint': 'Last name',
          'cv.email_hint': 'Email Address',
          'cv.phone_hint': 'Phone Number',
          'cv.about_hint': 'Write a short note about yourself',
          'cv.add_school': 'Add new school',
          'cv.add_school_title': 'Add New School',
          'cv.edit_school_title': 'Edit School',
          'cv.school_name': 'School Name',
          'cv.department': 'Department',
          'cv.graduation_year': 'Graduation Year',
          'cv.currently_studying': 'Still Studying',
          'cv.missing_school_name': 'School name cannot be empty',
          'cv.invalid_year': 'Enter a valid year',
          'cv.skills': 'Skills',
          'cv.add_skill_title': 'Add New Skill',
          'cv.skill_name_empty': 'Skill name cannot be empty',
          'cv.skill_exists': 'This skill has already been added',
          'cv.skill_hint': 'Skill (e.g. Flutter, Photoshop)',
          'cv.add_language': 'Add Language',
          'cv.add_new_language': 'Add new language',
          'cv.add_language_title': 'Add New Language',
          'cv.edit_language_title': 'Edit Language',
          'cv.language.english': 'English',
          'cv.language.german': 'German',
          'cv.language.french': 'French',
          'cv.language.spanish': 'Spanish',
          'cv.language.arabic': 'Arabic',
          'cv.language.turkish': 'Turkish',
          'cv.language.russian': 'Russian',
          'cv.language.italian': 'Italian',
          'cv.language.korean': 'Korean',
          'cv.level': 'Level',
          'cv.add_experience': 'Add Work Experience',
          'cv.add_new_experience': 'Add new work experience',
          'cv.add_experience_title': 'Add New Work Experience',
          'cv.edit_experience_title': 'Edit Experience',
          'cv.company_name': 'Company Name',
          'cv.position': 'Position',
          'cv.description_optional': 'Job Description (optional)',
          'cv.start_year': 'Start',
          'cv.end_year': 'End',
          'cv.currently_working': 'I still work here',
          'cv.ongoing': 'Ongoing',
          'cv.missing_company_position':
              'Company name and position are required',
          'cv.invalid_start_year': 'Enter a valid start year',
          'cv.invalid_end_year': 'Enter a valid end year',
          'cv.add_reference': 'Add Reference',
          'cv.add_new_reference': 'Add new reference',
          'cv.add_reference_title': 'Add New Reference',
          'cv.edit_reference_title': 'Edit Reference',
          'cv.name_surname': 'Full Name',
          'cv.phone_example': 'Phone (e.g. 05xx..)',
          'cv.missing_name_surname': 'Full name cannot be empty',
          'cv.save': 'Save',
          'cv.created_title': 'CV Created!',
          'cv.created_body':
              'Now you can apply for jobs much faster',
          'cv.save_failed': 'CV could not be saved. Please try again.',
          'cv.not_signed_in': 'You are not signed in.',
          'cv.photo_inappropriate':
              'Profile photo contains inappropriate content.',
          'cv.photo_upload_failed': 'Profile photo could not be uploaded.',
          'cv.missing_field': 'Missing Field',
          'cv.invalid_format': 'Invalid Format',
          'cv.missing_first_name': 'You cannot save without entering a first name',
          'cv.missing_last_name': 'You cannot save without entering a last name',
          'cv.missing_email': 'You cannot save without entering an email address',
          'cv.invalid_email': 'Please enter a valid email address',
          'cv.missing_phone': 'You cannot save without entering a phone number',
          'cv.invalid_phone': 'Please enter a valid phone number',
          'cv.missing_about':
              'You must provide a short note about yourself',
          'cv.missing_school':
              'You cannot save without entering at least one school',
          'qr.title': 'Personal QR Code',
          'qr.profile_subject': 'TurqApp Profile',
          'qr.profile_desc': 'View TurqApp profile',
          'qr.link_copied_title': 'Link Copied',
          'qr.link_copied_body': 'Profile link copied to clipboard',
          'qr.permission_required': 'Permission Required',
          'qr.gallery_permission_body':
              'You need to allow gallery access to save.',
          'qr.data_failed': 'QR code data could not be created.',
          'qr.saved': 'QR code saved to gallery.',
          'qr.save_failed': 'QR code could not be saved.',
          'qr.download_failed': 'An error occurred during download.',
          'post_creator.title_new': 'Prepare Post',
          'post_creator.title_edit': 'Edit Post',
          'post_creator.text_hint': 'Post text',
          'post_creator.publish': 'Publish',
          'post_creator.uploading': 'Uploading...',
          'post_creator.saving': 'Saving...',
          'post_creator.placeholder': 'What’s happening?',
          'post_creator.processing_wait': 'Please wait. Video is processing...',
          'post_creator.video_processing': 'Video Processing',
          'post_creator.look.original': 'Original',
          'post_creator.look.clear': 'Clean',
          'post_creator.look.cinema': 'Cinematic',
          'post_creator.look.vibe': 'Vivid',
          'post_creator.comments.everyone': 'Everyone',
          'post_creator.comments.verified': 'Verified accounts',
          'post_creator.comments.following': 'Accounts you follow',
          'post_creator.comments.closed': 'Comments off',
          'post_creator.comments.title': 'Who can reply?',
          'post_creator.comments.subtitle':
              'Choose who can reply to this post.',
          'post_creator.reshare.everyone': 'Everyone',
          'post_creator.reshare.verified': 'Verified accounts',
          'post_creator.reshare.following': 'Accounts you follow',
          'post_creator.reshare.closed': 'Reshares off',
          'post_creator.schedule.remove_title': 'Remove Schedule',
          'post_creator.schedule.remove_message':
              'Do you want to remove the scheduled post? It will be published immediately.',
          'post_creator.cover_title': 'Select Cover Photo',
          'post_creator.cover_selected': 'Cover selected',
          'post_creator.use_address': 'Use this address',
          'post_creator.poll_title': 'Poll',
          'post_creator.poll_time_options': 'Time Options',
          'post_creator.poll_option': 'Option {index}',
          'post_creator.poll_add_option': '+ Add one more option',
          'post_creator.poll_min_options': 'At least two options are required.',
          'post_creator.poll_requirement':
              'A poll needs text or image/video content.',
          'post_creator.validation_failed': 'Post validation failed',
          'post_creator.firestore_save_failed': 'Firestore save failed',
          'post_creator.upload_failed_title': 'Upload Failed',
          'post_creator.upload_failed_message':
              'Content safety check could not be completed.',
          'post_creator.image_rejected': 'This image cannot be uploaded.',
          'post_creator.video_rejected': 'This video cannot be uploaded.',
          'post_creator.no_internet': 'No internet connection found',
          'post_creator.draft_save_failed': 'Draft save failed',
          'post_creator.reshare_privacy_title': 'Reshare Privacy',
          'post_creator.reshare_everyone_desc':
              'Everyone can reshare.',
          'post_creator.reshare_followers_desc':
              'Only my followers can reshare.',
          'post_creator.reshare_closed_desc': 'Resharing is disabled.',
          'post_creator.schedule_title': 'Scheduled Publish Date',
          'post_creator.publish_item': 'Post {index}',
          'post_creator.preparing_posts': 'Preparing posts...',
          'post_creator.uploading_media': 'Uploading media files...',
          'post_creator.saving_to_database': 'Saving to the database...',
          'post_creator.video_nsfw_check_failed':
              'NSFW video check failed',
          'post_creator.post_counter_failed':
              'Post counter could not be updated',
          'post_creator.edit_target_missing':
              'The post to edit could not be found',
          'post_creator.edit_content_missing':
              'Edit content could not be found',
          'post_creator.edit_updated': 'Post updated',
          'post_creator.edit_update_failed': 'Post could not be updated',
          'post_creator.upload_failed_generic': 'Post upload failed',
          'post_creator.queue_already_added':
              'This media is already in the upload queue.',
          'post_creator.queue_added_complete':
              'Posts were added to the queue and will upload in the background.',
          'post_creator.queue_title': 'Upload Queue',
          'post_creator.queue_added_body':
              'Posts were added to the background queue',
          'post_creator.queue_add_failed': 'Adding to queue failed',
          'post_creator.photo_with_video_forbidden':
              'You cannot add photos while a video is selected. Only 1 video is allowed.',
          'post_creator.max_photo_count':
              'You can select at most {count} photos.',
          'post_creator.max_photo_add':
              'You can add at most {count} photos. Current: {current}, Trying to add: {adding}',
          'post_creator.photo_validation_prefix': 'Photo {index}: {error}',
          'post_creator.photos_compression_failed':
              'Photos were added, but compression failed.',
          'post_creator.warning_title': 'Warning',
          'post_creator.success_title': 'Success!',
          'post_creator.photo_added': 'Photo added. {saved}',
          'post_creator.photo_added_no_compress':
              'Photo added, but compression failed.',
          'post_creator.max_video_count':
              'You can select at most {count} videos.',
          'post_creator.no_post_uploaded': 'No post could be uploaded',
          'post_creator.image_upload_failed':
              'Image {index} could not be uploaded',
          'post_creator.video_reduce_failed':
              'The video could not be reduced below 35MB. Under 35MB uploads directly; over 60MB is not supported.',
          'post_creator.video_upload_failed': 'Video could not be uploaded',
          'post_creator.post_upload_failed':
              'Post {index} could not be uploaded',
          'post_creator.upload_success': 'Posts were published successfully!',
          'post_creator.upload_error': 'An error occurred while uploading.',
          'post_creator.upload_process_failed': 'Upload failed',
          'post_creator.critical_error': 'A critical error occurred.',
          'permissions.title': 'Device Permissions',
          'permissions.preferences': 'Your preferences',
          'permissions.offline_space': 'Offline Viewing Space',
          'permissions.offline_space_desc':
              'Content up to your selected GB amount is downloaded to your device and can be watched without an internet connection. Older videos are removed automatically as space fills up.',
          'permissions.allowed': 'Allowed',
          'permissions.denied': 'Not allowed',
          'permissions.enable': 'Enable permissions',
          'permissions.enable_location': 'Enable Location Services',
          'permissions.checking': 'Checking...',
          'permissions.dialog.update_device_settings':
              'Update device settings',
          'permissions.dialog.update_body':
              'Open device settings. You can update the "{title}" permission whenever you want.',
          'permissions.dialog.open_settings': 'Open device settings',
          'permissions.dialog.not_now': 'Not now',
          'permissions.quota.media_cache': 'Media cache',
          'permissions.quota.image_cache': 'Image cache',
          'permissions.quota.metadata': 'Metadata',
          'permissions.quota.reserve': 'Reserve space',
          'permissions.quota.os_safety': 'OS safety margin',
          'permissions.quota.plan_distribution': '{gb} GB plan distribution',
          'permissions.quota.soft_stop': 'Stream cache soft stop',
          'permissions.quota.hard_stop': 'Stream cache hard stop',
          'permissions.quota.recent_window':
              'Recent video protection window: {count} items',
          'permissions.quota.active_stream': 'Active stream usage',
          'permissions.quota.soft_remaining': 'Soft stop remaining',
          'permissions.quota.hard_remaining': 'Hard stop remaining',
          'permissions.playback.title': 'Data and Playback Preferences',
          'permissions.playback.help':
              'The system follows the cache plan; here you only choose how conservative Wi-Fi and mobile data behavior should be.',
          'permissions.playback.limit_cellular':
              'Limit with cache on mobile data',
          'permissions.playback.limit_cellular_desc':
              'If enabled, cached segments are used before fetching new ones on mobile data.',
          'permissions.playback.cellular_mode': 'Mobile data playback mode',
          'permissions.playback.cellular_mode_desc':
              'Determines how aggressive prefetch and quality can be under the cellular guard.',
          'permissions.playback.wifi_mode': 'Wi-Fi playback mode',
          'permissions.playback.wifi_mode_desc':
              'Determines how wide startup and ahead-window behavior can be on full Wi-Fi.',
          'permissions.detail.set_preferences': 'Set your preferences',
          'permissions.detail.preference_body':
              'You can decide whether TurqApp is allowed to access your {access}. You can change this choice whenever you want. {title} improves some app features.',
          'permissions.detail.device_setting': 'Your device setting:',
          'permissions.detail.other_option': 'Other option',
          'permissions.detail.allowed_desc':
              'TurqApp is allowed to access your {access}.',
          'permissions.detail.denied_desc':
              'TurqApp is not allowed to access your {access}.',
          'permissions.detail.go_device_settings':
              'Go to device settings to update your permissions.',
          'permissions.item.camera.title': 'Camera',
          'permissions.item.camera.access': 'camera',
          'permissions.item.camera.help_text':
              'How do we use your device camera?',
          'permissions.item.camera.help_sheet_title':
              'How do we use your device camera?',
          'permissions.item.camera.help_sheet_body':
              'TurqApp uses camera access so you can take photos, record videos and preview visual/audio effects.',
          'permissions.item.camera.help_sheet_body2':
              'You can learn more about how we use your camera in the Privacy Center.',
          'permissions.item.camera.help_sheet_link': 'Privacy Center',
          'permissions.item.contacts.title': 'Contacts',
          'permissions.item.contacts.access': 'contacts',
          'permissions.item.contacts.help_text':
              'How do we use your device contacts?',
          'permissions.item.contacts.help_sheet_title':
              'How do we use your device contacts?',
          'permissions.item.contacts.help_sheet_body':
              'TurqApp uses this information to help you connect with people you know more easily and to improve contact suggestions.',
          'permissions.item.contacts.help_sheet_link': 'Learn more',
          'permissions.item.location.title': 'Location Services',
          'permissions.item.location.access': 'location',
          'permissions.item.location.help_text':
              'How do we use your device location?',
          'permissions.item.location.help_sheet_title':
              'How do we use your device location?',
          'permissions.item.location.help_sheet_body':
              'TurqApp uses location information to help you discover nearby places, tag locations in posts/stories and improve safety features.',
          'permissions.item.location.help_sheet_body2':
              'You can learn more about how we use location data in the Privacy Center.',
          'permissions.item.location.help_sheet_link': 'Privacy Center',
          'permissions.item.microphone.title': 'Microphone',
          'permissions.item.microphone.access': 'microphone',
          'permissions.item.microphone.help_text':
              'How do we use your device microphone?',
          'permissions.item.microphone.help_sheet_title':
              'How do we use your device microphone?',
          'permissions.item.microphone.help_sheet_body':
              'TurqApp uses microphone access for features like recording audio in videos and previewing effects.',
          'permissions.item.microphone.help_sheet_body2':
              'You can learn more about how we use your microphone in the Privacy Center.',
          'permissions.item.microphone.help_sheet_link': 'Privacy Center',
          'permissions.item.notifications.title': 'Notifications',
          'permissions.item.notifications.access':
              'send instant notifications',
          'permissions.item.notifications.help_text':
              'How do we use your device notifications?',
          'permissions.item.notifications.help_sheet_title':
              'How do we use your device notifications?',
          'permissions.item.notifications.help_sheet_body':
              'TurqApp uses notification permission to send instant notifications when there is new activity on your account.',
          'permissions.item.notifications.help_sheet_body2':
              'You can learn more about how we use notifications in the Transparency Center.',
          'permissions.item.notifications.help_sheet_link':
              'Transparency Center',
          'permissions.item.photos.title': 'Photos',
          'permissions.item.photos.access': 'photos and videos',
          'permissions.item.photos.help_text':
              'How do we use your device photos?',
          'permissions.item.photos.help_sheet_title':
              'How do we use your device photos?',
          'permissions.item.photos.help_sheet_body':
              'TurqApp uses photo access so you can select and share photos/videos from your gallery and use editing tools.',
        },
        'de_DE': {
          'settings.title': 'Einstellungen',
          'settings.account': 'Konto',
          'settings.content': 'Inhalt',
          'settings.app': 'App',
          'settings.security_support': 'Sicherheit und Support',
          'settings.my_tasks': 'Meine Aufgaben',
          'settings.system_diagnostics': 'System und Diagnose',
          'settings.session': 'Sitzung',
          'settings.language': 'Sprache',
          'settings.edit_profile': 'Profil bearbeiten',
          'settings.badge_application': 'Mein Badge-Antrag',
          'settings.badge_renew': 'Badge erneuern',
          'settings.become_verified': 'Verifiziert werden',
          'become_verified.intro':
              'Verifizierungsabzeichen werden in unserer mobilen App verwendet, um verschiedene Nutzergruppen zu kennzeichnen und ihre Vertrauenswürdigkeit hervorzuheben.',
          'become_verified.annual_renewal':
              'Muss jedes Jahr erneuert werden.',
          'become_verified.footer':
              'Unsere Abzeichen sollen unserer Community helfen, in einer sicheren und transparenten Umgebung zu interagieren.\n\nFür weitere Informationen zur Profilverifizierung können Sie das TurqApp-Supportteam kontaktieren.',
          'become_verified.feature_ads': 'Werbung',
          'become_verified.feature_limited_ads': 'Begrenzte Werbung',
          'become_verified.feature_post_boost': 'Beitrag hervorheben',
          'become_verified.feature_highest': 'Höchste',
          'become_verified.feature_video_download': 'Video-Download',
          'become_verified.feature_long_video':
              'Veröffentlichung langer Videos',
          'become_verified.feature_statistics': 'Statistiken',
          'become_verified.feature_username': 'Benutzername',
          'become_verified.feature_verification_mark':
              'Verifizierungszeichen',
          'become_verified.feature_account_protection':
              'Erweiterter Kontoschutz',
          'become_verified.feature_channel_creation': 'Kanal erstellen',
          'become_verified.feature_priority_support': 'Erweiterter Support',
          'become_verified.feature_scheduled_video': 'Geplantes Video',
          'become_verified.feature_unlimited_listings':
              'Unbegrenzte Inserate',
          'become_verified.feature_unlimited_links':
              'Unbegrenzte Links',
          'become_verified.feature_assistant': 'Assistent werden',
          'become_verified.feature_scheduled_content':
              'Geplante Inhaltsfreigabe',
          'become_verified.feature_character_limit': 'Zeichenlimit',
          'become_verified.feature_character_limit_value': '1000 Zeichen',
          'become_verified.loss_title': 'Verlust des Verifizierungsabzeichens',
          'become_verified.loss_body':
              'Wenn unser Team Ihr Konto überprüft und entscheidet, dass es weiterhin unsere Anforderungen erfüllt, kann das Verifizierungszeichen erneut angezeigt werden. TurqApp kann das Abzeichen auch von Konten entfernen, die gegen die TurqApp-Regeln verstoßen.',
          'become_verified.step_social_accounts':
              '1. Ihre Social-Media-Konten',
          'become_verified.step_requested_username':
              '2. Gewünschter Benutzername',
          'become_verified.requested_username_hint':
              'Gewünschter Benutzername',
          'become_verified.step_social_confirmation':
              '3. Social-Media-Bestätigung',
          'become_verified.social_confirmation_body':
              'Sie können Ihren gewünschten Benutzernamen zusammen mit Ihrem aktuellen TurqApp-Benutzernamen über eines der unten aufgeführten Konten von einem Ihnen gehörenden Social-Media-Konto senden.',
          'become_verified.consent':
              'Ich bestätige, dass die eingegebenen Informationen mir gehören und dass ich dem Prüfungsprozess des Antrags zustimme.',
          'become_verified.step_barcode':
              '5. Barcode-Nr. der E-Government-Studienbescheinigung',
          'become_verified.barcode_hint': '20-stellige Barcode-Nummer',
          'become_verified.submit': 'Bewerben',
          'become_verified.received_title': 'Antrag erhalten',
          'become_verified.received_body':
              'Ihr Antrag wurde in die Warteschlange aufgenommen. Wir benachrichtigen Sie, sobald die Prüfung positiv abgeschlossen wurde.',
          'become_verified.received_note':
              'Die Bearbeitungszeit kann je nach Auslastung variieren. Sie werden nach Abschluss über die App informiert.',
          'become_verified.session_missing': 'Sitzung nicht gefunden.',
          'become_verified.already_received':
              'Ihr Antrag wurde bereits erhalten.',
          'become_verified.submit_failed':
              'Der Antrag konnte nicht gespeichert werden.',
          'become_verified.badge_blue': 'Blau',
          'become_verified.badge_red': 'Rot',
          'become_verified.badge_yellow': 'Gelb',
          'become_verified.badge_turquoise': 'Türkis',
          'become_verified.badge_gray': 'Grau',
          'become_verified.badge_black': 'Schwarz',
          'become_verified.badge_blue_desc':
              'Für individuelle Nutzer konzipiert.\nEs zeigt an, dass das Profil verifiziert und vertrauenswürdig ist.',
          'become_verified.badge_red_desc':
              'Für Schüler und Lehrer konzipiert.\nEs steht für eine im Bildungsbereich verifizierte Identität.',
          'become_verified.badge_yellow_desc':
              'Wird an Unternehmen und kommerzielle Organisationen vergeben.\nEs zeigt an, dass die Institution ein offizielles Unternehmen ist.',
          'become_verified.badge_turquoise_desc':
              'Wird an Nichtregierungsorganisationen vergeben.\nEs zeigt an, dass die Organisationen offiziell und vertrauenswürdig sind.',
          'become_verified.badge_gray_desc':
              'Speziell für öffentliche Einrichtungen, staatliche Stellen und Beamte definiert.\nEs symbolisiert offiziellen Status und Zuverlässigkeit.',
          'become_verified.badge_black_desc':
              'Für unsere Content-Moderatoren konzipiert.\nEs steht für eine Identität, die Nutzer sperrt und Inhalte entfernt.',
          'settings.blocked_users': 'Blockierte Nutzer',
          'settings.interests': 'Interessen',
          'settings.account_center': 'Kontozentrum',
          'settings.career_profile': 'Karriereprofil',
          'settings.saved_posts': 'Gespeicherte Beiträge',
          'settings.archive': 'Archiv',
          'settings.liked_posts': 'Gefällt mir',
          'settings.notifications': 'Benachrichtigungen',
          'settings.permissions': 'Berechtigungen',
          'settings.pasaj': 'Pasaj',
          'settings.pasaj.practice_exam': 'Probeprüfung',
          'education.previous_questions': 'Probetests',
          'tests.results_title': 'Ergebnisse',
          'tests.results_empty':
              'Keine Ergebnisse gefunden.\nFür diesen Test liegen keine Antwort- oder Fragendaten vor.',
          'tests.correct': 'Richtig',
          'tests.wrong': 'Falsch',
          'tests.blank': 'Leer',
          'tests.net': 'Netto',
          'tests.score': 'Punktzahl',
          'tests.question_number': 'Frage @index',
          'tests.solve_no_questions':
              'Frage nicht gefunden.\nFür diesen Test konnten keine Fragen geladen werden.',
          'tests.finish_test': 'Test beenden',
          'tests.my_results_empty':
              'Keine Ergebnisse gefunden.\nDu hast bisher noch keinen Test gelöst.',
          'tests.saved_empty': 'Es sind keine gespeicherten Tests vorhanden.',
          'tests.result_answer_missing':
              'Keine Ergebnisse gefunden.\nFür diesen Test liegen keine Antwortdaten vor.',
          'tests.type_test': '@type-Test',
          'tests.description_test': '@description-Test',
          'tests.solve_count': 'Du hast ihn @count Mal gelöst',
          'tests.create_title': 'Test erstellen',
          'tests.edit_title': 'Test bearbeiten',
          'tests.create_data_missing':
              'Keine Daten gefunden.\nApp-Links oder Testfragen konnten nicht geladen werden.',
          'tests.create_upload_failed':
              'Dieser Inhalt kann derzeit nicht verarbeitet werden. Bitte versuche einen anderen.',
          'tests.select_branch': 'Bereich wählen',
          'tests.select_language': 'Sprache wählen',
          'tests.cover_select': 'Titelbild auswählen',
          'tests.name_hint': 'Prüfungsname',
          'tests.post_exam_status': 'Nach der Prüfung @status',
          'tests.types': 'Prüfungstypen',
          'tests.date_duration': 'Prüfungsdatum und Dauer',
          'tests.duration_select': 'Prüfungsdauer wählen',
          'tests.create_description_hint':
              '9. Klasse Exponentialausdrücke und Wurzelausdrücke',
          'tests.share_status': 'Für alle: @status',
          'tests.status.open': 'Offen',
          'tests.status.closed': 'Geschlossen',
          'tests.share_public_info':
              'Gemäß der digitalen Ethik sollten urheberrechtlich geschützte Tests nicht geteilt werden.\nBitte verwende und veröffentliche Tests, die jeder lösen kann und die keine urheberrechtlich geschützten Inhalte enthalten.',
          'tests.share_private_info':
              'Dieser Test kann nur mit deinen eigenen Schülern geteilt werden. Nur Schüler, die die von dir angegebene ID eingeben, können auf den veröffentlichten Test zugreifen und ihn lösen.',
          'tests.test_id': 'Test-ID: @id',
          'tests.test_type': 'Testtyp',
          'tests.subjects': 'Fächer',
          'tests.exam_prep': 'Prüfungsvorbereitung',
          'tests.foreign_language': 'Fremdsprache',
          'tests.delete_test': 'Test löschen',
          'tests.prepare_test': 'Test vorbereiten',
          'tests.join_title': 'Am Test teilnehmen',
          'tests.search_title': 'Test suchen',
          'tests.search_id_hint': 'Test-ID suchen',
          'tests.join_help':
              'Du kannst den Test starten, indem du die Test-ID eingibst, die dir dein Lehrer mitgeteilt hat.',
          'tests.join_not_found':
              'Test nicht gefunden.\nEs wurde kein Test mit der eingegebenen Test-ID gefunden.',
          'tests.join_button': 'Test beitreten',
          'tests.no_shared': 'Keine geteilten Tests vorhanden.',
          'tests.my_tests_title': 'Meine Tests',
          'tests.my_tests_empty':
              'Keine Ergebnisse gefunden.\nDu hast bisher noch keine Tests erstellt.',
          'tests.completed_title': 'Du hast den Test beendet!',
          'tests.completed_body':
              'Du kannst deine Punktzahl und dein Verhältnis von richtigen und falschen Antworten unter „Meine Ergebnisse“ ansehen.',
          'tests.completed_short': 'Du hast den Test abgeschlossen!',
          'tests.action_select': 'Aktion wählen',
          'tests.action_select_body':
              'Wenn du eine Aktion für diesen Test ausführen möchtest, wähle unten eine der Optionen aus.',
          'tests.copy_test_id': 'Test-ID kopieren',
          'tests.solve_title': 'Test lösen',
          'tests.delete_confirm':
              'Möchtest du diesen Test wirklich löschen?',
          'tests.id_copied':
              'Test-ID wurde in die Zwischenablage kopiert',
          'tests.share_test_id_text':
              '@type-Test\n\nLade TurqApp jetzt herunter, um am Test teilzunehmen. Deine benötigte Test-ID ist @id\n\nApp jetzt herunterladen:\n\nAppStore: @appStore\nPlay Store: @playStore\n\nUm am Test teilzunehmen, gib die Test-ID auf dem Testbildschirm im Schülerbereich ein und beginne sofort mit dem Lösen.',
          'tests.type.middle_school': 'Mittelschule',
          'tests.type.high_school': 'Gymnasium',
          'tests.type.prep': 'Vorbereitung',
          'tests.type.language': 'Sprache',
          'tests.type.branch': 'Bereich',
          'tests.lesson.turkish': 'Türkisch',
          'tests.lesson.literature': 'Literatur',
          'tests.lesson.math': 'Mathematik',
          'tests.lesson.geometry': 'Geometrie',
          'tests.lesson.physics': 'Physik',
          'tests.lesson.chemistry': 'Chemie',
          'tests.lesson.biology': 'Biologie',
          'tests.lesson.history': 'Geschichte',
          'tests.lesson.geography': 'Geografie',
          'tests.lesson.philosophy': 'Philosophie',
          'tests.lesson.psychology': 'Psychologie',
          'tests.lesson.sociology': 'Soziologie',
          'tests.lesson.logic': 'Logik',
          'tests.lesson.religion': 'Religionskunde',
          'tests.lesson.science': 'Naturwissenschaften',
          'tests.lesson.revolution_history': 'Revolutionsgeschichte',
          'tests.lesson.foreign_language': 'Fremdsprache',
          'tests.lesson.basic_math': 'Grundlagen Mathematik',
          'tests.lesson.social_sciences': 'Sozialwissenschaften',
          'tests.lesson.literature_social_1':
              'Literatur - Sozialwissenschaften 1',
          'tests.lesson.social_sciences_2': 'Sozialwissenschaften 2',
          'tests.lesson.general_ability': 'Allgemeine Fähigkeiten',
          'tests.lesson.general_culture': 'Allgemeinbildung',
          'tests.language.english': 'Englisch',
          'tests.language.german': 'Deutsch',
          'tests.language.arabic': 'Arabisch',
          'tests.language.french': 'Französisch',
          'tests.language.russian': 'Russisch',
          'tests.lesson_based_title': '@type-Tests',
          'tests.none_in_category': 'Keine Tests vorhanden',
          'tests.add_question': 'Frage hinzufügen',
          'tests.no_questions_added':
              'Keine Fragen gefunden.\nFür diesen Test wurden noch keine Fragen hinzugefügt.',
          'tests.level_easy': 'Einfach',
          'tests.title': 'Tests',
          'tests.report_title': 'Über den Test',
          'tests.report_wrong_answers':
              'Der Test enthält falsche Antworten',
          'tests.report_wrong_section':
              'Der Test befindet sich im falschen Bereich',
          'tests.question_content_failed':
              'Der Frageninhalt konnte nicht geladen werden.\nBitte versuche es erneut.',
          'tests.capture_and_upload': 'Aufnehmen und hochladen',
          'tests.capture_and_upload_body':
              'Mache ein Foto der Frage, wähle die richtige Antwort und bereite sie ganz einfach vor!',
          'tests.select_from_gallery': 'Aus Galerie wählen',
          'tests.upload_from_camera': 'Von Kamera hochladen',
          'tests.nsfw_check_failed':
              'Die Bildsicherheitsprüfung konnte nicht abgeschlossen werden.',
          'tests.nsfw_detected': 'Unangemessenes Bild erkannt.',
          'practice.title': 'Online-Prüfung',
          'practice.search_title': 'Probeprüfung suchen',
          'practice.empty_title': 'Noch keine Probeprüfungen vorhanden',
          'practice.empty_body':
              'Derzeit sind keine Probeprüfungen im System vorhanden. Neue Prüfungen erscheinen hier, sobald sie hinzugefügt werden.',
          'practice.search_empty_title':
              'Keine Prüfung passt zu deiner Suche',
          'practice.search_empty_body_empty':
              'Derzeit sind keine Probeprüfungen im System vorhanden. Neue Prüfungen erscheinen hier, sobald sie hinzugefügt werden.',
          'practice.search_empty_body_query':
              'Versuche ein anderes Stichwort.',
          'practice.results_title': 'Meine Prüfungsergebnisse',
          'practice.saved_empty': 'Keine gespeicherten Probeprüfungen.',
          'practice.preview_no_questions':
              'Für diese Prüfung wurden keine Fragen gefunden. Bitte prüfe den Prüfungsinhalt oder füge neue Fragen hinzu.',
          'practice.preview_no_results':
              'Für diese Prüfung wurden keine Ergebnisse gefunden. Bitte prüfe deine Antworten oder löse die Prüfung erneut.',
          'practice.lesson_header': 'Fächer',
          'practice.answers_load_failed':
              'Antworten konnten nicht geladen werden.',
          'practice.lesson_results_load_failed':
              'Fachergebnisse konnten nicht geladen werden.',
          'practice.results_empty_title':
              'Du hast noch keine Prüfung abgelegt',
          'practice.results_empty_body':
              'Du hast noch an keiner Probeprüfung teilgenommen. Deine Ergebnisse erscheinen hier nach deiner Teilnahme.',
          'practice.published_empty':
              'Du hast noch keine Online-Prüfung veröffentlicht.',
          'practice.user_session_missing': 'Benutzersitzung nicht gefunden.',
          'practice.school_info_failed':
              'Schulinformationen konnten nicht geladen werden.',
          'practice.load_failed': 'Daten konnten nicht geladen werden.',
          'practice.slider_management': 'Slider-Verwaltung',
          'practice.create_disabled_title':
              'Nur für gelbes Abzeichen und höher',
          'practice.create_disabled_body':
              'Um eine Online-Prüfung zu erstellen, benötigst du ein verifiziertes Konto mit gelbem Abzeichen oder höher.',
          'practice.preview_title': 'Prüfungsdetails',
          'practice.report_exam': 'Prüfung melden',
          'practice.user_load_failed':
              'Benutzerinformationen konnten nicht geladen werden.',
          'practice.user_load_failed_body':
              'Benutzerinformationen konnten nicht geladen werden. Bitte versuche es erneut oder prüfe den Eigentümer der Prüfung.',
          'practice.invalidity_load_failed':
              'Ungültigkeitsstatus konnte nicht geladen werden.',
          'practice.cover_load_failed':
              'Titelbild konnte nicht geladen werden.',
          'practice.no_description':
              'Für diese Prüfung wurde keine Beschreibung hinzugefügt.',
          'practice.exam_info': 'Prüfungsinformationen',
          'practice.exam_type': 'Prüfungsart',
          'practice.exam_suffix': '@type-Prüfung',
          'practice.exam_datetime': 'Prüfungsdatum und Uhrzeit',
          'practice.exam_duration': 'Prüfungsdauer',
          'practice.duration_minutes': '@minutes Min',
          'practice.application_count': 'Bewerbungen',
          'practice.people_count': '@count Personen',
          'practice.owner': 'Prüfungsinhaber',
          'practice.apply_now': 'Jetzt bewerben',
          'practice.applied_short': 'Beworben',
          'practice.closed_starts_in':
              'Bewerbungen geschlossen.\nBeginnt in @minutes Min.',
          'practice.started': 'Prüfung gestartet',
          'practice.start_now': 'Jetzt starten',
          'practice.finished_short': 'Prüfung beendet',
          'practice.not_started': 'Prüfung nicht gestartet',
          'practice.application_closed_title':
              'Bewerbung geschlossen!',
          'practice.application_closed_body':
              'Bewerbungen schließen 15 Minuten vor Prüfungsbeginn.',
          'practice.not_applied_title': 'Du hast dich nicht beworben!',
          'practice.not_applied_body':
              'Du kannst nur an Prüfungen teilnehmen, für die du dich beworben hast.',
          'practice.not_allowed_title':
              'Du kannst die Prüfung nicht betreten!',
          'practice.not_allowed_body':
              'Du hast keinen Zugriff auf diese Prüfung. Du wurdest in dieser Prüfung zuvor als ungültig markiert und kannst vor dem Ende nicht erneut teilnehmen.',
          'practice.finished_title': 'Prüfung beendet!',
          'practice.finished_body':
              'Du kannst dich für die nächsten Prüfungen bewerben. Diese Prüfung ist beendet.',
          'practice.result_unavailable':
              'Das Ergebnis konnte nicht berechnet werden.',
          'practice.result_summary':
              'Richtig: @correct   •   Falsch: @wrong   •   Leer: @blank   •   Netto: @net',
          'practice.congrats_title': 'Glückwunsch!',
          'practice.removed_title':
              'Du wurdest aus der Prüfung entfernt!',
          'practice.removed_body':
              'Wir haben dich mehrfach gewarnt. Leider wurdest du wegen Verstoßes gegen die Prüfungsregeln entfernt und deine Prüfung wurde als ungültig markiert.',
          'practice.applied_title':
              'Deine Bewerbung wurde erhalten!',
          'practice.applied_body':
              'Deine Bewerbung wurde erfolgreich erhalten. Derzeit ist nichts weiter erforderlich.',
          'practice.apply_completed_title':
              'Deine Bewerbung ist abgeschlossen!',
          'practice.apply_completed_body':
              'Wir senden dir vor der Prüfung Erinnerungen. Viel Erfolg!',
          'practice.apply_failed': 'Bewerbung fehlgeschlagen.',
          'practice.application_check_failed':
              'Bewerbungsprüfung fehlgeschlagen.',
          'practice.question_image_failed':
              'Fragenbild konnte nicht geladen werden.',
          'practice.exam_started_title': 'Die Prüfung hat begonnen!',
          'practice.exam_started_body':
              'Wir glauben, dass deine Sorgfalt und Mühe in dieser Prüfung den Weg zum Erfolg ebnen werden. Viel Glück!',
          'practice.rules_title': 'Prüfungsregeln',
          'practice.rule_1':
              'Bitte schalte die Internetverbindung deines Telefons aus. Nach Abschluss der Prüfung kannst du sie wieder einschalten, um deine Antworten zu senden.',
          'practice.rule_2':
              'Wenn du die Prüfung verlässt, gelten alle Antworten als ungültig und dein Ergebnis wird nicht gespeichert. Bitte überlege sorgfältig, bevor du dies bestätigst.',
          'practice.rule_3':
              'Wenn du die App in den Hintergrund schickst, wird deine Prüfung als ungültig gewertet. Bitte achte darauf, die App nicht in den Hintergrund zu legen.',
          'practice.start_exam': 'Prüfung starten',
          'practice.finish_exam': 'Prüfung beenden',
          'practice.background_warning':
              'In kritischen Situationen wie dem Wechsel der App in den Hintergrund wird deine Prüfung als ungültig gewertet. Bitte sei vorsichtig und halte dich an die Regeln.',
          'practice.questions_load_failed':
              'Fragen konnten nicht geladen werden.',
          'practice.answers_save_failed':
              'Antworten konnten nicht gespeichert werden.',
          'past_questions.no_results': 'Es gibt keine Ergebnisse.',
          'past_questions.title': 'Probeprüfungen',
          'past_questions.mock_fallback': 'Probe',
          'past_questions.search_empty':
              'Keine Probeprüfung passt zu deiner Suche.',
          'past_questions.results_suffix': '@title Ergebnisse',
          'past_questions.local_result_summary':
              '@count Fragen wurden gelöst. Das Ergebnis wird lokal gespeichert; auf diesem Bildschirm wird nur die Nettoübersicht angezeigt.',
          'past_questions.mock_label': 'Probe @index',
          'past_questions.question_count': '@count Fragen',
          'past_questions.net_label': 'Netto',
          'past_questions.tests_by_year': '@type @year Tests',
          'past_questions.languages_title': '@type Sprachen',
          'past_questions.tests_by_type': '@type Tests',
          'past_questions.select_exam': 'Prüfung auswählen',
          'past_questions.questions_title': 'Fragen',
          'past_questions.continue_solving': 'Fragen weiter lösen',
          'past_questions.oabt_short': 'ÖABT',
          'past_questions.exam_type.associate': 'Associate Degree',
          'past_questions.exam_type.undergraduate': 'Bachelor',
          'past_questions.exam_type.middle_school': 'Sekundarstufe',
          'past_questions.branch.general_ability_culture':
              'Allgemeinwissen und Fähigkeiten',
          'past_questions.branch.group_a': 'Gruppe A',
          'past_questions.branch.education_sciences': 'Erziehungswissenschaften',
          'past_questions.branch.field_knowledge': 'Fachwissen',
          'past_questions.sessions_by_year': 'Sitzungen @year',
          'past_questions.teaching.title': 'Lehrämter',
          'past_questions.teaching.suffix': 'Lehramt',
          'past_questions.teaching.primary_math_short': 'P. Mathe',
          'past_questions.teaching.high_school_math_short': 'L. Mathe',
          'past_questions.teaching.german': 'Deutsch Lehramt',
          'past_questions.teaching.physical_education':
              'Sport Lehramt',
          'past_questions.teaching.biology': 'Biologie Lehramt',
          'past_questions.teaching.geography': 'Geografie Lehramt',
          'past_questions.teaching.religious_culture':
              'Religionskultur Lehramt',
          'past_questions.teaching.literature': 'Literatur Lehramt',
          'past_questions.teaching.science': 'Naturwissenschaften Lehramt',
          'past_questions.teaching.physics': 'Physik Lehramt',
          'past_questions.teaching.chemistry': 'Chemie Lehramt',
          'past_questions.teaching.high_school_math': 'Gymnasialmathematik',
          'past_questions.teaching.preschool': 'Vorschule',
          'past_questions.teaching.guidance': 'Beratung',
          'past_questions.teaching.social_studies': 'Sozialkunde Lehramt',
          'past_questions.teaching.classroom': 'Grundschullehramt',
          'past_questions.teaching.history': 'Geschichte Lehramt',
          'past_questions.teaching.turkish': 'Türkisch Lehramt',
          'past_questions.teaching.primary_math': 'Primarstufenmathematik',
          'past_questions.teaching.imam_hatip': 'Imam Hatip',
          'past_questions.teaching.english': 'Englisch Lehramt',
          'settings.about': 'Über',
          'settings.policies': 'Richtlinien',
          'settings.contact_us': 'Schreib uns',
          'settings.my_approval_results': 'Meine Freigabeergebnisse',
          'settings.admin_ads': 'Verwaltung / Anzeigenzentrum',
          'ads_center.title': 'Anzeigenzentrum',
          'ads_center.tab_dashboard': 'Dashboard',
          'ads_center.tab_campaigns': 'Kampagnen',
          'ads_center.tab_editor': 'Editor',
          'ads_center.tab_creatives': 'Kreative',
          'ads_center.tab_monitor': 'Monitor',
          'ads_center.tab_preview': 'Vorschau',
          'ads_center.admin_only': 'Dieser Bereich ist nur für Admins zugänglich.',
          'ads_center.summary': 'Übersicht',
          'ads_center.total_campaigns': 'Gesamte Kampagnen',
          'ads_center.active': 'Aktiv',
          'ads_center.paused': 'Pausiert',
          'ads_center.feature_flags': 'Feature Flags',
          'ads_center.status': 'Status',
          'ads_center.placement': 'Platzierung',
          'ads_center.include_test_campaigns': 'Testkampagnen einschließen',
          'ads_center.new_campaign': 'Neue Kampagne',
          'ads_center.no_campaigns': 'Keine Kampagne gefunden.',
          'ads_center.untitled_campaign': '(unbenannte Kampagne)',
          'ads_center.budget': 'Budget',
          'ads_center.activate': 'Aktivieren',
          'ads_center.pause': 'Pausieren',
          'ads_center.no_delivery_logs': 'Keine Delivery-Logs gefunden.',
          'ads_center.decision_detail': 'Entscheidungsdetail',
          'ads_center.no_creatives': 'Keine Kreativen gefunden.',
          'ads_center.untitled_creative': '(unbenannte Kreative)',
          'ads_center.reject_note': 'Ablehnungsnotiz',
          'ads_center.approve_note': 'Freigabenotiz',
          'ads_center.review_note_hint': 'Prüfnotiz',
          'ads_center.delivery_simulation': 'Delivery-Simulation',
          'ads_center.user_id': 'Benutzer-ID',
          'ads_center.country': 'Land',
          'ads_center.city': 'Stadt',
          'ads_center.age': 'Alter',
          'ads_center.run_simulation': 'Simulation starten',
          'ads_center.eligible_ad_found': 'Passende Anzeige gefunden',
          'ads_center.no_eligible_ad': 'Keine passende Anzeige gefunden',
          'ads_center.reasons': 'Gründe',
          'ads_center.create_campaign': 'Kampagne erstellen',
          'ads_center.update_campaign': 'Kampagne aktualisieren',
          'ads_center.save_creative': 'Kreativ speichern',
          'ads_center.campaign_saved_title': 'Kampagne gespeichert',
          'ads_center.campaign_saved_body': 'Kampagnen-ID: {id}',
          'ads_center.save_campaign_first':
              'Bitte speichere zuerst die Kampagne.',
          'ads_center.creative_saved_title': 'Kreativ gespeichert',
          'ads_center.creative_saved_body':
              'Die Werbekreative wurde erfolgreich gespeichert.',
          'ads_center.permission_denied':
              'Zugriff auf Ads-Center-Daten wurde verweigert (permission-denied).',
          'settings.admin_moderation': 'Verwaltung / Moderation',
          'settings.admin_reports': 'Verwaltung / Reports',
          'settings.admin_badges': 'Verwaltung / Badge-Verwaltung',
          'settings.admin_tasks': 'Verwaltung / Admin-Aufgaben',
          'settings.admin_approvals': 'Verwaltung / Admin-Freigaben',
          'settings.admin_push': 'Verwaltung / Push senden',
          'settings.admin_story_music': 'Verwaltung / Story-Musik',
          'settings.admin_support': 'Verwaltung / Nutzersupport',
          'settings.system_diag_menu': 'System- und Diagnosemenü',
          'settings.diagnostics.data_usage': 'Datenverbrauch',
          'settings.diagnostics.network': 'Netzwerk',
          'settings.diagnostics.connected': 'Verbunden',
          'settings.diagnostics.monthly_total': 'Monatlich gesamt',
          'settings.diagnostics.monthly_limit': 'Monatliches Limit',
          'settings.diagnostics.remaining': 'Verbleibend',
          'settings.diagnostics.limit_usage': 'Limitnutzung',
          'settings.diagnostics.wifi_usage': 'WLAN-Verbrauch',
          'settings.diagnostics.cellular_usage': 'Mobilfunkverbrauch',
          'settings.diagnostics.time_ranges': 'Zeiträume',
          'settings.diagnostics.this_month_actual': 'Diesen Monat (echt)',
          'settings.diagnostics.hourly_average': 'Durchschnitt pro Stunde',
          'settings.diagnostics.since_login_estimated':
              'Seit letzter Anmeldung (geschätzt)',
          'settings.diagnostics.details': 'Details',
          'settings.diagnostics.cache': 'Cache',
          'settings.diagnostics.saved_media_count':
              'Gespeicherte Medienanzahl',
          'settings.diagnostics.occupied_space': 'Belegter Speicher',
          'settings.diagnostics.offline_queue': 'Offline-Warteschlange',
          'settings.diagnostics.pending': 'Ausstehend',
          'settings.diagnostics.dead_letter': 'Dead-letter',
          'settings.diagnostics.status': 'Status',
          'settings.diagnostics.syncing': 'Synchronisiert',
          'settings.diagnostics.idle': 'Leerlauf',
          'settings.diagnostics.processed_total': 'Verarbeitet (gesamt)',
          'settings.diagnostics.failed_total': 'Fehler (gesamt)',
          'settings.diagnostics.last_sync': 'Letzte Synchronisierung',
          'settings.diagnostics.login_date': 'Anmeldedatum',
          'settings.diagnostics.login_time': 'Anmeldezeit',
          'settings.diagnostics.app_health_panel':
              'App-Gesundheitsübersicht',
          'settings.diagnostics.video_cache_detail':
              'Video-Cache-Details',
          'settings.diagnostics.quick_actions': 'Schnellaktionen',
          'settings.diagnostics.offline_queue_detail':
              'Offline-Warteschlangendetails',
          'settings.diagnostics.last_error_summary':
              'Letzte Fehlerzusammenfassung',
          'settings.diagnostics.error_report': 'Fehlerbericht',
          'settings.diagnostics.saved_videos': 'Gespeicherte Videos',
          'settings.diagnostics.saved_segments': 'Gespeicherte Segmente',
          'settings.diagnostics.disk_usage': 'Speichernutzung',
          'settings.diagnostics.unknown': 'Unbekannt',
          'settings.diagnostics.cache_traffic': 'Cache-Verkehr',
          'settings.diagnostics.hit_rate': 'Trefferquote',
          'settings.diagnostics.hit': 'Hit',
          'settings.diagnostics.miss': 'Miss',
          'settings.diagnostics.cache_served': 'Aus Cache geliefert',
          'settings.diagnostics.downloaded_from_network':
              'Aus dem Netzwerk geladen',
          'settings.diagnostics.prefetch': 'Prefetch',
          'settings.diagnostics.queue': 'Warteschlange',
          'settings.diagnostics.active_downloads': 'Aktive Downloads',
          'settings.diagnostics.paused': 'Pausiert',
          'settings.diagnostics.active': 'Aktiv',
          'settings.diagnostics.reset_data_counters':
              'Datenzähler zurücksetzen',
          'settings.diagnostics.data_counters_reset':
              'Datenzähler wurden zurückgesetzt',
          'settings.diagnostics.sync_offline_queue_now':
              'Offline-Warteschlange jetzt synchronisieren',
          'settings.diagnostics.offline_queue_sync_triggered':
              'Offline-Synchronisierung wurde ausgelöst',
          'settings.diagnostics.retry_dead_letter':
              'Dead-letter erneut versuchen',
          'settings.diagnostics.dead_letter_queued':
              'Dead-letter-Einträge wurden eingeplant',
          'settings.diagnostics.clear_dead_letter': 'Dead-letter löschen',
          'settings.diagnostics.dead_letter_cleared':
              'Dead-letter-Warteschlange geleert',
          'settings.diagnostics.pause_prefetch': 'Prefetch pausieren',
          'settings.diagnostics.prefetch_paused': 'Prefetch pausiert',
          'settings.diagnostics.service_not_ready':
              'Prefetch-Dienst ist nicht bereit',
          'settings.diagnostics.resume_prefetch': 'Prefetch fortsetzen',
          'settings.diagnostics.prefetch_resumed':
              'Prefetch fortgesetzt',
          'settings.diagnostics.online': 'Online',
          'settings.diagnostics.sync': 'Sync',
          'settings.diagnostics.processed': 'Verarbeitet',
          'settings.diagnostics.failed': 'Fehlgeschlagen',
          'settings.diagnostics.pending_first8':
              'Ausstehend (erste 8)',
          'settings.diagnostics.dead_letter_first8':
              'Dead-letter (erste 8)',
          'settings.diagnostics.sync_now': 'Jetzt synchronisieren',
          'settings.diagnostics.dead_letter_retry':
              'Dead-letter erneut versuchen',
          'settings.diagnostics.dead_letter_clear': 'Dead-letter löschen',
          'settings.diagnostics.no_recorded_error':
              'Keine gespeicherten Fehler gefunden.',
          'settings.diagnostics.error_code': 'Code',
          'settings.diagnostics.error_category': 'Kategorie',
          'settings.diagnostics.error_severity': 'Schweregrad',
          'settings.diagnostics.error_retryable': 'Erneut versuchbar',
          'settings.diagnostics.error_message': 'Nachricht',
          'settings.diagnostics.error_time': 'Zeit',
          'settings.sign_out': 'Abmelden',
          'settings.sign_out_title': 'Abmelden',
          'settings.sign_out_message':
              'Möchtest du dich wirklich abmelden?',
          'language.title': 'Sprache',
          'language.subtitle': 'Wähle die App-Sprache.',
          'language.note':
              'Einige Bereiche werden schrittweise übersetzt. Deine Auswahl wird sofort angewendet.',
          'language.option.tr': 'Türkisch',
          'language.option.en': 'Englisch',
          'language.option.de': 'Deutsch',
          'language.option.fr': 'Französisch',
          'language.option.it': 'Italienisch',
          'language.option.ru': 'Russisch',
          'language.option.ar': 'Arabisch',
          'login.tagline': '"Deine Geschichten kommen hier zusammen."',
          'login.device_accounts': 'Konten auf diesem Gerät',
          'login.last_used': 'Zuletzt verwendet',
          'login.saved_account': 'Gespeichertes Konto',
          'login.sign_in': 'Anmelden',
          'login.create_account': 'Konto erstellen',
          'login.policies': 'Verträge und Richtlinien',
          'login.identifier_hint': 'Benutzername oder E-Mail-Adresse',
          'login.password_hint': 'Dein Passwort',
          'login.reset': 'Zurücksetzen',
          'common.back': 'Zurück',
          'common.continue': 'Weiter',
          'common.all': 'Alle',
          'common.videos': 'Videos',
          'common.photos': 'Fotos',
          'common.no_results': 'Keine Ergebnisse gefunden',
          'common.success': 'Erfolgreich',
          'common.warning': 'Warnung',
          'common.delete': 'Löschen',
          'common.search': 'Suchen',
          'common.call': 'Anrufen',
          'common.view': 'Anzeigen',
          'common.create': 'Erstellen',
          'common.applications': 'Bewerbungen',
          'common.liked': 'Gefällt mir',
          'common.saved': 'Gespeichert',
          'common.unknown_category': 'Unbekannte Kategorie',
          'common.clear': 'Zurücksetzen',
          'common.share': 'Teilen',
          'common.show_more': 'Mehr anzeigen',
          'common.show_less': 'Weniger anzeigen',
          'common.hide': 'Ausblenden',
          'common.push': 'Push',
          'common.quote': 'Zitieren',
          'common.user': 'Nutzer',
          'common.close': 'Schließen',
          'common.retry': 'Erneut versuchen',
          'login.selected_account_password':
              '{username} ausgewählt. Vervollständige deine Anmeldedaten, um fortzufahren.',
          'login.selected_account_phone':
              '{username} ist mit einer Telefonnummer registriert. Für dieses Konto ist eine manuelle Anmeldung erforderlich.',
          'login.selected_account_manual':
              'Für {username} ist eine manuelle Anmeldung erforderlich.',
          'login.reset_password_title': 'Passwort zurücksetzen',
          'login.reset_password_help':
              'Gib deine E-Mail-Adresse ein, damit wir dein Konto finden können. Wir senden einen Bestätigungscode an die Telefonnummer, die in deinem Konto hinterlegt ist.',
          'login.email_label': 'E-Mail-Adresse',
          'login.email_hint': 'Gib deine E-Mail-Adresse ein',
          'login.get_code': 'Code anfordern',
          'login.resend_code': 'Erneut senden',
          'login.verification_code': 'Bestätigungscode',
          'login.verification_code_hint': '6-stelliger Bestätigungscode',
          'signup.step': 'Schritt {current}/3',
          'signup.create_account_title': 'Erstelle dein Konto',
          'signup.policy_intro':
              'Mit der Kontoerstellung und dem Fortfahren akzeptiere ich die ',
          'signup.policy_outro': ' Texte.',
          'signup.policy_short':
              'Ich akzeptiere die Verträge und Richtlinien.',
          'signup.policy_notice':
              'Diese Zustimmung kann als Teil des Kontoerstellungsprozesses gespeichert werden.',
          'signup.email': 'E-Mail',
          'signup.username': 'Benutzername',
          'signup.username_help':
              'Dein Benutzername sollte eindeutig, klar und nicht irreführend sein. Türkische Zeichen werden automatisch umgewandelt.',
          'signup.password': 'Passwort',
          'signup.password_help':
              'Passwort (Mindestens ein Buchstabe, eine Zahl, ein Satzzeichen; mindestens 6 Zeichen)',
          'signup.personal_info': 'Persönliche Daten',
          'signup.first_name': 'Vorname',
          'signup.last_name_optional': 'Nachname (Optional)',
          'signup.next': 'Weiter',
          'signup.verification_title': 'Bestätigung',
          'signup.verification_message':
              'Wir haben einen Bestätigungscode an +90{phone} gesendet. Gib den Code ein, um fortzufahren.',
          'signup.code_hint': '6-stelliger Code',
          'signup.required_acceptance_title': 'Zustimmung erforderlich',
          'signup.required_acceptance_body':
              'Du musst die Mitgliedschaftsvereinbarung und die Richtlinientexte akzeptieren, um fortzufahren.',
          'signup.invalid_email': 'Bitte gib eine gültige E-Mail-Adresse ein.',
          'signup.username_min':
              'Der Benutzername muss mindestens 8 Zeichen lang sein.',
          'signup.weak_password_title': 'Schwaches Passwort',
          'signup.weak_password_body':
              'Das Passwort muss mindestens einen Buchstaben, eine Zahl und ein Satzzeichen enthalten (mindestens 6 Zeichen).',
          'signup.unavailable_title': 'Nicht verfügbar',
          'signup.email_taken': 'Diese E-Mail wird bereits verwendet.',
          'signup.username_taken': 'Dieser Benutzername ist bereits vergeben.',
          'signup.check_failed_title': 'Prüfung fehlgeschlagen',
          'signup.check_failed_body':
              'Die Registrierungsprüfung ist derzeit nicht verfügbar. Bitte versuche es erneut.',
          'signup.limit_title': 'Limit erreicht',
          'signup.limit_body':
              'Für diese Telefonnummer können maximal 5 Konten erstellt werden.',
          'signup.username_taken_title': 'Benutzername bereits vergeben',
          'signup.username_taken_body':
              'Bitte wähle einen anderen Benutzernamen.',
          'signup.failed_title': 'Registrierung konnte nicht abgeschlossen werden',
          'signup.failed_body':
              'Beim Erstellen des Kontos ist ein Fehler aufgetreten. Bitte versuche es erneut.',
          'signup.missing_info_title': 'Fehlende Angaben',
          'signup.phone_name_rule':
              'Der Vorname muss mindestens 3 Zeichen lang sein und die Telefonnummer muss mit 5 beginnen und 10-stellig sein.',
          'signup.phone_invalid_title': 'Ungültige Telefonnummer',
          'signup.phone_invalid_body':
              'Bitte gib eine 10-stellige Telefonnummer ein, die mit 5 beginnt.',
          'signup.code_invalid_title': 'Ungültiger Code',
          'signup.code_invalid_body':
              'Bitte gib den 6-stelligen Bestätigungscode ein.',
          'signup.verify_failed_title': 'Bestätigung fehlgeschlagen',
          'signup.code_expired':
              'Der Code ist abgelaufen. Bitte fordere einen neuen an.',
          'signup.email_or_username_taken':
              'Diese E-Mail oder dieser Benutzername wird bereits verwendet.',
          'signup.code_not_found':
              'Bestätigungscode nicht gefunden. Bitte fordere einen neuen Code an.',
          'signup.code_wrong': 'Der Bestätigungscode ist falsch.',
          'signup.too_many_attempts':
              'Zu viele fehlgeschlagene Versuche. Bitte fordere einen neuen Code an.',
          'signup.code_no_longer_valid':
              'Der Code ist nicht mehr gültig. Bitte fordere einen neuen Code an.',
          'signup.verify_retry':
              'Der Code konnte nicht bestätigt werden. Bitte versuche es erneut.',
          'signup.account_create_failed_title':
              'Konto konnte nicht erstellt werden',
          'signup.email_in_use': 'Diese E-Mail-Adresse wird bereits verwendet.',
          'signup.invalid_email_auth': 'Die E-Mail-Adresse ist ungültig.',
          'signup.password_too_weak':
              'Das Passwort ist zu schwach. Bitte wähle ein stärkeres Passwort.',
          'signup.email_password_disabled':
              'Die Registrierung mit E-Mail/Passwort ist deaktiviert.',
          'signup.network_failed':
              'Es konnte keine Internetverbindung hergestellt werden.',
          'signup.operation_failed': 'Registrierung fehlgeschlagen.',
          'notifications.title': 'Benachrichtigungen',
          'notifications.instant': 'Sofortbenachrichtigungen',
          'notifications.categories': 'Kategorien',
          'notifications.device_notice':
              'Lass die Benachrichtigungsberechtigung in den Geräteeinstellungen aktiviert, damit Mitteilungen auf dem Sperrbildschirm angezeigt werden.',
          'notifications.device_settings': 'Geräteeinstellungen öffnen',
          'notifications.pause_all': 'Alle pausieren',
          'notifications.pause_all_desc':
              'Alle Benachrichtigungen vorübergehend stummschalten.',
          'notifications.sleep_mode': 'Schlafmodus',
          'notifications.sleep_mode_desc':
              'Benachrichtigungen beruhigen, wenn du nicht gestört werden möchtest.',
          'notifications.messages_only': 'Nur Nachrichten',
          'notifications.messages_only_desc':
              'Wenn aktiv, werden nur Nachrichtenbenachrichtigungen angezeigt.',
          'notifications.posts_comments': 'Beiträge und Kommentare',
          'notifications.posts_comments_desc':
              'Beitragsinteraktionen, Kommentare und Ankündigungen.',
          'notifications.comments': 'Kommentare',
          'notifications.comments_desc': 'Kommentare zu deinem Beitrag.',
          'comments.delete_message':
              'Möchtest du diesen Kommentar wirklich löschen?',
          'comments.delete_failed': 'Kommentar konnte nicht gelöscht werden.',
          'comments.title': 'Kommentare',
          'comments.empty': 'Sei der Erste mit einem Kommentar...',
          'comments.reply': 'Antworten',
          'comments.replying_to': 'Antwort an @nickname',
          'comments.sending': 'Wird gesendet',
          'comments.community_violation_title':
              'Verstoss gegen die Community-Regeln',
          'comments.community_violation_body':
              'Die von dir verwendete Sprache entspricht nicht unseren Community-Regeln. Bitte verwende eine respektvolle Sprache.',
          'post_sharers.empty': 'Noch hat niemand diesen Beitrag geteilt',
          'notifications.post_activity': 'Beitragsaktivität',
          'notifications.post_activity_desc':
              'Likes, Reposts und Beitrags-Pushs.',
          'notifications.follows': 'Follower',
          'notifications.follows_desc':
              'Neue Follower und Folgeaktivitäten.',
          'notifications.follow_notifs': 'Follower-Benachrichtigungen',
          'notifications.follow_notifs_desc':
              'Nutzer, die dir folgen, und Folgeaktivitäten.',
          'notifications.messages': 'Nachrichten',
          'notifications.messages_desc':
              'Chat- und Direktnachrichten-Benachrichtigungen.',
          'notifications.direct_messages': 'Nachrichten',
          'notifications.direct_messages_desc':
              'Einzelchats und neue eingehende Nachrichten.',
          'notifications.opportunities': 'Anzeigen und Bewerbungen',
          'notifications.opportunities_desc':
              'Bewerbungen auf Job- und Nachhilfeanzeigen.',
          'notifications.job_apps': 'Jobanzeigen-Bewerbungen',
          'notifications.job_apps_desc':
              'Neue Bewerbungen auf deine Jobanzeige.',
          'notifications.tutoring_apps': 'Nachhilfe-Bewerbungen',
          'notifications.tutoring_apps_desc':
              'Bewerbungen auf deine Nachhilfeanzeige.',
          'notifications.application_status': 'Bewerbungsstatus',
          'notifications.application_status_desc':
              'Ergebnisse und Statusaktualisierungen von Nachhilfe-Bewerbungen.',
          'notifications.marking_read': 'Wird als gelesen markiert...',
          'notifications.mark_all_read': 'Alle als gelesen markieren',
          'notifications.delete_all': 'Alle löschen',
          'notifications.tab_follow': 'Folgen',
          'notifications.tab_comment': 'Kommentar',
          'notifications.tab_mentions': 'Erwähnungen',
          'notifications.tab_listings': 'Anzeigen',
          'notifications.empty_filtered':
              'In diesem Filter gibt es keine Benachrichtigungen',
          'notifications.empty': 'Du hast keine Benachrichtigungen',
          'notifications.new': 'Neu',
          'notifications.today': 'Heute',
          'notifications.yesterday': 'Gestern',
          'notifications.older': 'Älter',
          'notifications.count_items': '{count} Einträge',
          'notifications.and_more':
              '{base} und {count} weitere Benachrichtigungen',
          'notification.item.default_interaction':
              'hat mit deinem Beitrag interagiert.',
          'notification.hint.profile': 'Profil',
          'notification.hint.chat': 'Chat',
          'notification.hint.listing_named': 'Anzeige: {label}',
          'notification.hint.listing': 'Anzeige',
          'notification.hint.tutoring': 'Nachhilfeanzeige',
          'notification.hint.comments': 'Kommentare',
          'notification.hint.post': 'Beitrag',
          'notification.desc.like': 'hat deinen Beitrag geliked',
          'notification.desc.comment': 'hat deinen Beitrag kommentiert',
          'notification.desc.reshare': 'hat deinen Beitrag erneut geteilt',
          'notification.desc.share': 'hat deinen Beitrag geteilt',
          'notification.desc.follow': 'folgt dir jetzt',
          'notification.desc.message': 'hat dir eine Nachricht gesendet',
          'notification.desc.job_application':
              'hat sich auf deine Anzeige beworben',
          'notification.desc.tutoring_application':
              'hat sich auf deine Nachhilfeanzeige beworben',
          'notification.desc.tutoring_status':
              'hat den Status der Nachhilfebewerbung aktualisiert',
          'support.title': 'Schreib uns',
          'support.card_title': 'Support-Nachricht',
          'support.direct_admin': 'Deine Nachricht wird direkt an den Admin gesendet.',
          'support.topic': 'Thema',
          'support.topic.account': 'Konto',
          'support.topic.payment': 'Zahlung',
          'support.topic.technical': 'Technisches Problem',
          'support.topic.content': 'Inhaltsbeschwerde',
          'support.topic.suggestion': 'Vorschlag',
          'support.message_hint': 'Beschreibe dein Problem oder Anliegen...',
          'support.send': 'Nachricht senden',
          'support.empty_title': 'Fehlende Angabe',
          'support.empty_body': 'Bitte schreibe eine Nachricht.',
          'support.sent_title': 'Gesendet',
          'support.sent_body': 'Deine Nachricht wurde an den Admin gesendet.',
          'support.error_title': 'Fehler',
          'support.error_body': 'Nachricht konnte nicht gesendet werden:',
          'liked_posts.no_posts': 'Keine Beiträge',
          'saved_posts.posts_tab': 'Beiträge',
          'saved_posts.series_tab': 'Serie',
          'saved_posts.series_badge': 'SERIE',
          'saved_posts.no_saved_posts': 'Keine gespeicherten Beiträge',
          'saved_posts.no_saved_series': 'Keine gespeicherten Serien',
          'blocked_users.empty': 'Du hast niemanden blockiert',
          'blocked_users.unblock': 'Blockierung aufheben',
          'blocked_users.unblock_confirm_title': 'Blockierung aufheben',
          'blocked_users.unblock_confirm_body':
              'Möchtest du die Blockierung für {nickname} wirklich aufheben?',
          'blocked_users.unblock_success':
              '{nickname} wurde aus der Blockierliste entfernt.',
          'blocked_users.unblock_failed':
              'Die Blockierung konnte nicht aufgehoben werden.',
          'profile_contact.title': 'Kontakt',
          'profile_contact.call': 'Anruf',
          'profile_contact.email': 'E-Mail',
          'editor_email.title': 'E-Mail-Bestätigung',
          'editor_email.email_hint': 'Deine Konto-E-Mail-Adresse',
          'editor_email.send_code': 'Bestätigungscode senden',
          'editor_email.resend_in':
              'Erneut senden in {seconds}s',
          'editor_email.note':
              'Diese Bestätigung dient der Sicherheit. Auch ohne Bestätigung kannst du die App weiter nutzen.',
          'editor_email.code_hint': '6-stelliger Bestätigungscode',
          'editor_email.verify_confirm':
              'Code bestätigen und freigeben',
          'editor_email.wait': 'Bitte warte {seconds} Sekunden.',
          'editor_email.session_missing':
              'Sitzung nicht gefunden. Bitte melde dich erneut an.',
          'editor_email.email_missing':
              'Für dein Konto wurde keine E-Mail gefunden.',
          'editor_email.code_sent':
              'Der Bestätigungscode wurde an deine E-Mail gesendet.',
          'editor_email.code_send_failed':
              'Der Bestätigungscode konnte nicht gesendet werden.',
          'editor_email.enter_code':
              'Bitte gib den 6-stelligen Bestätigungscode ein.',
          'editor_email.verified':
              'Deine E-Mail-Adresse wurde bestätigt.',
          'editor_email.verify_failed':
              'Die E-Mail-Adresse konnte nicht bestätigt werden.',
          'editor_phone.title': 'Telefonnummer',
          'editor_phone.phone_hint': 'Telefonnummer',
          'editor_phone.send_approval': 'Bestätigungs-E-Mail senden',
          'editor_phone.resend_in':
              'Erneut senden in {seconds}s',
          'editor_phone.code_hint': '6-stelliger Bestätigungscode',
          'editor_phone.verify_update':
              'Code bestätigen und aktualisieren',
          'editor_phone.wait': 'Bitte warte {seconds} Sekunden.',
          'editor_phone.invalid_phone':
              'Bitte gib eine 10-stellige Telefonnummer ein, die mit 5 beginnt.',
          'editor_phone.session_missing':
              'Sitzung nicht gefunden. Bitte melde dich erneut an.',
          'editor_phone.email_missing':
              'Es wurde keine E-Mail für diese Bestätigung gefunden.',
          'editor_phone.code_sent':
              'Der Bestätigungscode wurde an deine E-Mail gesendet.',
          'editor_phone.code_send_failed':
              'Der Bestätigungscode konnte nicht gesendet werden.',
          'editor_phone.enter_code':
              'Bitte gib den 6-stelligen Bestätigungscode ein.',
          'editor_phone.update_failed':
              'Die Telefonnummer konnte nicht aktualisiert werden.',
          'editor_phone.updated':
              'Deine Telefonnummer wurde aktualisiert.',
          'address.title': 'Adresse',
          'address.hint': 'Geschäfts- & Büroadresse',
          'biography.title': 'Biografie',
          'biography.hint': 'Erzähle etwas über dich..',
          'job_selector.title': 'Beruf & Kategorie',
          'job_selector.subtitle':
              'Deine Kategorie macht dein Profil leichter auffindbar.',
          'job_selector.search_hint': 'Suchen',
          'legacy_language.title': 'App-Sprache',
          'policy_detail.last_updated': 'Zuletzt aktualisiert: {date}',
          'statistics.title': 'Statistiken',
          'statistics.you': 'Du',
          'statistics.notice':
              'Deine Statistiken werden regelmäßig anhand deiner Aktivitäten der letzten 30 Tage aktualisiert.',
          'statistics.post_views_pct': 'Prozent der Beitragsaufrufe',
          'statistics.follower_growth_pct': 'Prozent des Follower-Wachstums',
          'statistics.profile_visits_30d': 'Profilbesuche (30 Tage)',
          'statistics.post_views': 'Beitragsaufrufe',
          'statistics.post_count': 'Beitragsanzahl',
          'statistics.story_count': 'Story-Anzahl',
          'statistics.follower_growth': 'Follower-Wachstum',
          'interests.personalize_feed': 'Personalisiere deinen Feed',
          'interests.selection_range':
              'Wähle mindestens {min} und höchstens {max} Interessen aus.',
          'interests.selected_count': '{selected}/{max} ausgewählt',
          'interests.ready': 'Bereit',
          'interests.search_hint': 'Interessen suchen',
          'interests.limit_title': 'Auswahllimit',
          'interests.limit_body':
              'Du kannst höchstens {max} Interessen auswählen.',
          'interests.min_title': 'Auswahl unvollständig',
          'interests.min_body':
              'Du musst mindestens {min} Interessen auswählen.',
          'view_changer.title': 'Ansicht',
          'view_changer.classic': 'Klassische Ansicht',
          'view_changer.modern': 'Moderne Ansicht',
          'social_links.title': 'Links ({count})',
          'social_links.add': 'Hinzufügen',
          'social_links.add_title': 'Link hinzufügen',
          'social_links.label_title': 'Titel',
          'social_links.username_hint': 'Benutzername',
          'social_links.remove_title': 'Link entfernen',
          'social_links.remove_message':
              'Möchtest du diesen Link wirklich entfernen?',
          'social_links.save_permission_error':
              'Berechtigungsfehler: Links dürfen nicht gespeichert werden.',
          'social_links.save_failed': 'Es ist ein Problem aufgetreten.',
          'pasaj.closed': 'Pasaj ist derzeit geschlossen',
          'pasaj.common.slider_admin': 'Slider-Verwaltung',
          'pasaj.common.my_results': 'Meine Ergebnisse',
          'pasaj.common.published': 'Veröffentlichte',
          'pasaj.common.my_applications': 'Meine Bewerbungen',
          'pasaj.common.post_listing': 'Inserat erstellen',
          'pasaj.common.all_turkiye': 'Ganz Türkei',
          'pasaj.job_finder.tab.explore': 'Entdecken',
          'pasaj.job_finder.tab.create': 'Anzeige erstellen',
          'pasaj.job_finder.tab.applications': 'Meine Bewerbungen',
          'pasaj.job_finder.tab.career_profile': 'Karriereprofil',
          'pasaj.tabs.scholarships': 'Stipendien',
          'pasaj.tabs.market': 'Mabil Markt',
          'pasaj.tabs.question_bank': 'Fragenbank',
          'pasaj.tabs.practice_exams': 'Probeprüfungen',
          'pasaj.tabs.online_exam': 'Online-Prüfung',
          'pasaj.tabs.answer_key': 'Antwortschlüssel',
          'pasaj.tabs.tutoring': 'Nachhilfe',
          'pasaj.tabs.job_finder': 'Arbeitgeber',
          'pasaj.question_bank.solve_later': 'Später lösen',
          'pasaj.answer_key.join': 'Beitreten',
          'answer_key.published': 'Veröffentlicht',
          'answer_key.my_results': 'Meine Ergebnisse',
          'answer_key.saved_empty': 'Keine gespeicherten Bücher.',
          'answer_key.new_create': 'Neu erstellen',
          'answer_key.create_optical_form': 'Optisches Formular\nErstellen',
          'answer_key.create_booklet_answer_key':
              'Buchlösungsschlüssel\nErstellen',
          'answer_key.create_optical_form_single':
              'Optisches Formular erstellen',
          'answer_key.give_exam_name': 'Gib deiner Prüfung einen Namen',
          'answer_key.join_exam_title': 'Prüfung beitreten',
          'answer_key.exam_id_hint': 'Prüfungs-ID',
          'answer_key.book': 'Buch',
          'answer_key.create_book': 'Buch erstellen',
          'answer_key.optical_form': 'Optisches Formular',
          'answer_key.delete_book': 'Buch löschen',
          'answer_key.share_owner_only':
              'Nur Admins und der Anzeigeninhaber können teilen.',
          'answer_key.book_answer_key_desc': 'Antwortschlüssel',
          'answer_key.delete_operation': 'Löschvorgang',
          'answer_key.delete_optical_confirm':
              'Möchtest du das optische Formular @name wirklich löschen?',
          'answer_key.total_questions': 'Insgesamt @count Fragen',
          'answer_key.participant_count': '@count Personen',
          'answer_key.id_copied': 'ID kopiert',
          'answer_key.answered_suffix': 'Vor @time beantwortet',
          'pasaj.tutoring.nearby_listings': 'Anzeigen in meiner Nähe',
          'pasaj.job_finder.title': 'Arbeitgeber',
          'pasaj.job_finder.search_hint':
              'Welche Art von Job suchst du?',
          'pasaj.job_finder.nearby_listings':
              'Die nächstgelegenen Anzeigen für dich',
          'pasaj.job_finder.no_search_result':
              'Keine Anzeigen passend zu deiner Suche gefunden',
          'pasaj.job_finder.no_city_listing':
              'Es gibt keine Anzeigen in deiner Stadt',
          'pasaj.job_finder.sort_high_salary': 'Höchstes Gehalt',
          'pasaj.job_finder.sort_low_salary': 'Niedrigstes Gehalt',
          'pasaj.job_finder.sort_nearest': 'Am nächsten',
          'pasaj.job_finder.career_profile': 'Karriereprofil',
          'pasaj.job_finder.detail_title': 'Jobdetails',
          'pasaj.job_finder.no_description':
              'Für diese Anzeige wurde keine Beschreibung hinzugefügt.',
          'pasaj.job_finder.job_info': 'Jobinformationen',
          'pasaj.job_finder.listing_info': 'Anzeigeninformationen',
          'pasaj.job_finder.application_count': 'Anzahl Bewerbungen',
          'pasaj.job_finder.work_type': 'Arbeitsart',
          'pasaj.job_finder.work_days': 'Arbeitstage',
          'pasaj.job_finder.work_hours': 'Arbeitszeiten',
          'pasaj.job_finder.personnel_count': 'Anzahl Personal',
          'pasaj.job_finder.benefits': 'Zusatzleistungen',
          'pasaj.job_finder.passive': 'Passiv',
          'pasaj.job_finder.salary_not_specified': 'Nicht angegeben',
          'pasaj.job_finder.edit_listing': 'Bearbeiten',
          'pasaj.job_finder.applications': 'Bewerbungen',
          'pasaj.job_finder.unpublish_title':
              'Anzeige offline nehmen',
          'pasaj.job_finder.unpublish_body':
              'Möchtest du diese Anzeige wirklich offline nehmen?',
          'pasaj.job_finder.unpublished':
              'Die Anzeige wurde offline genommen.',
          'pasaj.job_finder.unpublish_failed':
              'Die Anzeige konnte nicht entfernt werden: {error}',
          'pasaj.job_finder.already_applied':
              'Du hast dich bereits auf diese Anzeige beworben.',
          'pasaj.job_finder.cv_required': 'Lebenslauf erforderlich',
          'pasaj.job_finder.cv_required_body':
              'Du musst deinen Lebenslauf ausfüllen, bevor du dich bewerben kannst.',
          'pasaj.job_finder.create_cv': 'Lebenslauf erstellen',
          'pasaj.job_finder.applied': 'Beworben',
          'pasaj.job_finder.apply': 'Bewerben',
          'pasaj.job_finder.application_cancel_title':
              'Bewerbung abbrechen',
          'pasaj.job_finder.application_cancel_body':
              'Möchtest du deine Bewerbung wirklich abbrechen?',
          'pasaj.job_finder.application_cancelled':
              'Deine Bewerbung wurde abgebrochen.',
          'pasaj.job_finder.cancel_application':
              'Bewerbung abbrechen',
          'pasaj.job_finder.create_add_title': 'Anzeige hinzufügen',
          'pasaj.job_finder.create_edit_title': 'Anzeige bearbeiten',
          'pasaj.job_finder.create.basic_info': 'Grundinformationen',
          'pasaj.job_finder.create.company_name': 'Firmenname',
          'pasaj.job_finder.create.location': 'Standort',
          'pasaj.job_finder.create.job_desc': 'Jobbeschreibung',
          'pasaj.job_finder.create.listing_title': 'Anzeigentitel',
          'pasaj.job_finder.create.work_type': 'Arbeitsart',
          'pasaj.job_finder.create.work_days': 'Arbeitstage',
          'pasaj.job_finder.create.work_hours': 'Arbeitszeiten',
          'pasaj.job_finder.create.start': 'Beginn',
          'pasaj.job_finder.create.end': 'Ende',
          'pasaj.job_finder.create.profession': 'Beruf',
          'pasaj.job_finder.create.benefits': 'Zusatzleistungen',
          'pasaj.job_finder.create.personnel_count':
              'Anzahl Personal',
          'pasaj.job_finder.create.salary_range': 'Gehaltsspanne',
          'pasaj.job_finder.create.min_salary': 'Mindestgehalt',
          'pasaj.job_finder.create.max_salary': 'Höchstgehalt',
          'pasaj.job_finder.create.pick_gallery':
              'Aus Galerie wählen',
          'pasaj.job_finder.create.take_photo': 'Foto aufnehmen',
          'pasaj.job_finder.create.missing_field': 'Fehlendes Feld',
          'pasaj.job_finder.create.logo_required':
              'Du kannst nicht fortfahren, ohne ein Firmenlogo auszuwählen',
          'pasaj.job_finder.create.company_required':
              'Du kannst nicht fortfahren, ohne den Firmennamen einzugeben',
          'pasaj.job_finder.create.city_district_required':
              'Du kannst nicht fortfahren, ohne Stadt und Bezirk auszuwählen',
          'pasaj.job_finder.create.address_required':
              'Bitte gib deine Firmenadresse über deinen aktuellen Standort an',
          'pasaj.job_finder.create.work_type_required':
              'Du kannst nicht fortfahren, ohne eine Arbeitsart auszuwählen',
          'pasaj.job_finder.create.profession_required':
              'Du kannst nicht fortfahren, ohne einen Beruf auszuwählen',
          'pasaj.job_finder.create.description_required':
              'Du musst den Job beschreiben',
          'pasaj.job_finder.create.benefits_required':
              'Du musst mindestens eine Zusatzleistung auswählen',
          'pasaj.job_finder.create.min_salary_required':
              'Du musst das Mindestgehalt ausfüllen',
          'pasaj.job_finder.create.max_salary_required':
              'Du musst das Höchstgehalt ausfüllen',
          'pasaj.job_finder.create.invalid_salary_range':
              'Das Höchstgehalt darf nicht unter dem Mindestgehalt liegen',
          'pasaj.job_finder.create.crop_use': 'Zuschneiden und verwenden',
          'pasaj.job_finder.create.select_district': 'Bezirk auswählen',
          'pasaj.job_finder.image_security_failed':
              'Die Bild-Sicherheitsprüfung konnte nicht abgeschlossen werden',
          'pasaj.job_finder.image_nsfw_detected':
              'Unangemessenes Bild erkannt',
          'pasaj.job_finder.day.monday': 'Montag',
          'pasaj.job_finder.day.tuesday': 'Dienstag',
          'pasaj.job_finder.day.wednesday': 'Mittwoch',
          'pasaj.job_finder.day.thursday': 'Donnerstag',
          'pasaj.job_finder.day.friday': 'Freitag',
          'pasaj.job_finder.day.saturday': 'Samstag',
          'pasaj.job_finder.day.sunday': 'Sonntag',
          'pasaj.job_finder.benefit.meal': 'Verpflegung',
          'pasaj.job_finder.benefit.road_fee': 'Fahrtkostenzuschuss',
          'pasaj.job_finder.benefit.shuttle': 'Shuttle',
          'pasaj.job_finder.benefit.bonus': 'Bonus',
          'pasaj.job_finder.benefit.private_health':
              'Private Krankenversicherung',
          'pasaj.job_finder.benefit.retirement':
              'Private Altersvorsorge',
          'pasaj.job_finder.benefit.flexible_hours':
              'Flexible Arbeitszeiten',
          'pasaj.job_finder.benefit.remote_work': 'Remote-Arbeit',
          'pasaj.job_finder.my_applications': 'Meine Bewerbungen',
          'pasaj.job_finder.no_applications':
              'Du hast dich noch nicht beworben',
          'pasaj.job_finder.default_job_title': 'Stellenanzeige',
          'pasaj.job_finder.default_company': 'Unternehmen',
          'pasaj.job_finder.cancel_apply_title':
              'Bewerbung abbrechen',
          'pasaj.job_finder.cancel_apply_body':
              'Möchtest du diese Bewerbung wirklich abbrechen?',
          'pasaj.job_finder.saved_jobs': 'Gespeicherte',
          'pasaj.job_finder.no_saved_jobs':
              'Keine gespeicherten Anzeigen.',
          'pasaj.job_finder.my_ads': 'Meine Anzeigen',
          'pasaj.job_finder.published_tab': 'Veröffentlicht',
          'pasaj.job_finder.expired_tab': 'Abgelaufen',
          'pasaj.job_finder.no_my_ads': 'Keine Anzeigen gefunden',
          'pasaj.job_finder.finding_platform': 'Jobsuchplattform',
          'pasaj.job_finder.finding_how':
              'Wie funktioniert die Jobsuchplattform?',
          'pasaj.job_finder.finding_body':
              'Dein Lebenslauf wird mit deiner Zustimmung an Arbeitgeber weitergegeben. Arbeitgeber können vor dem Veröffentlichen einer Anzeige passende Kandidaten für ihre offenen Stellen über unser System prüfen. So erreichen Arbeitgeber schneller geeignete Mitarbeiter und Jobsuchende erhalten schneller Zugang zu Chancen. Unser Ziel ist es, den Einstellungsprozess für beide Seiten schneller und effektiver zu machen.',
          'pasaj.job_finder.looking_for_job': 'Ich suche Arbeit',
          'pasaj.job_finder.professional_profile': 'Professionelles Profil',
          'pasaj.job_finder.experience': 'Berufserfahrung',
          'pasaj.job_finder.education': 'Ausbildung',
          'pasaj.job_finder.languages': 'Sprachen',
          'pasaj.job_finder.skills': 'Fähigkeiten',
          'pasaj.job_finder.edit_cv': 'Lebenslauf bearbeiten',
          'pasaj.job_finder.no_cv_title':
              'Du hast noch keinen Lebenslauf erstellt',
          'pasaj.job_finder.no_cv_body':
              'Erstelle einen Lebenslauf, um deine Bewerbungen zu beschleunigen',
          'pasaj.job_finder.applicants': 'Bewerber',
          'pasaj.job_finder.no_applicants': 'Noch keine Bewerbungen',
          'pasaj.job_finder.unknown_user': 'Unbekannter Nutzer',
          'pasaj.job_finder.view_cv': 'Lebenslauf ansehen',
          'pasaj.job_finder.review': 'Prüfen',
          'pasaj.job_finder.accept': 'Annehmen',
          'pasaj.job_finder.reject': 'Ablehnen',
          'pasaj.job_finder.cv_not_found_title':
              'Lebenslauf nicht gefunden',
          'pasaj.job_finder.cv_not_found_body':
              'Für diesen Nutzer wurde kein gespeicherter Lebenslauf gefunden.',
          'pasaj.job_finder.status.pending': 'Ausstehend',
          'pasaj.job_finder.status.reviewing': 'In Prüfung',
          'pasaj.job_finder.status.accepted': 'Angenommen',
          'pasaj.job_finder.status.rejected': 'Abgelehnt',
          'pasaj.job_finder.status_updated':
              'Der Bewerbungsstatus wurde aktualisiert.',
          'pasaj.job_finder.status_update_failed':
              'Der Bewerbungsstatus konnte nicht aktualisiert werden.',
          'pasaj.job_finder.relogin_required':
              'Bitte melde dich erneut an, um fortzufahren.',
          'pasaj.job_finder.save_failed':
              'Speichern konnte nicht abgeschlossen werden.',
          'pasaj.job_finder.share_auth_required':
              'Nur Admins und Anzeigeninhaber können teilen.',
          'pasaj.job_finder.review_relogin_required':
              'Bitte melde dich zum Bewerten erneut an.',
          'pasaj.job_finder.review_own_forbidden':
              'Du kannst deine eigene Anzeige nicht bewerten.',
          'pasaj.job_finder.review_saved':
              'Deine Bewertung wurde gespeichert.',
          'pasaj.job_finder.review_save_failed':
              'Die Bewertung konnte nicht gespeichert werden.',
          'pasaj.job_finder.review_deleted':
              'Deine Bewertung wurde entfernt.',
          'pasaj.job_finder.review_delete_failed':
              'Die Bewertung konnte nicht entfernt werden.',
          'pasaj.job_finder.open_in_maps': 'In Karten öffnen',
          'pasaj.job_finder.open_google_maps':
              'In Google Maps öffnen',
          'pasaj.job_finder.open_apple_maps':
              'In Apple Karten öffnen',
          'pasaj.job_finder.open_yandex_maps':
              'In Yandex Maps öffnen',
          'pasaj.job_finder.map_load_failed':
              'Karte konnte nicht geladen werden',
          'pasaj.job_finder.open_maps_help':
              'Tippe, um den Standort in Karten zu öffnen.',
          'pasaj.job_finder.application_sent':
              'Deine Bewerbung wurde gesendet.',
          'pasaj.job_finder.application_failed':
              'Beim Senden der Bewerbung ist ein Problem aufgetreten.',
          'pasaj.job_finder.listing_not_found':
              'Anzeige wurde nicht gefunden',
          'pasaj.job_finder.reactivated':
              'Die Anzeige wurde erneut veröffentlicht.',
          'pasaj.job_finder.sort_title': 'Sortierung',
          'pasaj.job_finder.sort_newest': 'Neueste',
          'pasaj.job_finder.sort_nearest_me': 'In meiner Nähe',
          'pasaj.job_finder.sort_most_viewed': 'Am meisten angesehen',
          'pasaj.job_finder.clear_filters': 'Filter löschen',
          'pasaj.job_finder.select_city': 'Stadt auswählen',
          'pasaj.job_finder.work_type.full_time': 'Vollzeit',
          'pasaj.job_finder.work_type.part_time': 'Teilzeit',
          'pasaj.job_finder.work_type.remote': 'Remote',
          'pasaj.job_finder.work_type.hybrid': 'Hybrid',
          'pasaj.market.title': 'Markt',
          'pasaj.market.contact_phone': 'Telefon',
          'pasaj.market.contact_message': 'Nachricht',
          'pasaj.market.min_price': 'Min {value}',
          'pasaj.market.max_price': 'Max {value}',
          'pasaj.market.sort_price_asc': 'Preis aufsteigend',
          'pasaj.market.sort_price_desc': 'Preis absteigend',
          'pasaj.market.all_listings': 'Alle Anzeigen',
          'pasaj.market.main_categories': 'Hauptkategorien',
          'pasaj.market.category_search_hint':
              'Hauptkategorie, Unterkategorie, Marke suchen',
          'pasaj.market.call_now': 'Jetzt anrufen',
          'pasaj.market.inspect': 'Ansehen',
          'pasaj.market.empty_filtered':
              'Für diesen Filter wurden keine Anzeigen gefunden.',
          'pasaj.market.add_listing': 'Anzeige hinzufügen',
          'pasaj.market.my_listings': 'Meine Anzeigen',
          'pasaj.market.saved_items': 'Gespeicherte',
          'pasaj.market.my_offers': 'Meine Angebote',
          'pasaj.market.menu.create': 'Anzeige hinzufügen',
          'pasaj.market.menu.my_items': 'Meine Anzeigen',
          'pasaj.market.menu.saved': 'Gefällt mir',
          'pasaj.market.menu.offers': 'Meine Angebote',
          'pasaj.market.menu.categories': 'Kategorien',
          'pasaj.market.menu.nearby': 'In der Nähe',
          'pasaj.market.category.electronics': 'Elektronik',
          'pasaj.market.category.phone': 'Telefon',
          'pasaj.market.category.computer': 'Computer',
          'pasaj.market.category.gaming_electronics': 'Spielelektronik',
          'pasaj.market.category.clothing': 'Kleidung',
          'pasaj.market.category.home_living': 'Haus & Wohnen',
          'pasaj.market.category.sports': 'Sport',
          'pasaj.market.category.real_estate': 'Immobilien',
          'pasaj.market.detail_title': 'Anzeigendetails',
          'pasaj.market.report_listing': 'Anzeige melden',
          'pasaj.market.report_reason': 'Bitte wähle einen Grund.',
          'pasaj.market.no_description':
              'Für diese Anzeige wurde keine Beschreibung hinzugefügt.',
          'pasaj.market.listing_info': 'Anzeigeninformationen',
          'pasaj.market.phone_and_message': 'Telefon + Nachricht',
          'pasaj.market.message_only': 'Nur Nachricht',
          'pasaj.market.saved_count': 'Gespeichert von',
          'pasaj.market.offer_count': 'Angebote',
          'pasaj.market.default_seller': 'Turq Nutzer',
          'pasaj.market.owner_hint':
              'Diese Anzeige gehört dir. Du kannst sie hier bearbeiten oder teilen.',
          'pasaj.market.messages': 'Nachrichten',
          'pasaj.market.offers': 'Angebote',
          'pasaj.market.related_listings': 'Ähnliche Anzeigen',
          'pasaj.market.no_related':
              'Für diese Kategorie wurden keine weiteren Anzeigen gefunden.',
          'pasaj.market.report_received_title':
              'Deine Anfrage ist eingegangen!',
          'pasaj.market.report_received_body':
              'Die Anzeige wurde zur Prüfung vorgemerkt. Vielen Dank.',
          'pasaj.market.report_failed':
              'Die Anzeigenmeldung konnte nicht gesendet werden.',
          'pasaj.market.invalid_offer':
              'Wähle ein gültiges Angebot aus.',
          'pasaj.market.offer_sent': 'Angebot gesendet.',
          'pasaj.market.offer_own_forbidden':
              'Du kannst kein Angebot für deine eigene Anzeige machen.',
          'pasaj.market.offer_daily_limit':
              'Du kannst maximal 20 Angebote pro Tag machen.',
          'pasaj.market.offer_failed':
              'Das Angebot konnte nicht gesendet werden.',
          'pasaj.market.custom_offer': 'Eigenes Angebot festlegen',
          'pasaj.market.discount': '{value}% Rabatt',
          'pasaj.market.reviews': 'Bewertungen',
          'pasaj.market.rate': 'Bewerten',
          'pasaj.market.review_edit': 'Bearbeiten',
          'pasaj.market.no_reviews': 'Es gibt noch keine Bewertungen.',
          'pasaj.market.sign_in_to_review':
              'Du musst dich anmelden, um eine Bewertung abzugeben.',
          'pasaj.market.review_comment_hint':
              'Schreibe deinen Kommentar',
          'pasaj.market.select_rating':
              'Bitte wähle eine Bewertung aus.',
          'pasaj.market.review_saved':
              'Deine Bewertung wurde gespeichert.',
          'pasaj.market.review_updated':
              'Deine Bewertung wurde aktualisiert.',
          'pasaj.market.review_own_forbidden':
              'Du kannst deine eigene Anzeige nicht bewerten.',
          'pasaj.market.review_failed':
              'Die Bewertung konnte nicht gesendet werden.',
          'pasaj.market.review_deleted':
              'Deine Bewertung wurde entfernt.',
          'pasaj.market.review_delete_failed':
              'Die Bewertung konnte nicht entfernt werden.',
          'pasaj.market.location_missing': 'Standort nicht angegeben',
          'pasaj.market.status.sold': 'Verkauft',
          'pasaj.market.status.draft': 'Entwurf',
          'pasaj.market.status.archived': 'Archiviert',
          'pasaj.market.status.reserved': 'Reserviert',
          'pasaj.market.status.active': 'Aktiv',
          'pasaj.market.create.images': 'Bilder',
          'pasaj.market.create.basic_info': 'Grundinformationen',
          'pasaj.market.create.pick_category':
              'Du musst eine Kategorie auswählen.',
          'pasaj.market.create.title_required': 'Titel ist erforderlich.',
          'pasaj.market.create.title_hint': 'Titel',
          'pasaj.market.create.description_hint': 'Beschreibung',
          'pasaj.market.create.price_hint': 'Preis (TRY)',
          'pasaj.market.create.location': 'Standort',
          'pasaj.market.create.category': 'Kategorie',
          'pasaj.market.create.features': 'Anzeigenmerkmale',
          'pasaj.market.create.contact_preference':
              'Kontaktpräferenz',
          'pasaj.market.create.fields_after_category':
              'Diese Felder werden nach Abschluss der Kategorieauswahl geöffnet.',
          'pasaj.market.create.no_extra_fields':
              'Für diese Kategorie sind keine zusätzlichen Felder definiert.',
          'pasaj.market.create.main_category': 'Hauptkategorie',
          'pasaj.market.create.main_category_search':
              'Hauptkategorie, Unterkategorie, Marke suchen',
          'pasaj.market.create.no_subcategory':
              'Unter dieser Hauptkategorie gibt es keine auswählbaren Unterkategorien.',
          'pasaj.market.create.subcategory': 'Unterkategorie',
          'pasaj.market.create.subgroup': 'Untergruppe',
          'pasaj.market.create.product_type': 'Produkttyp',
          'pasaj.market.create.level': 'Ebene {value}',
          'pasaj.market.create.select_image':
              'Bild auswählen ({current}/{max})',
          'pasaj.market.create.cover': 'Titelbild',
          'pasaj.market.empty_my_listings':
              'Für diesen Zustand wurden keine Anzeigen gefunden.',
          'pasaj.market.status_update_failed':
              'Der Anzeigenstatus konnte nicht aktualisiert werden.',
          'pasaj.market.marked_sold':
              'Die Anzeige wurde als verkauft markiert.',
          'pasaj.market.marked_active':
              'Die Anzeige wurde aktiviert.',
          'pasaj.market.saved_empty':
              'Keine gemerkten Anzeigen gefunden.',
          'pasaj.market.removed_saved':
              'Aus den gemerkten Anzeigen entfernt.',
          'pasaj.market.unsave_failed':
              'Der gespeicherte Eintrag konnte nicht entfernt werden.',
          'pasaj.market.offers_title': 'Meine Angebote',
          'pasaj.market.sent_tab': 'Gesendet',
          'pasaj.market.received_tab': 'Erhalten',
          'pasaj.market.sent_offer': 'Gesendetes Angebot',
          'pasaj.market.received_offer': 'Erhaltenes Angebot',
          'pasaj.market.offer_empty':
              'Kein Eintrag für {subtitle} gefunden.',
          'pasaj.market.offer_accepted': 'Angebot angenommen.',
          'pasaj.market.offer_rejected': 'Angebot abgelehnt.',
          'pasaj.market.offer_already_processed':
              'Dieses Angebot wurde bereits bearbeitet.',
          'pasaj.market.offer_update_failed':
              'Das Angebot konnte nicht aktualisiert werden.',
          'pasaj.market.listing_unavailable':
              'Diese Anzeige ist derzeit nicht erreichbar.',
          'pasaj.market.filter.title': 'Filter',
          'pasaj.market.filter.all_cities': 'Alle Städte',
          'pasaj.market.filter.search_city': 'Stadt suchen',
          'pasaj.market.filter.price_range': 'Preisspanne',
          'pasaj.market.filter.min': 'Min',
          'pasaj.market.filter.max': 'Max',
          'pasaj.market.filter.sort': 'Sortierung',
          'pasaj.market.filter.newest': 'Neu',
          'pasaj.market.filter.ascending': 'Aufsteigend',
          'pasaj.market.filter.descending': 'Absteigend',
          'pasaj.market.filter.apply': 'Anwenden',
          'pasaj.market.search_hint': 'Anzeige suchen',
          'pasaj.market.search.no_results_body':
              'Keine Anzeigen passend zu deiner Suche gefunden.',
          'pasaj.market.search.result_count': '{count} Ergebnisse',
          'pasaj.market.search.start_title': 'Starte deine Anzeigensuche',
          'pasaj.market.search.start_body':
              'Deine letzten Suchen werden hier angezeigt.',
          'pasaj.market.search.recent': 'Letzte Suchen',
          'pasaj.market.sign_in_required_title': 'Anmeldung erforderlich',
          'pasaj.market.sign_in_to_save':
              'Du musst dich anmelden, um Anzeigen zu speichern.',
          'pasaj.market.saved_success': 'Anzeige gespeichert.',
          'pasaj.market.unsaved': 'Gespeicherter Eintrag entfernt.',
          'pasaj.market.save_failed':
              'Der Speichervorgang konnte nicht abgeschlossen werden.',
          'pasaj.market.coming_soon_title': 'Demnächst',
          'pasaj.market.coming_soon_body':
              '{title} wird bald hinzugefügt.',
          'pasaj.market.permission_required_title':
              'Berechtigung erforderlich',
          'pasaj.market.nearby_permission_required':
              'Für Anzeigen in deiner Nähe ist eine Standortberechtigung erforderlich.',
          'pasaj.market.location_not_found_title':
              'Standort nicht gefunden',
          'pasaj.market.city_not_found':
              'Stadtinformationen konnten nicht geladen werden.',
          'pasaj.market.limited_results_title': 'Begrenzte Ergebnisse',
          'pasaj.market.no_city_results':
              'Für {city} wurden keine Anzeigen gefunden.',
          'pasaj.market.nearby_ready':
              'Anzeigen in deiner Nähe für {city} werden angezeigt.',
          'pasaj.market.nearby_failed':
              'Anzeigen in deiner Nähe konnten nicht geladen werden.',
          'pasaj.market.limit_title': 'Limit',
          'pasaj.market.image_limit':
              'Du kannst bis zu {max} Bilder hinzufügen.',
          'pasaj.market.create.need_image':
              'Füge mindestens ein Bild hinzu, um zu veröffentlichen.',
          'pasaj.market.create.invalid_price':
              'Gib einen gültigen Preis ein.',
          'pasaj.market.create.city_district_required_short':
              'Stadt und Bezirk sind erforderlich.',
          'pasaj.market.create.field_required':
              'Feld {field} ist erforderlich.',
          'pasaj.market.user_session_not_found':
              'Benutzersitzung konnte nicht gefunden werden.',
          'pasaj.market.create.save_failed':
              'Anzeige konnte nicht gespeichert werden: {error}',
          'pasaj.market.image_security_failed':
              'Die Bildsicherheitsprüfung konnte nicht abgeschlossen werden',
          'pasaj.market.image_nsfw_detected':
              'Unangemessenes Bild erkannt',
          'pasaj.market.create.add_title': 'Anzeige hinzufügen',
          'pasaj.market.create.edit_title': 'Anzeige bearbeiten',
          'pasaj.market.create.update_draft': 'Entwurf aktualisieren',
          'pasaj.market.status.pending': 'Ausstehend',
          'pasaj.market.status.accepted': 'Angenommen',
          'pasaj.market.status.rejected': 'Abgelehnt',
          'pasaj.market.status.cancelled': 'Abgebrochen',
          'account_center.header_title': 'Profile und Anmeldedaten',
          'account_center.accounts': 'Konten',
          'account_center.no_accounts':
              'Diesem Gerät wurde noch kein Konto hinzugefügt.',
          'account_center.add_account': 'Konto hinzufügen',
          'account_center.personal_details': 'Persönliche Details',
          'account_center.security': 'Sicherheit',
          'account_center.active_account_title': 'Aktives Konto',
          'account_center.active_account_body':
              '@{username} ist bereits aktiv.',
          'account_center.reauth_title':
              'Erneute Anmeldung erforderlich',
          'account_center.reauth_body':
              'Du musst dich für @{username} erneut mit deinem Passwort anmelden.',
          'account_center.switch_failed_title':
              'Wechsel fehlgeschlagen',
          'account_center.switch_failed_body':
              'Für dieses Konto ist zuerst eine normale Anmeldung erforderlich.',
          'account_center.remove_active_forbidden':
              'Du kannst das aktive Konto hier nicht entfernen. Wechsle zuerst zu einem anderen Konto.',
          'account_center.remove_account_title': 'Konto entfernen',
          'account_center.remove_account_body':
              'Möchtest du @{username} aus den auf diesem Gerät gespeicherten Konten entfernen?',
          'account_center.account_removed':
              '@{username} wurde entfernt.',
          'account_center.single_device_title':
              'Bei neuer Anmeldung andere Telefone abmelden',
          'account_center.single_device_desc':
              'Wenn diese Einstellung aktiviert ist, wird bei einer Anmeldung von einem anderen Telefon die Sitzung auf diesem Gerät beendet. Für die erneute Anmeldung ist ein Passwort erforderlich.',
          'account_center.single_device_enabled':
              'Bei einer neuen Anmeldung von einem Gerät werden andere Telefone abgemeldet.',
          'account_center.single_device_disabled':
              'Das Konto kann gleichzeitig auf mehreren Telefonen angemeldet bleiben.',
          'account_center.no_personal_detail':
              'Es gibt noch keine persönlichen Details zum Anzeigen.',
          'account_center.contact_details': 'Kontaktdaten',
          'account_center.contact_info': 'Kontaktinformationen',
          'account_center.email': 'E-Mail',
          'account_center.phone': 'Telefon',
          'account_center.email_missing': 'Keine E-Mail hinzugefügt',
          'account_center.phone_missing': 'Keine Telefonnummer hinzugefügt',
          'account_center.verified': 'Bestätigt',
          'account_center.verify': 'Bestätigen',
          'account_center.unverified': 'Unbestätigt',
          'about_profile.title': 'Über dieses Konto',
          'about_profile.description':
              'Wir teilen Informationen über Konten auf TurqApp transparent, um das Vertrauen in unsere Community zu stärken.',
          'about_profile.joined_on': 'Beigetreten am {date}',
          'policies.center_title': 'Richtlinienzentrum',
          'policies.center_desc':
              'Vertrags-, Datenschutz-, Community- und Sicherheitstexte findest du hier.',
          'policies.last_updated': 'Zuletzt aktualisiert: {date}',
          'admin.no_access': 'Dieser Bereich ist nur für Admins zugänglich.',
          'admin.support.title': 'Nutzersupport',
          'admin.support.close_message': 'Nachricht schließen',
          'admin.support.answer_message': 'Nachricht beantworten',
          'admin.support.note': 'Admin-Notiz',
          'admin.support.empty': 'Es gibt noch keine Support-Nachrichten.',
          'admin.support.updated_title': 'Aktualisiert',
          'admin.support.updated_body': 'Support-Nachricht aktualisiert.',
          'admin.support.open': 'Offen',
          'admin.support.answered': 'Beantwortet',
          'admin.support.closed': 'Geschlossen',
          'admin.support.mark_answered': 'Beantwortet',
          'admin.support.close': 'Schließen',
          'admin.approvals.title': 'Admin-Freigaben',
          'admin.approvals.empty':
              'Es gibt keine ausstehenden Admin-Freigaben.',
          'admin.approvals.default_title': 'Admin-Freigabe',
          'admin.approvals.created_by': 'Erstellt von',
          'admin.approvals.rejection_reason': 'Ablehnungsgrund',
          'admin.approvals.approve': 'Genehmigen',
          'admin.approvals.reject': 'Ablehnen',
          'admin.approvals.approved': 'Genehmigt',
          'admin.approvals.rejected': 'Abgelehnt',
          'admin.approvals.pending': 'Ausstehend',
          'admin.approvals.approved_body': 'Die Aktion wurde genehmigt.',
          'admin.approvals.rejected_body': 'Die Aktion wurde abgelehnt.',
          'admin.approvals.approve_failed':
              'Freigabe konnte nicht abgeschlossen werden:',
          'admin.approvals.reject_failed': 'Ablehnung fehlgeschlagen:',
          'admin.my_approvals.title': 'Meine Freigabeergebnisse',
          'admin.my_approvals.load_failed':
              'Freigabeeinträge konnten nicht geladen werden.',
          'admin.my_approvals.empty':
              'Du hast noch keine Freigabeanfragen.',
          'admin.my_approvals.default_title': 'Freigabeanfrage',
          'admin.my_approvals.requested': 'Anfrage',
          'admin.my_approvals.result': 'Ergebnis',
          'admin.tasks.title': 'Admin-Aufgaben',
          'admin.tasks.editor_title':
              'Aufgaben nach Benutzername zuweisen',
          'admin.tasks.editor_help':
              'Gib den Benutzernamen ein, lade die Person, markiere die Aufgaben und speichere. Dieser Bildschirm dient dazu, die Aufgabenverteilung zentral zu verfolgen.',
          'admin.tasks.username': 'Benutzername',
          'admin.tasks.username_hint': '@benutzername',
          'admin.tasks.load': 'Laden',
          'admin.tasks.task_list': 'Aufgaben',
          'admin.tasks.saving': 'Wird gespeichert',
          'admin.tasks.save': 'Aufgaben speichern',
          'admin.tasks.clear': 'Leeren',
          'admin.tasks.assignments': 'Aufgabenzuweisungen',
          'admin.tasks.assignments_help':
              'Hier sehen wir die gesamte Aufgabenverteilung in einer Liste. Tippe auf eine Karte, um sie oben zu bearbeiten.',
          'admin.tasks.no_assignments':
              'Es gibt noch keine Aufgabenzuweisungen.',
          'admin.tasks.missing_info': 'Fehlende Angabe',
          'admin.tasks.username_required':
              'Benutzername ist erforderlich.',
          'admin.tasks.not_found': 'Nicht gefunden',
          'admin.tasks.user_not_found':
              'Es wurde kein Nutzer mit diesem Benutzernamen gefunden.',
          'admin.tasks.load_failed':
              'Nutzer konnte nicht geladen werden:',
          'admin.tasks.load_user_first':
              'Lade zuerst den Nutzer.',
          'admin.tasks.assignment_removed':
              'Aufgabenzuweisung für @{nickname} entfernt.',
          'admin.tasks.saved':
              'Aufgaben für @{nickname} gespeichert.',
          'admin.tasks.save_failed':
              'Aufgaben konnten nicht gespeichert werden:',
          'admin.tasks.cleared':
              'Aufgaben für @{nickname} wurden entfernt.',
          'admin.tasks.clear_failed':
              'Aufgaben konnten nicht entfernt werden:',
          'admin.tasks.updated_at': 'Aktualisiert',
          'admin.task.moderation.title': 'Moderation',
          'admin.task.moderation.desc':
              'Verwaltet Meldungen, Reports und Inhaltsschwellen.',
          'admin.task.reports.title': 'Reports',
          'admin.task.reports.desc':
              'Prüft Nutzer- und Inhaltsmeldungen.',
          'admin.task.badges.title': 'Badge-Verwaltung',
          'admin.task.badges.desc':
              'Prüft Badge-Anträge und vergibt Badges.',
          'admin.task.approvals.title': 'Freigaben / Anträge',
          'admin.task.approvals.desc':
              'Verfolgt Badge- und ähnliche Freigabewarteschlangen.',
          'admin.task.user_bans.title': 'Ban-Verwaltung',
          'admin.task.user_bans.desc':
              'Verhängt oder entfernt Nutzer-Sperren.',
          'admin.task.admin_push.title': 'Admin Push',
          'admin.task.admin_push.desc':
              'Sendet Sammelbenachrichtigungen und Systemhinweise.',
          'admin.task.ads_center.title': 'Anzeigenzentrum',
          'admin.task.ads_center.desc':
              'Verwaltet Werbe- und Kampagnenabläufe.',
          'admin.task.story_music.title': 'Story-Musik',
          'admin.task.story_music.desc':
              'Verwaltet Story-Musikkataloge.',
          'admin.task.pasaj.title': 'Pasaj-Betrieb',
          'admin.task.pasaj.desc':
              'Verfolgt Inhalte und Abläufe im Pasaj-Bereich.',
          'admin.task.support.title': 'Nutzersupport',
          'admin.task.support.desc':
              'Verfolgt Nutzeranfragen und Feedback.',
          'admin.moderation.title': 'Moderation',
          'admin.moderation.config_updated':
              'Konfiguration aktualisiert. Schwelle: {threshold}',
          'admin.moderation.config_failed':
              'Konfiguration konnte nicht aktualisiert werden',
          'admin.moderation.threshold_posts':
              'Beiträge über dem Schwellenwert (≥ {threshold})',
          'admin.moderation.list_failed':
              'Moderationsliste konnte nicht geladen werden.',
          'admin.moderation.no_threshold_posts':
              'Keine Beiträge überschreiten den Schwellenwert.',
          'admin.moderation.no_text': 'Kein Text',
          'admin.moderation.provisioning': 'Wird eingerichtet...',
          'admin.moderation.ensure_config':
              'Konfiguration einrichten/aktualisieren',
          'admin.moderation.user_ban_title': 'Benutzer-Sperrverwaltung',
          'admin.moderation.user_ban_help':
              '1. Verstoß: 1 Monat, 2. Verstoß: 3 Monate, 3. Verstoß: dauerhafte Sperre. Während einer temporären Sperre kann der Benutzer nur browsen, liken und erneut teilen.',
          'admin.moderation.ban_reason': 'Sperrgrund',
          'admin.moderation.apply_next_penalty':
              'Nächste Strafe anwenden',
          'admin.moderation.active_bans': 'Aktive Sperren',
          'admin.moderation.ban_list_failed':
              'Sperrliste konnte nicht geladen werden.',
          'admin.moderation.no_active_bans':
              'Keine aktiv gesperrten Benutzer.',
          'admin.moderation.permanent': 'Dauerhaft',
          'admin.moderation.expired': 'Abgelaufen',
          'admin.moderation.level': 'Stufe {level}',
          'admin.moderation.strike_status':
              'Strike: {count} • Status: {status}',
          'admin.moderation.ends_at': 'Ende: {date}',
          'admin.moderation.next_penalty': 'Nächste Strafe',
          'admin.moderation.clear_ban': 'Sperre aufheben',
          'admin.moderation.clear_ban_approval':
              'Freigabe zur Aufhebung der Sperre',
          'admin.moderation.ban_approval':
              'Freigabe für Sperraktion',
          'admin.moderation.clear_ban_summary':
              'Eine Anfrage zur Aufhebung der Sperre für @{nickname} wurde erstellt.',
          'admin.moderation.advance_penalty_summary':
              'Eine Anfrage für die nächste Strafe für @{nickname} wurde erstellt.',
          'admin.moderation.sent_for_approval':
              'Aktion an die Admin-Freigabewarteschlange gesendet.',
          'admin.moderation.ban_removed':
              'Sperre für @{nickname} aufgehoben.',
          'admin.moderation.permanent_applied':
              'Dauerhafte Sperre für @{nickname} angewendet.',
          'admin.moderation.level_applied':
              'Strafe der Stufe {level} für @{nickname} angewendet.',
          'admin.moderation.action_failed':
              'Sperraktion konnte nicht abgeschlossen werden.',
          'admin.badges.title': 'Badge-Verwaltung',
          'admin.badges.manage_by_username':
              'Badge per Benutzername verwalten',
          'admin.badges.manage_help':
              'Benutzernamen eingeben, Badge auswählen und speichern. Die Auswahl `Kein Badge` entfernt das aktuelle Badge.',
          'admin.badges.no_badge': 'Kein Badge',
          'admin.badges.badge_label': 'Badge',
          'admin.badges.save_badge': 'Badge speichern',
          'admin.badges.remove_selected_desc':
              'Entfernt das aktuelle Badge des ausgewählten Benutzers.',
          'admin.badges.change_approval_title':
              'Freigabe für Badge-Änderung',
          'admin.badges.remove_badge_summary':
              'Eine Anfrage zum Entfernen des Badges für @{nickname} wurde erstellt.',
          'admin.badges.give_badge_summary':
              'Eine Anfrage zur Vergabe des Badges {badge} für @{nickname} wurde erstellt.',
          'admin.badges.sent_for_approval':
              'Aktion an die Admin-Freigabewarteschlange gesendet.',
          'admin.badges.badge_removed':
              'Badge für @{nickname} entfernt.',
          'admin.badges.badge_saved':
              'Badge {badge} für @{nickname} gespeichert.',
          'admin.badges.permission_required':
              'Für diese Aktion ist Admin-Berechtigung erforderlich.',
          'admin.badges.invalid_input':
              'Die eingegebenen Informationen sind ungültig.',
          'admin.badges.multiple_users':
              'Für diesen Benutzernamen wurden mehrere Benutzer gefunden.',
          'admin.badges.save_failed':
              'Badge konnte nicht gespeichert werden.',
          'admin.badges.applications_title': 'Badge-Anträge',
          'admin.badges.applications_help':
              'Anträge kommen aus den Einstellungen. Social-Media- und TurqApp-Profillinks werden unten geöffnet.',
          'admin.badges.no_applications': 'Es gibt noch keine Anträge.',
          'admin.badges.no_badge_selected': 'Kein Badge ausgewählt',
          'admin.badges.status': 'Status: {status}',
          'admin.badges.approve_and_assign':
              'Freigeben und Badge vergeben',
          'admin.badges.application_approval_title':
              'Freigabe für Badge-Antrag',
          'admin.badges.application_approval_summary':
              'Das Badge {badge} für @{nickname} wurde zur Freigabe gesendet.',
          'admin.badges.application_sent_for_approval':
              'Antrag an die Admin-Freigabewarteschlange gesendet.',
          'admin.badges.application_approved':
              'Badge vergeben und Antrag genehmigt.',
          'admin.badges.application_approve_failed':
              'Der Antrag konnte nicht genehmigt werden.',
          'admin.badges.last_action': 'Letzte Aktion',
          'admin.push.title': 'Push senden',
          'admin.push.permission_title': 'Berechtigung',
          'admin.push.permission_body':
              'Zum Senden von Benachrichtigungen ist eine Administratorberechtigung erforderlich.',
          'admin.push.select_job': 'Beruf auswählen',
          'admin.push.required_title_body':
              'Titel- und Nachrichtenfelder sind erforderlich.',
          'admin.push.invalid_range_title': 'Ungültiger Bereich',
          'admin.push.invalid_range_body':
              'Das Mindestalter darf nicht größer als das Höchstalter sein.',
          'admin.push.no_results_title': 'Keine Ergebnisse',
          'admin.push.no_results_body':
              'Keine Benutzer entsprechen den ausgewählten Filtern.',
          'admin.push.target': 'Ziel',
          'admin.push.user_count': 'Benutzer',
          'admin.push.type': 'Typ',
          'admin.push.job': 'Beruf',
          'admin.push.location': 'Ort',
          'admin.push.gender': 'Geschlecht',
          'admin.push.age': 'Alter',
          'admin.push.started_title': 'Versand gestartet',
          'admin.push.started_body':
              'Benachrichtigung für {count} Benutzer in die Warteschlange gestellt.',
          'admin.push.send_failed':
              'Benachrichtigungsversand konnte nicht abgeschlossen werden',
          'admin.push.help':
              'Titel und Nachricht sind erforderlich. Wenn du die Filter leer lässt, geht es an alle.',
          'admin.push.title_field': 'Titel',
          'admin.push.message_field': 'Nachricht',
          'admin.push.optional_filters': 'Optionale Filter',
          'admin.push.target_uid': 'Ziel-UID (einzelner Nutzer)',
          'admin.push.people': 'Personen',
          'admin.push.location_hint': 'Ort (Stadt / Provinz / Bezirk)',
          'admin.push.min_age': 'Mindestalter',
          'admin.push.max_age': 'Höchstalter',
          'admin.push.saved_reports': 'Gespeicherte Berichte',
          'admin.push.no_reports': 'Es gibt noch keine Berichte.',
          'admin.push.report_title': 'Titel',
          'admin.push.report_message': 'Nachricht',
          'admin.push.report_filters': 'Filter',
          'admin.push.delete_report': 'Bericht löschen',
          'admin.push.send': 'Senden',
          'admin.reports.title': 'Reports',
          'admin.reports.data_failed':
              'Reports-Daten konnten nicht geladen werden.',
          'admin.reports.empty':
              'Es gibt noch keine Report-Aggregate.',
          'admin.reports.config_help':
              'Standard-Kategorieschwelle: 5\nBei Überschreitung wird der Inhalt automatisch aus der Veröffentlichung genommen\nAdmin-Aktion: erneut veröffentlichen oder verborgen halten',
          'admin.reports.config_updated':
              'adminConfig/reports wurde aktualisiert.',
          'admin.reports.config_failed':
              'Reports-Konfiguration konnte nicht aktualisiert werden',
          'admin.reports.restored':
              'Inhalt wurde wieder veröffentlicht.',
          'admin.reports.kept_hidden':
              'Inhalt wurde verborgen gehalten.',
          'admin.reports.action_failed':
              'Admin-Aktion fehlgeschlagen',
          'admin.reports.total_status':
              'Gesamt: {count} • Status: {status}',
          'admin.reports.category_counts': 'Kategoriezähler',
          'admin.reports.report_reasons': 'Meldegründe',
          'admin.reports.no_category_data': 'Keine Kategoriedaten.',
          'admin.reports.no_detail_reports':
              'Es gibt noch keine detaillierten Report-Einträge.',
          'admin.reports.no_reason': 'Kein Grund',
          'admin.reports.restore': 'Wieder veröffentlichen',
          'admin.reports.processing': 'Wird verarbeitet...',
          'admin.reports.keep_hidden': 'Verborgen halten',
          'admin.story_music.title': 'Story-Musik',
          'admin.story_music.cover_uploaded':
              'Coverbild wurde hochgeladen',
          'admin.story_music.cover_upload_failed':
              'Coverbild konnte nicht hochgeladen werden',
          'admin.story_music.title_url_required':
              'Titel und Musik-URL sind erforderlich',
          'admin.story_music.track_added': 'Track hinzugefügt',
          'admin.story_music.track_updated': 'Track aktualisiert',
          'admin.story_music.save_failed':
              'Track konnte nicht gespeichert werden',
          'admin.story_music.track_deleted': 'Track gelöscht',
          'admin.story_music.delete_failed':
              'Track konnte nicht gelöscht werden',
          'admin.story_music.preview_failed':
              'Vorschau konnte nicht abgespielt werden',
          'admin.story_music.new_track': 'Neuer Track',
          'admin.story_music.edit_track': 'Track bearbeiten',
          'admin.story_music.artist': 'Künstler',
          'admin.story_music.audio_url': 'Musik-URL',
          'admin.story_music.cover_url': 'Cover-URL',
          'admin.story_music.category': 'Kategorie',
          'admin.story_music.order': 'Reihenfolge',
          'admin.story_music.upload_cover': 'Cover hochladen',
          'admin.story_music.active': 'Aktiv',
          'admin.story_music.save_track': 'Track speichern',
          'admin.story_music.save_update': 'Änderungen speichern',
          'admin.story_music.no_tracks': 'Es gibt noch keine Tracks',
          'admin.story_music.untitled': 'Unbenannter Track',
          'admin.story_music.order_usage':
              'Reihenfolge {order} • Nutzung {count}',
          'common.cancel': 'Abbrechen',
          'common.save': 'Speichern',
          'common.select': 'Auswählen',
          'common.remove': 'Entfernen',
          'common.unspecified': 'Nicht angegeben',
          'common.yes': 'Ja',
          'common.no': 'Nein',
          'common.selected_count': '@count ausgewählt',
          'following.followers_tab': 'Follower {count}',
          'following.following_tab': 'Folgt {count}',
          'following.none': 'Noch keine Nutzer',
          'following.follow': 'Folgen',
          'following.following': 'Du folgst',
          'following.unfollow_title': 'Nicht mehr folgen',
          'following.unfollow_body':
              'Möchtest du @{nickname} wirklich nicht mehr folgen?',
          'following.update_failed':
              'Der Follow-Status konnte nicht aktualisiert werden.',
          'following.limit_title': 'Follow-Limit',
          'following.limit_body':
              'Du kannst heute nicht mehr Personen folgen.',
          'profile.highlight_remove_title': 'Highlight entfernen',
          'profile.highlight_remove_body':
              'Möchtest du dieses Highlight wirklich entfernen?',
          'profile.link_remove_title': 'Link entfernen',
          'profile.link_remove_body':
              'Möchtest du diesen Link wirklich entfernen?',
          'profile.edit': 'Bearbeiten',
          'profile.statistics': 'Statistiken',
          'profile.posts': 'Beiträge',
          'profile.followers': 'Follower',
          'profile.following': 'Folgt',
          'profile.likes': 'Likes',
          'profile.listings': 'Anzeigen',
          'profile.copy_profile_link': 'Profil-Link kopieren',
          'profile.profile_share_title': 'TurqApp Profil',
          'profile.private_account_title': 'Privates Konto',
          'profile.private_story_follow_required':
              'Du musst diesem Konto zuerst folgen, um Storys zu sehen.',
          'profile.unfollow_title': 'Entfolgen',
          'profile.unfollow_body':
              'Möchtest du @{nickname} wirklich entfolgen?',
          'profile.unfollow_confirm': 'Entfolgen',
          'profile.following_status': 'Du folgst',
          'profile.follow_button': 'Folgen',
          'profile.contact_options': 'Kontaktoptionen',
          'profile.unblock': 'Blockierung aufheben',
          'profile.remove_highlight_title': 'Highlight entfernen',
          'profile.remove_highlight_body':
              'Möchtest du dieses Highlight wirklich entfernen?',
          'profile.remove_highlight_confirm': 'Entfernen',
          'social_profile.private_follow_to_see_posts':
              'Folge diesem Konto, um Beiträge zu sehen.',
          'social_profile.blocked_user':
              'Du hast diesen Benutzer blockiert',
          'profile.no_posts': 'Keine Beiträge',
          'profile.no_photos': 'Keine Fotos',
          'profile.no_videos': 'Keine Videos',
          'profile.no_reshares': 'Keine Reshares',
          'profile.no_quotes': 'Noch keine Zitate',
          'profile.reshare_users_tab': 'Erneut geteilt von',
          'profile.quote_users_tab': 'Zitiert von',
          'profile.no_listings': 'Keine Anzeigen',
          'profile.post_about_title': 'Über den Beitrag',
          'profile.post_about_body':
              'Was möchtest du mit diesem Beitrag tun?',
          'profile.archive': 'Archivieren',
          'profile.review': 'Ansehen',
          'profile.location_missing': 'Kein Standort angegeben',
          'profile.status_sold': 'Verkauft',
          'profile.status_passive': 'Passiv',
          'profile.status_active': 'Aktiv',
          'profile.remove_reshare_title': 'Beitrag entfernen',
          'profile.remove_reshare_body':
              'Möchtest du diesen Beitrag wirklich aus den erneut geteilten Beiträgen entfernen?',
          'profile.scheduled_post_title': 'Geplanter Beitrag',
          'profile.scheduled_post_body':
              'Was möchtest du mit diesem Beitrag tun?',
          'profile.scheduled_subscribe_title': 'Vormerken',
          'profile.scheduled_subscribe_body':
              'Du erhältst am Veröffentlichungstag eine Benachrichtigung.',
          'profile.scheduled_none': 'Keine geplanten Beiträge',
          'common.edit': 'Bearbeiten',
          'common.update': 'Aktualisieren',
          'common.change': 'Ändern',
          'common.publish': 'Veröffentlichen',
          'common.loading': 'Wird geladen...',
          'common.now': 'jetzt',
          'common.info': 'Info',
          'common.error': 'Fehler',
          'common.ok': 'OK',
          'common.apply': 'Anwenden',
          'common.reset': 'Zurücksetzen',
          'common.select_city': 'Stadt wählen',
          'common.select_district': 'Bezirk wählen',
          'common.download': 'Herunterladen',
          'app.name': 'TurqApp',
          'common.copy': 'Kopieren',
          'common.copy_link': 'Link kopieren',
          'common.copied': 'Kopiert',
          'common.link_copied': 'Der Link wurde in die Zwischenablage kopiert',
          'common.archive': 'Archivieren',
          'common.unarchive': 'Aus Archiv entfernen',
          'common.report': 'Melden',
          'report.reported_user': 'Gemeldeter Benutzer',
          'report.what_issue': 'Welche Art von Problem meldest du?',
          'report.thanks_title':
              'Danke, dass du uns hilfst, TurqApp fuer alle besser zu machen!',
          'report.thanks_body':
              'Wir wissen, dass deine Zeit wertvoll ist. Danke, dass du dir die Zeit nimmst, uns zu helfen.',
          'report.how_it_works_title': 'Wie geht es weiter?',
          'report.how_it_works_body':
              'Deine Meldung ist bei uns eingegangen. Wir werden das gemeldete Profil aus deinem Feed ausblenden.',
          'report.whats_next_title': 'Was passiert als Naechstes?',
          'report.whats_next_body':
              'Unser Team wird dieses Profil innerhalb weniger Tage pruefen. Wenn ein Verstoss festgestellt wird, wird das Konto eingeschraenkt. Wenn kein Verstoss festgestellt wird und du wiederholt ungueltige Meldungen eingereicht hast, kann dein Konto eingeschraenkt werden.',
          'report.optional_block_title': 'Wenn du moechtest',
          'report.optional_block_body':
              'Du kannst dieses Profil blockieren. Wenn du das tust, wird dieser Benutzer in deinem Feed ueberhaupt nicht mehr angezeigt.',
          'report.block_user_button': '@nickname blockieren',
          'report.blocked_user_label': '@nickname wurde blockiert!',
          'report.block_user_info':
              'Verhindere, dass @nickname dir folgt oder dir Nachrichten sendet. Oeffentliche Beitraege koennen weiterhin gesehen werden, aber eine Interaktion mit dir ist nicht moeglich. Du wirst ausserdem die Beitraege von @nickname nicht mehr sehen.',
          'report.select_reason_title': 'Meldegrund wählen',
          'report.select_reason_body':
              'Du musst einen Grund auswählen, um fortzufahren.',
          'report.submitted_title': 'Deine Meldung ist bei uns eingegangen!',
          'report.submitted_body':
              'Wir werden @nickname prüfen. Vielen Dank für deine Meldung.',
          'report.submitting': 'Wird gesendet...',
          'report.done': 'Fertig',
          'report.reason.impersonation.title':
              'Nachahmung / Fake-Konto / Identitaetsmissbrauch',
          'report.reason.impersonation.desc':
              'Dieses Konto oder dieser Inhalt koennte jemand anderen imitieren, eine falsche Identitaet verwenden oder ohne Erlaubnis eine andere Person darstellen.',
          'report.reason.copyright.title':
              'Urheberrecht / Unerlaubte Inhaltsnutzung',
          'report.reason.copyright.desc':
              'Dieser Inhalt verwendet moeglicherweise urheberrechtlich geschuetztes Material ohne Erlaubnis oder verletzt geistiges Eigentum.',
          'report.reason.harassment.title':
              'Belaestigung / Zielscheibe / Mobbing',
          'report.reason.harassment.desc':
              'Dieser Inhalt scheint eine Person zu belaestigen, zu demuetigen, gezielt anzugreifen oder systematisch zu mobben.',
          'report.reason.hate_speech.title': 'Hassrede',
          'report.reason.hate_speech.desc':
              'Dieser Inhalt kann Hass, Diskriminierung oder herabsetzende Sprache gegenueber einer Person oder Gruppe enthalten.',
          'report.reason.nudity.title': 'Nacktheit / Sexuelle Inhalte',
          'report.reason.nudity.desc':
              'Dieser Inhalt kann Nacktheit, Obszonitaet oder explizites sexuelles Material enthalten.',
          'report.reason.violence.title': 'Gewalt / Drohung',
          'report.reason.violence.desc':
              'Dieser Inhalt kann physische Gewalt, Drohungen, Einschuechterung oder Aufrufe zu Schaden enthalten.',
          'report.reason.spam.title':
              'Spam / Wiederholende irrelevante Inhalte',
          'report.reason.spam.desc':
              'Dieser Inhalt wirkt wiederholend, irrelevant, irrefuehrend oder stoerend wie Spam.',
          'report.reason.scam.title': 'Betrug / Taeuschung',
          'report.reason.scam.desc':
              'Dieser Inhalt kann taeuschend oder betruegerisch sein, um Vertrauen, Geld oder Informationen auszunutzen.',
          'report.reason.misinformation.title':
              'Fehlinformation / Manipulation',
          'report.reason.misinformation.desc':
              'Dieser Inhalt kann Fakten verdrehen, Fehlinformationen verbreiten oder Menschen manipulieren.',
          'report.reason.illegal_content.title': 'Illegale Inhalte',
          'report.reason.illegal_content.desc':
              'Dieser Inhalt kann illegale Aktivitaeten, kriminelle Foerderung oder rechtswidriges Material enthalten.',
          'report.reason.child_safety.title': 'Verstoss gegen Kinderschutz',
          'report.reason.child_safety.desc':
              'Dieser Inhalt kann die Sicherheit von Kindern gefaehrden oder schaedliche Elemente enthalten, die fuer Kinder ungeeignet sind.',
          'report.reason.self_harm.title':
              'Selbstverletzung / Suizidverherrlichung',
          'report.reason.self_harm.desc':
              'Dieser Inhalt kann Selbstverletzung, Suizid oder schaedliches selbstbezogenes Verhalten foerdern.',
          'report.reason.privacy_violation.title': 'Verletzung der Privatsphaere',
          'report.reason.privacy_violation.desc':
              'Dieser Inhalt kann die unbefugte Weitergabe persoenlicher Daten, Doxxing oder eine Verletzung der Privatsphaere enthalten.',
          'report.reason.fake_engagement.title':
              'Gefaelschte Interaktion / Bot / Manipulatives Wachstum',
          'report.reason.fake_engagement.desc':
              'Dieser Inhalt kann gefaelschte Likes, Bot-Aktivitaeten oder manipulatives kuenstliches Wachstum beinhalten.',
          'report.reason.other.title': 'Andere',
          'report.reason.other.desc':
              'Es koennte einen anderen Verstoss geben, der oben nicht abgedeckt ist und den du von uns pruefen lassen moechtest.',
          'common.undo': 'Rückgängig',
          'common.edited': 'bearbeitet',
          'common.delete_post_title': 'Beitrag löschen',
          'common.delete_post_message':
              'Möchtest du diesen Beitrag wirklich löschen?',
          'common.delete_post_confirm': 'Beitrag löschen',
          'common.post_share_title': 'TurqApp Beitrag',
          'common.send': 'Senden',
          'common.block': 'Blockieren',
          'common.unknown_user': 'Unbekannter Benutzer',
          'common.unknown_company': 'Unbekannte Firma',
          'common.verified': 'Bestätigt',
          'common.verify': 'Bestätigen',
          'common.message': 'Nachricht',
          'common.phone': 'Telefon',
          'common.description': 'Beschreibung',
          'common.location': 'Standort',
          'common.category': 'Kategorie',
          'common.status': 'Status',
          'common.features': 'Merkmale',
          'common.contact': 'Kontakt',
          'common.city': 'Stadt',
          'comments.input_hint': 'Was denkst du daruber?',
          'explore.tab.trending': 'Trendthemen',
          'explore.tab.for_you': 'Für dich',
          'explore.tab.series': 'Serie',
          'explore.trending_rank': '@index - im Trend in der Türkei',
          'explore.no_results': 'Keine Ergebnisse gefunden',
          'explore.no_series': 'Keine Serie gefunden',
          'feed.empty_city': 'In deiner Stadt gibt es noch keine Beiträge',
          'feed.empty_following':
              'Von den Personen, denen du folgst, gibt es noch keine Beiträge',
          'post_likes.title': 'Likes',
          'post_likes.empty': 'Es gibt noch keine Likes',
          'post_state.hidden_title': 'Beitrag ausgeblendet',
          'post_state.hidden_body':
              'Dieser Beitrag wurde ausgeblendet. Ähnliche Beiträge siehst du weiter unten im Feed.',
          'post_state.archived_title': 'Beitrag archiviert',
          'post_state.archived_body':
              'Du hast diesen Beitrag archiviert.\nEr ist nun für niemanden mehr sichtbar.',
          'post_state.deleted_title': 'Beitrag gelöscht',
          'post_state.deleted_body': 'Dieser Beitrag ist nicht mehr veröffentlicht.',
          'post.share_title': 'TurqApp Beitrag',
          'post.archive': 'Archivieren',
          'post.unarchive': 'Aus Archiv entfernen',
          'post.like_failed':
              'Die Like-Aktion konnte nicht abgeschlossen werden.',
          'post.save_failed':
              'Die Speicheraktion konnte nicht abgeschlossen werden.',
          'post.reshare_failed':
              'Die Teilen-Aktion konnte nicht abgeschlossen werden.',
          'post.report_success': 'Beitrag gemeldet.',
          'post.report_failed':
              'Die Meldung konnte nicht abgeschlossen werden.',
          'post.hide_failed': 'Das Ausblenden konnte nicht abgeschlossen werden.',
          'post.reshare_action': 'Erneut teilen',
          'post.reshare_undo': 'Erneutes Teilen ruckgangig machen',
          'post.reshared_you': 'du hast es erneut geteilt',
          'post.reshared_by': '@name hat es erneut geteilt',
          'short.next_post': 'Zum nächsten Beitrag',
          'short.publish_as_post': 'Als Beitrag veröffentlichen',
          'short.add_to_story': 'Zu deiner Story hinzufügen',
          'short.shared_as_post_by': 'Als Beitrag geteilt von',
          'story.seens_title': 'Aufrufe (@count)',
          'story.no_seens': 'Niemand hat deine Story angesehen',
          'story.comments_title': 'Kommentare (@count)',
          'story.share_title': '@name Story',
          'story.share_desc': 'Story auf TurqApp ansehen',
          'story.drawing_title': 'Zeichnung hinzufugen',
          'story.brush_color': 'Pinselfarbe',
          'story.no_comments': 'Noch keine Kommentare',
          'story.add_comment_for': 'Kommentar für @nickname hinzufügen..',
          'story.delete_message': 'Diese Story löschen?',
          'story.permanent_delete': 'Dauerhaft löschen',
          'story.permanent_delete_message':
              'Diese Story dauerhaft löschen?',
          'story.comment_delete_message':
              'Möchtest du diesen Kommentar wirklich löschen?',
          'story.deleted_stories.title': 'Storys',
          'story.deleted_stories.tab_deleted': 'Geloescht',
          'story.deleted_stories.tab_expired': 'Abgelaufen',
          'story.deleted_stories.empty': 'Es gibt keine geloeschten Storys',
          'story.deleted_stories.snackbar_title': 'Story',
          'story.deleted_stories.reposted': 'Story erneut geteilt',
          'story.deleted_stories.deleted_forever':
              'Story dauerhaft geloescht',
          'story.deleted_stories.deleted_at': 'Geloescht: @time',
          'admin_push.queue_title': 'Push',
          'admin_push.queue_body_count':
              'Push fur @count Nutzer in die Warteschlange gestellt',
          'admin_push.queue_body': 'Push in die Warteschlange gestellt',
          'admin_push.failed_body': 'Push konnte nicht gesendet werden.',
          'story_music.title': 'Musik',
          'story_music.search_hint': 'Musik suchen',
          'story_music.no_active_stories':
              'Es gibt keine aktiven Storys mit dieser Musik',
          'story_music.untitled': 'Unbenannter Titel',
          'story_music.active_story_count': '@count aktive Storys',
          'story_music.minutes_ago': '@count Min',
          'story_music.hours_ago': '@count Std',
          'story_music.days_ago': '@count T',
          'chat.attach_photos': 'Fotos',
          'chat.list_title': 'Chats',
          'chat.tab_all': 'Alle',
          'chat.tab_unread': 'Ungelesen',
          'chat.tab_archive': 'Archiv',
          'chat.empty_title': 'Du hast noch keine Chats',
          'chat.empty_body':
              'Sobald du Nachrichten austauschst, werden deine Unterhaltungen hier angezeigt.',
          'chat.action_failed':
              'Die Aktion konnte wegen eines Berechtigungs- oder Datensatzproblems nicht abgeschlossen werden',
          'chat.attach_videos': 'Videos',
          'chat.attach_location': 'Standort',
          'chat.message_hint': 'Nachricht',
          'chat.no_starred_messages': 'Keine markierten Nachrichten',
          'chat.profile_stats':
              '@followers Follower · @following folgt · @posts Beitraege',
          'chat.selected_messages': '@count Nachrichten ausgewaehlt',
          'chat.today': 'Heute',
          'chat.yesterday': 'Gestern',
          'chat.typing': 'schreibt...',
          'chat.gif': 'GIF',
          'chat.ready_to_send': 'Bereit zum Senden',
          'chat.editing_message': 'Nachricht wird bearbeitet',
          'chat.video': 'Video',
          'chat.audio': 'Audio',
          'chat.location': 'Standort',
          'chat.post': 'Beitrag',
          'chat.person': 'Person',
          'chat.reply': 'Antworten',
          'chat.recording_timer': 'Aufnahme laeuft... @time',
          'chat.fetching_address': 'Adresse wird geladen...',
          'chat.add_star': 'Stern hinzufuegen',
          'chat.remove_star': 'Stern entfernen',
          'chat.you': 'Du',
          'chat.hide_photos': 'Fotos ausblenden',
          'chat.unsent_message': 'Nachricht wurde zurueckgenommen',
          'chat.reply_prompt': 'Antworten',
          'chat.open_in_maps': 'In Karten oeffnen',
          'chat.open_in_google_maps': 'In Google Maps oeffnen',
          'chat.open_in_apple_maps': 'In Apple Maps oeffnen',
          'chat.open_in_yandex_maps': 'In Yandex Maps oeffnen',
          'chat.contact_info': 'Kontaktinfo',
          'chat.save_to_contacts': 'Zu Kontakten hinzufuegen',
          'chat.call': 'Anrufen',
          'chat.delete_message_title': 'Nachricht loeschen',
          'chat.delete_message_body':
              'Moechtest du diese Nachricht wirklich loeschen?',
          'chat.delete_for_me': 'Nur fuer mich loeschen',
          'chat.delete_for_everyone': 'Fuer alle loeschen',
          'chat.delete_photo_title': 'Foto loeschen',
          'chat.delete_photo_body':
              'Moechtest du dieses Foto wirklich loeschen?',
          'chat.delete_photo_confirm': 'Foto loeschen',
          'chat.messages_delete_failed':
              'Nachrichten konnten nicht geloescht werden',
          'chat.image_upload_failed': 'Bild konnte nicht hochgeladen werden',
          'chat.image_upload_failed_with_error':
              'Bild konnte nicht hochgeladen werden: @error',
          'chat.video_upload_failed':
              'Beim Hochladen des Videos ist ein Fehler aufgetreten',
          'chat.microphone_permission_required': 'Berechtigung erforderlich',
          'chat.microphone_permission_denied':
              'Mikrofonberechtigung wurde nicht erteilt',
          'chat.voice_record_start_failed':
              'Sprachaufnahme konnte nicht gestartet werden',
          'chat.voice_message_upload_failed':
              'Beim Hochladen der Sprachnachricht ist ein Fehler aufgetreten',
          'chat.message_send_failed':
              'Nachricht konnte nicht gesendet werden. Bitte erneut versuchen.',
          'chat.shared_post_from': '@nickname s Beitrag gesendet',
          'chat.notif_video': 'Hat ein Video gesendet',
          'chat.notif_audio': 'Hat eine Sprachnachricht gesendet',
          'chat.notif_images': 'Hat @count Bilder gesendet',
          'chat.notif_post': 'Hat einen Beitrag geteilt',
          'chat.notif_location': 'Hat einen Standort gesendet',
          'chat.notif_contact': 'Hat einen Kontakt geteilt',
          'chat.notif_gif': 'Hat ein GIF gesendet',
          'chat.reply_target_missing':
              'Die beantwortete Nachricht konnte nicht gefunden werden',
          'chat.forwarded_title': 'Weitergeleitet',
          'chat.forwarded_body':
              'Die Nachricht wurde an den ausgewaehlten Chat weitergeleitet',
          'chat.tap_to_chat': 'Tippe, um den Chat zu starten.',
          'chat.photo': 'Foto',
          'chat.message_label': 'Nachricht',
          'chat.marked_unread': 'Chat als ungelesen markiert',
          'chat.limit_title': 'Limit',
          'chat.pin_limit': 'Es koennen maximal 5 Chats angeheftet werden',
          'chat.action_completed': 'Aktion abgeschlossen',
          'chat.muted': 'Chat stummgeschaltet',
          'chat.unmuted': 'Chat lautgeschaltet',
          'chat.archived': 'Chat ins Archiv verschoben',
          'chat.unarchived': 'Chat aus dem Archiv entfernt',
          'chat.delete_title': 'Chat loeschen',
          'chat.delete_message':
              'Moechtest du diesen Chat wirklich loeschen?',
          'chat.delete_confirm': 'Chat loeschen',
          'chat.deleted_title': 'Chat geloescht',
          'chat.deleted_body':
              'Der ausgewaehlte Chat wurde erfolgreich geloescht',
          'chat.unmute': 'Ton einschalten',
          'chat.mute': 'Stummschalten',
          'chat.mark_unread': 'Als ungelesen markieren',
          'chat.pin': 'Anheften',
          'chat.unpin': 'Loesen',
          'chat.muted_label': 'Stumm',
          'training.comments_title': 'Kommentare',
          'training.no_comments': 'Noch keine Kommentare.',
          'training.reply': 'Antworten',
          'training.hide_replies': 'Antworten ausblenden',
          'training.view_replies': '@count Antworten anzeigen',
          'training.unknown_user': 'Unbekannter Benutzer',
          'training.edit': 'Bearbeiten',
          'training.report': 'Melden',
          'training.reply_to_user': '@name antworten',
          'training.cancel': 'Abbrechen',
          'training.edit_comment_hint': 'Kommentar bearbeiten',
          'training.write_hint': 'Schreiben..',
          'training.pick_from_gallery': 'Aus Galerie waehlen',
          'training.take_photo': 'Foto aufnehmen',
          'training.time_now': 'gerade eben',
          'training.time_min': 'vor @count Min',
          'training.time_hour': 'vor @count Std',
          'training.time_day': 'vor @count T',
          'training.time_week': 'vor @count Wo',
          'training.photo_pick_failed':
              'Beim Auswaehlen des Fotos ist ein Fehler aufgetreten!',
          'training.photo_upload_failed':
              'Beim Hochladen des Fotos ist ein Fehler aufgetreten!',
          'training.question_bank_title': 'Fragenbank',
          'training.questions_loading': 'Fragen werden geladen...',
          'training.solve_later_empty':
              'Keine Später-lösen-Fragen gefunden!',
          'training.remove_solve_later': 'Aus Später lösen entfernen',
          'training.no_questions': 'Keine Fragen gefunden!',
          'training.answer_first': 'Beantworte zuerst die Frage!',
          'training.share': 'Teilen',
          'training.correct_ratio': '%@value Richtig',
          'training.wrong_ratio': '%@value Falsch',
          'training.complaint_select_one':
              'Bitte wähle mindestens eine Meldeoption aus.',
          'training.complaint_thanks':
              'Danke für deinen Hinweis.',
          'training.complaint_submit_failed':
              'Beim Senden deiner Meldung ist ein Fehler aufgetreten.',
          'training.no_questions_in_category':
              'In dieser Kategorie wurden keine Fragen gefunden.',
          'training.saved_load_failed':
              'Beim Laden gespeicherter Fragen ist ein Fehler aufgetreten.',
          'training.view_update_failed':
              'Beim Aktualisieren der Ansicht ist ein Fehler aufgetreten.',
          'training.saved_removed':
              'Frage aus Später-lösen-Liste entfernt!',
          'training.saved_added':
              'Frage zur Später-lösen-Liste hinzugefügt!',
          'training.saved_remove_failed':
              'Beim Entfernen aus Später lösen ist ein Fehler aufgetreten.',
          'training.saved_update_failed':
              'Beim Aktualisieren von Später lösen ist ein Fehler aufgetreten.',
          'training.like_removed': 'Gefällt mir entfernt!',
          'training.liked': 'Frage mit Gefällt mir markiert!',
          'training.like_remove_failed':
              'Beim Entfernen von Gefällt mir ist ein Fehler aufgetreten.',
          'training.like_add_failed':
              'Beim Hinzufügen von Gefällt mir ist ein Fehler aufgetreten.',
          'training.share_failed':
              'Teilen konnte nicht gestartet werden',
          'training.share_question_link_title':
              '@exam - @lesson Frage @number',
          'training.share_question_title':
              'TurqApp - @exam @lesson Frage',
          'training.share_question_desc': 'Frage aus der TurqApp Fragenbank',
          'training.leaderboard_empty':
              'Es wurde noch keine Rangliste erstellt.',
          'training.leaderboard_empty_body':
              'Löse Fragen in der Fragenbank, um in die Rangliste zu kommen.',
          'training.answer_locked':
              'Du kannst die Antwort auf diese Frage nicht ändern!',
          'training.answer_saved':
              'Die Antwort auf diese Frage wurde bereits gespeichert.',
          'training.answer_save_failed':
              'Beim Speichern der Antwort ist ein Fehler aufgetreten',
          'training.no_more_questions':
              'In dieser Kategorie gibt es keine weiteren Fragen!',
          'training.settings_opening': 'Einstellungsbildschirm wird geöffnet!',
          'training.fetch_more_failed':
              'Beim Laden weiterer Fragen ist ein Fehler aufgetreten',
          'training.comments_load_failed':
              'Beim Laden der Kommentare ist ein Fehler aufgetreten. Bitte versuche es erneut!',
          'training.comment_or_photo_required':
              'Du musst einen Kommentar oder ein Foto hinzufuegen!',
          'training.reply_or_photo_required':
              'Du musst eine Antwort oder ein Foto hinzufuegen!',
          'training.comment_added': 'Dein Kommentar wurde hinzugefuegt!',
          'training.comment_add_failed':
              'Beim Hinzufuegen des Kommentars ist ein Fehler aufgetreten. Bitte versuche es erneut!',
          'training.reply_added': 'Deine Antwort wurde hinzugefuegt!',
          'training.reply_add_failed':
              'Beim Hinzufuegen der Antwort ist ein Fehler aufgetreten. Bitte versuche es erneut!',
          'training.comment_deleted': 'Dein Kommentar wurde geloescht!',
          'training.comment_delete_failed':
              'Beim Loeschen des Kommentars ist ein Fehler aufgetreten. Bitte versuche es erneut!',
          'training.reply_deleted': 'Deine Antwort wurde geloescht!',
          'training.reply_delete_failed':
              'Beim Loeschen der Antwort ist ein Fehler aufgetreten. Bitte versuche es erneut!',
          'training.comment_updated': 'Dein Kommentar wurde aktualisiert!',
          'training.comment_update_failed':
              'Beim Bearbeiten des Kommentars ist ein Fehler aufgetreten. Bitte versuche es erneut!',
          'training.reply_updated': 'Deine Antwort wurde aktualisiert!',
          'training.reply_update_failed':
              'Beim Bearbeiten der Antwort ist ein Fehler aufgetreten. Bitte versuche es erneut!',
          'training.like_failed':
              'Beim Like-Vorgang ist ein Fehler aufgetreten. Bitte versuche es erneut!',
          'training.upload_failed_title': 'Upload fehlgeschlagen!',
          'training.upload_failed_body':
              'Dieser Inhalt kann derzeit nicht verarbeitet werden. Bitte versuche einen anderen Inhalt.',
          'common.accept': 'Annehmen',
          'common.reject': 'Ablehnen',
          'common.open_profile': 'Profil oeffnen',
          'tutoring.title': 'Nachhilfe',
          'tutoring.search_hint': 'Nach welcher Art Unterricht suchst du?',
          'tutoring.my_applications': 'Meine Bewerbungen',
          'tutoring.create_listing': 'Anzeige erstellen',
          'tutoring.my_listings': 'Meine Anzeigen',
          'tutoring.saved': 'Gespeichert',
          'tutoring.slider_admin': 'Slider-Verwaltung',
          'tutoring.review_title': 'Bewertung abgeben',
          'tutoring.review_hint': 'Schreibe deinen Kommentar (optional)',
          'tutoring.review_select_rating':
              'Bitte waehle eine Bewertung aus.',
          'tutoring.review_saved': 'Deine Bewertung wurde gespeichert.',
          'tutoring.applicants_title': 'Bewerber',
          'tutoring.no_applications': 'Es gibt noch keine Bewerbungen',
          'tutoring.application_label': 'Nachhilfe-Bewerbung',
          'tutoring.my_applications_empty':
              'Du hast noch keine Nachhilfe-Bewerbungen gesendet',
          'tutoring.instructor_fallback': 'Lehrkraft',
          'tutoring.cancel_application_title': 'Bewerbung abbrechen',
          'tutoring.cancel_application_body':
              'Möchtest du diese Bewerbung wirklich abbrechen?',
          'tutoring.cancel_application_action': 'Bewerbung abbrechen',
          'tutoring.my_listings_title': 'Meine Anzeigen',
          'tutoring.published': 'Veröffentlicht',
          'tutoring.expired': 'Abgelaufen',
          'tutoring.active_listings_empty':
              'Es gibt keine aktiven Nachhilfeanzeigen.',
          'tutoring.expired_listings_empty':
              'Es gibt keine abgelaufenen Nachhilfeanzeigen.',
          'tutoring.user_id_missing':
              'Benutzerkennung konnte nicht gefunden werden.',
          'tutoring.load_failed':
              'Beim Laden der Anzeigen ist ein Fehler aufgetreten: {error}',
          'tutoring.reactivated_title': 'Anzeige reaktiviert',
          'tutoring.reactivated_body':
              'Die Anzeige wurde erneut veröffentlicht.',
          'tutoring.user_load_failed':
              'Beim Laden der Benutzerinformationen ist ein Fehler aufgetreten: {error}',
          'tutoring.location_missing': 'Standort nicht gefunden',
          'tutoring.no_listings_in_region':
              'In dieser Region gibt es keine Nachhilfeanzeigen.',
          'tutoring.no_lessons_in_category':
              'In der Kategorie {category} gibt es keine Kurse.',
          'tutoring.search_empty':
              'Es wurde keine passende Anzeige für deine Suche gefunden.',
          'tutoring.search_empty_info':
              'Es wurde keine passende Nachhilfeanzeige gefunden!',
          'tutoring.similar_listings': 'Ähnliche Anzeigen',
          'tutoring.open_listing': 'Anzeige öffnen',
          'tutoring.report_listing': 'Anzeige melden',
          'tutoring.saved_empty': 'Keine gespeicherten Anzeigen.',
          'tutoring.detail_description': 'Beschreibung',
          'tutoring.detail_no_description':
              'Für diese Anzeige wurde keine Beschreibung hinzugefügt.',
          'tutoring.detail_lesson_info': 'Unterrichtsinformationen',
          'tutoring.detail_branch': 'Fachbereich',
          'tutoring.detail_price': 'Preis',
          'tutoring.detail_contact': 'Kontakt',
          'tutoring.detail_phone_and_message': 'Telefon + Nachricht',
          'tutoring.detail_message_only': 'Nur Nachricht',
          'tutoring.detail_gender_preference': 'Geschlechtspräferenz',
          'tutoring.detail_availability': 'Verfügbarkeit',
          'tutoring.detail_listing_info': 'Anzeigeninformationen',
          'tutoring.detail_instructor': 'Lehrkraft',
          'tutoring.detail_not_specified': 'Nicht angegeben',
          'tutoring.detail_city': 'Stadt',
          'tutoring.detail_views': 'Aufrufe',
          'tutoring.detail_status': 'Status',
          'tutoring.detail_status_passive': 'Passiv',
          'tutoring.detail_status_active': 'Aktiv',
          'tutoring.detail_location': 'Standort',
          'tutoring.create.city_select': 'Stadt auswählen',
          'tutoring.create.district_select': 'Bezirk auswählen',
          'tutoring.create.nsfw_check_failed':
              'Die NSFW-Bildprüfung ist fehlgeschlagen.',
          'tutoring.create.nsfw_detected':
              'Es wurde ein unangemessenes Bild erkannt.',
          'tutoring.create.fill_required':
              'Bitte füllen Sie alle Pflichtfelder aus!',
          'tutoring.create.published':
              'Die Nachhilfeanzeige wurde veröffentlicht!',
          'tutoring.create.publish_failed':
              'Beim Veröffentlichen der Anzeige ist ein Fehler aufgetreten.',
          'tutoring.create.updated': 'Anzeige aktualisiert!',
          'tutoring.create.no_changes':
              'Es wurden keine Änderungen vorgenommen!',
          'tutoring.create.update_failed':
              'Beim Aktualisieren der Anzeige ist ein Fehler aufgetreten.',
          'tutoring.call_disabled':
              'Anrufe sind für diese Anzeige deaktiviert.',
          'tutoring.message': 'Nachricht',
          'tutoring.messages': 'Nachrichten',
          'tutoring.phone_missing':
              'Die Telefonnummer des Lehrers wurde nicht gefunden.',
          'tutoring.phone_open_failed':
              'Die Telefon-App konnte nicht geöffnet werden.',
          'tutoring.unpublish_title': 'Anzeige entfernen',
          'tutoring.unpublish_body':
              'Möchtest du diese Nachhilfeanzeige wirklich aus der Veröffentlichung entfernen?',
          'tutoring.unpublished':
              'Die Anzeige wurde aus der Veröffentlichung entfernt.',
          'tutoring.apply_login_required':
              'Bitte melden Sie sich erneut an, um sich zu bewerben.',
          'tutoring.application_sent':
              'Deine Bewerbung wurde gesendet.',
          'tutoring.application_failed':
              'Während der Bewerbung ist ein Problem aufgetreten.',
          'tutoring.delete_success': 'Anzeige gelöscht!',
          'tutoring.delete_failed':
              'Beim Löschen der Anzeige ist ein Fehler aufgetreten.',
          'tutoring.filter_title': 'Filter',
          'tutoring.gender_title': 'Geschlecht',
          'tutoring.sort_title': 'Sortierung',
          'tutoring.lesson_place_title': 'Unterrichtsort',
          'tutoring.service_location_title': 'Angebotsort',
          'tutoring.gender.male': 'Männlich',
          'tutoring.gender.female': 'Weiblich',
          'tutoring.gender.any': 'Egal',
          'tutoring.sort.latest': 'Neueste',
          'tutoring.sort.nearest': 'In meiner Nähe',
          'tutoring.sort.most_viewed': 'Am meisten angesehen',
          'tutoring.lesson_place.student_home': 'Beim Schüler zu Hause',
          'tutoring.lesson_place.teacher_home': 'Beim Lehrer zu Hause',
          'tutoring.lesson_place.either_home':
              'Beim Schüler oder Lehrer zu Hause',
          'tutoring.lesson_place.remote': 'Fernunterricht',
          'tutoring.lesson_place.lesson_area': 'Unterrichtsbereich',
          'tutoring.branch.summer_school': 'Sommerschule',
          'tutoring.branch.secondary_education': 'Sekundarstufe',
          'tutoring.branch.primary_education': 'Grundschule',
          'tutoring.branch.foreign_language': 'Fremdsprache',
          'tutoring.branch.software': 'Software',
          'tutoring.branch.driving': 'Fahrunterricht',
          'tutoring.branch.sports': 'Sport',
          'tutoring.branch.art': 'Kunst',
          'tutoring.branch.music': 'Musik',
          'tutoring.branch.theatre': 'Theater',
          'tutoring.branch.personal_development': 'Persönliche Entwicklung',
          'tutoring.branch.vocational': 'Beruflich',
          'tutoring.branch.special_education': 'Sonderpädagogik',
          'tutoring.branch.children': 'Kinder',
          'tutoring.branch.diction': 'Diktion',
          'tutoring.branch.photography': 'Fotografie',
          'scholarship.applications_title': 'Bewerbungen (@count)',
          'scholarship.no_applications': 'Es gibt noch keine Bewerbungen',
          'scholarship.my_listings': 'Meine Stipendienanzeigen',
          'scholarship.no_my_listings': 'Du hast keine Stipendienanzeigen!',
          'scholarship.applications_suffix': '@title STIPENDIENBEWERBUNGEN',
          'scholarship.my_applications_title': 'Meine Stipendienbewerbungen',
          'scholarship.no_user_applications':
              'Du hast keine Stipendienbewerbungen!',
          'scholarship.saved_empty':
              'Keine gespeicherten Stipendien gefunden.',
          'scholarship.liked_empty':
              'Keine mit Gefällt mir markierten Stipendien gefunden.',
          'scholarship.remove_saved': 'Aus Gespeichert entfernen',
          'scholarship.remove_liked': 'Aus Gefällt mir entfernen',
          'scholarship.remove_saved_confirm':
              'Möchtest du dieses Stipendium wirklich aus den gespeicherten Einträgen entfernen?',
          'scholarship.remove_liked_confirm':
              'Möchtest du dieses Stipendium wirklich aus den Gefällt-mir-Einträgen entfernen?',
          'scholarship.removed_saved':
              'Stipendium aus den gespeicherten Einträgen entfernt.',
          'scholarship.removed_liked':
              'Stipendium aus den Gefällt-mir-Einträgen entfernt.',
          'scholarship.list_title': 'Stipendien (@count)',
          'scholarship.search_results_title': 'Suchergebnisse (@count)',
          'scholarship.empty_title': 'Noch keine Stipendien',
          'scholarship.empty_body': 'Neue Stipendien werden bald hinzugefügt',
          'scholarship.no_results_for':
              'Keine Ergebnisse für "@query" gefunden',
          'scholarship.search_hint_body':
              'Tipp: Versuche andere Schlüsselwörter',
          'scholarship.search_tip_header': 'Du kannst suchen nach:',
          'scholarship.load_more_failed':
              'Weitere Stipendien konnten nicht geladen werden.',
          'scholarship.like_failed': 'Like-Aktion fehlgeschlagen.',
          'scholarship.bookmark_failed':
              'Speicher-Aktion fehlgeschlagen.',
          'scholarship.share_owner_only':
              'Nur Admins und der Anzeigeninhaber können teilen.',
          'scholarship.share_missing_id':
              'Die Stipendien-ID für das Teilen wurde nicht gefunden.',
          'scholarship.share_failed': 'Teilen fehlgeschlagen.',
          'scholarship.share_fallback_desc': 'TurqApp Stipendienanzeige',
          'scholarship.share_detail_title':
              'TurqApp Bildung - Stipendiendetail',
          'scholarship.providers_title': 'Stipendiengeber',
          'scholarship.providers_empty':
              'Es wurden keine Stipendiengeber gefunden.',
          'scholarship.providers_load_failed':
              'Stipendiengeber konnten nicht geladen werden.',
          'scholarship.applications_load_failed':
              'Bewerbungen konnten nicht geladen werden.',
          'scholarship.withdraw_application': 'Bewerbung zurückziehen',
          'scholarship.withdraw_confirm_title': 'Achtung!',
          'scholarship.withdraw_confirm_body':
              'Möchtest du deine Bewerbung wirklich zurückziehen?',
          'scholarship.withdraw_success':
              'Deine Stipendienbewerbung wurde zurückgezogen.',
          'scholarship.withdraw_failed':
              'Die Bewerbung konnte nicht zurückgezogen werden.',
          'scholarship.session_missing':
              'Benutzersitzung ist nicht aktiv.',
          'scholarship.create_title': 'Stipendium erstellen',
          'scholarship.edit_title': 'Stipendium bearbeiten',
          'scholarship.preview_title': 'Stipendienvorschau',
          'scholarship.visual_info': 'Bildinformationen',
          'scholarship.basic_info': 'Grundinformationen',
          'scholarship.application_info': 'Bewerbungsinformationen',
          'scholarship.extra_info': 'Zusätzliche Informationen',
          'scholarship.title_label': 'Stipendientitel',
          'scholarship.provider_label': 'Stipendiengeber',
          'scholarship.website_label': 'Webseite',
          'scholarship.description_help':
              'Bitte schreibe die Stipendienbeschreibung in einem klaren Abschnitt.',
          'scholarship.no_description': 'Keine Beschreibung',
          'scholarship.conditions_label': 'Bewerbungsbedingungen',
          'scholarship.required_docs_label': 'Erforderliche Unterlagen',
          'scholarship.award_months_label': 'Fördermonate',
          'scholarship.application_place_label': 'Bewerbungsort',
          'scholarship.application_place_turqapp': 'TurqApp',
          'scholarship.application_place_website': 'Stipendien-Webseite',
          'scholarship.application_website_label': 'Stipendien-Webseite',
          'scholarship.application_dates_label': 'Bewerbungsdaten',
          'scholarship.detail_missing':
              'Fehler: Stipendiendaten wurden nicht gefunden.',
          'scholarship.detail_title': 'Stipendiendetail',
          'scholarship.delete_title': 'Stipendium löschen',
          'scholarship.delete_confirm':
              'Möchtest du dieses Stipendium wirklich löschen?',
          'scholarship.applications_heading': '@title Stipendienbewerbungen',
          'scholarship.applicant.personal_section': 'Persönliche Daten',
          'scholarship.applicant.education_section': 'Bildungsinformationen',
          'scholarship.applicant.family_section': 'Familieninformationen',
          'scholarship.applicant.full_name': 'Vollständiger Name',
          'scholarship.applicant.email': 'E-Mail-Adresse',
          'scholarship.applicant.phone': 'Telefonnummer',
          'scholarship.applicant.phone_open_failed':
              'Telefonanruf konnte nicht gestartet werden',
          'scholarship.applicant.email_open_failed':
              'E-Mail-Programm konnte nicht geöffnet werden',
          'chat.sign_in_required':
              'Du musst dich anmelden, um eine Nachricht zu senden.',
          'chat.cannot_message_self_listing':
              'Du kannst deiner eigenen Anzeige keine Nachricht senden.',
          'scholarship.applicant.country': 'Land',
          'scholarship.applicant.registry_city': 'Meldestadt',
          'scholarship.applicant.registry_district': 'Meldebezirk',
          'scholarship.applicant.birth_date': 'Geburtsdatum',
          'scholarship.applicant.marital_status': 'Familienstand',
          'scholarship.applicant.gender': 'Geschlecht',
          'scholarship.applicant.disability_report': 'Behindertenbericht',
          'scholarship.applicant.employment_status': 'Beschäftigungsstatus',
          'scholarship.applicant.education_level': 'Bildungsniveau',
          'scholarship.applicant.university': 'Universität',
          'scholarship.applicant.faculty': 'Fakultät',
          'scholarship.applicant.department': 'Abteilung',
          'scholarship.applicant.father_alive': 'Lebt der Vater?',
          'scholarship.applicant.father_name': 'Name des Vaters',
          'scholarship.applicant.father_surname': 'Nachname des Vaters',
          'scholarship.applicant.father_phone': 'Telefon des Vaters',
          'scholarship.applicant.father_job': 'Beruf des Vaters',
          'scholarship.applicant.father_income': 'Einkommen des Vaters',
          'scholarship.applicant.mother_alive': 'Lebt die Mutter?',
          'scholarship.applicant.mother_name': 'Name der Mutter',
          'scholarship.applicant.mother_surname': 'Nachname der Mutter',
          'scholarship.applicant.mother_phone': 'Telefon der Mutter',
          'scholarship.applicant.mother_job': 'Beruf der Mutter',
          'scholarship.applicant.mother_income': 'Einkommen der Mutter',
          'scholarship.applicant.home_ownership': 'Wohneigentum',
          'scholarship.applicant.residence_city': 'Wohnstadt',
          'scholarship.applicant.residence_district': 'Wohnbezirk',
          'family_info.title': 'Familieninformationen',
          'family_info.reset_menu': 'Familieninformationen zurücksetzen',
          'family_info.reset_title': 'Familieninformationen zurücksetzen',
          'family_info.reset_body':
              'Alle Familieninformationen werden gelöscht. Dieser Vorgang kann nicht rückgängig gemacht werden. Bist du sicher?',
          'family_info.select_father_alive':
              'Bitte wähle aus, ob dein Vater lebt',
          'family_info.select_mother_alive':
              'Bitte wähle aus, ob deine Mutter lebt',
          'family_info.father_name_surname': 'Name - Nachname des Vaters',
          'family_info.mother_name_surname': 'Name - Nachname der Mutter',
          'family_info.select_job': 'Beruf wählen',
          'family_info.father_salary': 'Nettogehalt des Vaters',
          'family_info.mother_salary': 'Nettogehalt der Mutter',
          'family_info.father_phone': 'Telefonnummer des Vaters',
          'family_info.mother_phone': 'Telefonnummer der Mutter',
          'family_info.salary_hint': 'Nettogehalt',
          'family_info.family_size': 'Familiengröße',
          'family_info.family_size_hint': 'Anzahl der Haushaltsmitglieder (einschließlich dir)',
          'family_info.residence_info': 'Wohnsitzinformationen',
          'family_info.father_salary_missing': 'Gehaltsangabe des Vaters',
          'family_info.father_phone_missing': 'Telefonnummer des Vaters',
          'family_info.father_phone_invalid':
              'Die Telefonnummer des Vaters muss 10-stellig sein',
          'family_info.mother_salary_missing': 'Gehaltsangabe der Mutter',
          'family_info.mother_phone_missing': 'Telefonnummer der Mutter',
          'family_info.mother_phone_invalid':
              'Die Telefonnummer der Mutter muss 10-stellig sein',
          'family_info.saved': 'Deine Familieninformationen wurden gespeichert.',
          'family_info.save_failed':
              'Die Informationen konnten nicht gespeichert werden.',
          'family_info.reset_success':
              'Die Familieninformationen wurden zurückgesetzt.',
          'family_info.reset_failed':
              'Die Informationen konnten nicht zurückgesetzt werden.',
          'family_info.home_owned': 'Eigenes Haus',
          'family_info.home_relative': 'Haus eines Verwandten',
          'family_info.home_lodging': 'Dienstwohnung',
          'family_info.home_rent': 'Miete',
          'personal_info.title': 'Persönliche Informationen',
          'personal_info.reset_menu': 'Meine Informationen zurücksetzen',
          'personal_info.reset_title': 'Bist du sicher?',
          'personal_info.reset_body':
              'Deine persönlichen Informationen werden zurückgesetzt. Dieser Vorgang kann nicht rückgängig gemacht werden.',
          'personal_info.reset_success':
              'Deine persönlichen Informationen wurden zurückgesetzt.',
          'personal_info.registry_info': 'Meldeort - Bezirk',
          'personal_info.birth_date_title': 'Dein Geburtsdatum',
          'personal_info.select_birth_date': 'Geburtsdatum wählen',
          'personal_info.select_marital_status': 'Familienstand wählen',
          'personal_info.select_gender': 'Geschlecht wählen',
          'personal_info.select_disability': 'Behinderungsstatus wählen',
          'personal_info.select_employment': 'Beschäftigungsstatus wählen',
          'personal_info.select_field': '@field wählen',
          'personal_info.city_load_failed':
              'Stadt- und Bezirksdaten konnten nicht geladen werden.',
          'personal_info.user_data_missing':
              'Benutzerdaten wurden nicht gefunden. Du kannst einen neuen Eintrag erstellen.',
          'personal_info.load_failed': 'Daten konnten nicht geladen werden.',
          'personal_info.select_country_error': 'Bitte wähle ein Land.',
          'personal_info.fill_city_district':
              'Bitte fülle Stadt und Bezirk aus.',
          'personal_info.saved':
              'Deine persönlichen Informationen wurden gespeichert.',
          'personal_info.save_failed':
              'Die Informationen konnten nicht gespeichert werden.',
          'personal_info.marital_single': 'Ledig',
          'personal_info.marital_married': 'Verheiratet',
          'personal_info.marital_divorced': 'Geschieden',
          'personal_info.gender_male': 'Männlich',
          'personal_info.gender_female': 'Weiblich',
          'personal_info.disability_yes': 'Vorhanden',
          'personal_info.disability_no': 'Keine',
          'personal_info.working_yes': 'Beschäftigt',
          'personal_info.working_no': 'Nicht beschäftigt',
          'education_info.title': 'Bildungsinformationen',
          'education_info.reset_menu':
              'Meine Bildungsinformationen zurücksetzen',
          'education_info.reset_title': 'Bist du sicher?',
          'education_info.reset_body':
              'Deine Bildungsinformationen werden zurückgesetzt. Dieser Vorgang kann nicht rückgängig gemacht werden.',
          'education_info.reset_success':
              'Deine Bildungsinformationen wurden zurückgesetzt.',
          'education_info.select_level':
              'Bitte wähle zuerst ein Bildungsniveau aus!',
          'education_info.middle_school': 'Schule',
          'education_info.high_school': 'Gymnasium',
          'education_info.class_level': 'Klasse',
          'education_info.level_middle_school': 'Mittelschule',
          'education_info.level_high_school': 'Gymnasium',
          'education_info.level_associate': 'Associate',
          'education_info.level_bachelor': 'Bachelor',
          'education_info.level_masters': 'Master',
          'education_info.level_doctorate': 'Doktorat',
          'education_info.class_grade': '@grade. Klasse',
          'education_info.select_field': '@field wählen',
          'education_info.initial_load_failed':
              'Die Anfangsdaten konnten nicht geladen werden.',
          'education_info.countries_load_failed':
              'Länder konnten nicht geladen werden.',
          'education_info.city_data_failed':
              'Stadt- und Bezirksdaten konnten nicht geladen werden.',
          'education_info.middle_schools_failed':
              'Schuldaten konnten nicht geladen werden.',
          'education_info.high_schools_failed':
              'Gymnasialdaten konnten nicht geladen werden.',
          'education_info.higher_education_failed':
              'Hochschuldaten konnten nicht geladen werden.',
          'education_info.saved_data_failed':
              'Gespeicherte Daten konnten nicht geladen werden.',
          'education_info.level_load_failed':
              'Stufendaten konnten nicht geladen werden.',
          'education_info.select_city_error':
              'Bitte wähle eine Stadt aus.',
          'education_info.select_district_error':
              'Bitte wähle einen Bezirk aus.',
          'education_info.select_middle_school_error':
              'Bitte wähle eine Mittelschule aus.',
          'education_info.select_high_school_error':
              'Bitte wähle ein Gymnasium aus.',
          'education_info.select_class_level_error':
              'Bitte wähle eine Klassenstufe aus.',
          'education_info.select_university_error':
              'Bitte wähle eine Universität aus.',
          'education_info.select_faculty_error':
              'Bitte wähle eine Fakultät aus.',
          'education_info.select_department_error':
              'Bitte wähle eine Abteilung aus.',
          'education_info.saved':
              'Deine Bildungsinformationen wurden gespeichert.',
          'education_info.save_failed': 'Speichern fehlgeschlagen.',
          'bank_info.title': 'Bankinformationen',
          'bank_info.reset_menu': 'Meine Bankinformationen zurücksetzen',
          'bank_info.reset_title': 'Bist du sicher?',
          'bank_info.reset_body':
              'Deine Bankinformationen werden zurückgesetzt. Dieser Vorgang kann nicht rückgängig gemacht werden.',
          'bank_info.reset_success':
              'Deine Bankinformationen wurden zurückgesetzt.',
          'bank_info.fast_title': 'Einfache Adresse (FAST)',
          'bank_info.fast_email': 'E-Mail',
          'bank_info.fast_phone': 'Telefon',
          'bank_info.fast_iban': 'IBAN',
          'bank_info.bank_label': 'Bank',
          'bank_info.select_bank': 'Bank wählen',
          'bank_info.select_fast_type': 'Typ der einfachen Adresse wählen',
          'bank_info.load_failed': 'Daten konnten nicht geladen werden.',
          'bank_info.missing_value':
              'Ohne vollständige IBAN-Angabe können wir nicht fortfahren.',
          'bank_info.missing_bank':
              'Du hast keine Bank für den Zahlungseingang ausgewählt. Diese Information wird geteilt, falls dein Stipendium genehmigt wird.',
          'bank_info.invalid_email':
              'Bitte gib eine gültige E-Mail-Adresse ein.',
          'bank_info.saved': 'Bankinformationen wurden gespeichert.',
          'bank_info.save_failed':
              'Die Informationen konnten nicht gespeichert werden.',
          'dormitory.title': 'Wohnheiminformationen',
          'dormitory.reset_menu': 'Meine Wohnheiminformationen zurücksetzen',
          'dormitory.reset_title': 'Bist du sicher?',
          'dormitory.reset_body':
              'Deine Wohnheiminformationen werden zurückgesetzt. Dieser Vorgang kann nicht rückgängig gemacht werden.',
          'dormitory.reset_success':
              'Deine Wohnheiminformationen wurden zurückgesetzt.',
          'dormitory.current_info': 'Aktuelle Wohnheiminformation',
          'dormitory.select_admin_type': 'Verwaltungsart wählen',
          'dormitory.admin_public': 'Staatlich',
          'dormitory.admin_private': 'Privat',
          'dormitory.select_dormitory': 'Wohnheim wählen',
          'dormitory.not_found_for_filters':
              'Für diese Stadt und Verwaltungsart wurde kein Wohnheim gefunden',
          'dormitory.saved': 'Deine Wohnheiminformationen wurden gespeichert.',
          'dormitory.save_failed': 'Die Daten konnten nicht gespeichert werden.',
          'dormitory.select_or_enter':
              'Bitte wähle ein Wohnheim oder gib einen Namen ein',
          'scholarship.application_start_date': 'Bewerbungsbeginn',
          'scholarship.application_end_date': 'Bewerbungsende',
          'scholarship.select_from_list': 'Aus Liste wählen',
          'scholarship.image_missing': 'Kein Bild gefunden',
          'scholarship.amount_label': 'Betrag',
          'scholarship.student_count_label': 'Anzahl der Studierenden',
          'scholarship.repayable_label': 'Rückzahlbar',
          'scholarship.duplicate_status_label': 'Mehrfachstatus',
          'scholarship.education_audience_label': 'Bildungszielgruppe',
          'scholarship.target_audience_label': 'Zielgruppe',
          'scholarship.country_label': 'Land',
          'scholarship.cities_label': 'Städte',
          'scholarship.universities_label': 'Universitäten',
          'scholarship.published_at': 'Veröffentlichungsdatum',
          'scholarship.show_less': 'Weniger anzeigen',
          'scholarship.show_all': 'Alle anzeigen',
          'scholarship.more_universities': '+@count weitere Universitäten',
          'scholarship.other_info': 'Weitere Informationen',
          'scholarship.application_how': 'Wie kann man sich bewerben?',
          'scholarship.application_via_turqapp_prefix':
              'Bewerbungen über TurqApp werden ',
          'scholarship.application_received_status': 'ANGENOMMEN.',
          'scholarship.application_not_received_status':
              'NICHT ANGENOMMEN.',
          'scholarship.edit_button': 'Stipendium bearbeiten',
          'scholarship.website_open_failed':
              'Die Webseite konnte nicht geöffnet werden. Bitte gib eine gültige URL ein.',
          'scholarship.checking_info': 'Informationen werden geprüft',
          'scholarship.user_data_missing':
              'Benutzerdaten konnten nicht gefunden werden. Bitte vervollständigen Sie Ihre Angaben.',
          'scholarship.check_info_failed':
              'Beim Prüfen der Informationen ist ein Fehler aufgetreten.',
          'scholarship.application_check_failed':
              'Beim Prüfen des Bewerbungsstatus ist ein Fehler aufgetreten.',
          'scholarship.login_required': 'Bitte melden Sie sich an.',
          'scholarship.profile_missing':
              'Für dieses Stipendium sind keine Profilinformationen verfügbar.',
          'scholarship.applied_success':
              'Ihre Stipendienbewerbung ist eingegangen.',
          'scholarship.apply_failed':
              'Die Bewerbung konnte nicht gespeichert werden.',
          'scholarship.follow_limit_title': 'Follow-Limit',
          'scholarship.follow_limit_body':
              'Sie können heute keinen weiteren Personen folgen.',
          'scholarship.follow_failed':
              'Die Folgeaktion ist fehlgeschlagen.',
          'scholarship.invalid': 'Ungültiges Stipendium.',
          'scholarship.delete_success':
              'Stipendium erfolgreich gelöscht.',
          'scholarship.delete_failed':
              'Beim Löschen des Stipendiums ist ein Fehler aufgetreten.',
          'scholarship.cancel_success':
              'Ihre Stipendienbewerbung wurde storniert.',
          'scholarship.cancel_failed':
              'Die Bewerbung konnte nicht storniert werden.',
          'scholarship.info_missing_title': 'Informationen fehlen',
          'scholarship.info_missing_body':
              'Du kannst dich nicht für Stipendien bewerben, ohne deine persönlichen, schulischen und familiären Informationen auszufüllen.',
          'scholarship.update_my_info': 'Meine Informationen aktualisieren',
          'scholarship.closed': 'Bewerbung geschlossen',
          'scholarship.applied': 'Du hast dich beworben',
          'scholarship.cancel_apply_title': 'Bewerbung abbrechen',
          'scholarship.cancel_apply_body':
              'Möchtest du diese Stipendienbewerbung wirklich abbrechen?',
          'scholarship.cancel_apply_button': 'Bewerbung abbrechen',
          'scholarship.amount_hint': 'Betrag',
          'scholarship.student_count_hint': 'z. B. 4',
          'scholarship.amount_student_count_notice':
              'Betrag und Anzahl der Studierenden werden auf der Bewerbungsseite nicht angezeigt.',
          'scholarship.degree_type_label': 'Studienart',
          'scholarship.degree_type_select': 'Studienart wählen',
          'scholarship.select_country': 'Land wählen',
          'scholarship.select_country_first':
              'Bitte wähle zuerst ein Land aus.',
          'scholarship.select_city_first':
              'Bitte wähle zuerst eine Stadt aus.',
          'scholarship.select_university': 'Universität wählen',
          'scholarship.selected_universities': 'Ausgewählte Universitäten:',
          'scholarship.logo_label': 'Logo auswählen',
          'scholarship.logo_pick': 'Logo auswählen',
          'scholarship.custom_design_optional': 'Dein Design (Optional)',
          'scholarship.custom_image_pick': 'Bild auswählen',
          'scholarship.template_select': 'Vorlage wählen',
          'scholarship.file_copy_failed':
              'Die Datei konnte nicht kopiert werden.',
          'scholarship.duplicate_status.can_receive': 'Kann erhalten',
          'scholarship.duplicate_status.cannot_receive_except_kyk':
              'Kann nicht erhalten (außer KYK)',
          'scholarship.target.population': 'Nach Bevölkerung',
          'scholarship.target.residence': 'Nach Wohnort',
          'scholarship.target.all_turkiye': 'Ganz Türkei',
          'scholarship.info.personal': 'Persönlich',
          'scholarship.info.school': 'Schule',
          'scholarship.info.family': 'Familie',
          'scholarship.info.dormitory': 'Wohnheim',
          'scholarship.education.all': 'Alle',
          'scholarship.education.middle_school': 'Mittelschule',
          'scholarship.education.high_school': 'Gymnasium',
          'scholarship.education.undergraduate': 'Bachelor',
          'scholarship.degree.associate': 'Associate Degree',
          'scholarship.degree.bachelor': 'Bachelor',
          'scholarship.degree.master': 'Master',
          'scholarship.degree.phd': 'Doktorat',
          'single_post.title': 'Beiträge',
          'edit_post.updating':
              'Bitte warten. Dein Beitrag wird aktualisiert',
          'common.district': 'Bezirk',
          'common.price': 'Preis',
          'common.views': 'Aufrufe',
          'common.company': 'Unternehmen',
          'common.salary': 'Gehalt',
          'common.address': 'Adresse',
          'profile_photo.camera': 'Foto aufnehmen',
          'profile_photo.gallery': 'Aus Galerie wählen',
          'edit_profile.title': 'Profilinformationen',
          'edit_profile.personal_info': 'Persönliche Informationen',
          'edit_profile.other_info': 'Weitere Informationen',
          'edit_profile.first_name_hint': 'Vorname',
          'edit_profile.last_name_hint': 'Nachname',
          'edit_profile.privacy': 'Kontoprivatsphäre',
          'edit_profile.links': 'Links',
          'edit_profile.contact_info': 'Kontaktinformationen',
          'edit_profile.address_info': 'Adressinformationen',
          'edit_profile.career_profile': 'Karriereprofil',
          'edit_profile.update_success':
              'Deine Profilinformationen wurden aktualisiert!',
          'edit_profile.update_failed': 'Aktualisierungsfehler: {error}',
          'edit_profile.remove_photo_title': 'Profilbild entfernen',
          'edit_profile.remove_photo_message':
              'Dein Profilbild wird entfernt und der Standard-Avatar verwendet. Bist du sicher?',
          'edit_profile.photo_removed': 'Dein Profilbild wurde entfernt.',
          'edit_profile.photo_remove_failed':
              'Beim Entfernen des Profilbilds ist ein Fehler aufgetreten.',
          'edit_profile.crop_use': 'Zuschneiden und verwenden',
          'edit_profile.delete_account': 'Konto löschen',
          'edit_profile.upload_failed_title': 'Upload fehlgeschlagen!',
          'edit_profile.upload_failed_body':
              'Dieser Inhalt kann derzeit nicht verarbeitet werden. Bitte versuche einen anderen Inhalt.',
          'delete_account.title': 'Konto löschen',
          'delete_account.confirm_title': 'Bestätigung zur Kontolöschung',
          'delete_account.confirm_body':
              'Bevor du dein Konto löschst, senden wir aus Sicherheitsgründen einen Bestätigungscode an deine registrierte E-Mail-Adresse.',
          'delete_account.code_hint': '6-stelliger Bestätigungscode',
          'delete_account.resend': 'Erneut senden',
          'delete_account.send_code': 'Code senden',
          'delete_account.validity_notice':
              'Der Code ist 1 Stunde gültig. Deine Löschanfrage wird nach {days} Tagen endgültig verarbeitet.',
          'delete_account.processing': 'Wird verarbeitet...',
          'delete_account.delete_my_account': 'Mein Konto löschen',
          'delete_account.no_email_title': 'Warnung',
          'delete_account.no_email_body':
              'Für dieses Konto ist keine E-Mail hinterlegt. Du kannst die Löschanfrage direkt starten.',
          'delete_account.session_missing':
              'Sitzung nicht gefunden. Bitte melde dich erneut an.',
          'delete_account.code_sent_title': 'Code gesendet',
          'delete_account.code_sent_body':
              'Der Bestätigungscode zur Löschung wurde an deine E-Mail-Adresse gesendet.',
          'delete_account.send_failed': 'Code konnte nicht gesendet werden.',
          'delete_account.invalid_code_title': 'Ungültiger Code',
          'delete_account.invalid_code_body':
              'Bitte gib den 6-stelligen Code ein.',
          'delete_account.verify_failed':
              'Code konnte nicht bestätigt werden.',
          'delete_account.request_received_title': 'Anfrage erhalten',
          'delete_account.request_received_body':
              'Dein Konto wird nach {days} Tagen dauerhaft gelöscht.',
          'delete_account.request_failed':
              'Beim Löschen deines Kontos ist ein Problem aufgetreten. Bitte versuche es später erneut.',
          'editor_nickname.title': 'Benutzername',
          'editor_nickname.hint': 'Benutzernamen erstellen',
          'editor_nickname.verified_locked':
              'Verifizierte Nutzer können ihren Benutzernamen nicht ändern',
          'editor_nickname.mimic_warning':
              'Benutzernamen, die echte Personen imitieren, können von TurqApp geändert werden, um unsere Community zu schützen.',
          'editor_nickname.tr_char_info':
              'Türkische Zeichen werden automatisch umgewandelt. (ç→c, ğ→g, ı→i, ö→o, ş→s, ü→u)',
          'editor_nickname.min_length': 'Muss mindestens 8 Zeichen lang sein',
          'editor_nickname.current_name': 'Dein aktueller Benutzername',
          'editor_nickname.edit_prompt': 'Zum Ändern bearbeiten',
          'editor_nickname.checking': 'Wird geprüft…',
          'editor_nickname.taken': 'Dieser Benutzername ist vergeben',
          'editor_nickname.available': 'Verfügbar',
          'editor_nickname.unavailable':
              'Konnte nicht geprüft werden',
          'editor_nickname.cooldown_limit':
              'In der ersten Stunde kann er nur 3 Mal geändert werden',
          'editor_nickname.change_after_days':
              'Benutzername kann wieder geändert werden in {days}T {hours}Std',
          'editor_nickname.change_after_hours':
              'Benutzername kann wieder geändert werden in {hours}Std',
          'editor_nickname.error_min_length':
              'Der Benutzername muss mindestens 8 Zeichen lang sein.',
          'editor_nickname.error_taken':
              'Dieser Benutzername ist bereits vergeben.',
          'editor_nickname.error_grace_limit':
              'Du kannst ihn in der ersten Stunde nur 3 Mal ändern.',
          'editor_nickname.error_cooldown':
              'Der Benutzername kann vor Ablauf von 15 Tagen nicht erneut geändert werden.',
          'editor_nickname.error_update_failed':
              'Benutzername konnte nicht aktualisiert werden.',
          'cv.title': 'Karriereprofil',
          'cv.personal_info': 'Persönliche Informationen',
          'cv.education_info': 'Bildungsinformationen',
          'cv.other_info': 'Weitere Informationen',
          'cv.profile_title': 'Karriereprofil',
          'cv.profile_body':
              'Stärke dein Karriereprofil mit einem Profilfoto und grundlegenden Informationen.',
          'cv.first_name_hint': 'Vorname',
          'cv.last_name_hint': 'Nachname',
          'cv.email_hint': 'E-Mail-Adresse',
          'cv.phone_hint': 'Telefonnummer',
          'cv.about_hint': 'Schreibe eine kurze Info über dich',
          'cv.add_school': 'Neue Schule hinzufügen',
          'cv.add_school_title': 'Neue Schule hinzufügen',
          'cv.edit_school_title': 'Schule bearbeiten',
          'cv.school_name': 'Schulname',
          'cv.department': 'Abteilung',
          'cv.graduation_year': 'Abschlussjahr',
          'cv.currently_studying': 'Ich studiere noch',
          'cv.missing_school_name': 'Der Schulname darf nicht leer sein',
          'cv.invalid_year': 'Gib ein gültiges Jahr ein',
          'cv.skills': 'Fähigkeiten',
          'cv.add_skill_title': 'Neue Fähigkeit hinzufügen',
          'cv.skill_name_empty': 'Der Fähigkeitsname darf nicht leer sein',
          'cv.skill_exists': 'Diese Fähigkeit wurde bereits hinzugefügt',
          'cv.skill_hint': 'Fähigkeit (z. B. Flutter, Photoshop)',
          'cv.add_language': 'Sprache hinzufügen',
          'cv.add_new_language': 'Neue Sprache hinzufügen',
          'cv.add_language_title': 'Neue Sprache hinzufügen',
          'cv.edit_language_title': 'Sprache bearbeiten',
          'cv.language.english': 'Englisch',
          'cv.language.german': 'Deutsch',
          'cv.language.french': 'Französisch',
          'cv.language.spanish': 'Spanisch',
          'cv.language.arabic': 'Arabisch',
          'cv.language.turkish': 'Türkisch',
          'cv.language.russian': 'Russisch',
          'cv.language.italian': 'Italienisch',
          'cv.language.korean': 'Koreanisch',
          'cv.level': 'Niveau',
          'cv.add_experience': 'Berufserfahrung hinzufügen',
          'cv.add_new_experience': 'Neue Berufserfahrung hinzufügen',
          'cv.add_experience_title': 'Neue Berufserfahrung hinzufügen',
          'cv.edit_experience_title': 'Erfahrung bearbeiten',
          'cv.company_name': 'Firmenname',
          'cv.position': 'Position',
          'cv.description_optional': 'Aufgabenbeschreibung (optional)',
          'cv.start_year': 'Beginn',
          'cv.end_year': 'Ende',
          'cv.currently_working': 'Ich arbeite noch hier',
          'cv.ongoing': 'Läuft noch',
          'cv.missing_company_position':
              'Firmenname und Position sind erforderlich',
          'cv.invalid_start_year': 'Gib ein gültiges Startjahr ein',
          'cv.invalid_end_year': 'Gib ein gültiges Endjahr ein',
          'cv.add_reference': 'Referenz hinzufügen',
          'cv.add_new_reference': 'Neue Referenz hinzufügen',
          'cv.add_reference_title': 'Neue Referenz hinzufügen',
          'cv.edit_reference_title': 'Referenz bearbeiten',
          'cv.name_surname': 'Vor- und Nachname',
          'cv.phone_example': 'Telefon (z. B. 05xx..)',
          'cv.missing_name_surname':
              'Vor- und Nachname dürfen nicht leer sein',
          'cv.save': 'Speichern',
          'cv.created_title': 'Lebenslauf erstellt!',
          'cv.created_body':
              'Jetzt kannst du dich viel schneller auf Jobs bewerben',
          'cv.save_failed':
              'Der Lebenslauf konnte nicht gespeichert werden. Bitte versuche es erneut.',
          'cv.not_signed_in': 'Du bist nicht angemeldet.',
          'cv.photo_inappropriate':
              'Das Profilbild enthält unangemessene Inhalte.',
          'cv.photo_upload_failed':
              'Das Profilbild konnte nicht hochgeladen werden.',
          'cv.missing_field': 'Fehlendes Feld',
          'cv.invalid_format': 'Ungültiges Format',
          'cv.missing_first_name':
              'Ohne Vornamen kann nicht gespeichert werden',
          'cv.missing_last_name':
              'Ohne Nachnamen kann nicht gespeichert werden',
          'cv.missing_email':
              'Ohne E-Mail-Adresse kann nicht gespeichert werden',
          'cv.invalid_email':
              'Bitte gib eine gültige E-Mail-Adresse ein',
          'cv.missing_phone':
              'Ohne Telefonnummer kann nicht gespeichert werden',
          'cv.invalid_phone':
              'Bitte gib eine gültige Telefonnummer ein',
          'cv.missing_about':
              'Du musst eine kurze Info über dich eingeben',
          'cv.missing_school':
              'Du kannst nicht speichern, ohne mindestens eine Schule anzugeben',
          'qr.title': 'Persönlicher QR-Code',
          'qr.profile_subject': 'TurqApp Profil',
          'qr.profile_desc': 'TurqApp Profil ansehen',
          'qr.link_copied_title': 'Link kopiert',
          'qr.link_copied_body': 'Profil-Link in die Zwischenablage kopiert',
          'qr.permission_required': 'Berechtigung erforderlich',
          'qr.gallery_permission_body':
              'Zum Speichern musst du den Galeriezugriff erlauben.',
          'qr.data_failed': 'QR-Code-Daten konnten nicht erstellt werden.',
          'qr.saved': 'QR-Code wurde in der Galerie gespeichert.',
          'qr.save_failed': 'QR-Code konnte nicht gespeichert werden.',
          'qr.download_failed':
              'Beim Herunterladen ist ein Fehler aufgetreten.',
          'post_creator.title_new': 'Beitrag vorbereiten',
          'post_creator.title_edit': 'Beitrag bearbeiten',
          'post_creator.text_hint': 'Beitragstext',
          'post_creator.publish': 'Veröffentlichen',
          'post_creator.uploading': 'Wird hochgeladen...',
          'post_creator.saving': 'Wird gespeichert...',
          'post_creator.placeholder': 'Was gibt es Neues?',
          'post_creator.processing_wait':
              'Bitte warten. Das Video wird verarbeitet...',
          'post_creator.video_processing': 'Video wird verarbeitet',
          'post_creator.look.original': 'Original',
          'post_creator.look.clear': 'Klar',
          'post_creator.look.cinema': 'Kino',
          'post_creator.look.vibe': 'Lebendig',
          'post_creator.comments.everyone': 'Alle',
          'post_creator.comments.verified': 'Verifizierte Konten',
          'post_creator.comments.following': 'Konten, denen du folgst',
          'post_creator.comments.closed': 'Kommentare deaktiviert',
          'post_creator.comments.title': 'Wer kann antworten?',
          'post_creator.comments.subtitle':
              'Wähle aus, wer auf diesen Beitrag antworten kann.',
          'post_creator.reshare.everyone': 'Alle',
          'post_creator.reshare.verified': 'Verifizierte Konten',
          'post_creator.reshare.following': 'Konten, denen du folgst',
          'post_creator.reshare.closed': 'Teilen deaktiviert',
          'post_creator.schedule.remove_title': 'Planung entfernen',
          'post_creator.schedule.remove_message':
              'Möchtest du den geplanten Beitrag entfernen? Er wird sofort veröffentlicht.',
          'post_creator.cover_title': 'Titelbild auswählen',
          'post_creator.cover_selected': 'Titelbild ausgewählt',
          'post_creator.use_address': 'Diese Adresse verwenden',
          'post_creator.poll_title': 'Umfrage',
          'post_creator.poll_time_options': 'Zeitoptionen',
          'post_creator.poll_option': 'Option {index}',
          'post_creator.poll_add_option': '+ Noch eine Option hinzufügen',
          'post_creator.poll_min_options':
              'Mindestens zwei Optionen sind erforderlich.',
          'post_creator.poll_requirement':
              'Für eine Umfrage ist Text oder Bild/Video erforderlich.',
          'post_creator.validation_failed':
              'Beitragsprüfung fehlgeschlagen',
          'post_creator.firestore_save_failed':
              'Firestore-Speicherung fehlgeschlagen',
          'post_creator.upload_failed_title': 'Upload fehlgeschlagen',
          'post_creator.upload_failed_message':
              'Die Sicherheitsprüfung des Inhalts konnte nicht abgeschlossen werden.',
          'post_creator.image_rejected':
              'Dieses Bild kann nicht hochgeladen werden.',
          'post_creator.video_rejected':
              'Dieses Video kann nicht hochgeladen werden.',
          'post_creator.no_internet': 'Keine Internetverbindung gefunden',
          'post_creator.draft_save_failed':
              'Entwurf konnte nicht gespeichert werden',
          'post_creator.reshare_privacy_title': 'Privatsphäre beim Teilen',
          'post_creator.reshare_everyone_desc':
              'Jeder kann erneut teilen.',
          'post_creator.reshare_followers_desc':
              'Nur meine Follower können erneut teilen.',
          'post_creator.reshare_closed_desc':
              'Weiterteilen ist deaktiviert.',
          'post_creator.schedule_title': 'Geplanter Veröffentlichungszeitpunkt',
          'post_creator.publish_item': 'Beitrag {index}',
          'post_creator.preparing_posts': 'Beiträge werden vorbereitet...',
          'post_creator.uploading_media':
              'Mediendateien werden hochgeladen...',
          'post_creator.saving_to_database':
              'Wird in der Datenbank gespeichert...',
          'post_creator.video_nsfw_check_failed':
              'NSFW-Videoprüfung fehlgeschlagen',
          'post_creator.post_counter_failed':
              'Der Beitragszähler konnte nicht aktualisiert werden',
          'post_creator.edit_target_missing':
              'Der zu bearbeitende Beitrag wurde nicht gefunden',
          'post_creator.edit_content_missing':
              'Bearbeitungsinhalt wurde nicht gefunden',
          'post_creator.edit_updated': 'Beitrag aktualisiert',
          'post_creator.edit_update_failed':
              'Beitrag konnte nicht aktualisiert werden',
          'post_creator.upload_failed_generic':
              'Beitrag konnte nicht hochgeladen werden',
          'post_creator.queue_already_added':
              'Diese Medien befinden sich bereits in der Upload-Warteschlange.',
          'post_creator.queue_added_complete':
              'Beiträge wurden zur Warteschlange hinzugefügt und werden im Hintergrund hochgeladen.',
          'post_creator.queue_title': 'Upload-Warteschlange',
          'post_creator.queue_added_body':
              'Beiträge wurden zur Hintergrund-Warteschlange hinzugefügt',
          'post_creator.queue_add_failed':
              'Hinzufügen zur Warteschlange fehlgeschlagen',
          'post_creator.photo_with_video_forbidden':
              'Du kannst keine Fotos hinzufügen, wenn bereits ein Video ausgewählt ist. Es ist nur 1 Video erlaubt.',
          'post_creator.max_photo_count':
              'Du kannst höchstens {count} Fotos auswählen.',
          'post_creator.max_photo_add':
              'Du kannst höchstens {count} Fotos hinzufügen. Aktuell: {current}, Hinzuzufügen: {adding}',
          'post_creator.photo_validation_prefix': 'Foto {index}: {error}',
          'post_creator.photos_compression_failed':
              'Fotos wurden hinzugefügt, aber die Komprimierung ist fehlgeschlagen.',
          'post_creator.warning_title': 'Warnung',
          'post_creator.success_title': 'Erfolgreich!',
          'post_creator.photo_added': 'Foto hinzugefügt. {saved}',
          'post_creator.photo_added_no_compress':
              'Foto hinzugefügt, aber die Komprimierung ist fehlgeschlagen.',
          'post_creator.max_video_count':
              'Du kannst höchstens {count} Videos auswählen.',
          'post_creator.no_post_uploaded':
              'Kein Beitrag konnte hochgeladen werden',
          'post_creator.image_upload_failed':
              'Bild {index} konnte nicht hochgeladen werden',
          'post_creator.video_reduce_failed':
              'Das Video konnte nicht unter 35 MB reduziert werden. Unter 35 MB wird direkt hochgeladen, über 60 MB wird nicht unterstützt.',
          'post_creator.video_upload_failed':
              'Video konnte nicht hochgeladen werden',
          'post_creator.post_upload_failed':
              'Beitrag {index} konnte nicht hochgeladen werden',
          'post_creator.upload_success':
              'Beiträge wurden erfolgreich veröffentlicht!',
          'post_creator.upload_error':
              'Beim Hochladen des Beitrags ist ein Fehler aufgetreten.',
          'post_creator.upload_process_failed': 'Upload fehlgeschlagen',
          'post_creator.critical_error':
              'Ein kritischer Fehler ist aufgetreten.',
          'permissions.title': 'Geräteberechtigungen',
          'permissions.preferences': 'Deine Einstellungen',
          'permissions.offline_space': 'Offline-Speicher',
          'permissions.offline_space_desc':
              'Inhalte bis zur ausgewählten GB-Menge werden auf dein Gerät geladen und können ohne Internetverbindung angesehen werden. Ältere Videos werden automatisch entfernt, wenn der Speicher voll wird.',
          'permissions.allowed': 'Erlaubt',
          'permissions.denied': 'Nicht erlaubt',
          'permissions.enable': 'Berechtigungen aktivieren',
          'permissions.enable_location': 'Ortungsdienste aktivieren',
          'permissions.checking': 'Wird geprüft...',
          'permissions.dialog.update_device_settings':
              'Geräteeinstellungen aktualisieren',
          'permissions.dialog.update_body':
              'Öffne die Geräteeinstellungen. Du kannst die Berechtigung "{title}" jederzeit aktualisieren.',
          'permissions.dialog.open_settings': 'Geräteeinstellungen öffnen',
          'permissions.dialog.not_now': 'Jetzt nicht',
          'permissions.quota.media_cache': 'Medien-Cache',
          'permissions.quota.image_cache': 'Bild-Cache',
          'permissions.quota.metadata': 'Metadaten',
          'permissions.quota.reserve': 'Reservierter Speicher',
          'permissions.quota.os_safety': 'OS-Sicherheitsreserve',
          'permissions.quota.plan_distribution':
              '{gb} GB Planverteilung',
          'permissions.quota.soft_stop': 'Stream-Cache Soft Stop',
          'permissions.quota.hard_stop': 'Stream-Cache Hard Stop',
          'permissions.quota.recent_window':
              'Schutzfenster für aktuelle Videos: {count} Inhalte',
          'permissions.quota.active_stream': 'Aktive Stream-Nutzung',
          'permissions.quota.soft_remaining': 'Verbleibend bis Soft Stop',
          'permissions.quota.hard_remaining': 'Verbleibend bis Hard Stop',
          'permissions.playback.title': 'Daten- und Wiedergabeeinstellungen',
          'permissions.playback.help':
              'Das System arbeitet nach dem Cache-Plan; hier wählst du nur, wie vorsichtig sich WLAN und mobile Daten verhalten sollen.',
          'permissions.playback.limit_cellular':
              'Mit Cache bei mobilen Daten begrenzen',
          'permissions.playback.limit_cellular_desc':
              'Wenn aktiv, wird bei mobilen Daten zuerst vorhandener Cache verwendet, bevor neue Segmente geladen werden.',
          'permissions.playback.cellular_mode':
              'Wiedergabemodus mobile Daten',
          'permissions.playback.cellular_mode_desc':
              'Legt fest, wie aggressiv Prefetch und Qualität unter mobilem Schutz sein dürfen.',
          'permissions.playback.wifi_mode': 'Wiedergabemodus WLAN',
          'permissions.playback.wifi_mode_desc':
              'Legt fest, wie weit Start- und Vorausladefenster im WLAN gehen dürfen.',
          'permissions.detail.set_preferences':
              'Lege deine Einstellungen fest',
          'permissions.detail.preference_body':
              'Du kannst entscheiden, ob TurqApp auf dein {access} zugreifen darf. Diese Auswahl kannst du jederzeit ändern. {title} verbessert einige App-Funktionen.',
          'permissions.detail.device_setting':
              'Deine Geräteeinstellung:',
          'permissions.detail.other_option': 'Andere Option',
          'permissions.detail.allowed_desc':
              'TurqApp darf auf dein {access} zugreifen.',
          'permissions.detail.denied_desc':
              'TurqApp darf nicht auf dein {access} zugreifen.',
          'permissions.detail.go_device_settings':
              'Gehe in die Geräteeinstellungen, um deine Berechtigungen zu aktualisieren.',
          'permissions.item.camera.title': 'Kamera',
          'permissions.item.camera.access': 'Kamera',
          'permissions.item.camera.help_text':
              'Wie verwenden wir die Kamera deines Geräts?',
          'permissions.item.camera.help_sheet_title':
              'Wie verwenden wir die Kamera deines Geräts?',
          'permissions.item.camera.help_sheet_body':
              'TurqApp verwendet den Kamerazugriff, damit du Fotos aufnehmen, Videos aufzeichnen und visuelle/audio Effekte in der Vorschau sehen kannst.',
          'permissions.item.camera.help_sheet_body2':
              'Mehr darüber, wie wir deine Kamera verwenden, erfährst du im Datenschutz-Center.',
          'permissions.item.camera.help_sheet_link':
              'Datenschutz-Center',
          'permissions.item.contacts.title': 'Kontakte',
          'permissions.item.contacts.access': 'Kontakte',
          'permissions.item.contacts.help_text':
              'Wie verwenden wir die Kontakte deines Geräts?',
          'permissions.item.contacts.help_sheet_title':
              'Wie verwenden wir die Kontakte deines Geräts?',
          'permissions.item.contacts.help_sheet_body':
              'TurqApp verwendet diese Informationen, um dir zu helfen, leichter mit bekannten Personen in Kontakt zu treten und Kontaktvorschläge zu verbessern.',
          'permissions.item.contacts.help_sheet_link':
              'Mehr erfahren',
          'permissions.item.location.title': 'Ortungsdienste',
          'permissions.item.location.access': 'Standort',
          'permissions.item.location.help_text':
              'Wie verwenden wir den Standort deines Geräts?',
          'permissions.item.location.help_sheet_title':
              'Wie verwenden wir den Standort deines Geräts?',
          'permissions.item.location.help_sheet_body':
              'TurqApp verwendet Standortinformationen, damit du Orte in deiner Nähe entdecken, Standorte in Beiträgen/Storys markieren und Sicherheitsfunktionen verbessern kannst.',
          'permissions.item.location.help_sheet_body2':
              'Mehr darüber, wie wir Standortdaten verwenden, erfährst du im Datenschutz-Center.',
          'permissions.item.location.help_sheet_link':
              'Datenschutz-Center',
          'permissions.item.microphone.title': 'Mikrofon',
          'permissions.item.microphone.access': 'Mikrofon',
          'permissions.item.microphone.help_text':
              'Wie verwenden wir das Mikrofon deines Geräts?',
          'permissions.item.microphone.help_sheet_title':
              'Wie verwenden wir das Mikrofon deines Geräts?',
          'permissions.item.microphone.help_sheet_body':
              'TurqApp verwendet den Mikrofonzugriff für Funktionen wie Audioaufnahme in Videos und Effektvorschauen.',
          'permissions.item.microphone.help_sheet_body2':
              'Mehr darüber, wie wir dein Mikrofon verwenden, erfährst du im Datenschutz-Center.',
          'permissions.item.microphone.help_sheet_link':
              'Datenschutz-Center',
          'permissions.item.notifications.title': 'Benachrichtigungen',
          'permissions.item.notifications.access':
              'sofortige Benachrichtigungen senden',
          'permissions.item.notifications.help_text':
              'Wie verwenden wir die Benachrichtigungen deines Geräts?',
          'permissions.item.notifications.help_sheet_title':
              'Wie verwenden wir die Benachrichtigungen deines Geräts?',
          'permissions.item.notifications.help_sheet_body':
              'TurqApp verwendet die Benachrichtigungsberechtigung, um dir sofortige Benachrichtigungen zu senden, wenn es neue Aktivitäten in deinem Konto gibt.',
          'permissions.item.notifications.help_sheet_body2':
              'Mehr darüber, wie wir Benachrichtigungen verwenden, erfährst du im Transparenz-Center.',
          'permissions.item.notifications.help_sheet_link':
              'Transparenz-Center',
          'permissions.item.photos.title': 'Fotos',
          'permissions.item.photos.access': 'Fotos und Videos',
          'permissions.item.photos.help_text':
              'Wie verwenden wir die Fotos deines Geräts?',
          'permissions.item.photos.help_sheet_title':
              'Wie verwenden wir die Fotos deines Geräts?',
          'permissions.item.photos.help_sheet_body':
              'TurqApp verwendet den Fotozugriff, damit du Fotos/Videos aus deiner Galerie auswählen und teilen sowie Bearbeitungstools nutzen kannst.',
        },
      };

    base['fr_FR'] = Map<String, String>.from(base['en_US']!)
      ..addAll({
        'settings.title': 'Parametres',
        'settings.account': 'Compte',
        'settings.content': 'Contenu',
        'settings.app': 'Application',
        'settings.security_support': 'Securite et assistance',
        'settings.my_tasks': 'Mes taches',
        'settings.system_diagnostics': 'Systeme et diagnostic',
        'settings.session': 'Session',
        'settings.language': 'Langue',
        'settings.edit_profile': 'Modifier le profil',
        'settings.saved_posts': 'Enregistrements',
        'settings.archive': 'Archive',
        'settings.liked_posts': 'J aime',
        'settings.notifications': 'Notifications',
        'settings.permissions': 'Autorisations',
        'settings.pasaj': 'Pasaj',
        'education.previous_questions': 'Tests pratiques',
        'tests.results_title': 'Resultats',
        'tests.results_empty':
            'Aucun resultat trouve.\nAucune donnee de reponse ou de question n est disponible pour ce test.',
        'tests.correct': 'Correct',
        'tests.wrong': 'Incorrect',
        'tests.blank': 'Vide',
        'tests.net': 'Net',
        'tests.score': 'Score',
        'tests.question_number': 'Question @index',
        'tests.solve_no_questions':
            'Question introuvable.\nLes questions de ce test n ont pas pu etre chargees.',
        'tests.finish_test': 'Terminer le test',
        'tests.my_results_empty':
            'Aucun resultat trouve.\nVous n avez encore jamais resolu de test.',
        'tests.saved_empty': 'Aucun test enregistre.',
        'tests.result_answer_missing':
            'Aucun resultat trouve.\nAucune donnee de reponse n est disponible pour ce test.',
        'tests.type_test': 'Test @type',
        'tests.description_test': 'Test @description',
        'tests.solve_count': 'Vous l avez resolu @count fois',
        'settings.about': 'A propos',
        'settings.policies': 'Politiques',
        'settings.contact_us': 'Nous ecrire',
        'settings.sign_out': 'Se deconnecter',
        'settings.sign_out_title': 'Se deconnecter',
        'settings.sign_out_message':
            'Etes-vous sur de vouloir vous deconnecter ?',
        'settings.admin_push': 'Administration / Envoyer une notification',
        'settings.diagnostics.data_usage': 'Utilisation des donnees',
        'settings.diagnostics.network': 'Reseau',
        'settings.diagnostics.connected': 'Connecte',
        'settings.diagnostics.monthly_total': 'Total mensuel',
        'settings.diagnostics.monthly_limit': 'Limite mensuelle',
        'settings.diagnostics.remaining': 'Restant',
        'settings.diagnostics.limit_usage': 'Utilisation de la limite',
        'settings.diagnostics.wifi_usage': 'Consommation Wi-Fi',
        'settings.diagnostics.cellular_usage': 'Consommation mobile',
        'settings.diagnostics.time_ranges': 'Plages horaires',
        'settings.diagnostics.this_month_actual': 'Ce mois-ci (reel)',
        'settings.diagnostics.hourly_average': 'Moyenne horaire',
        'settings.diagnostics.since_login_estimated':
            'Depuis la connexion (estime)',
        'settings.diagnostics.details': 'Details',
        'settings.diagnostics.cache': 'Cache',
        'settings.diagnostics.saved_media_count':
            'Nombre de medias enregistres',
        'settings.diagnostics.occupied_space': 'Espace occupe',
        'settings.diagnostics.offline_queue': 'File hors ligne',
        'settings.diagnostics.pending': 'En attente',
        'settings.diagnostics.dead_letter': 'Dead-letter',
        'settings.diagnostics.status': 'Etat',
        'settings.diagnostics.syncing': 'Synchronisation',
        'settings.diagnostics.idle': 'Inactif',
        'settings.diagnostics.processed_total': 'Traites (total)',
        'settings.diagnostics.failed_total': 'Echecs (total)',
        'settings.diagnostics.last_sync': 'Derniere synchro',
        'settings.diagnostics.login_date': 'Date de connexion',
        'settings.diagnostics.login_time': 'Heure de connexion',
        'settings.diagnostics.app_health_panel':
            'Panneau de sante de l application',
        'settings.diagnostics.video_cache_detail':
            'Details du cache video',
        'settings.diagnostics.quick_actions': 'Actions rapides',
        'settings.diagnostics.offline_queue_detail':
            'Details de la file hors ligne',
        'settings.diagnostics.last_error_summary':
            'Dernier resume d erreur',
        'settings.diagnostics.error_report': 'Rapport d erreur',
        'settings.diagnostics.saved_videos': 'Videos enregistrees',
        'settings.diagnostics.saved_segments': 'Segments enregistres',
        'settings.diagnostics.disk_usage': 'Utilisation du disque',
        'settings.diagnostics.unknown': 'Inconnu',
        'settings.diagnostics.cache_traffic': 'Trafic du cache',
        'settings.diagnostics.hit_rate': 'Taux de hit',
        'settings.diagnostics.hit': 'Hit',
        'settings.diagnostics.miss': 'Miss',
        'settings.diagnostics.cache_served': 'Servi depuis le cache',
        'settings.diagnostics.downloaded_from_network':
            'Telecharge depuis le reseau',
        'settings.diagnostics.prefetch': 'Prefetch',
        'settings.diagnostics.queue': 'File',
        'settings.diagnostics.active_downloads': 'Telechargements actifs',
        'settings.diagnostics.paused': 'En pause',
        'settings.diagnostics.active': 'Actif',
        'settings.diagnostics.reset_data_counters':
            'Reinitialiser les compteurs de donnees',
        'settings.diagnostics.data_counters_reset':
            'Les compteurs de donnees ont ete reinitialises.',
        'settings.diagnostics.sync_offline_queue_now':
            'Synchroniser la file hors ligne',
        'settings.diagnostics.offline_queue_sync_triggered':
            'La synchronisation de la file hors ligne a ete lancee.',
        'settings.diagnostics.retry_dead_letter':
            'Reessayer le dead-letter',
        'settings.diagnostics.dead_letter_queued':
            'Les elements dead-letter ont ete remis en file.',
        'settings.diagnostics.clear_dead_letter':
            'Effacer le dead-letter',
        'settings.diagnostics.dead_letter_cleared':
            'Les elements dead-letter ont ete supprimes.',
        'settings.diagnostics.pause_prefetch': 'Mettre le prefetch en pause',
        'settings.diagnostics.prefetch_paused':
            'Le prefetch a ete mis en pause',
        'settings.diagnostics.service_not_ready':
            'Le service n est pas encore pret.',
        'settings.diagnostics.resume_prefetch':
            'Reprendre le prefetch',
        'settings.diagnostics.prefetch_resumed': 'Le prefetch a repris',
        'settings.diagnostics.online': 'En ligne',
        'settings.diagnostics.sync': 'Sync',
        'settings.diagnostics.processed': 'Traites',
        'settings.diagnostics.failed': 'Echoues',
        'settings.diagnostics.pending_first8':
            'En attente (8 premiers)',
        'settings.diagnostics.dead_letter_first8':
            'Dead-letter (8 premiers)',
        'settings.diagnostics.sync_now': 'Synchroniser',
        'settings.diagnostics.dead_letter_retry':
            'Reessayer dead-letter',
        'settings.diagnostics.dead_letter_clear':
            'Effacer dead-letter',
        'settings.diagnostics.no_recorded_error':
            'Aucune erreur enregistree.',
        'settings.diagnostics.error_code': 'Code',
        'settings.diagnostics.error_category': 'Categorie',
        'settings.diagnostics.error_severity': 'Severite',
        'settings.diagnostics.error_retryable': 'Peut etre reessaye',
        'settings.diagnostics.error_message': 'Message',
        'settings.diagnostics.error_time': 'Heure',
        'account_center.header_title':
            'Profils et informations de connexion',
        'account_center.accounts': 'Comptes',
        'account_center.no_accounts':
            'Aucun compte n a encore ete ajoute a cet appareil.',
        'account_center.add_account': 'Ajouter un compte',
        'account_center.personal_details': 'Informations personnelles',
        'account_center.security': 'Securite',
        'account_center.active_account_title': 'Compte actif',
        'account_center.active_account_body':
            '@{username} est deja actif.',
        'account_center.reauth_title': 'Nouvelle connexion requise',
        'account_center.reauth_body':
            'Veuillez entrer de nouveau votre mot de passe pour changer de compte.',
        'account_center.switch_failed_title': 'Changement impossible',
        'account_center.switch_failed_body':
            'Le compte n a pas pu etre active.',
        'account_center.remove_active_forbidden':
            'Vous devez d abord passer a un autre compte.',
        'account_center.remove_account_title': 'Supprimer le compte',
        'account_center.remove_account_body':
            'Voulez-vous retirer @{username} de cet appareil ?',
        'account_center.account_removed': '@{username} a ete retire.',
        'account_center.single_device_title':
            'Connexion sur un seul appareil',
        'account_center.single_device_desc':
            'Lorsqu une connexion est effectuee sur un autre appareil, la session en cours est fermee et un mot de passe sera requis.',
        'account_center.single_device_enabled':
            'La connexion sur un seul appareil est activee.',
        'account_center.single_device_disabled':
            'La connexion sur un seul appareil est desactivee.',
        'account_center.no_personal_detail':
            'Aucun detail personnel n a ete ajoute.',
        'account_center.contact_details': 'Coordonnees',
        'account_center.contact_info': 'Informations de contact',
        'account_center.email': 'E-mail',
        'account_center.phone': 'Telephone',
        'account_center.email_missing': 'Aucun e-mail ajoute',
        'account_center.phone_missing': 'Aucun telephone ajoute',
        'account_center.verified': 'Verifie',
        'account_center.verify': 'Verifier',
        'account_center.unverified': 'Non verifie',
        'about_profile.title': 'A propos de ce compte',
        'about_profile.description':
            'Cette page montre les informations publiques essentielles et l historique de ce compte.',
        'about_profile.joined_on': 'A rejoint le {date}',
        'policies.center_title': 'Centre des politiques',
        'policies.center_desc':
            'Consultez ici les regles, les conditions et les documents d information de TurqApp.',
        'policies.last_updated': 'Derniere mise a jour : {date}',
        'language.title': 'Langue',
        'language.subtitle': 'Choisis la langue de l application.',
        'language.note':
            'Certaines pages seront traduites progressivement. Ton choix s applique immediatement.',
        'language.option.tr': 'Turc',
        'language.option.en': 'Anglais',
        'language.option.de': 'Allemand',
        'language.option.fr': 'Français',
        'language.option.it': 'Italien',
        'language.option.ru': 'Russe',
        'login.tagline': '"Vos histoires se rejoignent ici."',
        'login.device_accounts': 'Comptes sur cet appareil',
        'login.last_used': 'Dernier utilise',
        'login.saved_account': 'Compte enregistre',
        'login.sign_in': 'Se connecter',
        'login.create_account': 'Creer un compte',
        'login.policies': 'Contrats et politiques',
        'login.identifier_hint': 'Nom d utilisateur ou e-mail',
        'login.password_hint': 'Votre mot de passe',
        'login.reset': 'Reinitialiser',
        'login.reset_password_title': 'Reinitialiser votre mot de passe',
        'login.email_label': 'Adresse e-mail',
        'login.email_hint': 'Entrez votre adresse e-mail',
        'login.get_code': 'Obtenir le code',
        'login.resend_code': 'Renvoyer',
        'login.verification_code': 'Code de verification',
        'login.verification_code_hint': 'Code de verification a 6 chiffres',
        'common.back': 'Retour',
        'common.continue': 'Continuer',
        'common.all': 'Tous',
        'common.videos': 'Videos',
        'common.photos': 'Photos',
        'common.no_results': 'Aucun resultat',
        'common.success': 'Succes',
        'common.warning': 'Avertissement',
        'common.delete': 'Supprimer',
        'common.search': 'Rechercher',
        'common.call': 'Appeler',
        'common.view': 'Voir',
        'common.create': 'Creer',
        'common.applications': 'Candidatures',
        'common.liked': 'Aimes',
        'common.saved': 'Enregistre',
        'common.unknown_category': 'Categorie inconnue',
        'common.clear': 'Effacer',
        'answer_key.published': 'Publies',
        'answer_key.my_results': 'Mes resultats',
        'answer_key.saved_empty': 'Aucun livre enregistre.',
        'answer_key.new_create': 'Creer nouveau',
        'answer_key.create_optical_form': 'Creer\nfeuille optique',
        'answer_key.create_booklet_answer_key':
            'Creer\ncorrige de livre',
        'answer_key.create_optical_form_single':
            'Creer feuille optique',
        'answer_key.give_exam_name': 'Donnez un nom a votre examen',
        'answer_key.join_exam_title': 'Rejoindre l examen',
        'answer_key.exam_id_hint': 'ID examen',
        'answer_key.book': 'Livre',
        'answer_key.create_book': 'Creer un livre',
        'answer_key.optical_form': 'Feuille optique',
        'answer_key.delete_book': 'Supprimer le livre',
        'answer_key.share_owner_only':
            'Seuls les admins et le proprietaire de l annonce peuvent partager.',
        'answer_key.book_answer_key_desc': 'corrige',
        'answer_key.delete_operation': 'Suppression',
        'answer_key.delete_optical_confirm':
            'Voulez-vous vraiment supprimer la feuille optique nommee @name ?',
        'answer_key.total_questions': '@count questions au total',
        'answer_key.participant_count': '@count personnes',
        'answer_key.id_copied': 'ID copie',
        'answer_key.answered_suffix': 'Repondu il y a @time',
        'common.share': 'Partager',
        'common.show_more': 'Afficher plus',
        'common.show_less': 'Afficher moins',
        'common.hide': 'Masquer',
        'common.push': 'Push',
        'common.quote': 'Citer',
        'common.user': 'Utilisateur',
        'common.info': 'Info',
        'common.cancel': 'Annuler',
        'common.select': 'Sélectionner',
        'common.close': 'Fermer',
        'common.unspecified': 'Non spécifié',
        'common.yes': 'Oui',
        'common.no': 'Non',
        'common.selected_count': '@count selectionnes',
        'profile_photo.camera': 'Prendre une photo',
        'profile_photo.gallery': 'Choisir dans la galerie',
        'common.now': 'maintenant',
        'common.download': 'Telecharger',
        'app.name': 'TurqApp',
        'common.copy': 'Copier',
        'common.copy_link': 'Copier le lien',
        'common.copied': 'Copie',
        'common.link_copied': 'Le lien a ete copie dans le presse-papiers',
        'common.archive': 'Archiver',
        'common.unarchive': 'Retirer des archives',
        'common.apply': 'Appliquer',
        'common.reset': 'Reinitialiser',
        'common.select_city': 'Choisir une ville',
        'common.select_district': 'Choisir un arrondissement',
        'common.report': 'Signaler',
        'report.reported_user': 'Utilisateur signale',
        'report.what_issue': 'Quel type de probleme signalez-vous ?',
        'report.thanks_title':
            'Merci de nous aider a rendre TurqApp meilleur pour tout le monde !',
        'report.thanks_body':
            'Nous savons que votre temps est precieux. Merci de prendre le temps de nous aider.',
        'report.how_it_works_title': 'Comment cela fonctionne ?',
        'report.how_it_works_body':
            'Votre signalement nous est bien parvenu. Nous masquerons le profil signale de votre fil.',
        'report.whats_next_title': 'Et maintenant ?',
        'report.whats_next_body':
            'Notre equipe examinera ce profil sous quelques jours. Si une violation est constatee, le compte sera restreint. Si aucune violation n est detectee et que vous avez envoye plusieurs signalements invalides, votre compte pourra etre restreint.',
        'report.optional_block_title': 'Si vous voulez',
        'report.optional_block_body':
            'Vous pouvez bloquer ce profil. Si vous le faites, cet utilisateur n apparaitra plus du tout dans votre fil.',
        'report.block_user_button': 'Bloquer @nickname',
        'report.blocked_user_label': '@nickname a ete bloque !',
        'report.block_user_info':
            'Empecher @nickname de vous suivre ou de vous envoyer des messages. Il pourra toujours voir vos publications publiques mais ne pourra pas interagir avec vous. Vous ne verrez plus non plus les publications de @nickname.',
        'report.select_reason_title': 'Choisissez un motif',
        'report.select_reason_body':
            'Vous devez choisir un motif pour continuer.',
        'report.submitted_title': 'Votre demande nous est parvenue !',
        'report.submitted_body':
            'Nous examinerons @nickname. Merci pour votre signalement.',
        'report.submitting': 'Envoi…',
        'report.done': 'Termine',
        'report.reason.impersonation.title':
            'Usurpation / Faux compte / Usurpation d identite',
        'report.reason.impersonation.desc':
            'Ce compte ou ce contenu peut usurper l identite de quelqu un, utiliser une fausse identite ou representer une autre personne sans autorisation.',
        'report.reason.copyright.title':
            'Droits d auteur / Utilisation non autorisee',
        'report.reason.copyright.desc':
            'Ce contenu peut utiliser sans autorisation du materiel protege ou enfreindre la propriete intellectuelle.',
        'report.reason.harassment.title':
            'Harcèlement / Ciblage / Intimidation',
        'report.reason.harassment.desc':
            'Ce contenu semble harceler, humilier, cibler ou intimider de maniere repetee une personne.',
        'report.reason.hate_speech.title': 'Discours haineux',
        'report.reason.hate_speech.desc':
            'Ce contenu peut contenir de la haine, de la discrimination ou un langage degradant envers une personne ou un groupe.',
        'report.reason.nudity.title': 'Nudite / Contenu sexuel',
        'report.reason.nudity.desc':
            'Ce contenu peut contenir de la nudite, de l obscenite ou du materiel sexuel explicite.',
        'report.reason.violence.title': 'Violence / Menace',
        'report.reason.violence.desc':
            'Ce contenu peut inclure de la violence physique, des menaces, de l intimidation ou des appels a faire du mal.',
        'report.reason.spam.title':
            'Spam / Contenu repetitif non pertinent',
        'report.reason.spam.desc':
            'Ce contenu semble repetitif, non pertinent, trompeur ou perturbateur de maniere assimilable a du spam.',
        'report.reason.scam.title': 'Arnaque / Tromperie',
        'report.reason.scam.desc':
            'Ce contenu peut etre trompeur ou frauduleux afin d abuser de la confiance, de l argent ou des informations.',
        'report.reason.misinformation.title':
            'Desinformation / Manipulation',
        'report.reason.misinformation.desc':
            'Ce contenu peut deformer les faits, diffuser de fausses informations ou manipuler les gens.',
        'report.reason.illegal_content.title': 'Contenu illegal',
        'report.reason.illegal_content.desc':
            'Ce contenu peut impliquer une activite illegale, la promotion d un crime ou du materiel illicite.',
        'report.reason.child_safety.title':
            'Violation de la securite des enfants',
        'report.reason.child_safety.desc':
            'Ce contenu peut mettre en danger la securite des enfants ou comporter des elements nuisibles inappropries pour eux.',
        'report.reason.self_harm.title':
            'Automutilation / Incitation au suicide',
        'report.reason.self_harm.desc':
            'Ce contenu peut encourager l automutilation, le suicide ou des comportements autodestructeurs.',
        'report.reason.privacy_violation.title': 'Violation de la vie privee',
        'report.reason.privacy_violation.desc':
            'Ce contenu peut inclure le partage non autorise de donnees personnelles, du doxxing ou une atteinte a la vie privee.',
        'report.reason.fake_engagement.title':
            'Faux engagement / Bot / Croissance manipulee',
        'report.reason.fake_engagement.desc':
            'Ce contenu peut impliquer de faux likes, une activite de bots ou une croissance artificielle manipulee.',
        'report.reason.other.title': 'Autre',
        'report.reason.other.desc':
            'Il peut exister une autre violation non couverte ci-dessus que vous souhaitez nous faire examiner.',
        'common.undo': 'Annuler',
        'common.edited': 'modifie',
        'common.delete_post_title': 'Supprimer la publication',
        'common.delete_post_message':
            'Voulez-vous vraiment supprimer cette publication ?',
        'common.delete_post_confirm': 'Supprimer la publication',
        'common.post_share_title': 'Publication TurqApp',
        'common.send': 'Envoyer',
        'common.block': 'Bloquer',
        'common.unknown_user': 'Utilisateur inconnu',
        'common.unknown_company': 'Entreprise inconnue',
        'common.verified': 'Verifie',
        'common.verify': 'Verifier',
        'common.change': 'Modifier',
        'comments.input_hint': 'Qu en penses-tu ?',
        'explore.tab.trending': 'Tendances',
        'explore.tab.for_you': 'Pour vous',
        'explore.tab.series': 'Serie',
        'explore.trending_rank': '@index - tendance en Turquie',
        'explore.no_results': 'Aucun resultat',
        'explore.no_series': 'Aucune serie trouvee',
        'feed.empty_city': 'Il n y a pas encore de publications dans votre ville',
        'feed.empty_following':
            'Aucune publication des comptes que vous suivez pour le moment',
        'post_likes.title': 'Likes',
        'post_likes.empty': 'Il n y a pas encore de likes',
        'post_state.hidden_title': 'Publication masquee',
        'post_state.hidden_body':
            'Cette publication a ete masquee. Vous verrez des publications similaires plus bas dans votre fil.',
        'post_state.archived_title': 'Publication archivee',
        'post_state.archived_body':
            'Vous avez archive cette publication.\nElle ne sera plus visible pour personne.',
        'post_state.deleted_title': 'Publication supprimee',
        'post_state.deleted_body': 'Cette publication n est plus en ligne.',
        'post.share_title': 'Publication TurqApp',
        'post.archive': 'Archiver',
        'post.unarchive': 'Retirer des archives',
        'post.like_failed': 'Le like n a pas pu etre termine.',
        'post.save_failed': 'L enregistrement n a pas pu etre termine.',
        'post.reshare_failed': 'Le repartage n a pas pu etre termine.',
        'post.report_success': 'Publication signalee.',
        'post.report_failed': 'Le signalement n a pas pu etre termine.',
        'post.hide_failed': 'Le masquage n a pas pu etre termine.',
        'post.reshare_action': 'Repartager',
        'post.reshare_undo': 'Annuler le repartage',
        'post.reshared_you': 'vous l avez repartagee',
        'post.reshared_by': '@name l a repartagee',
        'short.next_post': 'Passer a la publication suivante',
        'short.publish_as_post': 'Publier comme post',
        'short.add_to_story': 'Ajouter a votre story',
        'short.shared_as_post_by': 'Partage comme publication par',
        'story.seens_title': 'Vues (@count)',
        'story.no_seens': 'Personne n a vu votre story',
        'story.comments_title': 'Commentaires (@count)',
        'story.share_title': 'Story de @name',
        'story.share_desc': 'Voir la story sur TurqApp',
        'story.drawing_title': 'Ajouter un dessin',
        'story.brush_color': 'Couleur du pinceau',
        'story.no_comments': 'Personne n a commente',
        'story.add_comment_for': 'Ajouter un commentaire pour @nickname..',
        'story.delete_message': 'Supprimer cette story ?',
        'story.permanent_delete': 'Supprimer definitivement',
        'story.permanent_delete_message':
            'Supprimer cette story definitivement ?',
        'story.comment_delete_message':
            'Voulez-vous vraiment supprimer ce commentaire ?',
        'story.deleted_stories.title': 'Stories',
        'story.deleted_stories.tab_deleted': 'Supprimees',
        'story.deleted_stories.tab_expired': 'Expirees',
        'story.deleted_stories.empty': 'Il n y a pas de stories supprimees',
        'story.deleted_stories.snackbar_title': 'Story',
        'story.deleted_stories.reposted': 'Story repartagee',
        'story.deleted_stories.deleted_forever':
            'Story supprimee definitivement',
        'story.deleted_stories.deleted_at': 'Supprimee : @time',
        'admin_push.queue_title': 'Push',
        'admin_push.queue_body_count':
            'Push mis en file d attente pour @count utilisateurs',
        'admin_push.queue_body': 'Push mis en file d attente',
        'admin_push.failed_body': 'Le push n a pas pu etre envoye.',
        'story_music.title': 'Musique',
        'story_music.no_active_stories':
            'Aucune story active avec cette musique',
        'story_music.untitled': 'Titre sans nom',
        'story_music.active_story_count': '@count stories actives',
        'story_music.minutes_ago': '@count min',
        'story_music.hours_ago': '@count h',
        'story_music.days_ago': '@count j',
        'chat.attach_photos': 'Photos',
        'chat.list_title': 'Discussions',
        'chat.tab_all': 'Toutes',
        'chat.tab_unread': 'Non lues',
        'chat.tab_archive': 'Archives',
        'chat.empty_title': 'Vous n avez pas encore de discussions',
        'chat.empty_body':
            'Quand vous commencerez a ecrire, vos conversations apparaitront ici.',
        'chat.action_failed':
            'L action n a pas pu etre terminee en raison d un probleme d autorisation ou d enregistrement',
        'chat.attach_videos': 'Videos',
        'chat.attach_location': 'Localisation',
        'chat.message_hint': 'Message',
        'chat.no_starred_messages': 'Aucun message favori',
        'chat.profile_stats':
            '@followers abonnes · @following abonnements · @posts publications',
        'chat.selected_messages': '@count messages selectionnes',
        'chat.today': 'Aujourd hui',
        'chat.yesterday': 'Hier',
        'chat.typing': 'est en train d ecrire...',
        'chat.gif': 'GIF',
        'chat.ready_to_send': 'Pret a envoyer',
        'chat.editing_message': 'Modification du message',
        'chat.video': 'Video',
        'chat.audio': 'Audio',
        'chat.location': 'Localisation',
        'chat.post': 'Publication',
        'chat.person': 'Personne',
        'chat.reply': 'Repondre',
        'chat.recording_timer': 'Enregistrement... @time',
        'chat.fetching_address': 'Recuperation de l adresse...',
        'chat.add_star': 'Ajouter une etoile',
        'chat.remove_star': 'Retirer l etoile',
        'chat.you': 'Vous',
        'chat.hide_photos': 'Masquer les photos',
        'chat.unsent_message': 'Message retire',
        'chat.reply_prompt': 'Repondre',
        'chat.open_in_maps': 'Ouvrir dans Maps',
        'chat.open_in_google_maps': 'Ouvrir dans Google Maps',
        'chat.open_in_apple_maps': 'Ouvrir dans Apple Maps',
        'chat.open_in_yandex_maps': 'Ouvrir dans Yandex Maps',
        'chat.contact_info': 'Informations du contact',
        'chat.save_to_contacts': 'Enregistrer dans les contacts',
        'chat.call': 'Appeler',
        'chat.delete_message_title': 'Supprimer le message',
        'chat.delete_message_body':
            'Voulez-vous vraiment supprimer ce message ?',
        'chat.delete_for_me': 'Supprimer pour moi',
        'chat.delete_for_everyone': 'Supprimer pour tout le monde',
        'chat.delete_photo_title': 'Supprimer la photo',
        'chat.delete_photo_body':
            'Voulez-vous vraiment supprimer cette photo ?',
        'chat.delete_photo_confirm': 'Supprimer la photo',
        'chat.messages_delete_failed':
            'Les messages n ont pas pu etre supprimes',
        'chat.image_upload_failed': 'Echec du televersement de l image',
        'chat.image_upload_failed_with_error':
            'Echec du televersement de l image : @error',
        'chat.video_upload_failed':
            'Une erreur est survenue lors du televersement de la video',
        'chat.microphone_permission_required': 'Autorisation requise',
        'chat.microphone_permission_denied':
            'L autorisation du microphone a ete refusee',
        'chat.voice_record_start_failed':
            'Impossible de demarrer l enregistrement audio',
        'chat.voice_message_upload_failed':
            'Une erreur est survenue lors du televersement du message vocal',
        'chat.message_send_failed':
            'Le message n a pas pu etre envoye. Veuillez reessayer.',
        'chat.shared_post_from': 'A envoye la publication de @nickname',
        'chat.notif_video': 'A envoye une video',
        'chat.notif_audio': 'A envoye un message vocal',
        'chat.notif_images': 'A envoye @count images',
        'chat.notif_post': 'A partage une publication',
        'chat.notif_location': 'A envoye une localisation',
        'chat.notif_contact': 'A partage un contact',
        'chat.notif_gif': 'A envoye un GIF',
        'chat.reply_target_missing':
            'Le message auquel vous repondez est introuvable',
        'chat.forwarded_title': 'Transfere',
        'chat.forwarded_body':
            'Le message a ete transfere a la discussion selectionnee',
        'chat.tap_to_chat': 'Touchez pour commencer a discuter.',
        'chat.photo': 'Photo',
        'chat.message_label': 'Message',
        'chat.marked_unread': 'Discussion marquee comme non lue',
        'chat.limit_title': 'Limite',
        'chat.pin_limit': 'Vous pouvez epingler jusqu a 5 discussions',
        'chat.action_completed': 'Action terminee',
        'chat.muted': 'Discussion en sourdine',
        'chat.unmuted': 'Discussion reactivee',
        'chat.archived': 'Discussion archivee',
        'chat.unarchived': 'Discussion retiree des archives',
        'chat.delete_title': 'Supprimer la discussion',
        'chat.delete_message':
            'Voulez-vous vraiment supprimer cette discussion ?',
        'chat.delete_confirm': 'Supprimer la discussion',
        'chat.deleted_title': 'Discussion supprimee',
        'chat.deleted_body':
            'La discussion selectionnee a ete supprimee avec succes',
        'chat.unmute': 'Retirer le mode silencieux',
        'chat.mute': 'Mettre en sourdine',
        'chat.mark_unread': 'Marquer comme non lu',
        'chat.pin': 'Epingler',
        'chat.unpin': 'Desepingler',
        'chat.muted_label': 'Silencieux',
        'training.comments_title': 'Commentaires',
        'training.no_comments': 'Pas encore de commentaires.',
        'training.reply': 'Repondre',
        'training.hide_replies': 'Masquer les reponses',
        'training.view_replies': 'Voir @count reponses',
        'training.unknown_user': 'Utilisateur inconnu',
        'training.edit': 'Modifier',
        'training.report': 'Signaler',
        'training.reply_to_user': 'Repondre a @name',
        'training.cancel': 'Annuler',
        'training.edit_comment_hint': 'Modifier le commentaire',
        'training.write_hint': 'Ecrire..',
        'training.pick_from_gallery': 'Choisir depuis la galerie',
        'training.take_photo': 'Prendre une photo',
        'training.time_now': 'a l instant',
        'training.time_min': 'il y a @count min',
        'training.time_hour': 'il y a @count h',
        'training.time_day': 'il y a @count j',
        'training.time_week': 'il y a @count sem',
        'training.photo_pick_failed':
            'Une erreur est survenue lors de la selection de la photo !',
        'training.photo_upload_failed':
            'Une erreur est survenue lors du televersement de la photo !',
        'training.question_bank_title': 'Banque de questions',
        'training.questions_loading': 'Chargement des questions...',
        'training.solve_later_empty':
            'Aucune question a resoudre plus tard n a ete trouvee !',
        'training.remove_solve_later': 'Retirer de Resoudre plus tard',
        'training.no_questions': 'Aucune question trouvee !',
        'training.answer_first': 'Repondez d abord a la question !',
        'training.share': 'Partager',
        'training.correct_ratio': '%@value Correct',
        'training.wrong_ratio': '%@value Incorrect',
        'training.complaint_select_one':
            'Veuillez choisir au moins une option de signalement.',
        'training.complaint_thanks':
            'Merci pour votre signalement.',
        'training.complaint_submit_failed':
            'Une erreur est survenue lors de l envoi de votre signalement.',
        'training.no_questions_in_category':
            'Aucune question n a ete trouvee dans cette categorie.',
        'training.saved_load_failed':
            'Une erreur est survenue lors du chargement des questions enregistrees.',
        'training.view_update_failed':
            'Une erreur est survenue lors de la mise a jour de la vue.',
        'training.saved_removed':
            'Question retiree de la liste Resoudre plus tard !',
        'training.saved_added':
            'Question ajoutee a la liste Resoudre plus tard !',
        'training.saved_remove_failed':
            'Une erreur est survenue lors du retrait de Resoudre plus tard.',
        'training.saved_update_failed':
            'Une erreur est survenue lors de la mise a jour de Resoudre plus tard.',
        'training.like_removed': 'Mention J aime retiree !',
        'training.liked': 'Question aimee !',
        'training.like_remove_failed':
            'Une erreur est survenue lors du retrait du J aime.',
        'training.like_add_failed':
            'Une erreur est survenue lors de l ajout du J aime.',
        'training.share_failed': 'Le partage n a pas pu etre lance',
        'training.share_question_link_title':
            '@exam - @lesson Question @number',
        'training.share_question_title':
            'TurqApp - @exam @lesson Question',
        'training.share_question_desc':
            'Question de la banque de questions TurqApp',
        'training.leaderboard_empty':
            'Aucun classement n a encore ete cree.',
        'training.leaderboard_empty_body':
            'Resolvez des questions dans la banque pour rejoindre le classement.',
        'training.answer_locked':
            'Vous ne pouvez pas modifier la reponse a cette question !',
        'training.answer_saved':
            'La reponse a cette question a deja ete enregistree.',
        'training.answer_save_failed':
            'Une erreur est survenue lors de l enregistrement de la reponse',
        'training.no_more_questions':
            'Il n y a plus de questions dans cette categorie !',
        'training.settings_opening':
            'Ouverture de l ecran des parametres !',
        'training.fetch_more_failed':
            'Une erreur est survenue lors du chargement de nouvelles questions',
        'training.comments_load_failed':
            'Une erreur est survenue lors du chargement des commentaires. Veuillez reessayer !',
        'training.comment_or_photo_required':
            'Vous devez ajouter un commentaire ou une photo !',
        'training.reply_or_photo_required':
            'Vous devez ajouter une reponse ou une photo !',
        'training.comment_added': 'Votre commentaire a ete ajoute !',
        'training.comment_add_failed':
            'Une erreur est survenue lors de l ajout du commentaire. Veuillez reessayer !',
        'training.reply_added': 'Votre reponse a ete ajoutee !',
        'training.reply_add_failed':
            'Une erreur est survenue lors de l ajout de la reponse. Veuillez reessayer !',
        'training.comment_deleted': 'Votre commentaire a ete supprime !',
        'training.comment_delete_failed':
            'Une erreur est survenue lors de la suppression du commentaire. Veuillez reessayer !',
        'training.reply_deleted': 'Votre reponse a ete supprimee !',
        'training.reply_delete_failed':
            'Une erreur est survenue lors de la suppression de la reponse. Veuillez reessayer !',
        'training.comment_updated': 'Votre commentaire a ete mis a jour !',
        'training.comment_update_failed':
            'Une erreur est survenue lors de la modification du commentaire. Veuillez reessayer !',
        'training.reply_updated': 'Votre reponse a ete mise a jour !',
        'training.reply_update_failed':
            'Une erreur est survenue lors de la modification de la reponse. Veuillez reessayer !',
        'training.like_failed':
            'Une erreur est survenue pendant le like. Veuillez reessayer !',
        'training.upload_failed_title': 'Echec du televersement !',
        'training.upload_failed_body':
            'Ce contenu ne peut pas etre traite pour le moment. Veuillez essayer un autre contenu.',
        'common.accept': 'Accepter',
        'common.reject': 'Refuser',
        'common.open_profile': 'Ouvrir le profil',
        'tutoring.title': 'Cours particuliers',
        'tutoring.search_hint': 'Quel type de cours recherchez-vous ?',
        'tutoring.my_applications': 'Mes candidatures',
        'tutoring.create_listing': 'Publier une annonce',
        'tutoring.my_listings': 'Mes annonces',
        'tutoring.saved': 'Enregistres',
        'tutoring.slider_admin': 'Gestion du slider',
        'tutoring.review_title': 'Laisser un avis',
        'tutoring.review_hint': 'Ecrivez votre commentaire (optionnel)',
        'tutoring.review_select_rating':
            'Veuillez selectionner une note.',
        'tutoring.review_saved': 'Votre avis a ete enregistre.',
        'tutoring.applicants_title': 'Candidats',
        'tutoring.no_applications': 'Il n y a pas encore de candidature',
        'tutoring.application_label': 'Candidature de cours particuliers',
        'tutoring.my_applications_empty':
            'Vous n avez encore fait aucune candidature de cours particuliers',
        'tutoring.instructor_fallback': 'Enseignant',
        'tutoring.cancel_application_title': 'Annuler la candidature',
        'tutoring.cancel_application_body':
            'Voulez-vous vraiment annuler cette candidature ?',
        'tutoring.cancel_application_action': 'Annuler la candidature',
        'tutoring.my_listings_title': 'Mes annonces',
        'tutoring.published': 'Publie',
        'tutoring.expired': 'Expire',
        'tutoring.active_listings_empty':
            'Il n y a pas d annonces de cours particuliers actives.',
        'tutoring.expired_listings_empty':
            'Il n y a pas d annonces de cours particuliers expirees.',
        'tutoring.user_id_missing':
            'Identifiant utilisateur introuvable.',
        'tutoring.load_failed':
            'Une erreur s est produite lors du chargement des annonces : {error}',
        'tutoring.reactivated_title': 'Annonce reactivee',
        'tutoring.reactivated_body': 'L annonce a ete republiee.',
        'tutoring.user_load_failed':
            'Une erreur s est produite lors du chargement des informations utilisateur : {error}',
        'tutoring.location_missing': 'Localisation introuvable',
        'tutoring.no_listings_in_region':
            'Aucune annonce de cours dans cette zone.',
        'tutoring.no_lessons_in_category':
            'Aucun cours dans la categorie {category}.',
        'tutoring.search_empty':
            'Aucune annonce ne correspond a votre recherche.',
        'tutoring.search_empty_info':
            'Aucune annonce de cours particuliers correspondante !',
        'tutoring.similar_listings': 'Annonces similaires',
        'tutoring.open_listing': 'Ouvrir l annonce',
        'tutoring.report_listing': 'Signaler l annonce',
        'tutoring.saved_empty': 'Aucune annonce enregistree.',
        'tutoring.detail_description': 'Description',
        'tutoring.detail_no_description':
            'Aucune description n a ete ajoutee a cette annonce.',
        'tutoring.detail_lesson_info': 'Informations sur le cours',
        'tutoring.detail_branch': 'Branche',
        'tutoring.detail_price': 'Prix',
        'tutoring.detail_contact': 'Contact',
        'tutoring.detail_phone_and_message': 'Telephone + Message',
        'tutoring.detail_message_only': 'Message uniquement',
        'tutoring.detail_gender_preference': 'Preference de genre',
        'tutoring.detail_availability': 'Disponibilite',
        'tutoring.detail_listing_info': 'Informations sur l annonce',
        'tutoring.detail_instructor': 'Enseignant',
        'tutoring.detail_not_specified': 'Non precise',
        'tutoring.detail_city': 'Ville',
        'tutoring.detail_views': 'Vues',
        'tutoring.detail_status': 'Statut',
        'tutoring.detail_status_passive': 'Passif',
        'tutoring.detail_status_active': 'Actif',
        'tutoring.detail_location': 'Localisation',
        'tutoring.create.city_select': 'Selectionner une ville',
        'tutoring.create.district_select': 'Selectionner un district',
        'tutoring.create.nsfw_check_failed':
            'La verification NSFW de l image a echoue.',
        'tutoring.create.nsfw_detected':
            'Une image inappropriee a ete detectee.',
        'tutoring.create.fill_required':
            'Veuillez remplir tous les champs obligatoires !',
        'tutoring.create.published':
            'L annonce de cours particuliers a ete publiee !',
        'tutoring.create.publish_failed':
            'Une erreur est survenue lors de la publication de l annonce.',
        'tutoring.create.updated': 'Annonce mise a jour !',
        'tutoring.create.no_changes':
            'Aucune modification n a ete effectuee !',
        'tutoring.create.update_failed':
            'Une erreur est survenue lors de la mise a jour de l annonce.',
        'tutoring.call_disabled':
            'Les appels sont desactives pour cette annonce.',
        'tutoring.message': 'Message',
        'tutoring.messages': 'Messages',
        'tutoring.phone_missing':
            'Le numero de telephone de l enseignant est introuvable.',
        'tutoring.phone_open_failed':
            'Impossible d ouvrir l application telephone.',
        'tutoring.unpublish_title': 'Retirer l annonce',
        'tutoring.unpublish_body':
            'Voulez-vous vraiment retirer cette annonce de cours particuliers de la publication ?',
        'tutoring.unpublished': 'Annonce retiree de la publication.',
        'tutoring.apply_login_required':
            'Reconnectez-vous pour postuler.',
        'tutoring.application_sent':
            'Votre candidature a ete envoyee.',
        'tutoring.application_failed':
            'Un probleme est survenu pendant la candidature.',
        'tutoring.delete_success': 'Annonce supprimee !',
        'tutoring.delete_failed':
            'Une erreur est survenue lors de la suppression de l annonce.',
        'tutoring.filter_title': 'Filtres',
        'tutoring.gender_title': 'Genre',
        'tutoring.sort_title': 'Tri',
        'tutoring.lesson_place_title': 'Lieu du cours',
        'tutoring.service_location_title': 'Zone de service',
        'tutoring.gender.male': 'Homme',
        'tutoring.gender.female': 'Femme',
        'tutoring.gender.any': 'Peu importe',
        'tutoring.sort.latest': 'Les plus recentes',
        'tutoring.sort.nearest': 'Les plus proches',
        'tutoring.sort.most_viewed': 'Les plus vues',
        'tutoring.lesson_place.student_home': 'Chez l eleve',
        'tutoring.lesson_place.teacher_home': 'Chez l enseignant',
        'tutoring.lesson_place.either_home':
            'Chez l eleve ou l enseignant',
        'tutoring.lesson_place.remote': 'Formation a distance',
        'tutoring.lesson_place.lesson_area': 'Zone de cours',
        'tutoring.branch.summer_school': 'Ecole d ete',
        'tutoring.branch.secondary_education': 'Enseignement secondaire',
        'tutoring.branch.primary_education': 'Enseignement primaire',
        'tutoring.branch.foreign_language': 'Langue etrangere',
        'tutoring.branch.software': 'Logiciel',
        'tutoring.branch.driving': 'Conduite',
        'tutoring.branch.sports': 'Sport',
        'tutoring.branch.art': 'Art',
        'tutoring.branch.music': 'Musique',
        'tutoring.branch.theatre': 'Theatre',
        'tutoring.branch.personal_development': 'Developpement personnel',
        'tutoring.branch.vocational': 'Professionnel',
        'tutoring.branch.special_education': 'Education specialisee',
        'tutoring.branch.children': 'Enfants',
        'tutoring.branch.diction': 'Diction',
        'tutoring.branch.photography': 'Photographie',
        'scholarship.applications_title': 'Candidatures (@count)',
        'scholarship.no_applications': 'Aucune candidature pour le moment',
        'scholarship.my_listings': 'Mes annonces de bourse',
        'scholarship.no_my_listings':
            'Vous n avez aucune annonce de bourse !',
        'scholarship.applications_suffix': 'CANDIDATURES BOURSE @title',
        'scholarship.my_applications_title': 'Mes candidatures de bourse',
        'scholarship.no_user_applications':
            'Vous n avez aucune candidature de bourse !',
        'scholarship.saved_empty': 'Aucune bourse enregistree.',
        'scholarship.liked_empty': 'Aucune bourse aimee.',
        'scholarship.remove_saved': 'Retirer des enregistrements',
        'scholarship.remove_liked': 'Retirer des favoris',
        'scholarship.remove_saved_confirm':
            'Voulez-vous vraiment retirer cette bourse des enregistrements ?',
        'scholarship.remove_liked_confirm':
            'Voulez-vous vraiment retirer cette bourse des favoris ?',
        'scholarship.removed_saved':
            'Bourse retiree des enregistrements.',
        'scholarship.removed_liked':
            'Bourse retiree des favoris.',
        'scholarship.list_title': 'Bourses (@count)',
        'scholarship.search_results_title': 'Resultats de recherche (@count)',
        'scholarship.empty_title': 'Aucune bourse pour le moment',
        'scholarship.empty_body': 'De nouvelles bourses seront ajoutees bientot',
        'scholarship.no_results_for':
            'Aucun resultat pour "@query"',
        'scholarship.search_hint_body':
            'Astuce : essayez d autres mots-cles',
        'scholarship.search_tip_header': 'Vous pouvez rechercher par :',
        'scholarship.load_more_failed':
            'Impossible de charger plus de bourses.',
        'scholarship.like_failed': 'Echec du like.',
        'scholarship.bookmark_failed': 'Echec de l enregistrement.',
        'scholarship.share_owner_only':
            'Seuls les admins et le proprietaire de l annonce peuvent partager.',
        'scholarship.share_missing_id':
            'Identifiant de bourse introuvable pour le partage.',
        'scholarship.share_failed': 'Echec du partage.',
        'scholarship.share_fallback_desc': 'Annonce de bourse TurqApp',
        'scholarship.share_detail_title':
            'TurqApp Education - Detail de la bourse',
        'scholarship.providers_title': 'Organismes de bourse',
        'scholarship.providers_empty':
            'Aucun organisme de bourse trouve.',
        'scholarship.providers_load_failed':
            'Impossible de charger les organismes de bourse.',
        'scholarship.applications_load_failed':
            'Impossible de charger les candidatures.',
        'scholarship.withdraw_application': 'Retirer la candidature',
        'scholarship.withdraw_confirm_title': 'Attention !',
        'scholarship.withdraw_confirm_body':
            'Voulez-vous vraiment retirer votre candidature ?',
        'scholarship.withdraw_success':
            'Votre candidature a la bourse a ete retiree.',
        'scholarship.withdraw_failed':
            'La candidature n a pas pu etre retiree.',
        'scholarship.session_missing':
            'La session utilisateur n est pas active.',
        'scholarship.create_title': 'Creer une bourse',
        'scholarship.edit_title': 'Modifier la bourse',
        'scholarship.preview_title': 'Apercu de la bourse',
        'scholarship.visual_info': 'Informations visuelles',
        'scholarship.basic_info': 'Informations de base',
        'scholarship.application_info': 'Informations de candidature',
        'scholarship.extra_info': 'Informations supplementaires',
        'scholarship.title_label': 'Titre de la bourse',
        'scholarship.provider_label': 'Organisme de bourse',
        'scholarship.website_label': 'Site web',
        'scholarship.description_help':
            'Veuillez rediger la description de la bourse en un seul bloc clair.',
        'scholarship.no_description': 'Aucune description',
        'scholarship.conditions_label': 'Conditions de candidature',
        'scholarship.required_docs_label': 'Documents requis',
        'scholarship.award_months_label': 'Mois de versement',
        'scholarship.application_place_label': 'Lieu de candidature',
        'scholarship.application_place_turqapp': 'TurqApp',
        'scholarship.application_place_website': 'Site web de la bourse',
        'scholarship.application_website_label': 'Site web de la bourse',
        'scholarship.application_dates_label': 'Dates de candidature',
        'scholarship.detail_missing':
            'Erreur : donnees de bourse introuvables.',
        'scholarship.detail_title': 'Detail de la bourse',
        'scholarship.delete_title': 'Supprimer la bourse',
        'scholarship.delete_confirm':
            'Voulez-vous vraiment supprimer cette bourse ?',
        'scholarship.applications_heading': 'Candidatures a la bourse @title',
        'scholarship.applicant.personal_section': 'Informations personnelles',
        'scholarship.applicant.education_section':
            'Informations sur l education',
        'scholarship.applicant.family_section': 'Informations familiales',
        'scholarship.applicant.full_name': 'Nom complet',
        'scholarship.applicant.email': 'Adresse e-mail',
        'scholarship.applicant.phone': 'Numero de telephone',
        'scholarship.applicant.phone_open_failed':
            'Impossible de lancer l appel telephonique',
        'scholarship.applicant.email_open_failed':
            'Impossible d ouvrir le client e-mail',
        'chat.sign_in_required':
            'Vous devez vous connecter pour envoyer un message.',
        'chat.cannot_message_self_listing':
            'Vous ne pouvez pas envoyer un message a votre propre annonce.',
        'scholarship.applicant.country': 'Pays',
        'scholarship.applicant.registry_city': 'Ville du registre',
        'scholarship.applicant.registry_district': 'District du registre',
        'scholarship.applicant.birth_date': 'Date de naissance',
        'scholarship.applicant.marital_status': 'Etat civil',
        'scholarship.applicant.gender': 'Genre',
        'scholarship.applicant.disability_report': 'Rapport de handicap',
        'scholarship.applicant.employment_status': "Situation d'emploi",
        'scholarship.applicant.education_level': "Niveau d'education",
        'scholarship.applicant.university': 'Universite',
        'scholarship.applicant.faculty': 'Faculte',
        'scholarship.applicant.department': 'Departement',
        'scholarship.applicant.father_alive': 'Le pere est-il en vie ?',
        'scholarship.applicant.father_name': 'Nom du pere',
        'scholarship.applicant.father_surname': 'Prenom du pere',
        'scholarship.applicant.father_phone': 'Telephone du pere',
        'scholarship.applicant.father_job': 'Profession du pere',
        'scholarship.applicant.father_income': 'Revenu du pere',
        'scholarship.applicant.mother_alive': 'La mere est-elle en vie ?',
        'scholarship.applicant.mother_name': 'Nom de la mere',
        'scholarship.applicant.mother_surname': 'Prenom de la mere',
        'scholarship.applicant.mother_phone': 'Telephone de la mere',
        'scholarship.applicant.mother_job': 'Profession de la mere',
        'scholarship.applicant.mother_income': 'Revenu de la mere',
        'scholarship.applicant.home_ownership': 'Statut du logement',
        'scholarship.applicant.residence_city': 'Ville de residence',
        'scholarship.applicant.residence_district': 'District de residence',
        'family_info.title': 'Informations familiales',
        'family_info.reset_menu': 'Reinitialiser les informations familiales',
        'family_info.reset_title': 'Reinitialiser les informations familiales',
        'family_info.reset_body':
            'Toutes vos informations familiales seront supprimees. Cette action est irreversible. Etes-vous sur ?',
        'family_info.select_father_alive':
            'Veuillez indiquer si votre pere est en vie',
        'family_info.select_mother_alive':
            'Veuillez indiquer si votre mere est en vie',
        'family_info.father_name_surname': 'Nom et prenom du pere',
        'family_info.mother_name_surname': 'Nom et prenom de la mere',
        'family_info.select_job': 'Choisir une profession',
        'family_info.father_salary': 'Salaire net du pere',
        'family_info.mother_salary': 'Salaire net de la mere',
        'family_info.father_phone': 'Numero du pere',
        'family_info.mother_phone': 'Numero de la mere',
        'family_info.salary_hint': 'Salaire net',
        'family_info.family_size': 'Taille de la famille',
        'family_info.family_size_hint':
            'Nombre de personnes vivant dans le foyer (y compris vous)',
        'family_info.residence_info': 'Informations de residence',
        'family_info.father_salary_missing': 'Information de salaire du pere',
        'family_info.father_phone_missing': 'Numero de telephone du pere',
        'family_info.father_phone_invalid':
            'Le numero du pere doit comporter 10 chiffres',
        'family_info.mother_salary_missing': 'Information de salaire de la mere',
        'family_info.mother_phone_missing': 'Numero de telephone de la mere',
        'family_info.mother_phone_invalid':
            'Le numero de la mere doit comporter 10 chiffres',
        'family_info.saved': 'Vos informations familiales ont ete enregistrees.',
        'family_info.save_failed':
            'Impossible d enregistrer les informations.',
        'family_info.reset_success':
            'Les informations familiales ont ete reinitialisees.',
        'family_info.reset_failed':
            'Impossible de reinitialiser les informations.',
        'family_info.home_owned': 'Maison personnelle',
        'family_info.home_relative': 'Maison d un proche',
        'family_info.home_lodging': 'Logement de fonction',
        'family_info.home_rent': 'Location',
        'personal_info.title': 'Informations personnelles',
        'personal_info.reset_menu': 'Reinitialiser mes informations',
        'personal_info.reset_title': 'Etes-vous sur ?',
        'personal_info.reset_body':
            'Vos informations personnelles seront reinitialisees. Cette action est irreversible.',
        'personal_info.reset_success':
            'Vos informations personnelles ont ete reinitialisees.',
        'personal_info.registry_info': 'Ville - district d enregistrement',
        'personal_info.birth_date_title': 'Votre date de naissance',
        'personal_info.select_birth_date': 'Choisir la date de naissance',
        'personal_info.select_marital_status': 'Choisir l etat civil',
        'personal_info.select_gender': 'Choisir le genre',
        'personal_info.select_disability': 'Choisir le statut de handicap',
        'personal_info.select_employment': "Choisir la situation d'emploi",
        'personal_info.select_field': 'Choisir @field',
        'personal_info.city_load_failed':
            'Les donnees de ville et de district n ont pas pu etre chargees.',
        'personal_info.user_data_missing':
            'Les donnees utilisateur sont introuvables. Vous pouvez creer un nouvel enregistrement.',
        'personal_info.load_failed': 'Les donnees n ont pas pu etre chargees.',
        'personal_info.select_country_error': 'Veuillez choisir un pays.',
        'personal_info.fill_city_district':
            'Veuillez renseigner la ville et le district.',
        'personal_info.saved':
            'Vos informations personnelles ont ete enregistrees.',
        'personal_info.save_failed':
            'Impossible d enregistrer les informations.',
        'personal_info.marital_single': 'Celibataire',
        'personal_info.marital_married': 'Marie',
        'personal_info.marital_divorced': 'Divorce',
        'personal_info.gender_male': 'Homme',
        'personal_info.gender_female': 'Femme',
        'personal_info.disability_yes': 'Oui',
        'personal_info.disability_no': 'Non',
        'personal_info.working_yes': 'Travaille',
        'personal_info.working_no': 'Ne travaille pas',
        'education_info.title': 'Informations sur l education',
        'education_info.reset_menu':
            'Reinitialiser mes informations d education',
        'education_info.reset_title': 'Etes-vous sur ?',
        'education_info.reset_body':
            'Vos informations d education seront reinitialisees. Cette action est irreversible.',
        'education_info.reset_success':
            'Vos informations d education ont ete reinitialisees.',
        'education_info.select_level':
            'Veuillez d abord choisir un niveau d education !',
        'education_info.middle_school': 'Ecole',
        'education_info.high_school': 'Lycee',
        'education_info.class_level': 'Classe',
        'education_info.level_middle_school': 'College',
        'education_info.level_high_school': 'Lycee',
        'education_info.level_associate': 'Cycle court',
        'education_info.level_bachelor': 'Licence',
        'education_info.level_masters': 'Master',
        'education_info.level_doctorate': 'Doctorat',
        'education_info.class_grade': '@gradee classe',
        'education_info.select_field': 'Choisir @field',
        'education_info.initial_load_failed':
            'Les donnees initiales n ont pas pu etre chargees.',
        'education_info.countries_load_failed':
            'Les pays n ont pas pu etre charges.',
        'education_info.city_data_failed':
            'Les donnees de ville et de district n ont pas pu etre chargees.',
        'education_info.middle_schools_failed':
            'Les donnees d ecole n ont pas pu etre chargees.',
        'education_info.high_schools_failed':
            'Les donnees de lycee n ont pas pu etre chargees.',
        'education_info.higher_education_failed':
            'Les donnees de l enseignement superieur n ont pas pu etre chargees.',
        'education_info.saved_data_failed':
            'Les donnees enregistrees n ont pas pu etre chargees.',
        'education_info.level_load_failed':
            'Les donnees du niveau n ont pas pu etre chargees.',
        'education_info.select_city_error': 'Veuillez choisir une ville.',
        'education_info.select_district_error':
            'Veuillez choisir un district.',
        'education_info.select_middle_school_error':
            'Veuillez choisir un college.',
        'education_info.select_high_school_error':
            'Veuillez choisir un lycee.',
        'education_info.select_class_level_error':
            'Veuillez choisir un niveau de classe.',
        'education_info.select_university_error':
            'Veuillez choisir une universite.',
        'education_info.select_faculty_error':
            'Veuillez choisir une faculte.',
        'education_info.select_department_error':
            'Veuillez choisir un departement.',
        'education_info.saved':
            'Vos informations d education ont ete enregistrees.',
        'education_info.save_failed': 'Echec de l enregistrement.',
        'bank_info.title': 'Informations bancaires',
        'bank_info.reset_menu': 'Reinitialiser mes informations bancaires',
        'bank_info.reset_title': 'Etes-vous sur ?',
        'bank_info.reset_body':
            'Vos informations bancaires seront reinitialisees. Cette action est irreversible.',
        'bank_info.reset_success':
            'Vos informations bancaires ont ete reinitialisees.',
        'bank_info.fast_title': 'Adresse rapide (FAST)',
        'bank_info.fast_email': 'E-mail',
        'bank_info.fast_phone': 'Telephone',
        'bank_info.fast_iban': 'IBAN',
        'bank_info.bank_label': 'Banque',
        'bank_info.select_bank': 'Choisir une banque',
        'bank_info.select_fast_type': 'Choisir le type d adresse rapide',
        'bank_info.load_failed': 'Les donnees n ont pas pu etre chargees.',
        'bank_info.missing_value':
            'Nous ne pouvons pas continuer sans completer les informations IBAN.',
        'bank_info.missing_bank':
            'Vous n avez pas choisi la banque qui recevra le paiement. Cette information sera partagee si votre bourse est approuvee.',
        'bank_info.invalid_email':
            'Veuillez saisir une adresse e-mail valide.',
        'bank_info.saved': 'Les informations bancaires ont ete enregistrees.',
        'bank_info.save_failed':
            'Impossible d enregistrer les informations.',
        'dormitory.title': 'Informations sur le dortoir',
        'dormitory.reset_menu':
            'Reinitialiser mes informations de dortoir',
        'dormitory.reset_title': 'Etes-vous sur ?',
        'dormitory.reset_body':
            'Vos informations de dortoir seront reinitialisees. Cette action est irreversible.',
        'dormitory.reset_success':
            'Vos informations de dortoir ont ete reinitialisees.',
        'dormitory.current_info': 'Information actuelle sur le dortoir',
        'dormitory.select_admin_type':
            'Choisir le type d administration',
        'dormitory.admin_public': 'Public',
        'dormitory.admin_private': 'Prive',
        'dormitory.select_dormitory': 'Choisir un dortoir',
        'dormitory.not_found_for_filters':
            'Aucun dortoir trouve pour cette ville et ce type d administration',
        'dormitory.saved': 'Vos informations de dortoir ont ete enregistrees.',
        'dormitory.save_failed':
            'Impossible d enregistrer les donnees.',
        'dormitory.select_or_enter':
            'Veuillez choisir un dortoir ou saisir un nom',
        'scholarship.application_start_date': 'Date de debut des candidatures',
        'scholarship.application_end_date': 'Date de fin des candidatures',
        'scholarship.select_from_list': 'Choisir dans la liste',
        'scholarship.image_missing': 'Aucune image trouvee',
        'scholarship.amount_label': 'Montant',
        'scholarship.student_count_label': 'Nombre d etudiants',
        'scholarship.repayable_label': 'Remboursable',
        'scholarship.duplicate_status_label': 'Statut de cumul',
        'scholarship.education_audience_label': 'Public educatif',
        'scholarship.target_audience_label': 'Public cible',
        'scholarship.country_label': 'Pays',
        'scholarship.cities_label': 'Villes',
        'scholarship.universities_label': 'Universites',
        'scholarship.published_at': 'Date de publication',
        'scholarship.show_less': 'Voir moins',
        'scholarship.show_all': 'Tout afficher',
        'scholarship.more_universities': '+@count universites en plus',
        'scholarship.other_info': 'Autres informations',
        'scholarship.application_how': 'Comment postuler ?',
        'scholarship.application_via_turqapp_prefix':
            'Les candidatures via TurqApp sont ',
        'scholarship.application_received_status': 'ACCEPTEES.',
        'scholarship.application_not_received_status': 'NON ACCEPTEES.',
        'scholarship.edit_button': 'Modifier la bourse',
        'scholarship.website_open_failed':
            'Le site web n a pas pu etre ouvert. Veuillez saisir une URL valide.',
        'scholarship.checking_info': 'Verification des informations',
        'scholarship.user_data_missing':
            'Les donnees utilisateur sont introuvables. Veuillez completer vos informations.',
        'scholarship.check_info_failed':
            'Une erreur est survenue lors de la verification des informations.',
        'scholarship.application_check_failed':
            'Une erreur est survenue lors de la verification du statut de candidature.',
        'scholarship.login_required': 'Veuillez vous connecter.',
        'scholarship.profile_missing':
            'Aucune information de profil n est disponible pour cette bourse.',
        'scholarship.applied_success':
            'Votre candidature a la bourse a ete recue.',
        'scholarship.apply_failed':
            'La candidature n a pas pu etre enregistree.',
        'scholarship.follow_limit_title': 'Limite de suivi',
        'scholarship.follow_limit_body':
            'Vous ne pouvez pas suivre davantage de personnes aujourd hui.',
        'scholarship.follow_failed':
            'L action de suivi a echoue.',
        'scholarship.invalid': 'Bourse invalide.',
        'scholarship.delete_success': 'Bourse supprimee avec succes.',
        'scholarship.delete_failed':
            'Une erreur est survenue lors de la suppression de la bourse.',
        'scholarship.cancel_success':
            'Votre candidature a la bourse a ete annulee.',
        'scholarship.cancel_failed':
            'La candidature n a pas pu etre annulee.',
        'scholarship.info_missing_title': 'Informations manquantes',
        'scholarship.info_missing_body':
            'Vous ne pouvez pas postuler a des bourses sans remplir vos informations personnelles, scolaires et familiales.',
        'scholarship.update_my_info': 'Mettre a jour mes informations',
        'scholarship.closed': 'Candidature fermee',
        'scholarship.applied': 'Candidature envoyee',
        'scholarship.cancel_apply_title': 'Annuler la candidature',
        'scholarship.cancel_apply_body':
            'Voulez-vous vraiment annuler cette candidature de bourse ?',
        'scholarship.cancel_apply_button': 'Annuler la candidature',
        'scholarship.amount_hint': 'Montant',
        'scholarship.student_count_hint': 'ex. 4',
        'scholarship.amount_student_count_notice':
            'Le montant et le nombre d etudiants ne sont pas affiches sur la page de candidature.',
        'scholarship.degree_type_label': 'Type de diplome',
        'scholarship.degree_type_select': 'Selectionner le type de diplome',
        'scholarship.select_country': 'Selectionner le pays',
        'scholarship.select_country_first':
            'Veuillez d abord selectionner un pays.',
        'scholarship.select_city_first':
            'Veuillez d abord selectionner une ville.',
        'scholarship.select_university': 'Selectionner l universite',
        'scholarship.selected_universities': 'Universites selectionnees :',
        'scholarship.logo_label': 'Choisir le logo',
        'scholarship.logo_pick': 'Choisir le logo',
        'scholarship.custom_design_optional': 'Votre design (optionnel)',
        'scholarship.custom_image_pick': 'Choisir l image',
        'scholarship.template_select': 'Choisir le modele',
        'scholarship.file_copy_failed': 'Le fichier n a pas pu etre copie.',
        'scholarship.duplicate_status.can_receive': 'Peut recevoir',
        'scholarship.duplicate_status.cannot_receive_except_kyk':
            'Ne peut pas recevoir (sauf KYK)',
        'scholarship.target.population': 'Selon la population',
        'scholarship.target.residence': 'Selon la residence',
        'scholarship.target.all_turkiye': 'Toute la Turquie',
        'scholarship.info.personal': 'Personnel',
        'scholarship.info.school': 'Ecole',
        'scholarship.info.family': 'Famille',
        'scholarship.info.dormitory': 'Dortoir',
        'scholarship.education.all': 'Tous',
        'scholarship.education.middle_school': 'College',
        'scholarship.education.high_school': 'Lycee',
        'scholarship.education.undergraduate': 'Licence',
        'scholarship.degree.associate': 'Diplome associe',
        'scholarship.degree.bachelor': 'Licence',
        'scholarship.degree.master': 'Master',
        'scholarship.degree.phd': 'Doctorat',
        'single_post.title': 'Publications',
        'edit_post.updating':
            'Veuillez patienter. Votre publication est en cours de mise a jour',
        'edit_profile.title': 'Informations du profil',
        'profile.copy_profile_link': 'Copier le lien du profil',
        'profile.profile_share_title': 'Profil TurqApp',
        'profile.private_account_title': 'Compte prive',
        'profile.private_story_follow_required':
            'Vous devez d abord suivre ce compte pour voir les stories.',
        'profile.unfollow_title': 'Ne plus suivre',
        'profile.unfollow_body':
            'Voulez-vous vraiment ne plus suivre @{nickname} ?',
        'profile.unfollow_confirm': 'Ne plus suivre',
        'profile.following_status': 'Abonne',
        'profile.follow_button': 'Suivre',
        'profile.contact_options': 'Options de contact',
        'profile.unblock': 'Debloquer',
        'profile.remove_highlight_title': 'Retirer le highlight',
        'profile.remove_highlight_body':
            'Voulez-vous vraiment retirer ce highlight ?',
        'profile.remove_highlight_confirm': 'Retirer',
        'social_profile.private_follow_to_see_posts':
            'Suivez ce compte pour voir les publications.',
        'social_profile.blocked_user': 'Vous avez bloque cet utilisateur',
        'edit_profile.personal_info': 'Informations personnelles',
        'edit_profile.other_info': 'Autres informations',
        'edit_profile.first_name_hint': 'Prenom',
        'edit_profile.last_name_hint': 'Nom',
        'edit_profile.privacy': 'Confidentialite du compte',
        'edit_profile.links': 'Liens',
        'edit_profile.contact_info': 'Coordonnees',
        'edit_profile.address_info': 'Informations d adresse',
        'edit_profile.career_profile': 'Profil de carriere',
        'edit_profile.update_success':
            'Les informations de votre profil ont ete mises a jour !',
        'edit_profile.update_failed': 'Erreur de mise a jour : {error}',
        'edit_profile.remove_photo_title': 'Supprimer la photo de profil',
        'edit_profile.remove_photo_message':
            'Votre photo de profil sera supprimee et l avatar par defaut sera utilise. Confirmez-vous ?',
        'edit_profile.photo_removed': 'Votre photo de profil a ete supprimee.',
        'edit_profile.photo_remove_failed':
            'Une erreur est survenue lors de la suppression de la photo de profil.',
        'edit_profile.crop_use': 'Rogner et utiliser',
        'edit_profile.delete_account': 'Supprimer le compte',
        'edit_profile.upload_failed_title': 'Echec du televersement !',
        'edit_profile.upload_failed_body':
            'Ce contenu ne peut pas etre traite pour le moment. Veuillez essayer un autre contenu.',
        'delete_account.title': 'Supprimer le compte',
        'delete_account.confirm_title': 'Confirmation de suppression du compte',
        'delete_account.confirm_body':
            'Avant de supprimer votre compte, nous envoyons un code de verification a votre adresse e-mail enregistree pour des raisons de securite.',
        'delete_account.code_hint': 'Code de verification a 6 chiffres',
        'delete_account.resend': 'Renvoyer',
        'delete_account.send_code': 'Envoyer le code',
        'delete_account.validity_notice':
            'Le code est valide pendant 1 heure. Votre demande de suppression sera traitee definitivement apres {days} jours.',
        'delete_account.processing': 'Traitement...',
        'delete_account.delete_my_account': 'Supprimer mon compte',
        'delete_account.no_email_title': 'Alerte',
        'delete_account.no_email_body':
            'Aucune adresse e-mail n est associee a ce compte. Vous pouvez lancer directement la demande de suppression.',
        'delete_account.session_missing':
            'Session introuvable. Veuillez vous reconnecter.',
        'delete_account.code_sent_title': 'Code envoye',
        'delete_account.code_sent_body':
            'Le code de confirmation de suppression a ete envoye a votre adresse e-mail.',
        'delete_account.send_failed': 'Impossible d envoyer le code.',
        'delete_account.invalid_code_title': 'Code invalide',
        'delete_account.invalid_code_body':
            'Veuillez saisir le code a 6 chiffres.',
        'delete_account.verify_failed':
            'Le code n a pas pu etre verifie.',
        'editor_nickname.title': 'Nom d utilisateur',
        'editor_nickname.hint': 'Creer un nom d utilisateur',
        'editor_nickname.verified_locked':
            'Les utilisateurs verifies ne peuvent pas modifier leur nom d utilisateur',
        'editor_nickname.mimic_warning':
            'Les noms d utilisateur qui imitent de vraies personnes peuvent etre modifies par TurqApp pour proteger notre communaute.',
        'editor_nickname.tr_char_info':
            'Les caracteres turcs sont convertis automatiquement. (ç→c, ğ→g, ı→i, ö→o, ş→s, ü→u)',
        'editor_nickname.min_length': 'Doit contenir au moins 8 caracteres',
        'editor_nickname.current_name':
            'Votre nom d utilisateur actuel',
        'editor_nickname.edit_prompt':
            'Modifiez pour effectuer un changement',
        'editor_nickname.checking': 'Verification…',
        'editor_nickname.taken': 'Ce nom d utilisateur est deja pris',
        'editor_nickname.available': 'Disponible',
        'editor_nickname.unavailable':
            'Verification impossible',
        'editor_nickname.cooldown_limit':
            'Il ne peut etre modifie que 3 fois pendant la premiere heure',
        'editor_nickname.change_after_days':
            'Le nom d utilisateur pourra etre modifie de nouveau dans {days}j {hours}h',
        'editor_nickname.change_after_hours':
            'Le nom d utilisateur pourra etre modifie de nouveau dans {hours}h',
        'editor_nickname.error_min_length':
            'Le nom d utilisateur doit contenir au moins 8 caracteres.',
        'editor_nickname.error_taken':
            'Ce nom d utilisateur est deja pris.',
        'editor_nickname.error_grace_limit':
            'Vous ne pouvez le modifier que 3 fois pendant la premiere heure.',
        'editor_nickname.error_cooldown':
            'Le nom d utilisateur ne peut pas etre modifie de nouveau avant 15 jours.',
        'editor_nickname.error_update_failed':
            'Le nom d utilisateur n a pas pu etre mis a jour.',
        'cv.title': 'Profil de carriere',
        'cv.personal_info': 'Informations personnelles',
        'cv.education_info': 'Informations sur les etudes',
        'cv.other_info': 'Autres informations',
        'cv.profile_title': 'Profil de carriere',
        'cv.profile_body':
            'Renforcez votre profil de carriere avec une photo de profil et des informations essentielles.',
        'cv.first_name_hint': 'Prenom',
        'cv.last_name_hint': 'Nom',
        'cv.email_hint': 'Adresse e-mail',
        'cv.phone_hint': 'Numero de telephone',
        'cv.about_hint': 'Parlez brievement de vous',
        'cv.add_school': 'Ajouter une ecole',
        'cv.add_school_title': 'Ajouter une nouvelle ecole',
        'cv.edit_school_title': 'Modifier l ecole',
        'cv.school_name': 'Nom de l ecole',
        'cv.department': 'Departement',
        'cv.graduation_year': 'Annee de fin',
        'cv.currently_studying': 'Je poursuis mes etudes',
        'cv.missing_school_name':
            'Le nom de l ecole ne peut pas etre vide',
        'cv.invalid_year': 'Veuillez saisir une annee valide',
        'cv.skills': 'Competences',
        'cv.add_skill_title': 'Ajouter une nouvelle competence',
        'cv.skill_name_empty':
            'Le nom de la competence ne peut pas etre vide',
        'cv.skill_exists': 'Cette competence a deja ete ajoutee',
        'cv.skill_hint': 'Competence (ex. Flutter, Photoshop)',
        'cv.add_language': 'Ajouter une langue',
        'cv.add_new_language': 'Ajouter une nouvelle langue',
        'cv.add_language_title': 'Ajouter une nouvelle langue',
        'cv.edit_language_title': 'Modifier la langue',
        'cv.level': 'Niveau',
        'cv.add_experience': 'Ajouter une experience',
        'cv.add_new_experience': 'Ajouter une nouvelle experience',
        'cv.add_experience_title': 'Ajouter une nouvelle experience',
        'cv.edit_experience_title': 'Modifier l experience',
        'cv.company_name': 'Nom de l entreprise',
        'cv.position': 'Poste',
        'cv.description_optional': 'Description du poste (optionnel)',
        'cv.start_year': 'Debut',
        'cv.end_year': 'Fin',
        'cv.currently_working': 'J y travaille encore',
        'cv.ongoing': 'En cours',
        'cv.missing_company_position':
            'Le nom de l entreprise et le poste sont obligatoires',
        'cv.invalid_start_year':
            'Veuillez saisir une annee de debut valide',
        'cv.invalid_end_year':
            'Veuillez saisir une annee de fin valide',
        'cv.add_reference': 'Ajouter une reference',
        'cv.add_new_reference': 'Ajouter une nouvelle reference',
        'cv.add_reference_title': 'Ajouter une nouvelle reference',
        'cv.edit_reference_title': 'Modifier la reference',
        'cv.name_surname': 'Nom et prenom',
        'cv.phone_example': 'Telephone (ex. 05xx..)',
        'cv.missing_name_surname':
            'Le nom et prenom ne peuvent pas etre vides',
        'cv.save': 'Enregistrer',
        'cv.created_title': 'CV cree !',
        'cv.created_body':
            'Vous pouvez maintenant postuler beaucoup plus rapidement',
        'cv.save_failed':
            'Le CV n a pas pu etre enregistre. Veuillez reessayer.',
        'cv.not_signed_in': 'Vous n etes pas connecte.',
        'cv.missing_field': 'Champ manquant',
        'cv.invalid_format': 'Format invalide',
        'cv.missing_first_name':
            'Vous ne pouvez pas enregistrer sans saisir un prenom',
        'cv.missing_last_name':
            'Vous ne pouvez pas enregistrer sans saisir un nom',
        'cv.missing_email':
            'Vous ne pouvez pas enregistrer sans saisir une adresse e-mail',
        'cv.invalid_email':
            'Veuillez saisir une adresse e-mail valide',
        'cv.missing_phone':
            'Vous ne pouvez pas enregistrer sans saisir un numero de telephone',
        'cv.invalid_phone':
            'Veuillez saisir un numero de telephone valide',
        'cv.missing_about':
            'Vous devez fournir une courte presentation de vous',
        'cv.missing_school':
            'Vous ne pouvez pas enregistrer sans ajouter au moins une ecole',
        'qr.title': 'QR code personnel',
        'qr.profile_subject': 'Profil TurqApp',
        'qr.link_copied_title': 'Lien copie',
        'qr.link_copied_body': 'Le lien du profil a ete copie',
        'qr.permission_required': 'Autorisation requise',
        'qr.gallery_permission_body':
            'Vous devez autoriser l acces a la galerie pour enregistrer.',
        'qr.data_failed': 'Impossible de generer les donnees du QR code.',
        'qr.saved': 'Le QR code a ete enregistre dans la galerie.',
        'qr.save_failed': 'Le QR code n a pas pu etre enregistre.',
        'qr.download_failed':
            'Une erreur est survenue pendant le telechargement.',
        'signup.create_account_title': 'Creez votre compte',
        'signup.policy_short':
            'J accepte les contrats et les politiques.',
        'signup.email': 'E-mail',
        'signup.username': 'Nom d utilisateur',
        'signup.password': 'Mot de passe',
        'signup.personal_info': 'Informations personnelles',
        'signup.first_name': 'Prenom',
        'signup.last_name_optional': 'Nom (optionnel)',
        'signup.next': 'Suivant',
        'signup.verification_title': 'Verification',
        'notifications.title': 'Notifications',
        'notifications.categories': 'Categories',
        'notifications.device_notice':
            'Pour voir les notifications sur l ecran verrouille, garde l autorisation active dans les reglages de l appareil.',
        'notifications.pause_all': 'Tout suspendre',
        'notifications.sleep_mode': 'Mode sommeil',
        'notifications.messages': 'Messages',
        'notifications.posts_comments': 'Publications et commentaires',
        'notifications.comments': 'Commentaires',
        'comments.delete_message':
            'Voulez-vous vraiment supprimer ce commentaire ?',
        'comments.delete_failed': 'Le commentaire n a pas pu etre supprime.',
        'comments.title': 'Commentaires',
        'comments.empty': 'Soyez le premier a commenter...',
        'comments.reply': 'Repondre',
        'comments.replying_to': 'Reponse a @nickname',
        'comments.sending': 'Envoi en cours',
        'comments.community_violation_title':
            'Contraire aux regles de la communaute',
        'comments.community_violation_body':
            'Le langage utilise ne respecte pas nos regles de la communaute. Merci d utiliser un langage respectueux.',
        'post_sharers.empty': 'Personne n a encore partage cette publication',
        'notifications.follows': 'Abonnements',
        'notifications.direct_messages': 'Messages directs',
        'notifications.opportunities': 'Annonces et candidatures',
        'support.title': 'Nous ecrire',
        'support.card_title': 'Message d assistance',
        'support.direct_admin': 'Votre message est transmis directement a l admin.',
        'support.topic': 'Sujet',
        'support.topic.account': 'Compte',
        'support.topic.payment': 'Paiement',
        'support.topic.technical': 'Probleme technique',
        'support.topic.content': 'Plainte concernant un contenu',
        'support.topic.suggestion': 'Suggestion',
        'support.message_hint': 'Ecrivez votre probleme ou votre demande...',
        'support.send': 'Envoyer le message',
        'support.empty_title': 'Information incomplete',
        'support.empty_body': 'Veuillez ecrire un message.',
        'support.sent_title': 'Envoye',
        'support.sent_body': 'Votre message a ete transmis a l admin.',
        'support.error_title': 'Erreur',
        'liked_posts.no_posts': 'Aucune publication',
        'saved_posts.posts_tab': 'Publications',
        'saved_posts.series_tab': 'Serie',
        'saved_posts.no_saved_posts':
            'Aucune publication enregistree',
        'saved_posts.no_saved_series': 'Aucune serie enregistree',
        'editor_email.title': 'Verification de l e-mail',
        'editor_email.email_hint': 'Votre adresse e-mail de compte',
        'editor_email.send_code': 'Envoyer le code de verification',
        'editor_email.resend_in': 'Nouveau renvoi dans {seconds}s',
        'editor_email.note':
            'Cette verification est effectuee pour des raisons de securite. Vous pouvez continuer a utiliser l application meme sans la confirmer.',
        'editor_email.code_hint': 'Code de verification a 6 chiffres',
        'editor_email.verify_confirm':
            'Verifier le code et confirmer',
        'editor_email.wait': 'Veuillez patienter {seconds} secondes.',
        'editor_email.session_missing':
            'Session introuvable. Veuillez vous reconnecter.',
        'editor_email.email_missing':
            'Aucune adresse e-mail n a ete trouvee sur votre compte.',
        'editor_email.code_sent':
            'Le code de verification a ete envoye a votre adresse e-mail.',
        'editor_email.code_send_failed':
            'Le code de verification n a pas pu etre envoye.',
        'editor_email.enter_code':
            'Veuillez saisir le code de verification a 6 chiffres.',
        'editor_email.verified':
            'Votre adresse e-mail a ete verifiee.',
        'editor_email.verify_failed':
            'L adresse e-mail n a pas pu etre verifiee.',
        'editor_phone.title': 'Numero de telephone',
        'editor_phone.phone_hint': 'Numero de telephone',
        'editor_phone.send_approval':
            'Envoyer l e-mail de verification',
        'editor_phone.resend_in': 'Nouveau renvoi dans {seconds}s',
        'editor_phone.code_hint': 'Code de verification a 6 chiffres',
        'editor_phone.verify_update':
            'Verifier le code et mettre a jour',
        'editor_phone.wait': 'Veuillez patienter {seconds} secondes.',
        'editor_phone.invalid_phone':
            'Veuillez saisir un numero a 10 chiffres commencant par 5.',
        'editor_phone.session_missing':
            'Session introuvable. Veuillez vous reconnecter.',
        'editor_phone.email_missing':
            'Aucun e-mail n est disponible pour verifier cette modification.',
        'editor_phone.code_sent':
            'Le code de verification a ete envoye a votre adresse e-mail.',
        'editor_phone.code_send_failed':
            'Le code de verification n a pas pu etre envoye.',
        'editor_phone.enter_code':
            'Veuillez saisir le code de verification a 6 chiffres.',
        'editor_phone.update_failed':
            'Le numero de telephone n a pas pu etre mis a jour.',
        'editor_phone.updated':
            'Votre numero de telephone a ete mis a jour.',
        'address.title': 'Adresse',
        'address.hint': 'Adresse du bureau ou de l entreprise',
        'biography.title': 'Biographie',
        'biography.hint': 'Parlez un peu de vous..',
        'profile_contact.title': 'Contact',
        'profile_contact.call': 'Appel',
        'profile_contact.email': 'E-mail',
        'job_selector.title': 'Metier et categorie',
        'job_selector.subtitle':
            'Votre categorie rend votre profil plus facile a decouvrir.',
        'job_selector.search_hint': 'Rechercher',
        'legacy_language.title': 'Langue de l application',
        'statistics.title': 'Statistiques',
        'statistics.you': 'Vous',
        'statistics.notice':
            'Vos statistiques sont mises a jour regulierement selon votre activite des 30 derniers jours.',
        'statistics.post_views_pct': 'Pourcentage de vues des publications',
        'statistics.follower_growth_pct':
            'Pourcentage de croissance des abonnes',
        'statistics.profile_visits_30d': 'Visites du profil (30 jours)',
        'statistics.post_views': 'Vues des publications',
        'statistics.post_count': 'Nombre de publications',
        'statistics.story_count': 'Nombre de stories',
        'statistics.follower_growth': 'Croissance des abonnes',
        'interests.personalize_feed': 'Personnalise ton fil',
        'interests.selection_range':
            'Selectionne au moins {min} et au maximum {max} centres d interet.',
        'interests.selected_count': '{selected}/{max} selectionnes',
        'interests.ready': 'Pret',
        'interests.search_hint': 'Rechercher des centres d interet',
        'interests.limit_title': 'Limite de selection',
        'interests.limit_body':
            'Vous pouvez selectionner au maximum {max} centres d interet.',
        'interests.min_title': 'Selection incomplete',
        'interests.min_body':
            'Vous devez selectionner au moins {min} centres d interet.',
        'view_changer.title': 'Affichage',
        'view_changer.classic': 'Affichage classique',
        'view_changer.modern': 'Affichage moderne',
        'social_links.title': 'Liens ({count})',
        'social_links.add': 'Ajouter',
        'social_links.add_title': 'Ajouter un lien',
        'social_links.label_title': 'Titre',
        'social_links.username_hint': 'Nom d utilisateur',
        'social_links.remove_title': 'Supprimer le lien',
        'social_links.remove_message':
            'Voulez-vous vraiment supprimer ce lien ?',
        'social_links.save_permission_error':
            'Erreur d autorisation : vous ne pouvez pas enregistrer ce lien.',
        'social_links.save_failed': 'Un probleme est survenu.',
        'post_creator.title_new': 'Preparer une publication',
        'post_creator.title_edit': 'Modifier la publication',
        'post_creator.publish': 'Publier',
        'post_creator.uploading': 'Telechargement...',
        'post_creator.saving': 'Enregistrement...',
        'post_creator.placeholder': 'Quoi de neuf ?',
        'post_creator.processing_wait':
            'Veuillez patienter. La video est en cours de traitement...',
        'post_creator.video_processing': 'Traitement de la video',
        'post_creator.look.original': 'Original',
        'post_creator.look.clear': 'Net',
        'post_creator.look.cinema': 'Cinematique',
        'post_creator.look.vibe': 'Vif',
        'post_creator.comments.everyone': 'Tout le monde',
        'post_creator.comments.verified': 'Comptes verifies',
        'post_creator.comments.following': 'Comptes que vous suivez',
        'post_creator.comments.closed': 'Commentaires fermes',
        'post_creator.comments.title': 'Qui peut repondre ?',
        'post_creator.comments.subtitle':
            'Choisissez qui peut repondre a cette publication.',
        'post_creator.reshare.everyone': 'Tout le monde',
        'post_creator.reshare.verified': 'Comptes verifies',
        'post_creator.reshare.following': 'Comptes que vous suivez',
        'post_creator.reshare.closed': 'Republication fermee',
        'post_creator.reshare_privacy_title':
            'Confidentialite du repartage',
        'post_creator.reshare_everyone_desc':
            'Tout le monde peut repartager.',
        'post_creator.reshare_followers_desc':
            'Seuls mes abonnes peuvent repartager.',
        'post_creator.reshare_closed_desc':
            'Le repartage est desactive.',
        'post_creator.warning_title': 'Avertissement',
        'post_creator.success_title': 'Succes !',
        'tests.create_title': 'Creer un test',
        'tests.edit_title': 'Modifier le test',
        'tests.create_data_missing':
            'Donnees introuvables.\nLes liens de l application ou les questions du test n ont pas pu etre charges.',
        'tests.create_upload_failed':
            'Ce contenu ne peut pas etre traite pour le moment. Veuillez essayer un autre contenu.',
        'tests.select_branch': 'Choisir une branche',
        'tests.select_language': 'Choisir une langue',
        'tests.cover_select': 'Choisir une image de couverture',
        'tests.name_hint': 'Nom de l examen',
        'tests.post_exam_status': 'Apres l examen @status',
        'tests.types': 'Types d examen',
        'tests.date_duration': 'Date et duree de l examen',
        'tests.duration_select': 'Choisir la duree de l examen',
        'tests.create_description_hint':
            '9e annee Expressions exponentielles et radicaux',
        'tests.share_status': 'Pour tout le monde : @status',
        'tests.status.open': 'Ouvert',
        'tests.status.closed': 'Ferme',
        'tests.share_public_info':
            'Conformement a l ethique numerique, les tests proteges par des droits d auteur ne doivent pas etre partages.\nVeuillez utiliser et publier des tests que tout le monde peut resoudre et qui ne contiennent pas de contenu protege.',
        'tests.share_private_info':
            'Ce test ne peut etre partage qu avec vos propres etudiants. Seuls les etudiants qui saisissent l identifiant fourni pourront acceder au test publie et le resoudre.',
        'tests.test_id': 'ID du test : @id',
        'tests.test_type': 'Type de test',
        'tests.subjects': 'Matieres',
        'tests.exam_prep': 'Preparation aux examens',
        'tests.foreign_language': 'Langue etrangere',
        'tests.delete_test': 'Supprimer le test',
        'tests.prepare_test': 'Preparer le test',
        'tests.join_title': 'Rejoindre le test',
        'tests.search_title': 'Rechercher un test',
        'tests.search_id_hint': 'Rechercher ID du test',
        'tests.join_help':
            'Vous pouvez commencer le test en saisissant l ID du test partage par votre enseignant.',
        'tests.join_not_found':
            'Test introuvable.\nAucun test ne correspond a l ID saisi.',
        'tests.join_button': 'Rejoindre le test',
        'tests.no_shared': 'Aucun test partage.',
        'tests.my_tests_title': 'Mes tests',
        'tests.my_tests_empty':
            'Aucun resultat trouve.\nVous n avez encore cree aucun test.',
        'tests.completed_title': 'Vous avez termine le test !',
        'tests.completed_body':
            'Vous pouvez consulter votre score et vos bonnes ou mauvaises reponses dans Mes resultats.',
        'tests.completed_short': 'Vous avez termine le test !',
        'tests.action_select': 'Choisir une action',
        'tests.action_select_body':
            'Si vous souhaitez effectuer une action sur ce test, choisissez une option ci-dessous.',
        'tests.copy_test_id': 'Copier l ID du test',
        'tests.solve_title': 'Resoudre le test',
        'tests.delete_confirm':
            'Voulez-vous vraiment supprimer ce test ?',
        'tests.id_copied': 'L ID du test a ete copie',
        'tests.share_test_id_text':
            'Test @type\n\nTelechargez TurqApp pour rejoindre le test. Votre ID de test requis est @id\n\nObtenez l application maintenant :\n\nAppStore : @appStore\nPlay Store : @playStore\n\nPour rejoindre le test, saisissez l ID du test depuis l ecran Tests dans l espace etudiant et commencez immediatement a repondre.',
        'tests.type.middle_school': 'College',
        'tests.type.high_school': 'Lycee',
        'tests.type.prep': 'Preparation',
        'tests.type.language': 'Langue',
        'tests.type.branch': 'Branche',
        'tests.lesson.turkish': 'Turc',
        'tests.lesson.literature': 'Litterature',
        'tests.lesson.math': 'Mathematiques',
        'tests.lesson.geometry': 'Geometrie',
        'tests.lesson.physics': 'Physique',
        'tests.lesson.chemistry': 'Chimie',
        'tests.lesson.biology': 'Biologie',
        'tests.lesson.history': 'Histoire',
        'tests.lesson.geography': 'Geographie',
        'tests.lesson.philosophy': 'Philosophie',
        'tests.lesson.psychology': 'Psychologie',
        'tests.lesson.sociology': 'Sociologie',
        'tests.lesson.logic': 'Logique',
        'tests.lesson.religion': 'Culture religieuse',
        'tests.lesson.science': 'Sciences',
        'tests.lesson.revolution_history': 'Histoire de la revolution',
        'tests.lesson.foreign_language': 'Langue etrangere',
        'tests.lesson.basic_math': 'Mathematiques de base',
        'tests.lesson.social_sciences': 'Sciences sociales',
        'tests.lesson.literature_social_1':
            'Litterature - Sciences sociales 1',
        'tests.lesson.social_sciences_2': 'Sciences sociales 2',
        'tests.lesson.general_ability': 'Aptitude generale',
        'tests.lesson.general_culture': 'Culture generale',
        'tests.language.english': 'Anglais',
        'tests.language.german': 'Allemand',
        'tests.language.arabic': 'Arabe',
        'tests.language.french': 'Francais',
        'tests.language.russian': 'Russe',
        'tests.lesson_based_title': 'Tests @type',
        'tests.none_in_category': 'Aucun test disponible',
        'tests.add_question': 'Ajouter une question',
        'tests.no_questions_added':
            'Aucune question trouvee.\nAucune question n a encore ete ajoutee pour ce test.',
        'tests.level_easy': 'Facile',
        'tests.title': 'Tests',
        'tests.report_title': 'A propos du test',
        'tests.report_wrong_answers':
            'Le test contient de mauvaises reponses',
        'tests.report_wrong_section':
            'Le test est dans la mauvaise section',
        'tests.question_content_failed':
            'Le contenu de la question n a pas pu etre charge.\nVeuillez reessayer.',
        'tests.capture_and_upload': 'Prendre et telecharger',
        'tests.capture_and_upload_body':
            'Prends une photo de la question, choisis la bonne reponse et prepare-la facilement !',
        'tests.select_from_gallery': 'Choisir depuis la galerie',
        'tests.upload_from_camera': 'Telecharger depuis la camera',
        'tests.nsfw_check_failed':
            'La verification de securite de l image n a pas pu etre terminee.',
        'tests.nsfw_detected': 'Image inappropriee detectee.',
        'practice.title': 'Examen en ligne',
        'practice.search_title': 'Rechercher un examen blanc',
        'practice.empty_title': 'Aucun examen blanc pour le moment',
        'practice.empty_body':
            'Aucun examen blanc n est actuellement disponible dans le systeme. Les nouveaux examens apparaitront ici lorsqu ils seront ajoutes.',
        'practice.search_empty_title':
            'Aucun examen ne correspond a votre recherche',
        'practice.search_empty_body_empty':
            'Aucun examen blanc n est actuellement disponible dans le systeme. Les nouveaux examens apparaitront ici lorsqu ils seront ajoutes.',
        'practice.search_empty_body_query':
            'Essayez un autre mot-cle.',
        'practice.results_title': 'Mes resultats d examen',
        'practice.saved_empty': 'Aucun examen pratique enregistre.',
        'practice.preview_no_questions':
            'Aucune question n a ete trouvee pour cet examen. Veuillez verifier le contenu de l examen ou ajouter de nouvelles questions.',
        'practice.preview_no_results':
            'Aucun resultat n a ete trouve pour cet examen. Veuillez verifier vos reponses ou repasser l examen.',
        'practice.lesson_header': 'Matieres',
        'practice.answers_load_failed':
            'Impossible de charger les reponses.',
        'practice.lesson_results_load_failed':
            'Impossible de charger les resultats des matieres.',
        'practice.results_empty_title':
            'Vous n avez pas encore passe d examen',
        'practice.results_empty_body':
            'Vous n avez participe a aucun examen blanc. Vos resultats apparaitront ici apres votre participation.',
        'practice.published_empty':
            'Vous n avez pas encore publie d examen en ligne.',
        'practice.user_session_missing':
            'Session utilisateur introuvable.',
        'practice.school_info_failed':
            'Les informations sur l ecole n ont pas pu etre chargees.',
        'practice.load_failed': 'Les donnees n ont pas pu etre chargees.',
        'practice.slider_management': 'Gestion du slider',
        'practice.create_disabled_title':
            'Reserve au badge jaune et superieur',
        'practice.create_disabled_body':
            'Pour creer un examen en ligne, vous devez avoir un compte verifie avec un badge jaune ou superieur.',
        'practice.preview_title': 'Detail de l examen',
        'practice.report_exam': 'Signaler l examen',
        'practice.user_load_failed':
            'Les informations utilisateur n ont pas pu etre chargees.',
        'practice.user_load_failed_body':
            'Les informations utilisateur n ont pas pu etre chargees. Veuillez reessayer ou verifier le proprietaire de l examen.',
        'practice.invalidity_load_failed':
            'Le statut d invalidite n a pas pu etre charge.',
        'practice.cover_load_failed':
            'L image de couverture n a pas pu etre chargee.',
        'practice.no_description':
            'Aucune description n a ete ajoutee pour cet examen.',
        'practice.exam_info': 'Informations sur l examen',
        'practice.exam_type': 'Type d examen',
        'practice.exam_suffix': 'Examen @type',
        'practice.exam_datetime': 'Date et heure de l examen',
        'practice.exam_duration': 'Duree de l examen',
        'practice.duration_minutes': '@minutes min',
        'practice.application_count': 'Candidatures',
        'practice.people_count': '@count personnes',
        'practice.owner': 'Proprietaire de l examen',
        'practice.apply_now': 'Postuler maintenant',
        'practice.applied_short': 'Postule',
        'practice.closed_starts_in':
            'Candidatures fermees.\nDebut dans @minutes min.',
        'practice.started': 'Examen commence',
        'practice.start_now': 'Commencer maintenant',
        'practice.finished_short': 'Examen termine',
        'practice.not_started': 'Examen non commence',
        'practice.application_closed_title':
            'Les candidatures sont fermees !',
        'practice.application_closed_body':
            'Les candidatures ferment 15 minutes avant le debut de l examen.',
        'practice.not_applied_title':
            'Vous n avez pas postule !',
        'practice.not_applied_body':
            'Vous ne pouvez pas rejoindre un examen sans candidature. Seuls les candidats peuvent participer.',
        'practice.not_allowed_title':
            'Vous ne pouvez pas entrer dans l examen !',
        'practice.not_allowed_body':
            'Vous n avez pas acces a cet examen. Vous avez deja ete invalide pour cet examen et vous ne pouvez pas y revenir avant sa fin.',
        'practice.finished_title': 'Examen termine !',
        'practice.finished_body':
            'Vous pouvez postuler aux prochains examens. Cet examen est termine.',
        'practice.result_unavailable':
            'Le resultat n a pas pu etre calcule.',
        'practice.result_summary':
            'Correct : @correct   •   Faux : @wrong   •   Vide : @blank   •   Net : @net',
        'practice.congrats_title': 'Felicitations !',
        'practice.removed_title':
            'Vous avez ete exclu de l examen !',
        'practice.removed_body':
            'Nous vous avons averti plusieurs fois. Malheureusement, comme vous n avez pas respecte les regles, votre examen a ete invalide.',
        'practice.applied_title':
            'Votre candidature a ete recue !',
        'practice.applied_body':
            'Votre candidature a ete recue avec succes. Vous n avez rien d autre a faire pour le moment.',
        'practice.apply_completed_title':
            'Votre candidature est terminee !',
        'practice.apply_completed_body':
            'Nous vous enverrons des rappels avant l examen. Bonne chance !',
        'practice.apply_failed': 'Echec de la candidature.',
        'practice.application_check_failed':
            'Echec de la verification de candidature.',
        'practice.question_image_failed':
            'L image de la question n a pas pu etre chargee.',
        'practice.exam_started_title': 'L examen a commence !',
        'practice.exam_started_body':
            'Nous pensons que votre attention et vos efforts ouvriront la voie au succes. Bonne chance !',
        'practice.rules_title': 'Regles de l examen',
        'practice.rule_1':
            'Veuillez couper la connexion internet de votre telephone. Une fois l examen termine, vous pourrez la reactiver pour envoyer vos reponses.',
        'practice.rule_2':
            'Si vous quittez l examen, toutes vos reponses seront considerees comme invalides et votre score ne sera pas enregistre. Reflechissez bien avant de confirmer.',
        'practice.rule_3':
            'Si vous mettez l application en arriere-plan, votre examen sera considere comme invalide. Veuillez eviter de mettre l application en arriere-plan.',
        'practice.start_exam': 'Commencer l examen',
        'practice.finish_exam': 'Terminer l examen',
        'practice.background_warning':
            'Dans les situations critiques comme la mise en arriere-plan de l application, votre examen sera considere comme invalide. Veuillez etre prudent et respecter les regles.',
        'practice.questions_load_failed':
            'Les questions n ont pas pu etre chargees.',
        'practice.answers_save_failed':
            'Les reponses n ont pas pu etre enregistrees.',
        'past_questions.no_results': 'Aucun resultat.',
        'past_questions.title': 'Examens blancs',
        'past_questions.mock_fallback': 'Essai',
        'past_questions.search_empty':
            'Aucun examen blanc ne correspond a votre recherche.',
        'past_questions.results_suffix': 'Resultats @title',
        'past_questions.local_result_summary':
            '@count questions ont ete resolues. Le resultat est stocke localement ; seul le resume net est affiche sur cet ecran.',
        'past_questions.mock_label': 'Essai @index',
        'past_questions.question_count': '@count Questions',
        'past_questions.net_label': 'Net',
        'past_questions.tests_by_year': 'Tests @type @year',
        'past_questions.languages_title': 'Langues @type',
        'past_questions.tests_by_type': 'Tests @type',
        'past_questions.select_exam': "Choisir l'examen",
        'past_questions.questions_title': 'Questions',
        'past_questions.continue_solving': 'Continuer à résoudre les questions',
        'past_questions.oabt_short': 'ÖABT',
        'past_questions.exam_type.associate': 'Diplôme associé',
        'past_questions.exam_type.undergraduate': 'Licence',
        'past_questions.exam_type.middle_school': 'Enseignement secondaire',
        'past_questions.branch.general_ability_culture':
            'Aptitude générale et culture générale',
        'past_questions.branch.group_a': 'Groupe A',
        'past_questions.branch.education_sciences': "Sciences de l'éducation",
        'past_questions.branch.field_knowledge': 'Connaissances spécialisées',
        'past_questions.sessions_by_year': 'Sessions @year',
        'past_questions.teaching.title': 'Branches d enseignement',
        'past_questions.teaching.suffix': 'enseignement',
        'past_questions.teaching.primary_math_short': 'M. primaire',
        'past_questions.teaching.high_school_math_short': 'M. lycee',
        'past_questions.teaching.german': 'Enseignement de l allemand',
        'past_questions.teaching.physical_education':
            'Enseignement de l education physique',
        'past_questions.teaching.biology': 'Enseignement de la biologie',
        'past_questions.teaching.geography': 'Enseignement de la geographie',
        'past_questions.teaching.religious_culture':
            'Enseignement de la culture religieuse',
        'past_questions.teaching.literature':
            'Enseignement de la litterature',
        'past_questions.teaching.science': 'Enseignement des sciences',
        'past_questions.teaching.physics': 'Enseignement de la physique',
        'past_questions.teaching.chemistry': 'Enseignement de la chimie',
        'past_questions.teaching.high_school_math': 'Mathematiques lycee',
        'past_questions.teaching.preschool': 'Prescolaire',
        'past_questions.teaching.guidance': 'Orientation',
        'past_questions.teaching.social_studies':
            'Enseignement des sciences sociales',
        'past_questions.teaching.classroom': 'Enseignement primaire',
        'past_questions.teaching.history': 'Enseignement de l histoire',
        'past_questions.teaching.turkish': 'Enseignement du turc',
        'past_questions.teaching.primary_math': 'Mathematiques primaire',
        'past_questions.teaching.imam_hatip': 'Imam Hatip',
        'past_questions.teaching.english': 'Enseignement de l anglais',
        'pasaj.closed': 'Pasaj est actuellement ferme',
        'pasaj.common.my_applications': 'Mes candidatures',
        'pasaj.common.post_listing': 'Publier une annonce',
        'pasaj.common.all_turkiye': 'Toute la Turquie',
        'pasaj.job_finder.tab.explore': 'Explorer',
        'pasaj.job_finder.tab.create': 'Publier une annonce',
        'pasaj.job_finder.tab.applications': 'Mes candidatures',
        'pasaj.job_finder.tab.career_profile': 'Profil de carriere',
        'pasaj.tabs.market': 'Marche mobile',
        'pasaj.tabs.practice_exams': 'Examens',
        'pasaj.tabs.tutoring': 'Cours particuliers',
        'pasaj.tabs.job_finder': 'Emploi',
        'pasaj.job_finder.title': 'Emploi',
        'pasaj.job_finder.search_hint': 'Quel type de travail cherches-tu ?',
        'pasaj.job_finder.nearby_listings':
            'Les annonces les plus proches de toi',
        'pasaj.job_finder.no_search_result':
            'Aucune annonce ne correspond a votre recherche',
        'pasaj.job_finder.no_city_listing':
            'Aucune annonce n est disponible dans votre ville',
        'pasaj.job_finder.sort_high_salary': 'Salaire eleve',
        'pasaj.job_finder.sort_low_salary': 'Salaire faible',
        'pasaj.job_finder.sort_nearest': 'Le plus proche',
        'pasaj.job_finder.career_profile': 'Profil de carriere',
        'pasaj.job_finder.detail_title': 'Detail de l annonce',
        'pasaj.job_finder.no_description':
            'Aucune description n a ete ajoutee pour cette annonce.',
        'pasaj.job_finder.job_info': 'Description du poste',
        'pasaj.job_finder.listing_info': 'Informations de l annonce',
        'pasaj.job_finder.application_count': 'Nombre de candidatures',
        'pasaj.job_finder.work_type': 'Type de travail',
        'pasaj.job_finder.work_days': 'Jours de travail',
        'pasaj.job_finder.work_hours': 'Heures de travail',
        'pasaj.job_finder.personnel_count':
            'Nombre de personnes a recruter',
        'pasaj.job_finder.benefits': 'Avantages',
        'pasaj.job_finder.passive': 'Passif',
        'pasaj.job_finder.salary_not_specified': 'Non precise',
        'pasaj.job_finder.edit_listing': 'Modifier',
        'pasaj.job_finder.applications': 'Candidatures',
        'pasaj.job_finder.apply': 'Postuler',
        'pasaj.job_finder.applied': 'Candidature envoyee',
        'pasaj.job_finder.cv_required': 'CV requis',
        'pasaj.job_finder.cv_required_body':
            'Vous devez completer votre CV avant de postuler.',
        'pasaj.job_finder.create_cv': 'Creer un CV',
        'pasaj.job_finder.application_sent':
            'Votre candidature a ete envoyee.',
        'pasaj.job_finder.application_failed':
            'Un probleme est survenu lors de l envoi de votre candidature.',
        'pasaj.job_finder.finding_platform':
            'Plateforme de recherche d emploi',
        'pasaj.job_finder.looking_for_job': 'Je cherche un emploi',
        'pasaj.job_finder.professional_profile':
            'Profil professionnel',
        'pasaj.job_finder.experience': 'Experience professionnelle',
        'pasaj.job_finder.education': 'Formation',
        'pasaj.job_finder.languages': 'Langues',
        'pasaj.job_finder.skills': 'Competences',
        'pasaj.market.title': 'Marche',
        'pasaj.market.contact_phone': 'Telephone',
        'pasaj.market.contact_message': 'Message',
        'pasaj.market.all_listings': 'Toutes les annonces',
        'pasaj.market.main_categories': 'Categories principales',
        'pasaj.market.category_search_hint':
            'Rechercher categorie principale, sous-categorie, marque',
        'pasaj.market.call_now': 'Appeler maintenant',
        'pasaj.market.inspect': 'Voir',
        'pasaj.market.empty_filtered':
            'Aucune annonce n a ete trouvee avec ce filtre.',
        'pasaj.market.add_listing': 'Ajouter une annonce',
        'pasaj.market.my_listings': 'Mes annonces',
        'pasaj.market.saved_items': 'Mes favoris',
        'pasaj.market.my_offers': 'Mes offres',
        'pasaj.market.detail_title': 'Detail de l annonce',
        'pasaj.market.report_listing': 'Signaler l annonce',
        'pasaj.market.no_description':
            'Aucune description n a ete ajoutee pour cette annonce.',
        'pasaj.market.listing_info': 'Informations de l annonce',
        'pasaj.market.saved_count': 'Enregistrements',
        'pasaj.market.offer_count': 'Offres',
        'pasaj.market.messages': 'Messages',
        'pasaj.market.offers': 'Offres',
        'pasaj.market.related_listings': 'Annonces similaires',
        'pasaj.market.no_related':
            'Aucune autre annonce n a ete trouvee dans cette categorie.',
        'pasaj.market.custom_offer':
            'Definis ton offre toi-meme',
        'pasaj.market.reviews': 'Evaluations',
        'pasaj.market.rate': 'Evaluer',
        'pasaj.job_finder.no_applications':
            'Vous n avez encore postule a aucune annonce',
        'pasaj.job_finder.default_job_title': 'Annonce d emploi',
        'pasaj.job_finder.default_company': 'Entreprise',
        'pasaj.job_finder.cancel_apply_title':
            'Annuler la candidature',
        'pasaj.job_finder.cancel_apply_body':
            'Voulez-vous vraiment annuler cette candidature ?',
        'pasaj.job_finder.saved_jobs': 'Enregistrees',
        'pasaj.job_finder.no_saved_jobs':
            'Aucune annonce enregistree.',
        'pasaj.job_finder.my_ads': 'Mes annonces',
        'pasaj.job_finder.published_tab': 'Publiees',
        'pasaj.job_finder.expired_tab': 'Expirees',
        'pasaj.job_finder.no_my_ads': 'Aucune annonce trouvee',
        'pasaj.job_finder.finding_how':
            'Comment fonctionne la plateforme de recherche d emploi ?',
        'pasaj.job_finder.finding_body':
            'Votre CV est partage avec les employeurs avec votre accord. Avant de publier une annonce, les employeurs peuvent consulter via notre systeme des candidats adaptes a leurs postes ouverts. Ainsi, les employeurs atteignent plus vite les bons candidats et les chercheurs d emploi accedent plus rapidement aux opportunites. Notre objectif est de rendre le processus de recrutement plus rapide et plus efficace pour les deux parties.',
        'pasaj.job_finder.edit_cv': 'Modifier le CV',
        'pasaj.job_finder.no_cv_title':
            'Vous n avez pas encore cree de CV',
        'pasaj.job_finder.no_cv_body':
            'Creez un CV pour accelerer vos candidatures',
        'pasaj.job_finder.applicants': 'Candidats',
        'pasaj.job_finder.no_applicants':
            'Aucune candidature pour le moment',
        'pasaj.job_finder.unknown_user': 'Utilisateur inconnu',
        'pasaj.job_finder.view_cv': 'Voir le CV',
        'pasaj.job_finder.review': 'Examiner',
        'pasaj.job_finder.accept': 'Accepter',
        'pasaj.job_finder.reject': 'Refuser',
        'pasaj.job_finder.cv_not_found_title': 'CV introuvable',
        'pasaj.job_finder.cv_not_found_body':
            'Aucun CV enregistre n a ete trouve pour cet utilisateur.',
        'pasaj.job_finder.status.pending': 'En attente',
        'pasaj.job_finder.status.reviewing': 'En cours d examen',
        'pasaj.job_finder.status.accepted': 'Acceptee',
        'pasaj.job_finder.status.rejected': 'Refusee',
        'pasaj.job_finder.status_updated':
            'Le statut de la candidature a ete mis a jour.',
        'pasaj.job_finder.status_update_failed':
            'Le statut de la candidature n a pas pu etre mis a jour.',
        'pasaj.job_finder.relogin_required':
            'Veuillez vous reconnecter pour continuer.',
        'pasaj.job_finder.save_failed':
            'L enregistrement n a pas pu etre termine.',
        'pasaj.job_finder.share_auth_required':
            'Seuls les admins et les proprietaires d annonces peuvent partager.',
        'pasaj.job_finder.review_relogin_required':
            'Veuillez vous reconnecter pour laisser un avis.',
        'pasaj.job_finder.review_own_forbidden':
            'Vous ne pouvez pas evaluer votre propre annonce.',
        'pasaj.job_finder.review_saved':
            'Votre evaluation a ete enregistree.',
        'pasaj.job_finder.review_save_failed':
            'L evaluation n a pas pu etre enregistree.',
        'pasaj.job_finder.review_deleted':
            'Votre evaluation a ete supprimee.',
        'pasaj.job_finder.review_delete_failed':
            'L evaluation n a pas pu etre supprimee.',
        'pasaj.job_finder.open_in_maps': 'Ouvrir dans Plans',
        'pasaj.job_finder.open_google_maps':
            'Ouvrir dans Google Maps',
        'pasaj.job_finder.open_apple_maps':
            'Ouvrir dans Apple Plans',
        'pasaj.job_finder.open_yandex_maps':
            'Ouvrir dans Yandex Maps',
        'pasaj.job_finder.map_load_failed':
            'La carte n a pas pu etre chargee',
        'pasaj.job_finder.open_maps_help':
            'Touchez pour ouvrir l emplacement dans Plans.',
        'pasaj.job_finder.listing_not_found':
            'Annonce introuvable',
        'pasaj.job_finder.reactivated':
            'L annonce a ete republee.',
        'pasaj.job_finder.sort_title': 'Tri',
        'pasaj.job_finder.sort_newest': 'Les plus recentes',
        'pasaj.job_finder.sort_nearest_me': 'Pres de moi',
        'pasaj.job_finder.sort_most_viewed': 'Les plus vues',
        'pasaj.job_finder.clear_filters': 'Effacer les filtres',
        'pasaj.job_finder.select_city': 'Choisir une ville',
        'pasaj.market.saved_success': 'Annonce enregistree.',
        'pasaj.market.unsaved': 'Annonce retiree des enregistrements.',
        'pasaj.market.save_failed':
            'L enregistrement n a pas pu etre termine.',
        'pasaj.market.report_received_title':
            'Votre signalement a ete recu !',
        'pasaj.market.report_received_body':
            'L annonce a ete mise en file de verification. Merci.',
        'pasaj.market.report_failed':
            'Le signalement de l annonce n a pas pu etre envoye.',
        'pasaj.market.invalid_offer':
            'Veuillez choisir une offre valide.',
        'pasaj.market.offer_sent': 'Offre envoyee.',
        'pasaj.market.offer_own_forbidden':
            'Vous ne pouvez pas faire une offre sur votre propre annonce.',
        'pasaj.market.offer_daily_limit':
            'Vous pouvez envoyer au maximum 20 offres par jour.',
        'pasaj.market.offer_failed':
            'L offre n a pas pu etre envoyee.',
        'pasaj.market.review_edit': 'Modifier',
        'pasaj.market.no_reviews':
            'Il n y a pas encore d evaluation.',
        'pasaj.market.sign_in_to_review':
            'Vous devez vous connecter pour laisser une evaluation.',
        'pasaj.market.review_comment_hint':
            'Ecrivez votre commentaire',
        'pasaj.market.select_rating':
            'Veuillez choisir une note.',
        'pasaj.market.review_saved':
            'Votre evaluation a ete enregistree.',
        'pasaj.market.review_updated':
            'Votre evaluation a ete mise a jour.',
        'pasaj.market.review_own_forbidden':
            'Vous ne pouvez pas evaluer votre propre annonce.',
        'pasaj.market.review_failed':
            'L evaluation n a pas pu etre envoyee.',
        'pasaj.market.review_deleted':
            'Votre evaluation a ete supprimee.',
        'pasaj.market.review_delete_failed':
            'L evaluation n a pas pu etre supprimee.',
        'pasaj.market.location_missing': 'Lieu non precise',
        'pasaj.market.status.sold': 'Vendu',
        'pasaj.market.status.draft': 'Brouillon',
        'pasaj.market.status.archived': 'Archive',
        'pasaj.market.status.reserved': 'Reserve',
        'pasaj.market.status.active': 'Actif',
      });

    base['it_IT'] = Map<String, String>.from(base['en_US']!)
      ..addAll({
        'settings.title': 'Impostazioni',
        'settings.account': 'Account',
        'settings.content': 'Contenuto',
        'settings.app': 'Applicazione',
        'settings.security_support': 'Sicurezza e supporto',
        'settings.my_tasks': 'I miei compiti',
        'settings.system_diagnostics': 'Sistema e diagnostica',
        'settings.session': 'Sessione',
        'settings.language': 'Lingua',
        'settings.edit_profile': 'Modifica profilo',
        'settings.saved_posts': 'Salvati',
        'settings.archive': 'Archivio',
        'settings.liked_posts': 'Mi piace',
        'settings.notifications': 'Notifiche',
        'settings.permissions': 'Autorizzazioni',
        'settings.pasaj': 'Pasaj',
        'education.previous_questions': 'Test pratici',
        'tests.results_title': 'Risultati',
        'tests.results_empty':
            'Nessun risultato trovato.\nNon sono disponibili dati di risposta o domande per questo test.',
        'tests.correct': 'Corrette',
        'tests.wrong': 'Errate',
        'tests.blank': 'Vuote',
        'tests.net': 'Netto',
        'tests.score': 'Punteggio',
        'tests.question_number': 'Domanda @index',
        'tests.solve_no_questions':
            'Domanda non trovata.\nNon e stato possibile caricare le domande di questo test.',
        'tests.finish_test': 'Termina il test',
        'tests.my_results_empty':
            'Nessun risultato trovato.\nNon hai mai risolto un test prima d ora.',
        'tests.saved_empty': 'Non ci sono test salvati.',
        'tests.result_answer_missing':
            'Nessun risultato trovato.\nNon sono disponibili dati di risposta per questo test.',
        'tests.type_test': 'Test @type',
        'tests.description_test': 'Test @description',
        'tests.solve_count': 'Lo hai risolto @count volte',
        'settings.about': 'Informazioni',
        'settings.policies': 'Politiche',
        'settings.contact_us': 'Contattaci',
        'settings.sign_out': 'Esci',
        'settings.sign_out_title': 'Esci',
        'settings.sign_out_message':
            'Sei sicuro di voler uscire?',
        'settings.admin_push': 'Admin / Invia push',
        'settings.diagnostics.data_usage': 'Utilizzo dati',
        'settings.diagnostics.network': 'Rete',
        'settings.diagnostics.connected': 'Connesso',
        'settings.diagnostics.monthly_total': 'Totale mensile',
        'settings.diagnostics.monthly_limit': 'Limite mensile',
        'settings.diagnostics.remaining': 'Rimanente',
        'settings.diagnostics.limit_usage': 'Uso del limite',
        'settings.diagnostics.wifi_usage': 'Consumo Wi-Fi',
        'settings.diagnostics.cellular_usage':
            'Consumo dati mobili',
        'settings.diagnostics.time_ranges': 'Intervalli di tempo',
        'settings.diagnostics.this_month_actual': 'Questo mese (reale)',
        'settings.diagnostics.hourly_average': 'Media oraria',
        'settings.diagnostics.since_login_estimated':
            'Dall accesso (stimato)',
        'settings.diagnostics.details': 'Dettagli',
        'settings.diagnostics.cache': 'Cache',
        'settings.diagnostics.saved_media_count':
            'Numero di media salvati',
        'settings.diagnostics.occupied_space': 'Spazio occupato',
        'settings.diagnostics.offline_queue': 'Coda offline',
        'settings.diagnostics.pending': 'In attesa',
        'settings.diagnostics.dead_letter': 'Dead-letter',
        'settings.diagnostics.status': 'Stato',
        'settings.diagnostics.syncing': 'Sincronizzazione',
        'settings.diagnostics.idle': 'Inattivo',
        'settings.diagnostics.processed_total': 'Elaborati (totale)',
        'settings.diagnostics.failed_total': 'Errori (totale)',
        'settings.diagnostics.last_sync': 'Ultima sincronizzazione',
        'settings.diagnostics.login_date': 'Data di accesso',
        'settings.diagnostics.login_time': 'Ora di accesso',
        'settings.diagnostics.app_health_panel':
            'Pannello salute applicazione',
        'settings.diagnostics.video_cache_detail':
            'Dettagli cache video',
        'settings.diagnostics.quick_actions': 'Azioni rapide',
        'settings.diagnostics.offline_queue_detail':
            'Dettagli coda offline',
        'settings.diagnostics.last_error_summary':
            'Ultimo riepilogo errori',
        'settings.diagnostics.error_report': 'Rapporto errore',
        'settings.diagnostics.saved_videos': 'Video salvati',
        'settings.diagnostics.saved_segments': 'Segmenti salvati',
        'settings.diagnostics.disk_usage': 'Utilizzo disco',
        'settings.diagnostics.unknown': 'Sconosciuto',
        'settings.diagnostics.cache_traffic': 'Traffico cache',
        'settings.diagnostics.hit_rate': 'Tasso di hit',
        'settings.diagnostics.hit': 'Hit',
        'settings.diagnostics.miss': 'Miss',
        'settings.diagnostics.cache_served': 'Servito dalla cache',
        'settings.diagnostics.downloaded_from_network':
            'Scaricato dalla rete',
        'settings.diagnostics.prefetch': 'Prefetch',
        'settings.diagnostics.queue': 'Coda',
        'settings.diagnostics.active_downloads':
            'Download attivi',
        'settings.diagnostics.paused': 'In pausa',
        'settings.diagnostics.active': 'Attivo',
        'settings.diagnostics.reset_data_counters':
            'Reimposta contatori dati',
        'settings.diagnostics.data_counters_reset':
            'I contatori dati sono stati reimpostati.',
        'settings.diagnostics.sync_offline_queue_now':
            'Sincronizza la coda offline',
        'settings.diagnostics.offline_queue_sync_triggered':
            'La sincronizzazione della coda offline e stata avviata.',
        'settings.diagnostics.retry_dead_letter':
            'Riprova dead-letter',
        'settings.diagnostics.dead_letter_queued':
            'Gli elementi dead-letter sono stati rimessi in coda.',
        'settings.diagnostics.clear_dead_letter':
            'Cancella dead-letter',
        'settings.diagnostics.dead_letter_cleared':
            'Gli elementi dead-letter sono stati eliminati.',
        'settings.diagnostics.pause_prefetch': 'Metti in pausa prefetch',
        'settings.diagnostics.prefetch_paused':
            'Il prefetch e stato messo in pausa',
        'settings.diagnostics.service_not_ready':
            'Il servizio non e ancora pronto.',
        'settings.diagnostics.resume_prefetch':
            'Riprendi prefetch',
        'settings.diagnostics.prefetch_resumed':
            'Il prefetch e ripreso',
        'settings.diagnostics.online': 'Online',
        'settings.diagnostics.sync': 'Sync',
        'settings.diagnostics.processed': 'Elaborati',
        'settings.diagnostics.failed': 'Errori',
        'settings.diagnostics.pending_first8':
            'In attesa (primi 8)',
        'settings.diagnostics.dead_letter_first8':
            'Dead-letter (primi 8)',
        'settings.diagnostics.sync_now': 'Sincronizza ora',
        'settings.diagnostics.dead_letter_retry': 'Riprova dead-letter',
        'settings.diagnostics.dead_letter_clear': 'Cancella dead-letter',
        'settings.diagnostics.no_recorded_error':
            'Nessun errore registrato.',
        'settings.diagnostics.error_code': 'Codice',
        'settings.diagnostics.error_category': 'Categoria',
        'settings.diagnostics.error_severity': 'Gravita',
        'settings.diagnostics.error_retryable': 'Riprovabile',
        'settings.diagnostics.error_message': 'Messaggio',
        'settings.diagnostics.error_time': 'Ora',
        'account_center.header_title':
            'Profili e dettagli di accesso',
        'account_center.accounts': 'Account',
        'account_center.no_accounts':
            'Nessun account e stato ancora aggiunto a questo dispositivo.',
        'account_center.add_account': 'Aggiungi account',
        'account_center.personal_details': 'Dettagli personali',
        'account_center.security': 'Sicurezza',
        'account_center.active_account_title': 'Account attivo',
        'account_center.active_account_body':
            '@{username} e gia attivo.',
        'account_center.reauth_title': 'Nuovo accesso richiesto',
        'account_center.reauth_body':
            'Inserisci di nuovo la password per cambiare account.',
        'account_center.switch_failed_title':
            'Cambio non riuscito',
        'account_center.switch_failed_body':
            'Impossibile attivare l account.',
        'account_center.remove_active_forbidden':
            'Devi prima passare a un altro account.',
        'account_center.remove_account_title': 'Rimuovi account',
        'account_center.remove_account_body':
            'Vuoi rimuovere @{username} da questo dispositivo?',
        'account_center.account_removed':
            '@{username} e stato rimosso.',
        'account_center.single_device_title':
            'Accesso da un solo dispositivo',
        'account_center.single_device_desc':
            'Quando effettui l accesso da un altro dispositivo, la sessione corrente viene chiusa e sara richiesta la password.',
        'account_center.single_device_enabled':
            'L accesso da un solo dispositivo e attivo.',
        'account_center.single_device_disabled':
            'L accesso da un solo dispositivo e disattivo.',
        'account_center.no_personal_detail':
            'Nessun dettaglio personale aggiunto.',
        'account_center.contact_details': 'Dettagli di contatto',
        'account_center.contact_info': 'Informazioni di contatto',
        'account_center.email': 'E-mail',
        'account_center.phone': 'Telefono',
        'account_center.email_missing': 'Nessuna e-mail aggiunta',
        'account_center.phone_missing': 'Nessun telefono aggiunto',
        'account_center.verified': 'Verificato',
        'account_center.verify': 'Verifica',
        'account_center.unverified': 'Non verificato',
        'about_profile.title': 'Informazioni su questo account',
        'about_profile.description':
            'Questa pagina mostra le informazioni pubbliche essenziali e la cronologia di questo account.',
        'about_profile.joined_on': 'Iscritto il {date}',
        'policies.center_title': 'Centro politiche',
        'policies.center_desc':
            'Qui puoi consultare regole, termini e documenti informativi di TurqApp.',
        'policies.last_updated': 'Ultimo aggiornamento: {date}',
        'language.title': 'Lingua',
        'language.subtitle': 'Scegli la lingua dell app.',
        'language.note':
            'Alcune schermate saranno tradotte gradualmente. La scelta viene applicata subito.',
        'language.option.tr': 'Turco',
        'language.option.en': 'Inglese',
        'language.option.de': 'Tedesco',
        'language.option.fr': 'Francese',
        'language.option.it': 'Italiano',
        'language.option.ru': 'Russo',
        'login.tagline': '"Le tue storie si incontrano qui."',
        'login.device_accounts': 'Account su questo dispositivo',
        'login.last_used': 'Ultimo usato',
        'login.saved_account': 'Account salvato',
        'login.sign_in': 'Accedi',
        'login.create_account': 'Crea account',
        'login.policies': 'Contratti e politiche',
        'login.identifier_hint': 'Nome utente o e-mail',
        'login.password_hint': 'La tua password',
        'login.reset': 'Reimposta',
        'login.reset_password_title': 'Reimposta la password',
        'login.email_label': 'Indirizzo e-mail',
        'login.email_hint': 'Inserisci il tuo indirizzo e-mail',
        'login.get_code': 'Ottieni codice',
        'login.resend_code': 'Invia di nuovo',
        'login.verification_code': 'Codice di verifica',
        'login.verification_code_hint': 'Codice di verifica a 6 cifre',
        'common.back': 'Indietro',
        'common.continue': 'Continua',
        'common.all': 'Tutti',
        'common.videos': 'Video',
        'common.photos': 'Foto',
        'common.no_results': 'Nessun risultato',
        'common.success': 'Operazione riuscita',
        'common.warning': 'Avviso',
        'common.delete': 'Elimina',
        'common.search': 'Cerca',
        'common.call': 'Chiama',
        'common.view': 'Visualizza',
        'common.create': 'Crea',
        'common.applications': 'Candidature',
        'common.liked': 'Mi piace',
        'common.saved': 'Salvato',
        'common.unknown_category': 'Categoria sconosciuta',
        'common.clear': 'Pulisci',
        'answer_key.published': 'Pubblicati',
        'answer_key.my_results': 'I miei risultati',
        'answer_key.saved_empty': 'Non ci sono libri salvati.',
        'answer_key.new_create': 'Crea nuovo',
        'answer_key.create_optical_form': 'Crea\nmodulo ottico',
        'answer_key.create_booklet_answer_key':
            'Crea\nsoluzioni libro',
        'answer_key.create_optical_form_single': 'Crea modulo ottico',
        'answer_key.give_exam_name': 'Dai un nome al tuo esame',
        'answer_key.join_exam_title': 'Partecipa all esame',
        'answer_key.exam_id_hint': 'ID esame',
        'answer_key.book': 'Libro',
        'answer_key.create_book': 'Crea libro',
        'answer_key.optical_form': 'Modulo ottico',
        'answer_key.delete_book': 'Elimina libro',
        'answer_key.share_owner_only':
            'Solo gli admin e il proprietario dell annuncio possono condividere.',
        'answer_key.book_answer_key_desc': 'soluzioni',
        'answer_key.delete_operation': 'Eliminazione',
        'answer_key.delete_optical_confirm':
            'Vuoi davvero eliminare il modulo ottico chiamato @name?',
        'answer_key.total_questions': '@count domande totali',
        'answer_key.participant_count': '@count persone',
        'answer_key.id_copied': 'ID copiato',
        'answer_key.answered_suffix': 'Risposto @time fa',
        'common.share': 'Condividi',
        'common.show_more': 'Mostra di più',
        'common.show_less': 'Mostra meno',
        'common.hide': 'Nascondi',
        'common.push': 'Push',
        'common.quote': 'Cita',
        'common.user': 'Utente',
        'common.info': 'Info',
        'common.cancel': 'Annulla',
        'common.select': 'Seleziona',
        'common.close': 'Chiudi',
        'common.unspecified': 'Non specificato',
        'common.yes': 'Si',
        'common.no': 'No',
        'common.selected_count': '@count selezionati',
        'profile_photo.camera': 'Scatta una foto',
        'profile_photo.gallery': 'Scegli dalla galleria',
        'common.now': 'ora',
        'common.download': 'Scarica',
        'app.name': 'TurqApp',
        'common.copy': 'Copia',
        'common.copy_link': 'Copia link',
        'common.copied': 'Copiato',
        'common.link_copied': 'Il link e stato copiato negli appunti',
        'common.archive': 'Archivia',
        'common.unarchive': 'Rimuovi dall archivio',
        'common.apply': 'Applica',
        'common.reset': 'Reimposta',
        'common.select_city': 'Seleziona citta',
        'common.select_district': 'Seleziona distretto',
        'common.report': 'Segnala',
        'report.reported_user': 'Utente segnalato',
        'report.what_issue': 'Che tipo di problema stai segnalando?',
        'report.thanks_title':
            'Grazie per aiutarci a rendere TurqApp migliore per tutti!',
        'report.thanks_body':
            'Sappiamo che il tuo tempo e prezioso. Grazie per aver dedicato del tempo ad aiutarci.',
        'report.how_it_works_title': 'Come funziona?',
        'report.how_it_works_body':
            'La tua segnalazione e arrivata. Nasconderemo il profilo segnalato dal tuo feed.',
        'report.whats_next_title': 'Cosa succede ora?',
        'report.whats_next_body':
            'Il nostro team esaminera questo profilo entro pochi giorni. Se verra trovata una violazione, l account sara limitato. Se non verra trovata alcuna violazione e avrai inviato ripetutamente segnalazioni non valide, il tuo account potrebbe essere limitato.',
        'report.optional_block_title': 'Se vuoi',
        'report.optional_block_body':
            'Puoi bloccare questo profilo. Se lo fai, questo utente non apparira piu nel tuo feed.',
        'report.block_user_button': 'Blocca @nickname',
        'report.blocked_user_label': '@nickname e stato bloccato!',
        'report.block_user_info':
            'Impedisci a @nickname di seguirti o inviarti messaggi. Potra comunque vedere i tuoi post pubblici ma non potra interagire con te. Anche tu non vedrai piu i post di @nickname.',
        'report.select_reason_title': 'Seleziona il motivo',
        'report.select_reason_body':
            'Devi scegliere un motivo per continuare.',
        'report.submitted_title': 'La tua richiesta è arrivata!',
        'report.submitted_body':
            'Esamineremo @nickname. Grazie per la tua segnalazione.',
        'report.submitting': 'Invio...',
        'report.done': 'Fatto',
        'report.reason.impersonation.title':
            'Imitazione / Account falso / Uso improprio dell identita',
        'report.reason.impersonation.desc':
            'Questo account o contenuto potrebbe imitare qualcun altro, usare un identita falsa o rappresentare un altra persona senza permesso.',
        'report.reason.copyright.title':
            'Copyright / Uso non autorizzato di contenuti',
        'report.reason.copyright.desc':
            'Questo contenuto potrebbe usare materiale protetto da copyright senza autorizzazione o violare la proprieta intellettuale.',
        'report.reason.harassment.title':
            'Molestie / Presa di mira / Bullismo',
        'report.reason.harassment.desc':
            'Questo contenuto sembra molestare, umiliare, prendere di mira o fare bullismo sistematico verso una persona.',
        'report.reason.hate_speech.title': 'Incitamento all odio',
        'report.reason.hate_speech.desc':
            'Questo contenuto potrebbe includere odio, discriminazione o linguaggio degradante verso una persona o un gruppo.',
        'report.reason.nudity.title': 'Nudita / Contenuto sessuale',
        'report.reason.nudity.desc':
            'Questo contenuto potrebbe includere nudita, oscenita o materiale sessuale esplicito.',
        'report.reason.violence.title': 'Violenza / Minaccia',
        'report.reason.violence.desc':
            'Questo contenuto potrebbe includere violenza fisica, minacce, intimidazioni o inviti a fare del male.',
        'report.reason.spam.title':
            'Spam / Contenuto ripetitivo non pertinente',
        'report.reason.spam.desc':
            'Questo contenuto appare ripetitivo, non pertinente, fuorviante o disturbante in modo simile allo spam.',
        'report.reason.scam.title': 'Truffa / Inganno',
        'report.reason.scam.desc':
            'Questo contenuto potrebbe essere ingannevole o fraudolento per abusare di fiducia, denaro o informazioni.',
        'report.reason.misinformation.title':
            'Disinformazione / Manipolazione',
        'report.reason.misinformation.desc':
            'Questo contenuto potrebbe distorcere i fatti, diffondere disinformazione o manipolare le persone.',
        'report.reason.illegal_content.title': 'Contenuto illegale',
        'report.reason.illegal_content.desc':
            'Questo contenuto potrebbe coinvolgere attivita illegali, promozione criminale o materiale illecito.',
        'report.reason.child_safety.title':
            'Violazione della sicurezza dei minori',
        'report.reason.child_safety.desc':
            'Questo contenuto potrebbe mettere in pericolo la sicurezza dei minori o contenere elementi dannosi non adatti ai bambini.',
        'report.reason.self_harm.title':
            'Autolesionismo / Incoraggiamento al suicidio',
        'report.reason.self_harm.desc':
            'Questo contenuto potrebbe promuovere autolesionismo, suicidio o comportamenti autodistruttivi.',
        'report.reason.privacy_violation.title':
            'Violazione della privacy',
        'report.reason.privacy_violation.desc':
            'Questo contenuto potrebbe includere condivisione non autorizzata di dati personali, doxxing o violazione della privacy.',
        'report.reason.fake_engagement.title':
            'Coinvolgimento falso / Bot / Crescita manipolata',
        'report.reason.fake_engagement.desc':
            'Questo contenuto potrebbe implicare falsi like, attivita di bot o crescita artificiale manipolata.',
        'report.reason.other.title': 'Altro',
        'report.reason.other.desc':
            'Potrebbe esserci un altra violazione non coperta sopra che desideri farci esaminare.',
        'common.undo': 'Annulla',
        'common.edited': 'modificato',
        'common.delete_post_title': 'Elimina post',
        'common.delete_post_message':
            'Vuoi davvero eliminare questo post?',
        'common.delete_post_confirm': 'Elimina post',
        'common.post_share_title': 'Post TurqApp',
        'common.send': 'Invia',
        'common.block': 'Blocca',
        'common.unknown_user': 'Utente sconosciuto',
        'common.unknown_company': 'Azienda sconosciuta',
        'common.verified': 'Verificato',
        'common.verify': 'Verifica',
        'common.change': 'Modifica',
        'comments.input_hint': 'Cosa ne pensi?',
        'explore.tab.trending': 'Tendenze',
        'explore.tab.for_you': 'Per te',
        'explore.tab.series': 'Serie',
        'explore.trending_rank': '@index - di tendenza in Turchia',
        'explore.no_results': 'Nessun risultato',
        'explore.no_series': 'Nessuna serie trovata',
        'feed.empty_city':
            'Non ci sono ancora post nella tua citta',
        'feed.empty_following':
            'Nessun post ancora dalle persone che segui',
        'post_likes.title': 'Mi piace',
        'post_likes.empty': 'Non ci sono ancora mi piace',
        'post_state.hidden_title': 'Post nascosto',
        'post_state.hidden_body':
            'Questo post e stato nascosto. Vedrai contenuti simili piu in basso nel feed.',
        'post_state.archived_title': 'Post archiviato',
        'post_state.archived_body':
            'Hai archiviato questo post.\nNon sara piu visibile a nessuno.',
        'post_state.deleted_title': 'Post eliminato',
        'post_state.deleted_body': 'Questo post non e piu pubblicato.',
        'post.share_title': 'Post TurqApp',
        'post.archive': 'Archivia',
        'post.unarchive': 'Rimuovi dall archivio',
        'post.like_failed': 'L operazione di like non puo essere completata.',
        'post.save_failed':
            'L operazione di salvataggio non puo essere completata.',
        'post.reshare_failed':
            'L operazione di ricondivisione non puo essere completata.',
        'post.report_success': 'Post segnalato.',
        'post.report_failed': 'La segnalazione non puo essere completata.',
        'post.hide_failed': 'Non e stato possibile completare il nascondimento.',
        'post.reshare_action': 'Ricondividi',
        'post.reshare_undo': 'Annulla ricondivisione',
        'post.reshared_you': 'lo hai ricondiviso',
        'post.reshared_by': '@name lo ha ricondiviso',
        'short.next_post': 'Vai al post successivo',
        'short.publish_as_post': 'Pubblica come post',
        'short.add_to_story': 'Aggiungi alla tua storia',
        'short.shared_as_post_by': 'Condiviso come post da',
        'story.seens_title': 'Visualizzazioni (@count)',
        'story.no_seens': 'Nessuno ha visto la tua storia',
        'story.comments_title': 'Commenti (@count)',
        'story.share_title': 'Storia di @name',
        'story.share_desc': 'Guarda la storia su TurqApp',
        'story.drawing_title': 'Aggiungi disegno',
        'story.brush_color': 'Colore del pennello',
        'story.no_comments': 'Nessun commento ancora',
        'story.add_comment_for': 'Aggiungi un commento per @nickname..',
        'story.delete_message': 'Eliminare questa storia?',
        'story.permanent_delete': 'Elimina definitivamente',
        'story.permanent_delete_message':
            'Eliminare definitivamente questa storia?',
        'story.comment_delete_message':
            'Vuoi davvero eliminare questo commento?',
        'story.deleted_stories.title': 'Storie',
        'story.deleted_stories.tab_deleted': 'Eliminate',
        'story.deleted_stories.tab_expired': 'Scadute',
        'story.deleted_stories.empty': 'Non ci sono storie eliminate',
        'story.deleted_stories.snackbar_title': 'Storia',
        'story.deleted_stories.reposted': 'Storia ripubblicata',
        'story.deleted_stories.deleted_forever':
            'Storia eliminata definitivamente',
        'story.deleted_stories.deleted_at': 'Eliminata: @time',
        'admin_push.queue_title': 'Push',
        'admin_push.queue_body_count':
            'Push messo in coda per @count utenti',
        'admin_push.queue_body': 'Push messo in coda',
        'admin_push.failed_body': 'Il push non puo essere inviato.',
        'story_music.title': 'Musica',
        'story_music.no_active_stories':
            'Non ci sono storie attive con questa musica',
        'story_music.untitled': 'Brano senza titolo',
        'story_music.active_story_count': '@count storie attive',
        'story_music.minutes_ago': '@count min',
        'story_music.hours_ago': '@count h',
        'story_music.days_ago': '@count g',
        'chat.attach_photos': 'Foto',
        'chat.list_title': 'Chat',
        'chat.tab_all': 'Tutte',
        'chat.tab_unread': 'Non lette',
        'chat.tab_archive': 'Archivio',
        'chat.empty_title': 'Non hai ancora chat',
        'chat.empty_body':
            'Quando inizierai a messaggiare, le conversazioni appariranno qui.',
        'chat.action_failed':
            'L azione non puo essere completata per un problema di autorizzazione o di record',
        'chat.attach_videos': 'Video',
        'chat.attach_location': 'Posizione',
        'chat.message_hint': 'Messaggio',
        'chat.no_starred_messages': 'Nessun messaggio speciale',
        'chat.profile_stats':
            '@followers follower · @following seguiti · @posts post',
        'chat.selected_messages': '@count messaggi selezionati',
        'chat.today': 'Oggi',
        'chat.yesterday': 'Ieri',
        'chat.typing': 'sta scrivendo...',
        'chat.gif': 'GIF',
        'chat.ready_to_send': 'Pronto da inviare',
        'chat.editing_message': 'Modifica del messaggio',
        'chat.video': 'Video',
        'chat.audio': 'Audio',
        'chat.location': 'Posizione',
        'chat.post': 'Post',
        'chat.person': 'Persona',
        'chat.reply': 'Rispondi',
        'chat.recording_timer': 'Registrazione... @time',
        'chat.fetching_address': 'Recupero indirizzo...',
        'chat.add_star': 'Aggiungi stella',
        'chat.remove_star': 'Rimuovi stella',
        'chat.you': 'Tu',
        'chat.hide_photos': 'Nascondi foto',
        'chat.unsent_message': 'Messaggio annullato',
        'chat.reply_prompt': 'Rispondi',
        'chat.open_in_maps': 'Apri in Maps',
        'chat.open_in_google_maps': 'Apri in Google Maps',
        'chat.open_in_apple_maps': 'Apri in Apple Maps',
        'chat.open_in_yandex_maps': 'Apri in Yandex Maps',
        'chat.contact_info': 'Informazioni contatto',
        'chat.save_to_contacts': 'Salva nei contatti',
        'chat.call': 'Chiama',
        'chat.delete_message_title': 'Elimina messaggio',
        'chat.delete_message_body':
            'Vuoi davvero eliminare questo messaggio?',
        'chat.delete_for_me': 'Elimina solo per me',
        'chat.delete_for_everyone': 'Elimina per tutti',
        'chat.delete_photo_title': 'Elimina foto',
        'chat.delete_photo_body': 'Vuoi davvero eliminare questa foto?',
        'chat.delete_photo_confirm': 'Elimina foto',
        'chat.messages_delete_failed': 'Impossibile eliminare i messaggi',
        'chat.image_upload_failed': 'Caricamento immagine non riuscito',
        'chat.image_upload_failed_with_error':
            'Caricamento immagine non riuscito: @error',
        'chat.video_upload_failed':
            'Si e verificato un errore durante il caricamento del video',
        'chat.microphone_permission_required': 'Autorizzazione richiesta',
        'chat.microphone_permission_denied':
            'Permesso microfono non concesso',
        'chat.voice_record_start_failed':
            'Impossibile avviare la registrazione vocale',
        'chat.voice_message_upload_failed':
            'Si e verificato un errore durante il caricamento del messaggio vocale',
        'chat.message_send_failed':
            'Impossibile inviare il messaggio. Riprova.',
        'chat.shared_post_from': 'Ha inviato il post di @nickname',
        'chat.notif_video': 'Ha inviato un video',
        'chat.notif_audio': 'Ha inviato un messaggio vocale',
        'chat.notif_images': 'Ha inviato @count immagini',
        'chat.notif_post': 'Ha condiviso un post',
        'chat.notif_location': 'Ha inviato una posizione',
        'chat.notif_contact': 'Ha condiviso un contatto',
        'chat.notif_gif': 'Ha inviato una GIF',
        'chat.reply_target_missing':
            'Il messaggio a cui rispondi non e stato trovato',
        'chat.forwarded_title': 'Inoltrato',
        'chat.forwarded_body':
            'Il messaggio e stato inoltrato alla chat selezionata',
        'chat.tap_to_chat': 'Tocca per iniziare a chattare.',
        'chat.photo': 'Foto',
        'chat.message_label': 'Messaggio',
        'chat.marked_unread': 'Chat segnata come non letta',
        'chat.limit_title': 'Limite',
        'chat.pin_limit': 'Puoi fissare fino a 5 chat',
        'chat.action_completed': 'Azione completata',
        'chat.muted': 'Chat silenziata',
        'chat.unmuted': 'Audio chat riattivato',
        'chat.archived': 'Chat spostata nell archivio',
        'chat.unarchived': 'Chat rimossa dall archivio',
        'chat.delete_title': 'Elimina chat',
        'chat.delete_message':
            'Vuoi davvero eliminare questa chat?',
        'chat.delete_confirm': 'Elimina chat',
        'chat.deleted_title': 'Chat eliminata',
        'chat.deleted_body':
            'La chat selezionata e stata eliminata con successo',
        'chat.unmute': 'Riattiva audio',
        'chat.mute': 'Silenzia',
        'chat.mark_unread': 'Segna come non letta',
        'chat.pin': 'Fissa',
        'chat.unpin': 'Rimuovi pin',
        'chat.muted_label': 'Silenziosa',
        'training.comments_title': 'Commenti',
        'training.no_comments': 'Nessun commento ancora.',
        'training.reply': 'Rispondi',
        'training.hide_replies': 'Nascondi risposte',
        'training.view_replies': 'Vedi @count risposte',
        'training.unknown_user': 'Utente sconosciuto',
        'training.edit': 'Modifica',
        'training.report': 'Segnala',
        'training.reply_to_user': 'Rispondi a @name',
        'training.cancel': 'Annulla',
        'training.edit_comment_hint': 'Modifica commento',
        'training.write_hint': 'Scrivi..',
        'training.pick_from_gallery': 'Scegli dalla galleria',
        'training.take_photo': 'Scatta una foto',
        'training.time_now': 'proprio ora',
        'training.time_min': '@count min fa',
        'training.time_hour': '@count h fa',
        'training.time_day': '@count g fa',
        'training.time_week': '@count sett fa',
        'training.photo_pick_failed':
            'Si e verificato un errore durante la selezione della foto!',
        'training.photo_upload_failed':
            'Si e verificato un errore durante il caricamento della foto!',
        'training.question_bank_title': 'Banca delle domande',
        'training.questions_loading': 'Caricamento domande...',
        'training.solve_later_empty':
            'Nessuna domanda da risolvere piu tardi trovata!',
        'training.remove_solve_later': 'Rimuovi da Risolvi dopo',
        'training.no_questions': 'Nessuna domanda trovata!',
        'training.answer_first': 'Rispondi prima alla domanda!',
        'training.share': 'Condividi',
        'training.correct_ratio': '%@value Corrette',
        'training.wrong_ratio': '%@value Errate',
        'training.complaint_select_one':
            'Seleziona almeno un motivo di segnalazione.',
        'training.complaint_thanks':
            'Grazie per la segnalazione.',
        'training.complaint_submit_failed':
            'Si e verificato un errore durante l invio della segnalazione.',
        'training.no_questions_in_category':
            'Nessuna domanda trovata in questa categoria.',
        'training.saved_load_failed':
            'Si e verificato un errore durante il caricamento delle domande salvate.',
        'training.view_update_failed':
            'Si e verificato un errore durante l aggiornamento della visualizzazione.',
        'training.saved_removed':
            'Domanda rimossa dalla lista Risolvi dopo!',
        'training.saved_added':
            'Domanda aggiunta alla lista Risolvi dopo!',
        'training.saved_remove_failed':
            'Si e verificato un errore durante la rimozione da Risolvi dopo.',
        'training.saved_update_failed':
            'Si e verificato un errore durante l aggiornamento di Risolvi dopo.',
        'training.like_removed': 'Mi piace rimosso!',
        'training.liked': 'Domanda apprezzata!',
        'training.like_remove_failed':
            'Si e verificato un errore durante la rimozione del Mi piace.',
        'training.like_add_failed':
            'Si e verificato un errore durante l aggiunta del Mi piace.',
        'training.share_failed': 'Impossibile avviare la condivisione',
        'training.share_question_link_title':
            '@exam - @lesson Domanda @number',
        'training.share_question_title':
            'TurqApp - Domanda @exam @lesson',
        'training.share_question_desc':
            'Domanda della banca delle domande TurqApp',
        'training.leaderboard_empty':
            'Nessuna classifica e stata ancora creata.',
        'training.leaderboard_empty_body':
            'Risolvi domande nella banca per entrare in classifica.',
        'training.answer_locked':
            'Non puoi modificare la risposta a questa domanda!',
        'training.answer_saved':
            'La risposta a questa domanda e gia stata salvata.',
        'training.answer_save_failed':
            'Si e verificato un errore durante il salvataggio della risposta',
        'training.no_more_questions':
            'Non ci sono altre domande in questa categoria!',
        'training.settings_opening':
            'Apertura della schermata impostazioni!',
        'training.fetch_more_failed':
            'Si e verificato un errore durante il caricamento di altre domande',
        'training.comments_load_failed':
            'Si e verificato un errore durante il caricamento dei commenti. Riprova!',
        'training.comment_or_photo_required':
            'Devi aggiungere un commento o una foto!',
        'training.reply_or_photo_required':
            'Devi aggiungere una risposta o una foto!',
        'training.comment_added': 'Il tuo commento e stato aggiunto!',
        'training.comment_add_failed':
            'Si e verificato un errore durante l aggiunta del commento. Riprova!',
        'training.reply_added': 'La tua risposta e stata aggiunta!',
        'training.reply_add_failed':
            'Si e verificato un errore durante l aggiunta della risposta. Riprova!',
        'training.comment_deleted': 'Il tuo commento e stato eliminato!',
        'training.comment_delete_failed':
            'Si e verificato un errore durante l eliminazione del commento. Riprova!',
        'training.reply_deleted': 'La tua risposta e stata eliminata!',
        'training.reply_delete_failed':
            'Si e verificato un errore durante l eliminazione della risposta. Riprova!',
        'training.comment_updated': 'Il tuo commento e stato aggiornato!',
        'training.comment_update_failed':
            'Si e verificato un errore durante la modifica del commento. Riprova!',
        'training.reply_updated': 'La tua risposta e stata aggiornata!',
        'training.reply_update_failed':
            'Si e verificato un errore durante la modifica della risposta. Riprova!',
        'training.like_failed':
            'Si e verificato un errore durante il like. Riprova!',
        'training.upload_failed_title': 'Caricamento non riuscito!',
        'training.upload_failed_body':
            'Questo contenuto non puo essere elaborato al momento. Prova con un altro contenuto.',
        'common.accept': 'Accetta',
        'common.reject': 'Rifiuta',
        'common.open_profile': 'Apri profilo',
        'tutoring.title': 'Lezioni private',
        'tutoring.search_hint': 'Che tipo di lezione stai cercando?',
        'tutoring.my_applications': 'Le mie candidature',
        'tutoring.create_listing': 'Pubblica annuncio',
        'tutoring.my_listings': 'I miei annunci',
        'tutoring.saved': 'Salvati',
        'tutoring.slider_admin': 'Gestione slider',
        'tutoring.review_title': 'Lascia una recensione',
        'tutoring.review_hint': 'Scrivi il tuo commento (opzionale)',
        'tutoring.review_select_rating':
            'Seleziona una valutazione.',
        'tutoring.review_saved': 'La tua recensione e stata salvata.',
        'tutoring.applicants_title': 'Candidati',
        'tutoring.no_applications': 'Non ci sono ancora candidature',
        'tutoring.application_label': 'Candidatura per lezione privata',
        'tutoring.my_applications_empty':
            'Non hai ancora inviato candidature per lezioni private',
        'tutoring.instructor_fallback': 'Insegnante',
        'tutoring.cancel_application_title': 'Annulla candidatura',
        'tutoring.cancel_application_body':
            'Vuoi davvero annullare questa candidatura?',
        'tutoring.cancel_application_action': 'Annulla candidatura',
        'tutoring.my_listings_title': 'I miei annunci',
        'tutoring.published': 'Pubblicati',
        'tutoring.expired': 'Scaduti',
        'tutoring.active_listings_empty':
            'Non ci sono annunci di lezioni private attivi.',
        'tutoring.expired_listings_empty':
            'Non ci sono annunci di lezioni private scaduti.',
        'tutoring.user_id_missing':
            'Impossibile trovare l identita utente.',
        'tutoring.load_failed':
            'Si e verificato un errore durante il caricamento degli annunci: {error}',
        'tutoring.reactivated_title': 'Annuncio riattivato',
        'tutoring.reactivated_body':
            'L annuncio e stato pubblicato di nuovo.',
        'tutoring.user_load_failed':
            'Si e verificato un errore durante il caricamento delle informazioni utente: {error}',
        'tutoring.location_missing': 'Posizione non trovata',
        'tutoring.no_listings_in_region':
            'Non ci sono annunci di lezioni in questa zona.',
        'tutoring.no_lessons_in_category':
            'Non ci sono lezioni nella categoria {category}.',
        'tutoring.search_empty':
            'Nessun annuncio corrisponde alla tua ricerca.',
        'tutoring.search_empty_info':
            'Nessun annuncio di lezioni private corrispondente!',
        'tutoring.similar_listings': 'Annunci simili',
        'tutoring.open_listing': 'Apri annuncio',
        'tutoring.report_listing': 'Segnala annuncio',
        'tutoring.saved_empty': 'Nessun annuncio salvato.',
        'tutoring.detail_description': 'Descrizione',
        'tutoring.detail_no_description':
            'Nessuna descrizione e stata aggiunta per questo annuncio.',
        'tutoring.detail_lesson_info': 'Informazioni sulla lezione',
        'tutoring.detail_branch': 'Categoria',
        'tutoring.detail_price': 'Prezzo',
        'tutoring.detail_contact': 'Contatto',
        'tutoring.detail_phone_and_message': 'Telefono + Messaggio',
        'tutoring.detail_message_only': 'Solo messaggio',
        'tutoring.detail_gender_preference': 'Preferenza di genere',
        'tutoring.detail_availability': 'Disponibilita',
        'tutoring.detail_listing_info': 'Informazioni sull annuncio',
        'tutoring.detail_instructor': 'Insegnante',
        'tutoring.detail_not_specified': 'Non specificato',
        'tutoring.detail_city': 'Citta',
        'tutoring.detail_views': 'Visualizzazioni',
        'tutoring.detail_status': 'Stato',
        'tutoring.detail_status_passive': 'Passivo',
        'tutoring.detail_status_active': 'Attivo',
        'tutoring.detail_location': 'Posizione',
        'tutoring.create.city_select': 'Seleziona citta',
        'tutoring.create.district_select': 'Seleziona distretto',
        'tutoring.create.nsfw_check_failed':
            'Il controllo NSFW dell immagine non e riuscito.',
        'tutoring.create.nsfw_detected':
            'E stata rilevata un immagine non appropriata.',
        'tutoring.create.fill_required':
            'Compila tutti i campi obbligatori!',
        'tutoring.create.published':
            'L annuncio di lezione privata e stato pubblicato!',
        'tutoring.create.publish_failed':
            'Si e verificato un errore durante la pubblicazione dell annuncio.',
        'tutoring.create.updated': 'Annuncio aggiornato!',
        'tutoring.create.no_changes': 'Nessuna modifica effettuata!',
        'tutoring.create.update_failed':
            'Si e verificato un errore durante l aggiornamento dell annuncio.',
        'tutoring.call_disabled':
            'Le chiamate sono disabilitate per questo annuncio.',
        'tutoring.message': 'Messaggio',
        'tutoring.messages': 'Messaggi',
        'tutoring.phone_missing':
            'Il numero di telefono dell insegnante non e stato trovato.',
        'tutoring.phone_open_failed':
            'Impossibile aprire l app telefono.',
        'tutoring.unpublish_title': 'Rimuovi annuncio',
        'tutoring.unpublish_body':
            'Vuoi davvero rimuovere dalla pubblicazione questo annuncio di lezioni private?',
        'tutoring.unpublished':
            'Annuncio rimosso dalla pubblicazione.',
        'tutoring.apply_login_required':
            'Accedi di nuovo per candidarti.',
        'tutoring.application_sent':
            'La tua candidatura e stata inviata.',
        'tutoring.application_failed':
            'Si e verificato un problema durante la candidatura.',
        'tutoring.delete_success': 'Annuncio eliminato!',
        'tutoring.delete_failed':
            'Si e verificato un errore durante l eliminazione dell annuncio.',
        'tutoring.filter_title': 'Filtri',
        'tutoring.gender_title': 'Genere',
        'tutoring.sort_title': 'Ordinamento',
        'tutoring.lesson_place_title': 'Luogo della lezione',
        'tutoring.service_location_title': 'Area di servizio',
        'tutoring.gender.male': 'Uomo',
        'tutoring.gender.female': 'Donna',
        'tutoring.gender.any': 'Indifferente',
        'tutoring.sort.latest': 'Piu recenti',
        'tutoring.sort.nearest': 'Piu vicini a me',
        'tutoring.sort.most_viewed': 'Piu visualizzati',
        'tutoring.lesson_place.student_home': 'Casa dello studente',
        'tutoring.lesson_place.teacher_home': 'Casa dell insegnante',
        'tutoring.lesson_place.either_home':
            'Casa dello studente o dell insegnante',
        'tutoring.lesson_place.remote': 'Didattica a distanza',
        'tutoring.lesson_place.lesson_area': 'Area lezioni',
        'tutoring.branch.summer_school': 'Scuola estiva',
        'tutoring.branch.secondary_education': 'Scuola secondaria',
        'tutoring.branch.primary_education': 'Scuola primaria',
        'tutoring.branch.foreign_language': 'Lingua straniera',
        'tutoring.branch.software': 'Software',
        'tutoring.branch.driving': 'Guida',
        'tutoring.branch.sports': 'Sport',
        'tutoring.branch.art': 'Arte',
        'tutoring.branch.music': 'Musica',
        'tutoring.branch.theatre': 'Teatro',
        'tutoring.branch.personal_development': 'Crescita personale',
        'tutoring.branch.vocational': 'Professionale',
        'tutoring.branch.special_education': 'Educazione speciale',
        'tutoring.branch.children': 'Bambini',
        'tutoring.branch.diction': 'Dizione',
        'tutoring.branch.photography': 'Fotografia',
        'scholarship.applications_title': 'Candidature (@count)',
        'scholarship.no_applications': 'Non ci sono ancora candidature',
        'scholarship.my_listings': 'I miei annunci di borsa',
        'scholarship.no_my_listings':
            'Non hai alcun annuncio di borsa!',
        'scholarship.applications_suffix': 'CANDIDATURE BORSA @title',
        'scholarship.my_applications_title':
            'Le mie candidature alla borsa',
        'scholarship.no_user_applications':
            'Non hai candidature alla borsa!',
        'scholarship.saved_empty': 'Nessuna borsa salvata trovata.',
        'scholarship.liked_empty': 'Nessuna borsa con Mi piace trovata.',
        'scholarship.remove_saved': 'Rimuovi dai salvati',
        'scholarship.remove_liked': 'Rimuovi dai Mi piace',
        'scholarship.remove_saved_confirm':
            'Sei sicuro di voler rimuovere questa borsa dai salvati?',
        'scholarship.remove_liked_confirm':
            'Sei sicuro di voler rimuovere questa borsa dai Mi piace?',
        'scholarship.removed_saved':
            'Borsa rimossa dai salvati.',
        'scholarship.removed_liked':
            'Borsa rimossa dai Mi piace.',
        'scholarship.list_title': 'Borse di studio (@count)',
        'scholarship.search_results_title': 'Risultati di ricerca (@count)',
        'scholarship.empty_title': 'Nessuna borsa di studio per ora',
        'scholarship.empty_body':
            'Nuove borse di studio saranno aggiunte presto',
        'scholarship.no_results_for':
            'Nessun risultato per "@query"',
        'scholarship.search_hint_body':
            'Suggerimento: prova parole chiave diverse',
        'scholarship.search_tip_header': 'Puoi cercare per:',
        'scholarship.load_more_failed':
            'Impossibile caricare altre borse di studio.',
        'scholarship.like_failed':
            'Operazione Mi piace non riuscita.',
        'scholarship.bookmark_failed':
            'Operazione di salvataggio non riuscita.',
        'scholarship.share_owner_only':
            'Solo gli admin e il proprietario dell annuncio possono condividere.',
        'scholarship.share_missing_id':
            'ID borsa di studio non trovato per la condivisione.',
        'scholarship.share_failed': 'Condivisione non riuscita.',
        'scholarship.share_fallback_desc':
            'Annuncio di borsa di studio TurqApp',
        'scholarship.share_detail_title':
            'TurqApp Educazione - Dettaglio borsa di studio',
        'scholarship.providers_title': 'Enti erogatori di borse',
        'scholarship.providers_empty':
            'Nessun ente erogatore trovato.',
        'scholarship.providers_load_failed':
            'Impossibile caricare gli enti erogatori.',
        'scholarship.applications_load_failed':
            'Impossibile caricare le candidature.',
        'scholarship.withdraw_application': 'Ritira candidatura',
        'scholarship.withdraw_confirm_title': 'Attenzione!',
        'scholarship.withdraw_confirm_body':
            'Vuoi davvero ritirare la tua candidatura?',
        'scholarship.withdraw_success':
            'La tua candidatura alla borsa e stata ritirata.',
        'scholarship.withdraw_failed':
            'Impossibile ritirare la candidatura.',
        'scholarship.session_missing':
            'La sessione utente non e attiva.',
        'scholarship.create_title': 'Crea borsa di studio',
        'scholarship.edit_title': 'Modifica borsa di studio',
        'scholarship.preview_title': 'Anteprima borsa di studio',
        'scholarship.visual_info': 'Informazioni visive',
        'scholarship.basic_info': 'Informazioni di base',
        'scholarship.application_info': 'Informazioni sulla candidatura',
        'scholarship.extra_info': 'Informazioni aggiuntive',
        'scholarship.title_label': 'Titolo della borsa',
        'scholarship.provider_label': 'Ente erogatore',
        'scholarship.website_label': 'Sito web',
        'scholarship.description_help':
            'Scrivi la descrizione della borsa in un unico blocco chiaro.',
        'scholarship.no_description': 'Nessuna descrizione',
        'scholarship.conditions_label': 'Requisiti di candidatura',
        'scholarship.required_docs_label': 'Documenti richiesti',
        'scholarship.award_months_label': 'Mesi di erogazione',
        'scholarship.application_place_label': 'Luogo di candidatura',
        'scholarship.application_place_turqapp': 'TurqApp',
        'scholarship.application_place_website': 'Sito web della borsa',
        'scholarship.application_website_label': 'Sito web della borsa',
        'scholarship.application_dates_label': 'Date di candidatura',
        'scholarship.detail_missing':
            'Errore: dati della borsa non trovati.',
        'scholarship.detail_title': 'Dettaglio borsa',
        'scholarship.delete_title': 'Elimina borsa',
        'scholarship.delete_confirm':
            'Sei sicuro di voler eliminare questa borsa?',
        'scholarship.applications_heading': 'Candidature alla borsa @title',
        'scholarship.applicant.personal_section': 'Informazioni personali',
        'scholarship.applicant.education_section':
            "Informazioni sull'istruzione",
        'scholarship.applicant.family_section': 'Informazioni familiari',
        'scholarship.applicant.full_name': 'Nome completo',
        'scholarship.applicant.email': 'Indirizzo e-mail',
        'scholarship.applicant.phone': 'Numero di telefono',
        'scholarship.applicant.phone_open_failed':
            'Impossibile avviare la chiamata telefonica',
        'scholarship.applicant.email_open_failed':
            'Impossibile aprire il client e-mail',
        'chat.sign_in_required':
            'Devi accedere per inviare un messaggio.',
        'chat.cannot_message_self_listing':
            'Non puoi inviare un messaggio al tuo annuncio.',
        'scholarship.applicant.country': 'Paese',
        'scholarship.applicant.registry_city': 'Citta di registrazione',
        'scholarship.applicant.registry_district': 'Distretto di registrazione',
        'scholarship.applicant.birth_date': 'Data di nascita',
        'scholarship.applicant.marital_status': 'Stato civile',
        'scholarship.applicant.gender': 'Genere',
        'scholarship.applicant.disability_report': 'Rapporto di disabilita',
        'scholarship.applicant.employment_status': 'Stato lavorativo',
        'scholarship.applicant.education_level': 'Livello di istruzione',
        'scholarship.applicant.university': 'Universita',
        'scholarship.applicant.faculty': 'Facolta',
        'scholarship.applicant.department': 'Dipartimento',
        'scholarship.applicant.father_alive': 'Il padre e in vita?',
        'scholarship.applicant.father_name': 'Nome del padre',
        'scholarship.applicant.father_surname': 'Cognome del padre',
        'scholarship.applicant.father_phone': 'Telefono del padre',
        'scholarship.applicant.father_job': 'Lavoro del padre',
        'scholarship.applicant.father_income': 'Reddito del padre',
        'scholarship.applicant.mother_alive': 'La madre e in vita?',
        'scholarship.applicant.mother_name': 'Nome della madre',
        'scholarship.applicant.mother_surname': 'Cognome della madre',
        'scholarship.applicant.mother_phone': 'Telefono della madre',
        'scholarship.applicant.mother_job': 'Lavoro della madre',
        'scholarship.applicant.mother_income': 'Reddito della madre',
        'scholarship.applicant.home_ownership': 'Possesso della casa',
        'scholarship.applicant.residence_city': 'Citta di residenza',
        'scholarship.applicant.residence_district': 'Distretto di residenza',
        'family_info.title': 'Informazioni familiari',
        'family_info.reset_menu': 'Reimposta informazioni familiari',
        'family_info.reset_title': 'Reimposta informazioni familiari',
        'family_info.reset_body':
            'Tutte le informazioni familiari verranno eliminate. Questa azione non puo essere annullata. Sei sicuro?',
        'family_info.select_father_alive':
            'Seleziona se tuo padre e in vita',
        'family_info.select_mother_alive':
            'Seleziona se tua madre e in vita',
        'family_info.father_name_surname': 'Nome e cognome del padre',
        'family_info.mother_name_surname': 'Nome e cognome della madre',
        'family_info.select_job': 'Seleziona professione',
        'family_info.father_salary': 'Stipendio netto del padre',
        'family_info.mother_salary': 'Stipendio netto della madre',
        'family_info.father_phone': 'Numero del padre',
        'family_info.mother_phone': 'Numero della madre',
        'family_info.salary_hint': 'Stipendio netto',
        'family_info.family_size': 'Dimensione della famiglia',
        'family_info.family_size_hint':
            'Numero di persone che vivono in casa (compreso te)',
        'family_info.residence_info': 'Informazioni di residenza',
        'family_info.father_salary_missing': 'Informazione sul reddito del padre',
        'family_info.father_phone_missing': 'Numero di telefono del padre',
        'family_info.father_phone_invalid':
            'Il numero del padre deve contenere 10 cifre',
        'family_info.mother_salary_missing': 'Informazione sul reddito della madre',
        'family_info.mother_phone_missing': 'Numero di telefono della madre',
        'family_info.mother_phone_invalid':
            'Il numero della madre deve contenere 10 cifre',
        'family_info.saved': 'Le informazioni familiari sono state salvate.',
        'family_info.save_failed':
            'Impossibile salvare le informazioni.',
        'family_info.reset_success':
            'Le informazioni familiari sono state reimpostate.',
        'family_info.reset_failed':
            'Impossibile reimpostare le informazioni.',
        'family_info.home_owned': 'Casa di proprieta',
        'family_info.home_relative': 'Casa di un familiare',
        'family_info.home_lodging': 'Alloggio di servizio',
        'family_info.home_rent': 'Affitto',
        'personal_info.title': 'Informazioni personali',
        'personal_info.reset_menu': 'Reimposta le mie informazioni',
        'personal_info.reset_title': 'Sei sicuro?',
        'personal_info.reset_body':
            'Le tue informazioni personali verranno reimpostate. Questa azione non puo essere annullata.',
        'personal_info.reset_success':
            'Le tue informazioni personali sono state reimpostate.',
        'personal_info.registry_info': 'Citta - distretto di registrazione',
        'personal_info.birth_date_title': 'La tua data di nascita',
        'personal_info.select_birth_date': 'Seleziona data di nascita',
        'personal_info.select_marital_status': 'Seleziona stato civile',
        'personal_info.select_gender': 'Seleziona genere',
        'personal_info.select_disability': 'Seleziona stato di disabilita',
        'personal_info.select_employment': 'Seleziona stato lavorativo',
        'personal_info.select_field': 'Seleziona @field',
        'personal_info.city_load_failed':
            'Impossibile caricare i dati di citta e distretto.',
        'personal_info.user_data_missing':
            'Dati utente non trovati. Puoi creare un nuovo record.',
        'personal_info.load_failed': 'Impossibile caricare i dati.',
        'personal_info.select_country_error': 'Seleziona un paese.',
        'personal_info.fill_city_district':
            'Compila citta e distretto.',
        'personal_info.saved': 'Le tue informazioni personali sono state salvate.',
        'personal_info.save_failed':
            'Impossibile salvare le informazioni.',
        'personal_info.marital_single': 'Celibe/Nubile',
        'personal_info.marital_married': 'Sposato',
        'personal_info.marital_divorced': 'Divorziato',
        'personal_info.gender_male': 'Uomo',
        'personal_info.gender_female': 'Donna',
        'personal_info.disability_yes': 'Si',
        'personal_info.disability_no': 'No',
        'personal_info.working_yes': 'Lavora',
        'personal_info.working_no': 'Non lavora',
        'education_info.title': 'Informazioni sull istruzione',
        'education_info.reset_menu':
            'Reimposta le mie informazioni di istruzione',
        'education_info.reset_title': 'Sei sicuro?',
        'education_info.reset_body':
            'Le tue informazioni di istruzione verranno reimpostate. Questa azione non puo essere annullata.',
        'education_info.reset_success':
            'Le tue informazioni di istruzione sono state reimpostate.',
        'education_info.select_level':
            'Seleziona prima un livello di istruzione!',
        'education_info.middle_school': 'Scuola',
        'education_info.high_school': 'Liceo',
        'education_info.class_level': 'Classe',
        'education_info.level_middle_school': 'Scuola media',
        'education_info.level_high_school': 'Liceo',
        'education_info.level_associate': 'Diploma breve',
        'education_info.level_bachelor': 'Laurea',
        'education_info.level_masters': 'Master',
        'education_info.level_doctorate': 'Dottorato',
        'education_info.class_grade': '@gradeª classe',
        'education_info.select_field': 'Seleziona @field',
        'education_info.initial_load_failed':
            'Impossibile caricare i dati iniziali.',
        'education_info.countries_load_failed':
            'Impossibile caricare i paesi.',
        'education_info.city_data_failed':
            'Impossibile caricare i dati di citta e distretto.',
        'education_info.middle_schools_failed':
            'Impossibile caricare i dati della scuola.',
        'education_info.high_schools_failed':
            'Impossibile caricare i dati del liceo.',
        'education_info.higher_education_failed':
            'Impossibile caricare i dati universitari.',
        'education_info.saved_data_failed':
            'Impossibile caricare i dati salvati.',
        'education_info.level_load_failed':
            'Impossibile caricare i dati del livello.',
        'education_info.select_city_error': 'Seleziona una citta.',
        'education_info.select_district_error': 'Seleziona un distretto.',
        'education_info.select_middle_school_error':
            'Seleziona una scuola media.',
        'education_info.select_high_school_error':
            'Seleziona un liceo.',
        'education_info.select_class_level_error':
            'Seleziona un livello di classe.',
        'education_info.select_university_error':
            'Seleziona un universita.',
        'education_info.select_faculty_error':
            'Seleziona una facolta.',
        'education_info.select_department_error':
            'Seleziona un dipartimento.',
        'education_info.saved':
            'Le tue informazioni di istruzione sono state salvate.',
        'education_info.save_failed': 'Salvataggio non riuscito.',
        'bank_info.title': 'Informazioni bancarie',
        'bank_info.reset_menu': 'Reimposta le mie informazioni bancarie',
        'bank_info.reset_title': 'Sei sicuro?',
        'bank_info.reset_body':
            'Le tue informazioni bancarie verranno reimpostate. Questa azione non puo essere annullata.',
        'bank_info.reset_success':
            'Le tue informazioni bancarie sono state reimpostate.',
        'bank_info.fast_title': 'Indirizzo rapido (FAST)',
        'bank_info.fast_email': 'E-mail',
        'bank_info.fast_phone': 'Telefono',
        'bank_info.fast_iban': 'IBAN',
        'bank_info.bank_label': 'Banca',
        'bank_info.select_bank': 'Seleziona banca',
        'bank_info.select_fast_type': 'Seleziona tipo di indirizzo rapido',
        'bank_info.load_failed': 'Impossibile caricare i dati.',
        'bank_info.missing_value':
            'Non possiamo continuare senza completare le informazioni IBAN.',
        'bank_info.missing_bank':
            'Non hai selezionato la banca su cui riceverai il pagamento. Questa informazione verra condivisa se la tua borsa verra approvata.',
        'bank_info.invalid_email':
            'Inserisci un indirizzo e-mail valido.',
        'bank_info.saved': 'Le informazioni bancarie sono state salvate.',
        'bank_info.save_failed':
            'Impossibile salvare le informazioni.',
        'dormitory.title': 'Informazioni sul dormitorio',
        'dormitory.reset_menu':
            'Reimposta le mie informazioni sul dormitorio',
        'dormitory.reset_title': 'Sei sicuro?',
        'dormitory.reset_body':
            'Le informazioni sul dormitorio verranno reimpostate. Questa azione non puo essere annullata.',
        'dormitory.reset_success':
            'Le informazioni sul dormitorio sono state reimpostate.',
        'dormitory.current_info': 'Informazioni attuali sul dormitorio',
        'dormitory.select_admin_type':
            'Seleziona il tipo di amministrazione',
        'dormitory.admin_public': 'Pubblico',
        'dormitory.admin_private': 'Privato',
        'dormitory.select_dormitory': 'Seleziona dormitorio',
        'dormitory.not_found_for_filters':
            'Nessun dormitorio trovato per questa citta e tipo di amministrazione',
        'dormitory.saved': 'Le informazioni sul dormitorio sono state salvate.',
        'dormitory.save_failed': 'Impossibile salvare i dati.',
        'dormitory.select_or_enter':
            'Seleziona un dormitorio o inserisci un nome',
        'scholarship.application_start_date': 'Data di inizio candidatura',
        'scholarship.application_end_date': 'Data di fine candidatura',
        'scholarship.select_from_list': 'Seleziona dall elenco',
        'scholarship.image_missing': 'Nessuna immagine trovata',
        'scholarship.amount_label': 'Importo',
        'scholarship.student_count_label': 'Numero di studenti',
        'scholarship.repayable_label': 'Rimborsabile',
        'scholarship.duplicate_status_label': 'Stato duplicato',
        'scholarship.education_audience_label': 'Pubblico educativo',
        'scholarship.target_audience_label': 'Pubblico target',
        'scholarship.country_label': 'Paese',
        'scholarship.cities_label': 'Citta',
        'scholarship.universities_label': 'Universita',
        'scholarship.published_at': 'Data di pubblicazione',
        'scholarship.show_less': 'Mostra meno',
        'scholarship.show_all': 'Mostra tutto',
        'scholarship.more_universities': '+@count universita in piu',
        'scholarship.other_info': 'Altre informazioni',
        'scholarship.application_how': 'Come candidarsi?',
        'scholarship.application_via_turqapp_prefix':
            'Le candidature tramite TurqApp sono ',
        'scholarship.application_received_status': 'ACCETTATE.',
        'scholarship.application_not_received_status': 'NON ACCETTATE.',
        'scholarship.edit_button': 'Modifica borsa di studio',
        'scholarship.website_open_failed':
            'Impossibile aprire il sito web. Inserisci un URL valido.',
        'scholarship.checking_info': 'Controllo informazioni',
        'scholarship.user_data_missing':
            'I dati utente non sono stati trovati. Completa le tue informazioni.',
        'scholarship.check_info_failed':
            'Si e verificato un errore durante il controllo delle informazioni.',
        'scholarship.application_check_failed':
            'Si e verificato un errore durante il controllo dello stato della candidatura.',
        'scholarship.login_required': 'Accedi per favore.',
        'scholarship.profile_missing':
            'Non ci sono informazioni di profilo per questa borsa.',
        'scholarship.applied_success':
            'La tua candidatura alla borsa e stata ricevuta.',
        'scholarship.apply_failed':
            'Impossibile salvare la candidatura.',
        'scholarship.follow_limit_title': 'Limite di follow',
        'scholarship.follow_limit_body':
            'Oggi non puoi seguire altre persone.',
        'scholarship.follow_failed':
            'L operazione di follow non e riuscita.',
        'scholarship.invalid': 'Borsa non valida.',
        'scholarship.delete_success':
            'Borsa eliminata con successo.',
        'scholarship.delete_failed':
            'Si e verificato un errore durante l eliminazione della borsa.',
        'scholarship.cancel_success':
            'La tua candidatura alla borsa e stata annullata.',
        'scholarship.cancel_failed':
            'Impossibile annullare la candidatura.',
        'scholarship.info_missing_title': 'Informazioni mancanti',
        'scholarship.info_missing_body':
            'Non puoi candidarti alle borse di studio senza completare le tue informazioni personali, scolastiche e familiari.',
        'scholarship.update_my_info': 'Aggiorna le mie informazioni',
        'scholarship.closed': 'Candidature chiuse',
        'scholarship.applied': 'Hai gia fatto domanda',
        'scholarship.cancel_apply_title': 'Annulla candidatura',
        'scholarship.cancel_apply_body':
            'Vuoi davvero annullare questa candidatura alla borsa di studio?',
        'scholarship.cancel_apply_button': 'Annulla candidatura',
        'scholarship.amount_hint': 'Importo',
        'scholarship.student_count_hint': 'es. 4',
        'scholarship.amount_student_count_notice':
            'Importo e numero di studenti non vengono mostrati nella pagina di candidatura.',
        'scholarship.degree_type_label': 'Tipo di laurea',
        'scholarship.degree_type_select': 'Seleziona tipo di laurea',
        'scholarship.select_country': 'Seleziona paese',
        'scholarship.select_country_first':
            'Seleziona prima un paese.',
        'scholarship.select_city_first':
            'Seleziona prima una citta.',
        'scholarship.select_university': 'Seleziona universita',
        'scholarship.selected_universities': 'Universita selezionate:',
        'scholarship.logo_label': 'Seleziona logo',
        'scholarship.logo_pick': 'Seleziona logo',
        'scholarship.custom_design_optional': 'Il tuo design (opzionale)',
        'scholarship.custom_image_pick': 'Seleziona immagine',
        'scholarship.template_select': 'Seleziona modello',
        'scholarship.file_copy_failed':
            'Impossibile copiare il file.',
        'scholarship.duplicate_status.can_receive': 'Puo ricevere',
        'scholarship.duplicate_status.cannot_receive_except_kyk':
            'Non puo ricevere (tranne KYK)',
        'scholarship.target.population': 'In base alla popolazione',
        'scholarship.target.residence': 'In base alla residenza',
        'scholarship.target.all_turkiye': 'Tutta la Turchia',
        'scholarship.info.personal': 'Personale',
        'scholarship.info.school': 'Scuola',
        'scholarship.info.family': 'Famiglia',
        'scholarship.info.dormitory': 'Dormitorio',
        'scholarship.education.all': 'Tutti',
        'scholarship.education.middle_school': 'Scuola media',
        'scholarship.education.high_school': 'Liceo',
        'scholarship.education.undergraduate': 'Laurea',
        'scholarship.degree.associate': 'Diploma associato',
        'scholarship.degree.bachelor': 'Laurea',
        'scholarship.degree.master': 'Master',
        'scholarship.degree.phd': 'Dottorato',
        'single_post.title': 'Post',
        'edit_post.updating':
            'Attendi. Il tuo post sta venendo aggiornato',
        'edit_profile.title': 'Informazioni profilo',
        'profile.copy_profile_link': 'Copia link profilo',
        'profile.profile_share_title': 'Profilo TurqApp',
        'profile.private_account_title': 'Account privato',
        'profile.private_story_follow_required':
            'Devi seguire prima questo account per vedere le storie.',
        'profile.unfollow_title': 'Smetti di seguire',
        'profile.unfollow_body':
            'Vuoi davvero smettere di seguire @{nickname}?',
        'profile.unfollow_confirm': 'Smetti di seguire',
        'profile.following_status': 'Lo segui',
        'profile.follow_button': 'Segui',
        'profile.contact_options': 'Opzioni di contatto',
        'profile.unblock': 'Sblocca',
        'profile.remove_highlight_title': 'Rimuovi highlight',
        'profile.remove_highlight_body':
            'Vuoi davvero rimuovere questo highlight?',
        'profile.remove_highlight_confirm': 'Rimuovi',
        'social_profile.private_follow_to_see_posts':
            'Segui questo account per vedere i post.',
        'social_profile.blocked_user': 'Hai bloccato questo utente',
        'edit_profile.personal_info': 'Informazioni personali',
        'edit_profile.other_info': 'Altre informazioni',
        'edit_profile.first_name_hint': 'Nome',
        'edit_profile.last_name_hint': 'Cognome',
        'edit_profile.privacy': 'Privacy account',
        'edit_profile.links': 'Collegamenti',
        'edit_profile.contact_info': 'Informazioni di contatto',
        'edit_profile.address_info': 'Informazioni indirizzo',
        'edit_profile.career_profile': 'Profilo carriera',
        'edit_profile.update_success':
            'Le informazioni del tuo profilo sono state aggiornate!',
        'edit_profile.update_failed': 'Errore di aggiornamento: {error}',
        'edit_profile.remove_photo_title': 'Rimuovi foto profilo',
        'edit_profile.remove_photo_message':
            'La tua foto profilo verra rimossa e verra usato l avatar predefinito. Confermi?',
        'edit_profile.photo_removed': 'La tua foto profilo e stata rimossa.',
        'edit_profile.photo_remove_failed':
            'Si e verificato un errore durante la rimozione della foto profilo.',
        'edit_profile.crop_use': 'Ritaglia e usa',
        'edit_profile.delete_account': 'Elimina account',
        'edit_profile.upload_failed_title': 'Caricamento non riuscito!',
        'edit_profile.upload_failed_body':
            'Questo contenuto non puo essere elaborato in questo momento. Prova con un contenuto diverso.',
        'delete_account.title': 'Elimina account',
        'delete_account.confirm_title': 'Conferma eliminazione account',
        'delete_account.confirm_body':
            'Prima di eliminare il tuo account, inviamo un codice di verifica al tuo indirizzo e-mail registrato per motivi di sicurezza.',
        'delete_account.code_hint': 'Codice di verifica a 6 cifre',
        'delete_account.resend': 'Invia di nuovo',
        'delete_account.send_code': 'Invia codice',
        'delete_account.validity_notice':
            'Il codice e valido per 1 ora. La tua richiesta di eliminazione verra elaborata in modo definitivo dopo {days} giorni.',
        'delete_account.processing': 'Elaborazione...',
        'delete_account.delete_my_account': 'Elimina il mio account',
        'delete_account.no_email_title': 'Avviso',
        'delete_account.no_email_body':
            'Nessuna e-mail e associata a questo account. Puoi avviare direttamente la richiesta di eliminazione.',
        'delete_account.session_missing':
            'Sessione non trovata. Accedi di nuovo.',
        'delete_account.code_sent_title': 'Codice inviato',
        'delete_account.code_sent_body':
            'Il codice di conferma per l eliminazione e stato inviato al tuo indirizzo e-mail.',
        'delete_account.send_failed': 'Impossibile inviare il codice.',
        'delete_account.invalid_code_title': 'Codice non valido',
        'delete_account.invalid_code_body':
            'Inserisci il codice a 6 cifre.',
        'delete_account.verify_failed':
            'Impossibile verificare il codice.',
        'editor_nickname.title': 'Nome utente',
        'editor_nickname.hint': 'Crea nome utente',
        'editor_nickname.verified_locked':
            'Gli utenti verificati non possono cambiare il nome utente',
        'editor_nickname.mimic_warning':
            'I nomi utente che imitano persone reali possono essere modificati da TurqApp per proteggere la community.',
        'editor_nickname.tr_char_info':
            'I caratteri turchi vengono convertiti automaticamente. (ç→c, ğ→g, ı→i, ö→o, ş→s, ü→u)',
        'editor_nickname.min_length':
            'Deve contenere almeno 8 caratteri',
        'editor_nickname.current_name': 'Il tuo nome utente attuale',
        'editor_nickname.edit_prompt':
            'Modifica per effettuare un cambiamento',
        'editor_nickname.checking': 'Verifica…',
        'editor_nickname.taken': 'Questo nome utente e gia in uso',
        'editor_nickname.available': 'Disponibile',
        'editor_nickname.unavailable':
            'Impossibile verificare',
        'editor_nickname.cooldown_limit':
            'Puo essere cambiato solo 3 volte nella prima ora',
        'editor_nickname.change_after_days':
            'Il nome utente potra essere cambiato di nuovo tra {days}g {hours}h',
        'editor_nickname.change_after_hours':
            'Il nome utente potra essere cambiato di nuovo tra {hours}h',
        'editor_nickname.error_min_length':
            'Il nome utente deve contenere almeno 8 caratteri.',
        'editor_nickname.error_taken':
            'Questo nome utente e gia in uso.',
        'editor_nickname.error_grace_limit':
            'Puoi cambiarlo solo 3 volte nella prima ora.',
        'editor_nickname.error_cooldown':
            'Il nome utente non puo essere cambiato di nuovo prima di 15 giorni.',
        'editor_nickname.error_update_failed':
            'Impossibile aggiornare il nome utente.',
        'cv.title': 'Profilo carriera',
        'cv.personal_info': 'Informazioni personali',
        'cv.education_info': 'Informazioni sull istruzione',
        'cv.other_info': 'Altre informazioni',
        'cv.profile_title': 'Profilo carriera',
        'cv.profile_body':
            'Rendi piu forte il tuo profilo carriera con una foto profilo e informazioni di base.',
        'cv.first_name_hint': 'Nome',
        'cv.last_name_hint': 'Cognome',
        'cv.email_hint': 'Indirizzo e-mail',
        'cv.phone_hint': 'Numero di telefono',
        'cv.about_hint': 'Scrivi una breve descrizione di te',
        'cv.add_school': 'Aggiungi scuola',
        'cv.add_school_title': 'Aggiungi nuova scuola',
        'cv.edit_school_title': 'Modifica scuola',
        'cv.school_name': 'Nome della scuola',
        'cv.department': 'Dipartimento',
        'cv.graduation_year': 'Anno di diploma',
        'cv.currently_studying': 'Sto ancora studiando',
        'cv.missing_school_name':
            'Il nome della scuola non puo essere vuoto',
        'cv.invalid_year': 'Inserisci un anno valido',
        'cv.skills': 'Competenze',
        'cv.add_skill_title': 'Aggiungi nuova competenza',
        'cv.skill_name_empty':
            'Il nome della competenza non puo essere vuoto',
        'cv.skill_exists': 'Questa competenza e gia stata aggiunta',
        'cv.skill_hint': 'Competenza (es. Flutter, Photoshop)',
        'cv.add_language': 'Aggiungi lingua',
        'cv.add_new_language': 'Aggiungi nuova lingua',
        'cv.add_language_title': 'Aggiungi nuova lingua',
        'cv.edit_language_title': 'Modifica lingua',
        'cv.level': 'Livello',
        'cv.add_experience': 'Aggiungi esperienza',
        'cv.add_new_experience': 'Aggiungi nuova esperienza',
        'cv.add_experience_title': 'Aggiungi nuova esperienza',
        'cv.edit_experience_title': 'Modifica esperienza',
        'cv.company_name': 'Nome azienda',
        'cv.position': 'Posizione',
        'cv.description_optional': 'Descrizione del ruolo (opzionale)',
        'cv.start_year': 'Inizio',
        'cv.end_year': 'Fine',
        'cv.currently_working': 'Lavoro ancora qui',
        'cv.ongoing': 'In corso',
        'cv.missing_company_position':
            'Nome azienda e posizione sono obbligatori',
        'cv.invalid_start_year':
            'Inserisci un anno di inizio valido',
        'cv.invalid_end_year':
            'Inserisci un anno di fine valido',
        'cv.add_reference': 'Aggiungi referenza',
        'cv.add_new_reference': 'Aggiungi nuova referenza',
        'cv.add_reference_title': 'Aggiungi nuova referenza',
        'cv.edit_reference_title': 'Modifica referenza',
        'cv.name_surname': 'Nome e cognome',
        'cv.phone_example': 'Telefono (es. 05xx..)',
        'cv.missing_name_surname':
            'Nome e cognome non possono essere vuoti',
        'cv.save': 'Salva',
        'cv.created_title': 'CV creato!',
        'cv.created_body':
            'Ora puoi candidarti molto piu velocemente',
        'cv.save_failed':
            'Impossibile salvare il CV. Riprova.',
        'cv.not_signed_in': 'Non hai effettuato l accesso.',
        'cv.missing_field': 'Campo mancante',
        'cv.invalid_format': 'Formato non valido',
        'cv.missing_first_name':
            'Non puoi salvare senza inserire il nome',
        'cv.missing_last_name':
            'Non puoi salvare senza inserire il cognome',
        'cv.missing_email':
            'Non puoi salvare senza inserire un indirizzo e-mail',
        'cv.invalid_email':
            'Inserisci un indirizzo e-mail valido',
        'cv.missing_phone':
            'Non puoi salvare senza inserire un numero di telefono',
        'cv.invalid_phone':
            'Inserisci un numero di telefono valido',
        'cv.missing_about':
            'Devi fornire una breve descrizione di te',
        'cv.missing_school':
            'Non puoi salvare senza aggiungere almeno una scuola',
        'qr.title': 'QR personale',
        'qr.profile_subject': 'Profilo TurqApp',
        'qr.link_copied_title': 'Link copiato',
        'qr.link_copied_body': 'Link del profilo copiato negli appunti',
        'qr.permission_required': 'Permesso richiesto',
        'qr.gallery_permission_body':
            'Devi consentire l accesso alla galleria per salvare.',
        'qr.data_failed': 'Impossibile creare i dati del QR.',
        'qr.saved': 'QR salvato nella galleria.',
        'qr.save_failed': 'Impossibile salvare il QR.',
        'qr.download_failed':
            'Si e verificato un errore durante il download.',
        'signup.create_account_title': 'Crea il tuo account',
        'signup.policy_short':
            'Accetto i contratti e le politiche.',
        'signup.email': 'E-mail',
        'signup.username': 'Nome utente',
        'signup.password': 'Password',
        'signup.personal_info': 'Informazioni personali',
        'signup.first_name': 'Nome',
        'signup.last_name_optional': 'Cognome (opzionale)',
        'signup.next': 'Avanti',
        'signup.verification_title': 'Verifica',
        'notifications.title': 'Notifiche',
        'notifications.categories': 'Categorie',
        'notifications.device_notice':
            'Per vedere le notifiche nella schermata di blocco, tieni attivo il permesso nelle impostazioni del dispositivo.',
        'notifications.pause_all': 'Sospendi tutto',
        'notifications.sleep_mode': 'Modalita sonno',
        'notifications.messages': 'Messaggi',
        'notifications.posts_comments': 'Post e commenti',
        'notifications.comments': 'Commenti',
        'comments.delete_message':
            'Vuoi davvero eliminare questo commento?',
        'comments.delete_failed': 'Impossibile eliminare il commento.',
        'comments.title': 'Commenti',
        'comments.empty': 'Sii il primo a commentare...',
        'comments.reply': 'Rispondi',
        'comments.replying_to': 'Risposta a @nickname',
        'comments.sending': 'Invio in corso',
        'comments.community_violation_title':
            'Contrario alle regole della community',
        'comments.community_violation_body':
            'Il linguaggio usato non rispetta le nostre regole della community. Usa un linguaggio rispettoso.',
        'post_sharers.empty': 'Nessuno ha ancora condiviso questo post',
        'notifications.follows': 'Seguiti',
        'notifications.direct_messages': 'Messaggi diretti',
        'notifications.opportunities': 'Annunci e candidature',
        'support.title': 'Contattaci',
        'support.card_title': 'Messaggio di supporto',
        'support.direct_admin': 'Il tuo messaggio viene inviato direttamente all admin.',
        'support.topic': 'Argomento',
        'support.topic.account': 'Account',
        'support.topic.payment': 'Pagamento',
        'support.topic.technical': 'Problema tecnico',
        'support.topic.content': 'Segnalazione contenuto',
        'support.topic.suggestion': 'Suggerimento',
        'support.message_hint': 'Scrivi il tuo problema o la tua richiesta...',
        'support.send': 'Invia messaggio',
        'support.empty_title': 'Informazione mancante',
        'support.empty_body': 'Scrivi un messaggio.',
        'support.sent_title': 'Inviato',
        'support.sent_body': 'Il tuo messaggio e stato inviato all admin.',
        'support.error_title': 'Errore',
        'liked_posts.no_posts': 'Nessun post',
        'saved_posts.posts_tab': 'Post',
        'saved_posts.series_tab': 'Serie',
        'saved_posts.no_saved_posts': 'Nessun post salvato',
        'saved_posts.no_saved_series': 'Nessuna serie salvata',
        'editor_email.title': 'Verifica e-mail',
        'editor_email.email_hint': 'Il tuo indirizzo e-mail del profilo',
        'editor_email.send_code': 'Invia codice di verifica',
        'editor_email.resend_in': 'Nuovo invio tra {seconds}s',
        'editor_email.note':
            'Questa verifica serve per sicurezza. Puoi continuare a usare l app anche senza confermarla.',
        'editor_email.code_hint': 'Codice di verifica a 6 cifre',
        'editor_email.verify_confirm':
            'Verifica il codice e conferma',
        'editor_email.wait': 'Attendi {seconds} secondi.',
        'editor_email.session_missing':
            'Sessione non trovata. Accedi di nuovo.',
        'editor_email.email_missing':
            'Nessun indirizzo e-mail trovato nel tuo account.',
        'editor_email.code_sent':
            'Il codice di verifica e stato inviato al tuo indirizzo e-mail.',
        'editor_email.code_send_failed':
            'Impossibile inviare il codice di verifica.',
        'editor_email.enter_code':
            'Inserisci il codice di verifica a 6 cifre.',
        'editor_email.verified':
            'Il tuo indirizzo e-mail e stato verificato.',
        'editor_email.verify_failed':
            'Impossibile verificare l indirizzo e-mail.',
        'editor_phone.title': 'Numero di telefono',
        'editor_phone.phone_hint': 'Numero di telefono',
        'editor_phone.send_approval': 'Invia e-mail di conferma',
        'editor_phone.resend_in': 'Nuovo invio tra {seconds}s',
        'editor_phone.code_hint': 'Codice di verifica a 6 cifre',
        'editor_phone.verify_update':
            'Verifica il codice e aggiorna',
        'editor_phone.wait': 'Attendi {seconds} secondi.',
        'editor_phone.invalid_phone':
            'Inserisci un numero di 10 cifre che inizi con 5.',
        'editor_phone.session_missing':
            'Sessione non trovata. Accedi di nuovo.',
        'editor_phone.email_missing':
            'Nessuna e-mail disponibile per verificare questa modifica.',
        'editor_phone.code_sent':
            'Il codice di verifica e stato inviato al tuo indirizzo e-mail.',
        'editor_phone.code_send_failed':
            'Impossibile inviare il codice di verifica.',
        'editor_phone.enter_code':
            'Inserisci il codice di verifica a 6 cifre.',
        'editor_phone.update_failed':
            'Impossibile aggiornare il numero di telefono.',
        'editor_phone.updated':
            'Il tuo numero di telefono e stato aggiornato.',
        'address.title': 'Indirizzo',
        'address.hint': 'Indirizzo ufficio o attivita',
        'biography.title': 'Biografia',
        'biography.hint': 'Parla un po di te..',
        'profile_contact.title': 'Contatto',
        'profile_contact.call': 'Chiamata',
        'profile_contact.email': 'E-mail',
        'job_selector.title': 'Professione e categoria',
        'job_selector.subtitle':
            'La tua categoria rende il tuo profilo piu facile da trovare.',
        'job_selector.search_hint': 'Cerca',
        'legacy_language.title': 'Lingua dell app',
        'statistics.title': 'Statistiche',
        'statistics.you': 'Tu',
        'statistics.notice':
            'Le tue statistiche vengono aggiornate regolarmente in base alle tue attivita degli ultimi 30 giorni.',
        'statistics.post_views_pct': 'Percentuale visualizzazioni post',
        'statistics.follower_growth_pct':
            'Percentuale crescita follower',
        'statistics.profile_visits_30d': 'Visite profilo (30 giorni)',
        'statistics.post_views': 'Visualizzazioni post',
        'statistics.post_count': 'Numero di post',
        'statistics.story_count': 'Numero di storie',
        'statistics.follower_growth': 'Crescita follower',
        'interests.personalize_feed': 'Personalizza il tuo feed',
        'interests.selection_range':
            'Seleziona almeno {min} e al massimo {max} interessi.',
        'interests.selected_count': '{selected}/{max} selezionati',
        'interests.ready': 'Pronto',
        'interests.search_hint': 'Cerca interessi',
        'interests.limit_title': 'Limite di selezione',
        'interests.limit_body':
            'Puoi selezionare al massimo {max} interessi.',
        'interests.min_title': 'Selezione incompleta',
        'interests.min_body':
            'Devi selezionare almeno {min} interessi.',
        'view_changer.title': 'Vista',
        'view_changer.classic': 'Vista classica',
        'view_changer.modern': 'Vista moderna',
        'social_links.title': 'Collegamenti ({count})',
        'social_links.add': 'Aggiungi',
        'social_links.add_title': 'Aggiungi collegamento',
        'social_links.label_title': 'Titolo',
        'social_links.username_hint': 'Nome utente',
        'social_links.remove_title': 'Rimuovi collegamento',
        'social_links.remove_message':
            'Vuoi davvero rimuovere questo collegamento?',
        'social_links.save_permission_error':
            'Errore di autorizzazione: non puoi salvare questo collegamento.',
        'social_links.save_failed': 'Si e verificato un problema.',
        'post_creator.title_new': 'Prepara post',
        'post_creator.title_edit': 'Modifica post',
        'post_creator.publish': 'Pubblica',
        'post_creator.uploading': 'Caricamento...',
        'post_creator.saving': 'Salvataggio...',
        'post_creator.placeholder': 'Che cosa succede?',
        'post_creator.processing_wait':
            'Attendi. Il video e in elaborazione...',
        'post_creator.video_processing': 'Elaborazione video',
        'post_creator.look.original': 'Originale',
        'post_creator.look.clear': 'Pulito',
        'post_creator.look.cinema': 'Cinematico',
        'post_creator.look.vibe': 'Vivace',
        'post_creator.comments.everyone': 'Tutti',
        'post_creator.comments.verified': 'Account verificati',
        'post_creator.comments.following': 'Account che segui',
        'post_creator.comments.closed': 'Commenti disattivati',
        'post_creator.comments.title': 'Chi puo rispondere?',
        'post_creator.comments.subtitle':
            'Scegli chi puo rispondere a questo post.',
        'post_creator.reshare.everyone': 'Tutti',
        'post_creator.reshare.verified': 'Account verificati',
        'post_creator.reshare.following': 'Account che segui',
        'post_creator.reshare.closed': 'Ricondivisione disattivata',
        'post_creator.reshare_privacy_title':
            'Privacy della ricondivisione',
        'post_creator.reshare_everyone_desc':
            'Tutti possono ricondividere.',
        'post_creator.reshare_followers_desc':
            'Solo i miei follower possono ricondividere.',
        'post_creator.reshare_closed_desc':
            'La ricondivisione e disabilitata.',
        'post_creator.warning_title': 'Avviso',
        'post_creator.success_title': 'Successo!',
        'tests.create_title': 'Crea test',
        'tests.edit_title': 'Modifica test',
        'tests.create_data_missing':
            'Dati non trovati.\nI collegamenti dell app o le domande del test non sono stati caricati.',
        'tests.create_upload_failed':
            'Questo contenuto non puo essere elaborato al momento. Prova con un altro contenuto.',
        'tests.select_branch': 'Seleziona branca',
        'tests.select_language': 'Seleziona lingua',
        'tests.cover_select': 'Seleziona immagine di copertina',
        'tests.name_hint': 'Nome esame',
        'tests.post_exam_status': 'Dopo l esame @status',
        'tests.types': 'Tipi di esame',
        'tests.date_duration': 'Data e durata dell esame',
        'tests.duration_select': 'Seleziona durata esame',
        'tests.create_description_hint':
            '9a classe Espressioni esponenziali e radicali',
        'tests.share_status': 'Per tutti: @status',
        'tests.status.open': 'Aperto',
        'tests.status.closed': 'Chiuso',
        'tests.share_public_info':
            'In conformita con l etica digitale, i test protetti da copyright non devono essere condivisi.\nUsa e pubblica test che tutti possono risolvere e che non contengono contenuti protetti da copyright.',
        'tests.share_private_info':
            'Questo test puo essere condiviso solo con i tuoi studenti. Solo gli studenti che inseriscono l ID fornito da te possono accedere e risolvere il test pubblicato.',
        'tests.test_id': 'ID test: @id',
        'tests.test_type': 'Tipo di test',
        'tests.subjects': 'Materie',
        'tests.exam_prep': 'Preparazione esami',
        'tests.foreign_language': 'Lingua straniera',
        'tests.delete_test': 'Elimina test',
        'tests.prepare_test': 'Prepara test',
        'tests.join_title': 'Partecipa al test',
        'tests.search_title': 'Cerca test',
        'tests.search_id_hint': 'Cerca ID test',
        'tests.join_help':
            'Puoi iniziare il test inserendo l ID del test condiviso dal tuo insegnante.',
        'tests.join_not_found':
            'Test non trovato.\nNessun test corrisponde all ID inserito.',
        'tests.join_button': 'Partecipa al test',
        'tests.no_shared': 'Non ci sono test condivisi.',
        'tests.my_tests_title': 'I miei test',
        'tests.my_tests_empty':
            'Nessun risultato trovato.\nNon hai ancora creato test.',
        'tests.completed_title': 'Hai completato il test!',
        'tests.completed_body':
            'Puoi controllare il tuo punteggio e il rapporto corrette o errate in I miei risultati.',
        'tests.completed_short': 'Hai completato il test!',
        'tests.action_select': 'Seleziona azione',
        'tests.action_select_body':
            'Se vuoi eseguire un azione su questo test, scegli una delle opzioni seguenti.',
        'tests.copy_test_id': 'Copia ID test',
        'tests.solve_title': 'Risolvi test',
        'tests.delete_confirm':
            'Sei sicuro di voler eliminare questo test?',
        'tests.id_copied': 'ID test copiato negli appunti',
        'tests.share_test_id_text':
            'Test @type\n\nScarica subito TurqApp per partecipare al test. L ID del test richiesto e @id\n\nScarica ora l app:\n\nAppStore: @appStore\nPlay Store: @playStore\n\nPer partecipare al test, inserisci l ID test dalla schermata Test nell area studente e inizia subito a risolverlo.',
        'tests.type.middle_school': 'Scuola media',
        'tests.type.high_school': 'Scuola superiore',
        'tests.type.prep': 'Preparazione',
        'tests.type.language': 'Lingua',
        'tests.type.branch': 'Branca',
        'tests.lesson.turkish': 'Turco',
        'tests.lesson.literature': 'Letteratura',
        'tests.lesson.math': 'Matematica',
        'tests.lesson.geometry': 'Geometria',
        'tests.lesson.physics': 'Fisica',
        'tests.lesson.chemistry': 'Chimica',
        'tests.lesson.biology': 'Biologia',
        'tests.lesson.history': 'Storia',
        'tests.lesson.geography': 'Geografia',
        'tests.lesson.philosophy': 'Filosofia',
        'tests.lesson.psychology': 'Psicologia',
        'tests.lesson.sociology': 'Sociologia',
        'tests.lesson.logic': 'Logica',
        'tests.lesson.religion': 'Cultura religiosa',
        'tests.lesson.science': 'Scienze',
        'tests.lesson.revolution_history': 'Storia della rivoluzione',
        'tests.lesson.foreign_language': 'Lingua straniera',
        'tests.lesson.basic_math': 'Matematica di base',
        'tests.lesson.social_sciences': 'Scienze sociali',
        'tests.lesson.literature_social_1':
            'Letteratura - Scienze sociali 1',
        'tests.lesson.social_sciences_2': 'Scienze sociali 2',
        'tests.lesson.general_ability': 'Abilita generale',
        'tests.lesson.general_culture': 'Cultura generale',
        'tests.language.english': 'Inglese',
        'tests.language.german': 'Tedesco',
        'tests.language.arabic': 'Arabo',
        'tests.language.french': 'Francese',
        'tests.language.russian': 'Russo',
        'tests.lesson_based_title': 'Test @type',
        'tests.none_in_category': 'Nessun test disponibile',
        'tests.add_question': 'Aggiungi domanda',
        'tests.no_questions_added':
            'Nessuna domanda trovata.\nNon sono ancora state aggiunte domande per questo test.',
        'tests.level_easy': 'Facile',
        'tests.title': 'Test',
        'tests.report_title': 'Informazioni sul test',
        'tests.report_wrong_answers':
            'Il test contiene risposte errate',
        'tests.report_wrong_section':
            'Il test e nella sezione sbagliata',
        'tests.question_content_failed':
            'Il contenuto della domanda non puo essere caricato.\nRiprova.',
        'tests.capture_and_upload': 'Scatta e carica',
        'tests.capture_and_upload_body':
            'Scatta una foto della domanda, scegli la risposta corretta e preparala facilmente!',
        'tests.select_from_gallery': 'Seleziona dalla galleria',
        'tests.upload_from_camera': 'Carica dalla fotocamera',
        'tests.nsfw_check_failed':
            'Il controllo di sicurezza dell immagine non puo essere completato.',
        'tests.nsfw_detected': 'Immagine non appropriata rilevata.',
        'practice.title': 'Esame online',
        'practice.search_title': 'Cerca esame di prova',
        'practice.empty_title': 'Nessun esame di prova per ora',
        'practice.empty_body':
            'Al momento non ci sono esami di prova nel sistema. I nuovi esami appariranno qui quando verranno aggiunti.',
        'practice.search_empty_title':
            'Nessun esame corrisponde alla tua ricerca',
        'practice.search_empty_body_empty':
            'Al momento non ci sono esami di prova nel sistema. I nuovi esami appariranno qui quando verranno aggiunti.',
        'practice.search_empty_body_query':
            'Prova una parola chiave diversa.',
        'practice.results_title': 'I miei risultati',
        'practice.saved_empty': 'Non ci sono esami pratici salvati.',
        'practice.preview_no_questions':
            'Nessuna domanda trovata per questo esame. Controlla il contenuto dell esame o aggiungi nuove domande.',
        'practice.preview_no_results':
            'Nessun risultato trovato per questo esame. Controlla le tue risposte o rifai l esame.',
        'practice.lesson_header': 'Materie',
        'practice.answers_load_failed':
            'Impossibile caricare le risposte.',
        'practice.lesson_results_load_failed':
            'Impossibile caricare i risultati delle materie.',
        'practice.results_empty_title':
            'Non hai ancora sostenuto un esame',
        'practice.results_empty_body':
            'Non hai ancora partecipato a nessun esame di prova. I tuoi risultati appariranno qui dopo la partecipazione.',
        'practice.published_empty':
            'Non hai ancora pubblicato un esame online.',
        'practice.user_session_missing':
            'Sessione utente non trovata.',
        'practice.school_info_failed':
            'Impossibile caricare le informazioni sulla scuola.',
        'practice.load_failed': 'Impossibile caricare i dati.',
        'practice.slider_management': 'Gestione slider',
        'practice.create_disabled_title':
            'Solo per badge giallo e superiori',
        'practice.create_disabled_body':
            'Per creare un esame online hai bisogno di un account verificato con badge giallo o superiore.',
        'practice.preview_title': 'Dettagli esame',
        'practice.report_exam': 'Segnala esame',
        'practice.user_load_failed':
            'Impossibile caricare le informazioni utente.',
        'practice.user_load_failed_body':
            'Impossibile caricare le informazioni utente. Riprova o controlla il proprietario dell esame.',
        'practice.invalidity_load_failed':
            'Impossibile caricare lo stato di invalidita.',
        'practice.cover_load_failed':
            'Impossibile caricare l immagine di copertina.',
        'practice.no_description':
            'Nessuna descrizione e stata aggiunta per questo esame.',
        'practice.exam_info': 'Informazioni esame',
        'practice.exam_type': 'Tipo di esame',
        'practice.exam_suffix': 'Esame @type',
        'practice.exam_datetime': 'Data e ora dell esame',
        'practice.exam_duration': 'Durata dell esame',
        'practice.duration_minutes': '@minutes min',
        'practice.application_count': 'Candidature',
        'practice.people_count': '@count persone',
        'practice.owner': 'Proprietario dell esame',
        'practice.apply_now': 'Candidati ora',
        'practice.applied_short': 'Candidato',
        'practice.closed_starts_in':
            'Candidature chiuse.\nInizia tra @minutes min.',
        'practice.started': 'Esame iniziato',
        'practice.start_now': 'Inizia ora',
        'practice.finished_short': 'Esame terminato',
        'practice.not_started': 'Esame non iniziato',
        'practice.application_closed_title':
            'Candidature chiuse!',
        'practice.application_closed_body':
            'Le candidature chiudono 15 minuti prima dell inizio dell esame.',
        'practice.not_applied_title': 'Non hai fatto domanda!',
        'practice.not_applied_body':
            'Non puoi partecipare a un esame senza candidatura. Possono partecipare solo i candidati.',
        'practice.not_allowed_title':
            'Non puoi entrare nell esame!',
        'practice.not_allowed_body':
            'Non hai accesso a questo esame. Sei gia stato invalidato in questo esame e non puoi rientrare prima della fine.',
        'practice.finished_title': 'Esame terminato!',
        'practice.finished_body':
            'Puoi candidarti ai prossimi esami. Questo esame e terminato.',
        'practice.result_unavailable':
            'Impossibile calcolare il risultato.',
        'practice.result_summary':
            'Corrette: @correct   •   Errate: @wrong   •   Vuote: @blank   •   Netto: @net',
        'practice.congrats_title': 'Congratulazioni!',
        'practice.removed_title':
            'Sei stato rimosso dall esame!',
        'practice.removed_body':
            'Ti abbiamo avvisato piu volte. Purtroppo, poiche non hai rispettato le regole, il tuo esame e stato invalidato.',
        'practice.applied_title':
            'La tua candidatura e stata ricevuta!',
        'practice.applied_body':
            'La tua candidatura e stata ricevuta con successo. Al momento non devi fare altro.',
        'practice.apply_completed_title':
            'La tua candidatura e completa!',
        'practice.apply_completed_body':
            'Ti invieremo dei promemoria prima dell esame. Buona fortuna!',
        'practice.apply_failed': 'Invio candidatura non riuscito.',
        'practice.application_check_failed':
            'Controllo candidatura non riuscito.',
        'practice.question_image_failed':
            'Impossibile caricare l immagine della domanda.',
        'practice.exam_started_title': 'L esame e iniziato!',
        'practice.exam_started_body':
            'Crediamo che la tua cura e il tuo impegno apriranno la strada al successo. Buona fortuna!',
        'practice.rules_title': 'Regole dell esame',
        'practice.rule_1':
            'Disattiva la connessione internet del telefono. Quando l esame sara terminato, potrai riattivarla per inviare le risposte.',
        'practice.rule_2':
            'Se esci dall esame, tutte le risposte saranno considerate non valide e il punteggio non verra salvato. Pensa bene prima di confermare.',
        'practice.rule_3':
            'Se metti l app in background, l esame verra considerato non valido. Cerca di non mandare l app in background.',
        'practice.start_exam': 'Inizia esame',
        'practice.finish_exam': 'Termina esame',
        'practice.background_warning':
            'In situazioni critiche come il passaggio dell app in background, il tuo esame verra considerato non valido. Fai attenzione e segui le regole.',
        'practice.questions_load_failed':
            'Impossibile caricare le domande.',
        'practice.answers_save_failed':
            'Impossibile salvare le risposte.',
        'past_questions.no_results': 'Nessun risultato.',
        'past_questions.title': 'Esami di prova',
        'past_questions.mock_fallback': 'Prova',
        'past_questions.search_empty':
            'Nessun esame di prova corrisponde alla tua ricerca.',
        'past_questions.results_suffix': 'Risultati @title',
        'past_questions.local_result_summary':
            'Sono state risolte @count domande. Il risultato e salvato localmente; in questa schermata viene mostrato solo il riepilogo netto.',
        'past_questions.mock_label': 'Prova @index',
        'past_questions.question_count': '@count Domande',
        'past_questions.net_label': 'Netto',
        'past_questions.tests_by_year': 'Test @type @year',
        'past_questions.languages_title': 'Lingue @type',
        'past_questions.tests_by_type': 'Test @type',
        'past_questions.select_exam': 'Seleziona esame',
        'past_questions.questions_title': 'Domande',
        'past_questions.continue_solving': 'Continua a risolvere le domande',
        'past_questions.oabt_short': 'ÖABT',
        'past_questions.exam_type.associate': 'Laurea breve',
        'past_questions.exam_type.undergraduate': 'Laurea',
        'past_questions.exam_type.middle_school': 'Scuola secondaria',
        'past_questions.branch.general_ability_culture':
            'Abilità generale e cultura generale',
        'past_questions.branch.group_a': 'Gruppo A',
        'past_questions.branch.education_sciences': "Scienze dell'educazione",
        'past_questions.branch.field_knowledge': 'Conoscenza di settore',
        'past_questions.sessions_by_year': 'Sessioni @year',
        'past_questions.teaching.title': 'Rami di insegnamento',
        'past_questions.teaching.suffix': 'insegnamento',
        'past_questions.teaching.primary_math_short': 'M. primaria',
        'past_questions.teaching.high_school_math_short': 'M. liceo',
        'past_questions.teaching.german': 'Insegnamento del tedesco',
        'past_questions.teaching.physical_education':
            'Insegnamento dell educazione fisica',
        'past_questions.teaching.biology': 'Insegnamento della biologia',
        'past_questions.teaching.geography': 'Insegnamento della geografia',
        'past_questions.teaching.religious_culture':
            'Insegnamento della cultura religiosa',
        'past_questions.teaching.literature':
            'Insegnamento della letteratura',
        'past_questions.teaching.science': 'Insegnamento delle scienze',
        'past_questions.teaching.physics': 'Insegnamento della fisica',
        'past_questions.teaching.chemistry': 'Insegnamento della chimica',
        'past_questions.teaching.high_school_math': 'Matematica liceale',
        'past_questions.teaching.preschool': 'Prescolare',
        'past_questions.teaching.guidance': 'Orientamento',
        'past_questions.teaching.social_studies':
            'Insegnamento degli studi sociali',
        'past_questions.teaching.classroom': 'Insegnamento di classe',
        'past_questions.teaching.history': 'Insegnamento della storia',
        'past_questions.teaching.turkish': 'Insegnamento del turco',
        'past_questions.teaching.primary_math': 'Matematica primaria',
        'past_questions.teaching.imam_hatip': 'Imam Hatip',
        'past_questions.teaching.english': 'Insegnamento dell inglese',
        'pasaj.closed': 'Pasaj e attualmente chiuso',
        'pasaj.common.my_applications': 'Le mie candidature',
        'pasaj.common.post_listing': 'Pubblica annuncio',
        'pasaj.common.all_turkiye': 'Tutta la Turchia',
        'pasaj.job_finder.tab.explore': 'Esplora',
        'pasaj.job_finder.tab.create': 'Crea annuncio',
        'pasaj.job_finder.tab.applications': 'Le mie candidature',
        'pasaj.job_finder.tab.career_profile': 'Profilo di carriera',
        'pasaj.tabs.market': 'Mercato mobile',
        'pasaj.tabs.practice_exams': 'Esami',
        'pasaj.tabs.tutoring': 'Lezioni private',
        'pasaj.tabs.job_finder': 'Lavoro',
        'pasaj.job_finder.title': 'Lavoro',
        'pasaj.job_finder.search_hint': 'Che tipo di lavoro stai cercando?',
        'pasaj.job_finder.nearby_listings':
            'Gli annunci piu vicini a te',
        'pasaj.job_finder.no_search_result':
            'Nessun annuncio corrisponde alla tua ricerca',
        'pasaj.job_finder.no_city_listing':
            'Non ci sono annunci nella tua citta',
        'pasaj.job_finder.sort_high_salary': 'Stipendio alto',
        'pasaj.job_finder.sort_low_salary': 'Stipendio basso',
        'pasaj.job_finder.sort_nearest': 'Piu vicino',
        'pasaj.job_finder.career_profile': 'Profilo professionale',
        'pasaj.job_finder.detail_title': 'Dettaglio annuncio',
        'pasaj.job_finder.no_description':
            'Per questo annuncio non e stata aggiunta alcuna descrizione.',
        'pasaj.job_finder.job_info': 'Descrizione del lavoro',
        'pasaj.job_finder.listing_info': 'Informazioni sull annuncio',
        'pasaj.job_finder.application_count': 'Numero di candidature',
        'pasaj.job_finder.work_type': 'Tipo di lavoro',
        'pasaj.job_finder.work_days': 'Giorni lavorativi',
        'pasaj.job_finder.work_hours': 'Orario di lavoro',
        'pasaj.job_finder.personnel_count': 'Numero di persone da assumere',
        'pasaj.job_finder.benefits': 'Vantaggi',
        'pasaj.job_finder.passive': 'Passivo',
        'pasaj.job_finder.salary_not_specified': 'Non specificato',
        'pasaj.job_finder.edit_listing': 'Modifica',
        'pasaj.job_finder.applications': 'Candidature',
        'pasaj.job_finder.apply': 'Candidati',
        'pasaj.job_finder.applied': 'Candidatura inviata',
        'pasaj.job_finder.cv_required': 'CV richiesto',
        'pasaj.job_finder.cv_required_body':
            'Devi completare il tuo CV prima di candidarti.',
        'pasaj.job_finder.create_cv': 'Crea CV',
        'pasaj.job_finder.application_sent':
            'La tua candidatura e stata inviata.',
        'pasaj.job_finder.application_failed':
            'Si e verificato un problema durante l invio della candidatura.',
        'pasaj.job_finder.finding_platform':
            'Piattaforma di ricerca lavoro',
        'pasaj.job_finder.looking_for_job': 'Cerco lavoro',
        'pasaj.job_finder.professional_profile':
            'Profilo professionale',
        'pasaj.job_finder.experience': 'Esperienza lavorativa',
        'pasaj.job_finder.education': 'Formazione',
        'pasaj.job_finder.languages': 'Lingue',
        'pasaj.job_finder.skills': 'Competenze',
        'pasaj.market.title': 'Mercato',
        'pasaj.market.contact_phone': 'Telefono',
        'pasaj.market.contact_message': 'Messaggio',
        'pasaj.market.all_listings': 'Tutti gli annunci',
        'pasaj.market.main_categories': 'Categorie principali',
        'pasaj.market.category_search_hint':
            'Cerca categoria principale, sottocategoria, marca',
        'pasaj.market.call_now': 'Chiama ora',
        'pasaj.market.inspect': 'Esamina',
        'pasaj.market.empty_filtered':
            'Nessun annuncio trovato con questo filtro.',
        'pasaj.market.add_listing': 'Aggiungi annuncio',
        'pasaj.market.my_listings': 'I miei annunci',
        'pasaj.market.saved_items': 'I miei preferiti',
        'pasaj.market.my_offers': 'Le mie offerte',
        'pasaj.market.detail_title': 'Dettaglio annuncio',
        'pasaj.market.report_listing': 'Segnala annuncio',
        'pasaj.market.no_description':
            'Per questo annuncio non e stata aggiunta alcuna descrizione.',
        'pasaj.market.listing_info': 'Informazioni annuncio',
        'pasaj.market.saved_count': 'Salvataggi',
        'pasaj.market.offer_count': 'Offerte',
        'pasaj.market.messages': 'Messaggi',
        'pasaj.market.offers': 'Offerte',
        'pasaj.market.related_listings': 'Annunci simili',
        'pasaj.market.no_related':
            'Nessun altro annuncio trovato in questa categoria.',
        'pasaj.market.custom_offer':
            'Definisci tu la tua offerta',
        'pasaj.market.reviews': 'Recensioni',
        'pasaj.market.rate': 'Valuta',
        'pasaj.job_finder.no_applications':
            'Non ti sei ancora candidato a nessun annuncio',
        'pasaj.job_finder.default_job_title': 'Annuncio di lavoro',
        'pasaj.job_finder.default_company': 'Azienda',
        'pasaj.job_finder.cancel_apply_title':
            'Annulla candidatura',
        'pasaj.job_finder.cancel_apply_body':
            'Vuoi davvero annullare questa candidatura?',
        'pasaj.job_finder.saved_jobs': 'Salvati',
        'pasaj.job_finder.no_saved_jobs':
            'Nessun annuncio salvato.',
        'pasaj.job_finder.my_ads': 'I miei annunci',
        'pasaj.job_finder.published_tab': 'Pubblicati',
        'pasaj.job_finder.expired_tab': 'Scaduti',
        'pasaj.job_finder.no_my_ads':
            'Nessun annuncio trovato',
        'pasaj.job_finder.finding_how':
            'Come funziona la piattaforma per trovare lavoro?',
        'pasaj.job_finder.finding_body':
            'Il tuo CV viene condiviso con i datori di lavoro con il tuo consenso. Prima di pubblicare un annuncio, i datori di lavoro possono esaminare tramite il nostro sistema i candidati adatti alle loro posizioni aperte. In questo modo i datori di lavoro raggiungono piu rapidamente i candidati giusti e chi cerca lavoro accede piu velocemente alle opportunita. Il nostro obiettivo e rendere il processo di assunzione piu rapido ed efficace per entrambe le parti.',
        'pasaj.job_finder.edit_cv': 'Modifica CV',
        'pasaj.job_finder.no_cv_title':
            'Non hai ancora creato un CV',
        'pasaj.job_finder.no_cv_body':
            'Crea un CV per velocizzare le tue candidature',
        'pasaj.job_finder.applicants': 'Candidati',
        'pasaj.job_finder.no_applicants':
            'Nessuna candidatura per ora',
        'pasaj.job_finder.unknown_user': 'Utente sconosciuto',
        'pasaj.job_finder.view_cv': 'Visualizza CV',
        'pasaj.job_finder.review': 'Esamina',
        'pasaj.job_finder.accept': 'Accetta',
        'pasaj.job_finder.reject': 'Rifiuta',
        'pasaj.job_finder.cv_not_found_title': 'CV non trovato',
        'pasaj.job_finder.cv_not_found_body':
            'Per questo utente non e stato trovato alcun CV salvato.',
        'pasaj.job_finder.status.pending': 'In attesa',
        'pasaj.job_finder.status.reviewing': 'In revisione',
        'pasaj.job_finder.status.accepted': 'Accettata',
        'pasaj.job_finder.status.rejected': 'Rifiutata',
        'pasaj.job_finder.status_updated':
            'Lo stato della candidatura e stato aggiornato.',
        'pasaj.job_finder.status_update_failed':
            'Lo stato della candidatura non e stato aggiornato.',
        'pasaj.job_finder.relogin_required':
            'Accedi di nuovo per continuare.',
        'pasaj.job_finder.save_failed':
            'Salvataggio non completato.',
        'pasaj.job_finder.share_auth_required':
            'Solo gli admin e i proprietari dell annuncio possono condividere.',
        'pasaj.job_finder.review_relogin_required':
            'Accedi di nuovo per lasciare una recensione.',
        'pasaj.job_finder.review_own_forbidden':
            'Non puoi recensire il tuo annuncio.',
        'pasaj.job_finder.review_saved':
            'La tua recensione e stata salvata.',
        'pasaj.job_finder.review_save_failed':
            'La recensione non e stata salvata.',
        'pasaj.job_finder.review_deleted':
            'La tua recensione e stata rimossa.',
        'pasaj.job_finder.review_delete_failed':
            'La recensione non e stata rimossa.',
        'pasaj.job_finder.open_in_maps': 'Apri in Mappe',
        'pasaj.job_finder.open_google_maps':
            'Apri in Google Maps',
        'pasaj.job_finder.open_apple_maps':
            'Apri in Apple Mappe',
        'pasaj.job_finder.open_yandex_maps':
            'Apri in Yandex Maps',
        'pasaj.job_finder.map_load_failed':
            'Impossibile caricare la mappa',
        'pasaj.job_finder.open_maps_help':
            'Tocca per aprire la posizione in Mappe.',
        'pasaj.job_finder.listing_not_found':
            'Annuncio non trovato',
        'pasaj.job_finder.reactivated':
            'L annuncio e stato ripubblicato.',
        'pasaj.job_finder.sort_title': 'Ordina',
        'pasaj.job_finder.sort_newest': 'Piu recenti',
        'pasaj.job_finder.sort_nearest_me': 'Vicino a me',
        'pasaj.job_finder.sort_most_viewed': 'Piu visualizzati',
        'pasaj.job_finder.clear_filters': 'Cancella filtri',
        'pasaj.job_finder.select_city': 'Seleziona citta',
        'pasaj.market.saved_success': 'Annuncio salvato.',
        'pasaj.market.unsaved':
            'Annuncio rimosso dai salvati.',
        'pasaj.market.save_failed':
            'Salvataggio non completato.',
        'pasaj.market.report_received_title':
            'La tua segnalazione e stata ricevuta!',
        'pasaj.market.report_received_body':
            'L annuncio e stato inviato in revisione. Grazie.',
        'pasaj.market.report_failed':
            'Impossibile inviare la segnalazione dell annuncio.',
        'pasaj.market.invalid_offer':
            'Seleziona un offerta valida.',
        'pasaj.market.offer_sent': 'Offerta inviata.',
        'pasaj.market.offer_own_forbidden':
            'Non puoi fare un offerta sul tuo annuncio.',
        'pasaj.market.offer_daily_limit':
            'Puoi inviare al massimo 20 offerte al giorno.',
        'pasaj.market.offer_failed':
            'Impossibile inviare l offerta.',
        'pasaj.market.review_edit': 'Modifica',
        'pasaj.market.no_reviews':
            'Non ci sono ancora recensioni.',
        'pasaj.market.sign_in_to_review':
            'Devi accedere per lasciare una recensione.',
        'pasaj.market.review_comment_hint':
            'Scrivi il tuo commento',
        'pasaj.market.select_rating':
            'Seleziona una valutazione.',
        'pasaj.market.review_saved':
            'La tua recensione e stata salvata.',
        'pasaj.market.review_updated':
            'La tua recensione e stata aggiornata.',
        'pasaj.market.review_own_forbidden':
            'Non puoi recensire il tuo annuncio.',
        'pasaj.market.review_failed':
            'La recensione non e stata inviata.',
        'pasaj.market.review_deleted':
            'La tua recensione e stata rimossa.',
        'pasaj.market.review_delete_failed':
            'La recensione non e stata rimossa.',
        'pasaj.market.location_missing': 'Posizione non specificata',
        'pasaj.market.status.sold': 'Venduto',
        'pasaj.market.status.draft': 'Bozza',
        'pasaj.market.status.archived': 'Archiviato',
        'pasaj.market.status.reserved': 'Riservato',
        'pasaj.market.status.active': 'Attivo',
      });

    base['ru_RU'] = Map<String, String>.from(base['en_US']!)
      ..addAll({
        'settings.title': 'Настройки',
        'settings.account': 'Аккаунт',
        'settings.content': 'Контент',
        'settings.app': 'Приложение',
        'settings.security_support': 'Безопасность и поддержка',
        'settings.my_tasks': 'Мои задачи',
        'settings.system_diagnostics': 'Система и диагностика',
        'settings.session': 'Сессия',
        'settings.language': 'Язык',
        'settings.edit_profile': 'Редактировать профиль',
        'settings.saved_posts': 'Сохраненное',
        'settings.archive': 'Архив',
        'settings.liked_posts': 'Понравившееся',
        'settings.notifications': 'Уведомления',
        'settings.permissions': 'Разрешения',
        'settings.pasaj': 'Pasaj',
        'education.previous_questions': 'Пробные тесты',
        'tests.results_title': 'Результаты',
        'tests.results_empty':
            'Результаты не найдены.\nДля этого теста нет данных об ответах или вопросах.',
        'tests.correct': 'Верно',
        'tests.wrong': 'Неверно',
        'tests.blank': 'Пусто',
        'tests.net': 'Нетто',
        'tests.score': 'Баллы',
        'tests.question_number': 'Вопрос @index',
        'tests.solve_no_questions':
            'Вопрос не найден.\nНе удалось загрузить вопросы для этого теста.',
        'tests.finish_test': 'Завершить тест',
        'tests.my_results_empty':
            'Результаты не найдены.\nВы еще ни разу не проходили тест.',
        'tests.saved_empty': 'Сохраненных тестов нет.',
        'tests.result_answer_missing':
            'Результаты не найдены.\nДля этого теста нет данных об ответах.',
        'tests.type_test': 'Тест @type',
        'tests.description_test': 'Тест @description',
        'tests.solve_count': 'Вы прошли его @count раз',
        'settings.about': 'О приложении',
        'settings.policies': 'Политики',
        'settings.contact_us': 'Написать нам',
        'settings.sign_out': 'Выйти',
        'settings.sign_out_title': 'Выйти',
        'settings.sign_out_message':
            'Вы уверены, что хотите выйти?',
        'settings.admin_push': 'Админ / Отправить push',
        'settings.diagnostics.data_usage':
            'Использование данных',
        'settings.diagnostics.network': 'Сеть',
        'settings.diagnostics.connected': 'Подключено',
        'settings.diagnostics.monthly_total':
            'Всего за месяц',
        'settings.diagnostics.monthly_limit':
            'Месячный лимит',
        'settings.diagnostics.remaining': 'Осталось',
        'settings.diagnostics.limit_usage':
            'Использование лимита',
        'settings.diagnostics.wifi_usage':
            'Использование Wi-Fi',
        'settings.diagnostics.cellular_usage':
            'Использование мобильных данных',
        'settings.diagnostics.time_ranges':
            'Промежутки времени',
        'settings.diagnostics.this_month_actual':
            'Этот месяц (факт)',
        'settings.diagnostics.hourly_average':
            'Среднее за час',
        'settings.diagnostics.since_login_estimated':
            'С момента входа (оценка)',
        'settings.diagnostics.details': 'Детали',
        'settings.diagnostics.cache': 'Кэш',
        'settings.diagnostics.saved_media_count':
            'Количество сохраненных медиа',
        'settings.diagnostics.occupied_space':
            'Занятое пространство',
        'settings.diagnostics.offline_queue':
            'Оффлайн-очередь',
        'settings.diagnostics.pending': 'В ожидании',
        'settings.diagnostics.dead_letter': 'Dead-letter',
        'settings.diagnostics.status': 'Статус',
        'settings.diagnostics.syncing': 'Синхронизация',
        'settings.diagnostics.idle': 'Ожидание',
        'settings.diagnostics.processed_total':
            'Обработано (всего)',
        'settings.diagnostics.failed_total':
            'Ошибок (всего)',
        'settings.diagnostics.last_sync':
            'Последняя синхронизация',
        'settings.diagnostics.login_date': 'Дата входа',
        'settings.diagnostics.login_time': 'Время входа',
        'settings.diagnostics.app_health_panel':
            'Панель состояния приложения',
        'settings.diagnostics.video_cache_detail':
            'Детали видеокэша',
        'settings.diagnostics.quick_actions':
            'Быстрые действия',
        'settings.diagnostics.offline_queue_detail':
            'Детали оффлайн-очереди',
        'settings.diagnostics.last_error_summary':
            'Последняя сводка ошибок',
        'settings.diagnostics.error_report':
            'Отчет об ошибке',
        'settings.diagnostics.saved_videos':
            'Сохраненные видео',
        'settings.diagnostics.saved_segments':
            'Сохраненные сегменты',
        'settings.diagnostics.disk_usage':
            'Использование диска',
        'settings.diagnostics.unknown': 'Неизвестно',
        'settings.diagnostics.cache_traffic':
            'Трафик кэша',
        'settings.diagnostics.hit_rate':
            'Коэффициент попаданий',
        'settings.diagnostics.hit': 'Hit',
        'settings.diagnostics.miss': 'Miss',
        'settings.diagnostics.cache_served':
            'Отдано из кэша',
        'settings.diagnostics.downloaded_from_network':
            'Загружено из сети',
        'settings.diagnostics.prefetch': 'Prefetch',
        'settings.diagnostics.queue': 'Очередь',
        'settings.diagnostics.active_downloads':
            'Активные загрузки',
        'settings.diagnostics.paused': 'На паузе',
        'settings.diagnostics.active': 'Активно',
        'settings.diagnostics.reset_data_counters':
            'Сбросить счетчики данных',
        'settings.diagnostics.data_counters_reset':
            'Счетчики данных были сброшены.',
        'settings.diagnostics.sync_offline_queue_now':
            'Синхронизировать оффлайн-очередь',
        'settings.diagnostics.offline_queue_sync_triggered':
            'Синхронизация оффлайн-очереди запущена.',
        'settings.diagnostics.retry_dead_letter':
            'Повторить dead-letter',
        'settings.diagnostics.dead_letter_queued':
            'Элементы dead-letter снова поставлены в очередь.',
        'settings.diagnostics.clear_dead_letter':
            'Очистить dead-letter',
        'settings.diagnostics.dead_letter_cleared':
            'Элементы dead-letter удалены.',
        'settings.diagnostics.pause_prefetch':
            'Поставить prefetch на паузу',
        'settings.diagnostics.prefetch_paused':
            'Prefetch поставлен на паузу',
        'settings.diagnostics.service_not_ready':
            'Сервис пока не готов.',
        'settings.diagnostics.resume_prefetch':
            'Продолжить prefetch',
        'settings.diagnostics.prefetch_resumed':
            'Prefetch возобновлен',
        'settings.diagnostics.online': 'Онлайн',
        'settings.diagnostics.sync': 'Sync',
        'settings.diagnostics.processed': 'Обработано',
        'settings.diagnostics.failed': 'Ошибки',
        'settings.diagnostics.pending_first8':
            'В ожидании (первые 8)',
        'settings.diagnostics.dead_letter_first8':
            'Dead-letter (первые 8)',
        'settings.diagnostics.sync_now':
            'Синхронизировать сейчас',
        'settings.diagnostics.dead_letter_retry':
            'Повторить dead-letter',
        'settings.diagnostics.dead_letter_clear':
            'Очистить dead-letter',
        'settings.diagnostics.no_recorded_error':
            'Нет записанных ошибок.',
        'settings.diagnostics.error_code': 'Код',
        'settings.diagnostics.error_category': 'Категория',
        'settings.diagnostics.error_severity': 'Уровень',
        'settings.diagnostics.error_retryable':
            'Можно повторить',
        'settings.diagnostics.error_message': 'Сообщение',
        'settings.diagnostics.error_time': 'Время',
        'account_center.header_title':
            'Профили и данные входа',
        'account_center.accounts': 'Аккаунты',
        'account_center.no_accounts':
            'На это устройство пока не добавлен ни один аккаунт.',
        'account_center.add_account': 'Добавить аккаунт',
        'account_center.personal_details':
            'Личные данные',
        'account_center.security': 'Безопасность',
        'account_center.active_account_title':
            'Активный аккаунт',
        'account_center.active_account_body':
            '@{username} уже активен.',
        'account_center.reauth_title':
            'Требуется повторный вход',
        'account_center.reauth_body':
            'Пожалуйста, снова введите пароль, чтобы переключить аккаунт.',
        'account_center.switch_failed_title':
            'Не удалось переключить',
        'account_center.switch_failed_body':
            'Не удалось активировать аккаунт.',
        'account_center.remove_active_forbidden':
            'Сначала нужно переключиться на другой аккаунт.',
        'account_center.remove_account_title':
            'Удалить аккаунт',
        'account_center.remove_account_body':
            'Удалить @{username} с этого устройства?',
        'account_center.account_removed':
            '@{username} удален.',
        'account_center.single_device_title':
            'Вход с одного устройства',
        'account_center.single_device_desc':
            'При входе с другого устройства текущая сессия будет закрыта и потребуется пароль.',
        'account_center.single_device_enabled':
            'Вход с одного устройства включен.',
        'account_center.single_device_disabled':
            'Вход с одного устройства отключен.',
        'account_center.no_personal_detail':
            'Личные данные не добавлены.',
        'account_center.contact_details':
            'Контактные данные',
        'account_center.contact_info':
            'Контактная информация',
        'account_center.email': 'E-mail',
        'account_center.phone': 'Телефон',
        'account_center.email_missing':
            'E-mail не добавлен',
        'account_center.phone_missing':
            'Телефон не добавлен',
        'account_center.verified': 'Подтверждено',
        'account_center.verify': 'Подтвердить',
        'account_center.unverified': 'Не подтверждено',
        'about_profile.title': 'Об этом аккаунте',
        'about_profile.description':
            'На этой странице показаны основные публичные сведения и история этого аккаунта.',
        'about_profile.joined_on': 'Присоединился {date}',
        'policies.center_title': 'Центр политик',
        'policies.center_desc':
            'Здесь можно просмотреть правила, условия и информационные документы TurqApp.',
        'policies.last_updated':
            'Последнее обновление: {date}',
        'language.title': 'Язык',
        'language.subtitle': 'Выберите язык приложения.',
        'language.note':
            'Некоторые экраны будут переводиться постепенно. Выбор применяется сразу.',
        'language.option.tr': 'Турецкий',
        'language.option.en': 'Английский',
        'language.option.de': 'Немецкий',
        'language.option.fr': 'Французский',
        'language.option.it': 'Итальянский',
        'language.option.ru': 'Русский',
        'login.tagline': '"Ваши истории соединяются здесь."',
        'login.device_accounts': 'Аккаунты на этом устройстве',
        'login.last_used': 'Последний использованный',
        'login.saved_account': 'Сохраненный аккаунт',
        'login.sign_in': 'Войти',
        'login.create_account': 'Создать аккаунт',
        'login.policies': 'Договоры и политики',
        'login.identifier_hint': 'Имя пользователя или e-mail',
        'login.password_hint': 'Ваш пароль',
        'login.reset': 'Сбросить',
        'login.reset_password_title': 'Сброс пароля',
        'login.email_label': 'Адрес e-mail',
        'login.email_hint': 'Введите адрес e-mail',
        'login.get_code': 'Получить код',
        'login.resend_code': 'Отправить снова',
        'login.verification_code': 'Код подтверждения',
        'login.verification_code_hint': '6-значный код подтверждения',
        'common.back': 'Назад',
        'common.continue': 'Продолжить',
        'common.all': 'Все',
        'common.videos': 'Видео',
        'common.photos': 'Фото',
        'common.no_results': 'Ничего не найдено',
        'common.success': 'Успешно',
        'common.warning': 'Предупреждение',
        'common.delete': 'Удалить',
        'common.search': 'Поиск',
        'common.call': 'Позвонить',
        'common.view': 'Открыть',
        'common.create': 'Создать',
        'common.applications': 'Заявки',
        'common.liked': 'Понравившиеся',
        'common.saved': 'Сохранено',
        'common.unknown_category': 'Неизвестная категория',
        'common.clear': 'Очистить',
        'answer_key.published': 'Опубликованные',
        'answer_key.my_results': 'Мои результаты',
        'answer_key.saved_empty': 'Нет сохраненных книг.',
        'answer_key.new_create': 'Создать новый',
        'answer_key.create_optical_form': 'Создать\nоптическую форму',
        'answer_key.create_booklet_answer_key':
            'Создать\nключ ответов книги',
        'answer_key.create_optical_form_single':
            'Создать оптическую форму',
        'answer_key.give_exam_name': 'Дайте экзамену название',
        'answer_key.join_exam_title': 'Присоединиться к экзамену',
        'answer_key.exam_id_hint': 'ID экзамена',
        'answer_key.book': 'Книга',
        'answer_key.create_book': 'Создать книгу',
        'answer_key.optical_form': 'Оптическая форма',
        'answer_key.delete_book': 'Удалить книгу',
        'answer_key.share_owner_only':
            'Только админы и владелец объявления могут делиться.',
        'answer_key.book_answer_key_desc': 'ключ ответов',
        'answer_key.delete_operation': 'Удаление',
        'answer_key.delete_optical_confirm':
            'Вы уверены, что хотите удалить оптическую форму @name?',
        'answer_key.total_questions': 'Всего @count вопросов',
        'answer_key.participant_count': '@count человек',
        'answer_key.id_copied': 'ID скопирован',
        'answer_key.answered_suffix': 'Отвечено @time назад',
        'common.share': 'Поделиться',
        'common.show_more': 'Показать больше',
        'common.show_less': 'Показать меньше',
        'common.hide': 'Скрыть',
        'common.push': 'Push',
        'common.quote': 'Цитировать',
        'common.user': 'Пользователь',
        'common.info': 'Инфо',
        'common.cancel': 'Отмена',
        'common.select': 'Выбрать',
        'common.close': 'Закрыть',
        'common.unspecified': 'Не указано',
        'common.yes': 'Да',
        'common.no': 'Нет',
        'common.selected_count': '@count выбрано',
        'profile_photo.camera': 'Сделать фото',
        'profile_photo.gallery': 'Выбрать из галереи',
        'common.now': 'сейчас',
        'common.download': 'Скачать',
        'app.name': 'TurqApp',
        'common.copy': 'Копировать',
        'common.copy_link': 'Копировать ссылку',
        'common.copied': 'Скопировано',
        'common.link_copied': 'Ссылка скопирована в буфер обмена',
        'common.archive': 'Архивировать',
        'common.unarchive': 'Убрать из архива',
        'common.apply': 'Применить',
        'common.reset': 'Сбросить',
        'common.select_city': 'Выбрать город',
        'common.select_district': 'Выбрать район',
        'common.report': 'Пожаловаться',
        'report.reported_user': 'Пользователь, на которого жалуются',
        'report.what_issue': 'Какую проблему вы хотите сообщить?',
        'report.thanks_title':
            'Спасибо, что помогаете нам сделать TurqApp лучше для всех!',
        'report.thanks_body':
            'Мы знаем, что ваше время ценно. Спасибо, что нашли время помочь нам.',
        'report.how_it_works_title': 'Как это работает?',
        'report.how_it_works_body':
            'Ваша жалоба получена. Мы скроем указанный профиль из вашей ленты.',
        'report.whats_next_title': 'Что будет дальше?',
        'report.whats_next_body':
            'Наша команда проверит этот профиль в течение нескольких дней. Если нарушение подтвердится, аккаунт будет ограничен. Если нарушение не подтвердится, а вы многократно отправляли недействительные жалобы, ваш аккаунт может быть ограничен.',
        'report.optional_block_title': 'Если хотите',
        'report.optional_block_body':
            'Вы можете заблокировать этот профиль. В таком случае этот пользователь больше совсем не будет появляться в вашей ленте.',
        'report.block_user_button': 'Заблокировать @nickname',
        'report.blocked_user_label': '@nickname заблокирован!',
        'report.block_user_info':
            'Запретите @nickname подписываться на вас и отправлять вам сообщения. Он по-прежнему сможет видеть ваши публичные посты, но не сможет взаимодействовать с вами. Вы также перестанете видеть посты @nickname.',
        'report.select_reason_title': 'Выберите причину жалобы',
        'report.select_reason_body':
            'Чтобы продолжить, нужно выбрать причину.',
        'report.submitted_title': 'Ваша заявка получена!',
        'report.submitted_body':
            'Мы проверим @nickname. Спасибо за вашу жалобу.',
        'report.submitting': 'Отправка...',
        'report.done': 'Готово',
        'report.reason.impersonation.title':
            'Выдача себя за другого / Фейковый аккаунт / Кража личности',
        'report.reason.impersonation.desc':
            'Этот аккаунт или контент может выдавать себя за другого человека, использовать поддельную личность или представлять другого человека без разрешения.',
        'report.reason.copyright.title':
            'Авторские права / Несанкционированное использование контента',
        'report.reason.copyright.desc':
            'Этот контент может использовать защищенные авторским правом материалы без разрешения или нарушать права интеллектуальной собственности.',
        'report.reason.harassment.title':
            'Домогательства / Целенаправленная травля / Буллинг',
        'report.reason.harassment.desc':
            'Этот контент, похоже, оскорбляет, унижает, целенаправленно атакует или систематически травит человека.',
        'report.reason.hate_speech.title': 'Язык вражды',
        'report.reason.hate_speech.desc':
            'Этот контент может содержать ненависть, дискриминацию или уничижительные высказывания в адрес человека или группы.',
        'report.reason.nudity.title': 'Нагота / Сексуальный контент',
        'report.reason.nudity.desc':
            'Этот контент может содержать наготу, непристойность или откровенные сексуальные материалы.',
        'report.reason.violence.title': 'Насилие / Угроза',
        'report.reason.violence.desc':
            'Этот контент может включать физическое насилие, угрозы, запугивание или призывы причинить вред.',
        'report.reason.spam.title':
            'Спам / Повторяющийся нерелевантный контент',
        'report.reason.spam.desc':
            'Этот контент выглядит повторяющимся, нерелевантным, вводящим в заблуждение или навязчивым, как спам.',
        'report.reason.scam.title': 'Мошенничество / Обман',
        'report.reason.scam.desc':
            'Этот контент может быть обманным или мошенническим с целью злоупотребления доверием, деньгами или информацией.',
        'report.reason.misinformation.title':
            'Дезинформация / Манипуляция',
        'report.reason.misinformation.desc':
            'Этот контент может искажать факты, распространять ложную информацию или манипулировать людьми.',
        'report.reason.illegal_content.title': 'Незаконный контент',
        'report.reason.illegal_content.desc':
            'Этот контент может быть связан с незаконной деятельностью, пропагандой преступлений или противоправными материалами.',
        'report.reason.child_safety.title':
            'Нарушение безопасности детей',
        'report.reason.child_safety.desc':
            'Этот контент может угрожать безопасности детей или содержать вредные элементы, неприемлемые для детей.',
        'report.reason.self_harm.title':
            'Самоповреждение / Поощрение суицида',
        'report.reason.self_harm.desc':
            'Этот контент может поощрять самоповреждение, суицид или иное опасное саморазрушительное поведение.',
        'report.reason.privacy_violation.title': 'Нарушение конфиденциальности',
        'report.reason.privacy_violation.desc':
            'Этот контент может включать несанкционированное распространение личных данных, доксинг или нарушение приватности.',
        'report.reason.fake_engagement.title':
            'Фальшивая активность / Боты / Манипулятивный рост',
        'report.reason.fake_engagement.desc':
            'Этот контент может включать накрученные лайки, активность ботов или манипулятивный искусственный рост.',
        'report.reason.other.title': 'Другое',
        'report.reason.other.desc':
            'Может быть другое нарушение, не указанное выше, которое вы хотите, чтобы мы проверили.',
        'common.undo': 'Отменить',
        'common.edited': 'изменено',
        'common.delete_post_title': 'Удалить пост',
        'common.delete_post_message': 'Вы уверены, что хотите удалить этот пост?',
        'common.delete_post_confirm': 'Удалить пост',
        'common.post_share_title': 'Пост TurqApp',
        'common.send': 'Отправить',
        'common.block': 'Заблокировать',
        'common.unknown_user': 'Неизвестный пользователь',
        'common.unknown_company': 'Неизвестная компания',
        'common.verified': 'Подтверждено',
        'common.verify': 'Подтвердить',
        'common.change': 'Изменить',
        'comments.input_hint': 'Что ты об этом думаешь?',
        'explore.tab.trending': 'Тренды',
        'explore.tab.for_you': 'Для вас',
        'explore.tab.series': 'Серия',
        'explore.trending_rank': '@index - в тренде в Турции',
        'explore.no_results': 'Ничего не найдено',
        'explore.no_series': 'Серии не найдены',
        'feed.empty_city': 'В вашем городе пока нет публикаций',
        'feed.empty_following':
            'Пока нет публикаций от пользователей, на которых вы подписаны',
        'post_likes.title': 'Лайки',
        'post_likes.empty': 'Лайков пока нет',
        'post_state.hidden_title': 'Пост скрыт',
        'post_state.hidden_body':
            'Этот пост скрыт. Похожие публикации будут показываться ниже в вашей ленте.',
        'post_state.archived_title': 'Пост архивирован',
        'post_state.archived_body':
            'Вы архивировали этот пост.\nТеперь его никто не увидит.',
        'post_state.deleted_title': 'Пост удален',
        'post_state.deleted_body': 'Этот пост больше не опубликован.',
        'post.share_title': 'Пост TurqApp',
        'post.archive': 'Архивировать',
        'post.unarchive': 'Убрать из архива',
        'post.like_failed': 'Не удалось выполнить действие лайка.',
        'post.save_failed': 'Не удалось выполнить сохранение.',
        'post.reshare_failed': 'Не удалось выполнить репост.',
        'post.report_success': 'Пост отправлен на проверку.',
        'post.report_failed': 'Не удалось выполнить жалобу.',
        'post.hide_failed': 'Не удалось завершить скрытие.',
        'post.reshare_action': 'Репост',
        'post.reshare_undo': 'Отменить репост',
        'post.reshared_you': 'вы сделали репост',
        'post.reshared_by': '@name сделал репост',
        'short.next_post': 'Перейти к следующему посту',
        'short.publish_as_post': 'Опубликовать как пост',
        'short.add_to_story': 'Добавить в историю',
        'short.shared_as_post_by': 'Поделившиеся как постом',
        'story.seens_title': 'Просмотры (@count)',
        'story.no_seens': 'Никто не посмотрел вашу историю',
        'story.comments_title': 'Комментарии (@count)',
        'story.share_title': 'История @name',
        'story.share_desc': 'Открыть историю в TurqApp',
        'story.drawing_title': 'Добавить рисунок',
        'story.brush_color': 'Цвет кисти',
        'story.no_comments': 'Комментариев пока нет',
        'story.add_comment_for': 'Добавить комментарий для @nickname..',
        'story.delete_message': 'Удалить эту историю?',
        'story.permanent_delete': 'Удалить навсегда',
        'story.permanent_delete_message':
            'Удалить эту историю навсегда?',
        'story.comment_delete_message':
            'Вы уверены, что хотите удалить этот комментарий?',
        'story.deleted_stories.title': 'Истории',
        'story.deleted_stories.tab_deleted': 'Удаленные',
        'story.deleted_stories.tab_expired': 'Истекшие',
        'story.deleted_stories.empty': 'Удаленных историй нет',
        'story.deleted_stories.snackbar_title': 'История',
        'story.deleted_stories.reposted': 'История опубликована снова',
        'story.deleted_stories.deleted_forever':
            'История удалена навсегда',
        'story.deleted_stories.deleted_at': 'Удалена: @time',
        'admin_push.queue_title': 'Push',
        'admin_push.queue_body_count':
            'Push поставлен в очередь для @count пользователей',
        'admin_push.queue_body': 'Push поставлен в очередь',
        'admin_push.failed_body': 'Не удалось отправить push.',
        'story_music.title': 'Музыка',
        'story_music.no_active_stories':
            'С этой музыкой нет активных историй',
        'story_music.untitled': 'Безымянный трек',
        'story_music.active_story_count': '@count активных историй',
        'story_music.minutes_ago': '@count мин',
        'story_music.hours_ago': '@count ч',
        'story_music.days_ago': '@count д',
        'chat.attach_photos': 'Фотографии',
        'chat.list_title': 'Чаты',
        'chat.tab_all': 'Все',
        'chat.tab_unread': 'Непрочитанные',
        'chat.tab_archive': 'Архив',
        'chat.empty_title': 'У вас пока нет чатов',
        'chat.empty_body':
            'Когда вы начнете переписываться, ваши разговоры появятся здесь.',
        'chat.action_failed':
            'Не удалось выполнить действие из-за проблемы с правами или записью',
        'chat.attach_videos': 'Видео',
        'chat.attach_location': 'Локация',
        'chat.message_hint': 'Сообщение',
        'chat.no_starred_messages': 'Нет избранных сообщений',
        'chat.profile_stats':
            '@followers подписчиков · @following подписок · @posts публикаций',
        'chat.selected_messages': 'Выбрано сообщений: @count',
        'chat.today': 'Сегодня',
        'chat.yesterday': 'Вчера',
        'chat.typing': 'печатает...',
        'chat.gif': 'GIF',
        'chat.ready_to_send': 'Готово к отправке',
        'chat.editing_message': 'Редактирование сообщения',
        'chat.video': 'Видео',
        'chat.audio': 'Аудио',
        'chat.location': 'Локация',
        'chat.post': 'Пост',
        'chat.person': 'Контакт',
        'chat.reply': 'Ответить',
        'chat.recording_timer': 'Идет запись... @time',
        'chat.fetching_address': 'Получение адреса...',
        'chat.add_star': 'Добавить в избранное',
        'chat.remove_star': 'Убрать из избранного',
        'chat.you': 'Вы',
        'chat.hide_photos': 'Скрыть фото',
        'chat.unsent_message': 'Сообщение отозвано',
        'chat.reply_prompt': 'Ответить',
        'chat.open_in_maps': 'Открыть в картах',
        'chat.open_in_google_maps': 'Открыть в Google Maps',
        'chat.open_in_apple_maps': 'Открыть в Apple Maps',
        'chat.open_in_yandex_maps': 'Открыть в Yandex Maps',
        'chat.contact_info': 'Информация о контакте',
        'chat.save_to_contacts': 'Сохранить в контакты',
        'chat.call': 'Позвонить',
        'chat.delete_message_title': 'Удалить сообщение',
        'chat.delete_message_body':
            'Вы уверены, что хотите удалить это сообщение?',
        'chat.delete_for_me': 'Удалить только у меня',
        'chat.delete_for_everyone': 'Удалить у всех',
        'chat.delete_photo_title': 'Удалить фото',
        'chat.delete_photo_body': 'Вы уверены, что хотите удалить это фото?',
        'chat.delete_photo_confirm': 'Удалить фото',
        'chat.messages_delete_failed': 'Не удалось удалить сообщения',
        'chat.image_upload_failed': 'Не удалось загрузить изображение',
        'chat.image_upload_failed_with_error':
            'Не удалось загрузить изображение: @error',
        'chat.video_upload_failed':
            'Произошла ошибка при загрузке видео',
        'chat.microphone_permission_required': 'Требуется разрешение',
        'chat.microphone_permission_denied':
            'Доступ к микрофону не предоставлен',
        'chat.voice_record_start_failed':
            'Не удалось начать запись голоса',
        'chat.voice_message_upload_failed':
            'Произошла ошибка при загрузке голосового сообщения',
        'chat.message_send_failed':
            'Не удалось отправить сообщение. Попробуйте еще раз.',
        'chat.shared_post_from': 'Отправил публикацию @nickname',
        'chat.notif_video': 'Отправил видео',
        'chat.notif_audio': 'Отправил голосовое сообщение',
        'chat.notif_images': 'Отправил изображений: @count',
        'chat.notif_post': 'Поделился публикацией',
        'chat.notif_location': 'Отправил локацию',
        'chat.notif_contact': 'Поделился контактом',
        'chat.notif_gif': 'Отправил GIF',
        'chat.reply_target_missing':
            'Сообщение, на которое вы отвечаете, не найдено',
        'chat.forwarded_title': 'Переслано',
        'chat.forwarded_body':
            'Сообщение переслано в выбранный чат',
        'chat.tap_to_chat': 'Нажмите, чтобы начать чат.',
        'chat.photo': 'Фото',
        'chat.message_label': 'Сообщение',
        'chat.marked_unread': 'Чат отмечен как непрочитанный',
        'chat.limit_title': 'Лимит',
        'chat.pin_limit': 'Можно закрепить не более 5 чатов',
        'chat.action_completed': 'Действие выполнено',
        'chat.muted': 'Чат отключен',
        'chat.unmuted': 'Звук чата включен',
        'chat.archived': 'Чат перемещен в архив',
        'chat.unarchived': 'Чат удален из архива',
        'chat.delete_title': 'Удалить чат',
        'chat.delete_message':
            'Вы уверены, что хотите удалить этот чат?',
        'chat.delete_confirm': 'Удалить чат',
        'chat.deleted_title': 'Чат удален',
        'chat.deleted_body': 'Выбранный чат успешно удален',
        'chat.unmute': 'Включить звук',
        'chat.mute': 'Отключить звук',
        'chat.mark_unread': 'Отметить как непрочитанный',
        'chat.pin': 'Закрепить',
        'chat.unpin': 'Открепить',
        'chat.muted_label': 'Без звука',
        'training.comments_title': 'Комментарии',
        'training.no_comments': 'Комментариев пока нет.',
        'training.reply': 'Ответить',
        'training.hide_replies': 'Скрыть ответы',
        'training.view_replies': 'Показать ответы: @count',
        'training.unknown_user': 'Неизвестный пользователь',
        'training.edit': 'Редактировать',
        'training.report': 'Пожаловаться',
        'training.reply_to_user': 'Ответить пользователю @name',
        'training.cancel': 'Отмена',
        'training.edit_comment_hint': 'Редактировать комментарий',
        'training.write_hint': 'Напишите..',
        'training.pick_from_gallery': 'Выбрать из галереи',
        'training.take_photo': 'Сделать фото',
        'training.time_now': 'только что',
        'training.time_min': '@count мин назад',
        'training.time_hour': '@count ч назад',
        'training.time_day': '@count д назад',
        'training.time_week': '@count нед назад',
        'training.photo_pick_failed':
            'Произошла ошибка при выборе фотографии!',
        'training.photo_upload_failed':
            'Произошла ошибка при загрузке фотографии!',
        'training.question_bank_title': 'Банк вопросов',
        'training.questions_loading': 'Загрузка вопросов...',
        'training.solve_later_empty':
            'Вопросы для Решить позже не найдены!',
        'training.remove_solve_later': 'Убрать из Решить позже',
        'training.no_questions': 'Вопросы не найдены!',
        'training.answer_first': 'Сначала ответьте на вопрос!',
        'training.share': 'Поделиться',
        'training.correct_ratio': '%@value Верно',
        'training.wrong_ratio': '%@value Неверно',
        'training.complaint_select_one':
            'Выберите хотя бы один вариант жалобы.',
        'training.complaint_thanks':
            'Спасибо за сообщение.',
        'training.complaint_submit_failed':
            'Произошла ошибка при отправке жалобы.',
        'training.no_questions_in_category':
            'В этой категории вопросы не найдены.',
        'training.saved_load_failed':
            'Произошла ошибка при загрузке сохраненных вопросов.',
        'training.view_update_failed':
            'Произошла ошибка при обновлении просмотра.',
        'training.saved_removed':
            'Вопрос удален из списка Решить позже!',
        'training.saved_added':
            'Вопрос добавлен в список Решить позже!',
        'training.saved_remove_failed':
            'Произошла ошибка при удалении из Решить позже.',
        'training.saved_update_failed':
            'Произошла ошибка при обновлении Решить позже.',
        'training.like_removed': 'Лайк удален!',
        'training.liked': 'Вопрос отмечен лайком!',
        'training.like_remove_failed':
            'Произошла ошибка при удалении лайка.',
        'training.like_add_failed':
            'Произошла ошибка при добавлении лайка.',
        'training.share_failed': 'Не удалось начать публикацию',
        'training.share_question_link_title':
            '@exam - @lesson Вопрос @number',
        'training.share_question_title':
            'TurqApp - @exam @lesson вопрос',
        'training.share_question_desc':
            'Вопрос из банка вопросов TurqApp',
        'training.leaderboard_empty':
            'Таблица лидеров ещё не сформирована.',
        'training.leaderboard_empty_body':
            'Решайте вопросы в банке, чтобы попасть в рейтинг.',
        'training.answer_locked':
            'Вы не можете изменить ответ на этот вопрос!',
        'training.answer_saved':
            'Ответ на этот вопрос уже сохранен.',
        'training.answer_save_failed':
            'Произошла ошибка при сохранении ответа',
        'training.no_more_questions':
            'В этой категории больше нет вопросов!',
        'training.settings_opening':
            'Открывается экран настроек!',
        'training.fetch_more_failed':
            'Произошла ошибка при загрузке дополнительных вопросов',
        'training.comments_load_failed':
            'Произошла ошибка при загрузке комментариев. Попробуйте еще раз!',
        'training.comment_or_photo_required':
            'Нужно добавить комментарий или фото!',
        'training.reply_or_photo_required':
            'Нужно добавить ответ или фото!',
        'training.comment_added': 'Ваш комментарий добавлен!',
        'training.comment_add_failed':
            'Произошла ошибка при добавлении комментария. Попробуйте еще раз!',
        'training.reply_added': 'Ваш ответ добавлен!',
        'training.reply_add_failed':
            'Произошла ошибка при добавлении ответа. Попробуйте еще раз!',
        'training.comment_deleted': 'Ваш комментарий удален!',
        'training.comment_delete_failed':
            'Произошла ошибка при удалении комментария. Попробуйте еще раз!',
        'training.reply_deleted': 'Ваш ответ удален!',
        'training.reply_delete_failed':
            'Произошла ошибка при удалении ответа. Попробуйте еще раз!',
        'training.comment_updated': 'Ваш комментарий обновлен!',
        'training.comment_update_failed':
            'Произошла ошибка при редактировании комментария. Попробуйте еще раз!',
        'training.reply_updated': 'Ваш ответ обновлен!',
        'training.reply_update_failed':
            'Произошла ошибка при редактировании ответа. Попробуйте еще раз!',
        'training.like_failed':
            'Произошла ошибка во время лайка. Попробуйте еще раз!',
        'training.upload_failed_title': 'Ошибка загрузки!',
        'training.upload_failed_body':
            'Этот контент сейчас не может быть обработан. Попробуйте другой.',
        'common.accept': 'Принять',
        'common.reject': 'Отклонить',
        'common.open_profile': 'Открыть профиль',
        'tutoring.title': 'Частные уроки',
        'tutoring.search_hint': 'Какой урок вы ищете?',
        'tutoring.my_applications': 'Мои заявки',
        'tutoring.create_listing': 'Создать объявление',
        'tutoring.my_listings': 'Мои объявления',
        'tutoring.saved': 'Сохраненные',
        'tutoring.slider_admin': 'Управление слайдером',
        'tutoring.review_title': 'Оставить отзыв',
        'tutoring.review_hint': 'Напишите комментарий (необязательно)',
        'tutoring.review_select_rating':
            'Пожалуйста, выберите оценку.',
        'tutoring.review_saved': 'Ваш отзыв сохранен.',
        'tutoring.applicants_title': 'Кандидаты',
        'tutoring.no_applications': 'Заявок пока нет',
        'tutoring.application_label': 'Заявка на частный урок',
        'tutoring.my_applications_empty':
            'Вы еще не отправляли заявки на частные уроки',
        'tutoring.instructor_fallback': 'Преподаватель',
        'tutoring.cancel_application_title': 'Отменить заявку',
        'tutoring.cancel_application_body':
            'Вы уверены, что хотите отменить эту заявку?',
        'tutoring.cancel_application_action': 'Отменить заявку',
        'tutoring.my_listings_title': 'Мои объявления',
        'tutoring.published': 'Опубликованные',
        'tutoring.expired': 'Истекшие',
        'tutoring.active_listings_empty':
            'Активных объявлений о частных уроках нет.',
        'tutoring.expired_listings_empty':
            'Объявлений о частных уроках с истекшим сроком нет.',
        'tutoring.user_id_missing':
            'Не удалось определить пользователя.',
        'tutoring.load_failed':
            'Произошла ошибка при загрузке объявлений: {error}',
        'tutoring.reactivated_title': 'Объявление снова активно',
        'tutoring.reactivated_body':
            'Объявление снова опубликовано.',
        'tutoring.user_load_failed':
            'Произошла ошибка при загрузке данных пользователя: {error}',
        'tutoring.location_missing': 'Местоположение не найдено',
        'tutoring.no_listings_in_region':
            'В этом районе нет объявлений о частных уроках.',
        'tutoring.no_lessons_in_category':
            'В категории {category} нет уроков.',
        'tutoring.search_empty':
            'По вашему запросу не найдено ни одного объявления.',
        'tutoring.search_empty_info':
            'Подходящих объявлений о частных уроках не найдено!',
        'tutoring.similar_listings': 'Похожие объявления',
        'tutoring.open_listing': 'Открыть объявление',
        'tutoring.report_listing': 'Пожаловаться на объявление',
        'tutoring.saved_empty': 'Нет сохраненных объявлений.',
        'tutoring.detail_description': 'Описание',
        'tutoring.detail_no_description':
            'Для этого объявления описание не добавлено.',
        'tutoring.detail_lesson_info': 'Информация об уроке',
        'tutoring.detail_branch': 'Направление',
        'tutoring.detail_price': 'Цена',
        'tutoring.detail_contact': 'Контакт',
        'tutoring.detail_phone_and_message': 'Телефон + сообщение',
        'tutoring.detail_message_only': 'Только сообщение',
        'tutoring.detail_gender_preference': 'Предпочтительный пол',
        'tutoring.detail_availability': 'Доступность',
        'tutoring.detail_listing_info': 'Информация об объявлении',
        'tutoring.detail_instructor': 'Преподаватель',
        'tutoring.detail_not_specified': 'Не указано',
        'tutoring.detail_city': 'Город',
        'tutoring.detail_views': 'Просмотры',
        'tutoring.detail_status': 'Статус',
        'tutoring.detail_status_passive': 'Пассивно',
        'tutoring.detail_status_active': 'Активно',
        'tutoring.detail_location': 'Местоположение',
        'tutoring.create.city_select': 'Выберите город',
        'tutoring.create.district_select': 'Выберите район',
        'tutoring.create.nsfw_check_failed':
            'Проверка NSFW изображения не удалась.',
        'tutoring.create.nsfw_detected':
            'Обнаружено неприемлемое изображение.',
        'tutoring.create.fill_required':
            'Пожалуйста, заполните все обязательные поля!',
        'tutoring.create.published':
            'Объявление о частном уроке опубликовано!',
        'tutoring.create.publish_failed':
            'Произошла ошибка при публикации объявления.',
        'tutoring.create.updated': 'Объявление обновлено!',
        'tutoring.create.no_changes': 'Изменений не было!',
        'tutoring.create.update_failed':
            'Произошла ошибка при обновлении объявления.',
        'tutoring.call_disabled':
            'Звонки для этого объявления отключены.',
        'tutoring.message': 'Сообщение',
        'tutoring.messages': 'Сообщения',
        'tutoring.phone_missing':
            'Номер телефона преподавателя не найден.',
        'tutoring.phone_open_failed':
            'Не удалось открыть приложение телефона.',
        'tutoring.unpublish_title': 'Снять объявление',
        'tutoring.unpublish_body':
            'Вы уверены, что хотите снять это объявление о частных уроках с публикации?',
        'tutoring.unpublished':
            'Объявление снято с публикации.',
        'tutoring.apply_login_required':
            'Войдите снова, чтобы подать заявку.',
        'tutoring.application_sent':
            'Ваша заявка отправлена.',
        'tutoring.application_failed':
            'Во время подачи заявки возникла проблема.',
        'tutoring.delete_success': 'Объявление удалено!',
        'tutoring.delete_failed':
            'Произошла ошибка при удалении объявления.',
        'tutoring.filter_title': 'Фильтры',
        'tutoring.gender_title': 'Пол',
        'tutoring.sort_title': 'Сортировка',
        'tutoring.lesson_place_title': 'Место занятия',
        'tutoring.service_location_title': 'Зона обслуживания',
        'tutoring.gender.male': 'Мужчина',
        'tutoring.gender.female': 'Женщина',
        'tutoring.gender.any': 'Неважно',
        'tutoring.sort.latest': 'Самые новые',
        'tutoring.sort.nearest': 'Ближе всего ко мне',
        'tutoring.sort.most_viewed': 'Самые просматриваемые',
        'tutoring.lesson_place.student_home': 'Дом ученика',
        'tutoring.lesson_place.teacher_home': 'Дом преподавателя',
        'tutoring.lesson_place.either_home':
            'Дом ученика или преподавателя',
        'tutoring.lesson_place.remote': 'Дистанционное обучение',
        'tutoring.lesson_place.lesson_area': 'Зона занятий',
        'tutoring.branch.summer_school': 'Летняя школа',
        'tutoring.branch.secondary_education': 'Среднее образование',
        'tutoring.branch.primary_education': 'Начальное образование',
        'tutoring.branch.foreign_language': 'Иностранный язык',
        'tutoring.branch.software': 'Программирование',
        'tutoring.branch.driving': 'Вождение',
        'tutoring.branch.sports': 'Спорт',
        'tutoring.branch.art': 'Искусство',
        'tutoring.branch.music': 'Музыка',
        'tutoring.branch.theatre': 'Театр',
        'tutoring.branch.personal_development': 'Личностное развитие',
        'tutoring.branch.vocational': 'Профессиональное',
        'tutoring.branch.special_education': 'Специальное образование',
        'tutoring.branch.children': 'Дети',
        'tutoring.branch.diction': 'Дикция',
        'tutoring.branch.photography': 'Фотография',
        'scholarship.applications_title': 'Заявки (@count)',
        'scholarship.no_applications': 'Пока нет заявок',
        'scholarship.my_listings': 'Мои объявления о стипендии',
        'scholarship.no_my_listings':
            'У вас нет объявлений о стипендии!',
        'scholarship.applications_suffix': 'ЗАЯВКИ НА СТИПЕНДИЮ @title',
        'scholarship.my_applications_title':
            'Мои заявки на стипендию',
        'scholarship.no_user_applications':
            'У вас нет заявок на стипендию!',
        'scholarship.saved_empty':
            'Сохраненные стипендии не найдены.',
        'scholarship.liked_empty':
            'Не найдено понравившихся стипендий.',
        'scholarship.remove_saved': 'Убрать из сохраненных',
        'scholarship.remove_liked': 'Убрать из понравившихся',
        'scholarship.remove_saved_confirm':
            'Вы уверены, что хотите убрать эту стипендию из сохраненных?',
        'scholarship.remove_liked_confirm':
            'Вы уверены, что хотите убрать эту стипендию из понравившихся?',
        'scholarship.removed_saved':
            'Стипендия удалена из сохраненных.',
        'scholarship.removed_liked':
            'Стипендия удалена из понравившихся.',
        'scholarship.list_title': 'Стипендии (@count)',
        'scholarship.search_results_title': 'Результаты поиска (@count)',
        'scholarship.empty_title': 'Пока нет стипендий',
        'scholarship.empty_body': 'Новые стипендии скоро появятся',
        'scholarship.no_results_for':
            'Ничего не найдено по запросу "@query"',
        'scholarship.search_hint_body':
            'Подсказка: попробуйте другие ключевые слова',
        'scholarship.search_tip_header': 'Можно искать по:',
        'scholarship.load_more_failed':
            'Не удалось загрузить больше стипендий.',
        'scholarship.like_failed': 'Не удалось поставить лайк.',
        'scholarship.bookmark_failed': 'Не удалось сохранить.',
        'scholarship.share_owner_only':
            'Поделиться могут только админ и владелец объявления.',
        'scholarship.share_missing_id':
            'Не найден ID стипендии для публикации.',
        'scholarship.share_failed': 'Не удалось поделиться.',
        'scholarship.share_fallback_desc':
            'Объявление о стипендии TurqApp',
        'scholarship.share_detail_title':
            'TurqApp Education - Детали стипендии',
        'scholarship.providers_title': 'Организации, выдающие стипендии',
        'scholarship.providers_empty':
            'Организации, выдающие стипендии, не найдены.',
        'scholarship.providers_load_failed':
            'Не удалось загрузить организации, выдающие стипендии.',
        'scholarship.applications_load_failed':
            'Не удалось загрузить заявки.',
        'scholarship.withdraw_application': 'Отозвать заявку',
        'scholarship.withdraw_confirm_title': 'Внимание!',
        'scholarship.withdraw_confirm_body':
            'Вы уверены, что хотите отозвать свою заявку?',
        'scholarship.withdraw_success':
            'Ваша заявка на стипендию отозвана.',
        'scholarship.withdraw_failed': 'Не удалось отозвать заявку.',
        'scholarship.session_missing':
            'Сессия пользователя не активна.',
        'scholarship.create_title': 'Создать стипендию',
        'scholarship.edit_title': 'Редактировать стипендию',
        'scholarship.preview_title': 'Предпросмотр стипендии',
        'scholarship.visual_info': 'Визуальная информация',
        'scholarship.basic_info': 'Основная информация',
        'scholarship.application_info': 'Информация о заявке',
        'scholarship.extra_info': 'Дополнительная информация',
        'scholarship.title_label': 'Название стипендии',
        'scholarship.provider_label': 'Организатор стипендии',
        'scholarship.website_label': 'Веб-сайт',
        'scholarship.description_help':
            'Пожалуйста, напишите описание стипендии одним понятным блоком.',
        'scholarship.no_description': 'Нет описания',
        'scholarship.conditions_label': 'Условия подачи заявки',
        'scholarship.required_docs_label': 'Необходимые документы',
        'scholarship.award_months_label': 'Месяцы выплаты',
        'scholarship.application_place_label': 'Куда подать заявку',
        'scholarship.application_place_turqapp': 'TurqApp',
        'scholarship.application_place_website': 'Сайт стипендии',
        'scholarship.application_website_label': 'Сайт стипендии',
        'scholarship.application_dates_label': 'Сроки подачи заявки',
        'scholarship.detail_missing':
            'Ошибка: данные стипендии не найдены.',
        'scholarship.detail_title': 'Детали стипендии',
        'scholarship.delete_title': 'Удалить стипендию',
        'scholarship.delete_confirm':
            'Вы уверены, что хотите удалить эту стипендию?',
        'scholarship.applications_heading': 'Заявки на стипендию @title',
        'scholarship.applicant.personal_section': 'Личные данные',
        'scholarship.applicant.education_section': 'Сведения об образовании',
        'scholarship.applicant.family_section': 'Семейные сведения',
        'scholarship.applicant.full_name': 'Полное имя',
        'scholarship.applicant.email': 'Адрес электронной почты',
        'scholarship.applicant.phone': 'Номер телефона',
        'scholarship.applicant.phone_open_failed':
            'Не удалось начать телефонный звонок',
        'scholarship.applicant.email_open_failed':
            'Не удалось открыть почтовый клиент',
        'chat.sign_in_required':
            'Войдите, чтобы отправить сообщение.',
        'chat.cannot_message_self_listing':
            'Нельзя отправить сообщение своему объявлению.',
        'scholarship.applicant.country': 'Страна',
        'scholarship.applicant.registry_city': 'Город регистрации',
        'scholarship.applicant.registry_district': 'Район регистрации',
        'scholarship.applicant.birth_date': 'Дата рождения',
        'scholarship.applicant.marital_status': 'Семейное положение',
        'scholarship.applicant.gender': 'Пол',
        'scholarship.applicant.disability_report':
            'Справка об инвалидности',
        'scholarship.applicant.employment_status': 'Статус занятости',
        'scholarship.applicant.education_level': 'Уровень образования',
        'scholarship.applicant.university': 'Университет',
        'scholarship.applicant.faculty': 'Факультет',
        'scholarship.applicant.department': 'Отделение',
        'scholarship.applicant.father_alive': 'Отец жив?',
        'scholarship.applicant.father_name': 'Имя отца',
        'scholarship.applicant.father_surname': 'Фамилия отца',
        'scholarship.applicant.father_phone': 'Телефон отца',
        'scholarship.applicant.father_job': 'Работа отца',
        'scholarship.applicant.father_income': 'Доход отца',
        'scholarship.applicant.mother_alive': 'Мать жива?',
        'scholarship.applicant.mother_name': 'Имя матери',
        'scholarship.applicant.mother_surname': 'Фамилия матери',
        'scholarship.applicant.mother_phone': 'Телефон матери',
        'scholarship.applicant.mother_job': 'Работа матери',
        'scholarship.applicant.mother_income': 'Доход матери',
        'scholarship.applicant.home_ownership': 'Статус жилья',
        'scholarship.applicant.residence_city': 'Город проживания',
        'scholarship.applicant.residence_district': 'Район проживания',
        'family_info.title': 'Семейные сведения',
        'family_info.reset_menu': 'Сбросить семейные сведения',
        'family_info.reset_title': 'Сбросить семейные сведения',
        'family_info.reset_body':
            'Все семейные сведения будут удалены. Это действие нельзя отменить. Вы уверены?',
        'family_info.select_father_alive':
            'Пожалуйста, укажите, жив ли отец',
        'family_info.select_mother_alive':
            'Пожалуйста, укажите, жива ли мать',
        'family_info.father_name_surname': 'Имя и фамилия отца',
        'family_info.mother_name_surname': 'Имя и фамилия матери',
        'family_info.select_job': 'Выберите профессию',
        'family_info.father_salary': 'Чистый доход отца',
        'family_info.mother_salary': 'Чистый доход матери',
        'family_info.father_phone': 'Контакт отца',
        'family_info.mother_phone': 'Контакт матери',
        'family_info.salary_hint': 'Чистый доход',
        'family_info.family_size': 'Размер семьи',
        'family_info.family_size_hint':
            'Количество проживающих в семье (включая вас)',
        'family_info.residence_info': 'Сведения о проживании',
        'family_info.father_salary_missing': 'Сведения о доходе отца',
        'family_info.father_phone_missing': 'Номер телефона отца',
        'family_info.father_phone_invalid':
            'Номер телефона отца должен содержать 10 цифр',
        'family_info.mother_salary_missing': 'Сведения о доходе матери',
        'family_info.mother_phone_missing': 'Номер телефона матери',
        'family_info.mother_phone_invalid':
            'Номер телефона матери должен содержать 10 цифр',
        'family_info.saved': 'Семейные сведения сохранены.',
        'family_info.save_failed':
            'Не удалось сохранить сведения.',
        'family_info.reset_success': 'Семейные сведения сброшены.',
        'family_info.reset_failed': 'Не удалось сбросить сведения.',
        'family_info.home_owned': 'Собственное жилье',
        'family_info.home_relative': 'Жилье родственника',
        'family_info.home_lodging': 'Служебное жилье',
        'family_info.home_rent': 'Аренда',
        'personal_info.title': 'Личные данные',
        'personal_info.reset_menu': 'Сбросить мои данные',
        'personal_info.reset_title': 'Вы уверены?',
        'personal_info.reset_body':
            'Ваши личные данные будут сброшены. Это действие нельзя отменить.',
        'personal_info.reset_success': 'Личные данные сброшены.',
        'personal_info.registry_info': 'Город и район регистрации',
        'personal_info.birth_date_title': 'Дата вашего рождения',
        'personal_info.select_birth_date': 'Выберите дату рождения',
        'personal_info.select_marital_status':
            'Выберите семейное положение',
        'personal_info.select_gender': 'Выберите пол',
        'personal_info.select_disability':
            'Выберите статус инвалидности',
        'personal_info.select_employment':
            'Выберите статус занятости',
        'personal_info.select_field': 'Выберите @field',
        'personal_info.city_load_failed':
            'Не удалось загрузить данные о городе и районе.',
        'personal_info.user_data_missing':
            'Данные пользователя не найдены. Вы можете создать новую запись.',
        'personal_info.load_failed': 'Не удалось загрузить данные.',
        'personal_info.select_country_error': 'Выберите страну.',
        'personal_info.fill_city_district':
            'Пожалуйста, заполните город и район.',
        'personal_info.saved': 'Личные данные сохранены.',
        'personal_info.save_failed': 'Не удалось сохранить данные.',
        'personal_info.marital_single': 'Холост/Не замужем',
        'personal_info.marital_married': 'Женат/Замужем',
        'personal_info.marital_divorced': 'Разведен/Разведена',
        'personal_info.gender_male': 'Мужской',
        'personal_info.gender_female': 'Женский',
        'personal_info.disability_yes': 'Есть',
        'personal_info.disability_no': 'Нет',
        'personal_info.working_yes': 'Работает',
        'personal_info.working_no': 'Не работает',
        'education_info.title': 'Сведения об образовании',
        'education_info.reset_menu':
            'Сбросить мои сведения об образовании',
        'education_info.reset_title': 'Вы уверены?',
        'education_info.reset_body':
            'Ваши сведения об образовании будут сброшены. Это действие нельзя отменить.',
        'education_info.reset_success':
            'Сведения об образовании были сброшены.',
        'education_info.select_level':
            'Сначала выберите уровень образования!',
        'education_info.middle_school': 'Школа',
        'education_info.high_school': 'Старшая школа',
        'education_info.class_level': 'Класс',
        'education_info.level_middle_school': 'Средняя школа',
        'education_info.level_high_school': 'Старшая школа',
        'education_info.level_associate': 'Колледж',
        'education_info.level_bachelor': 'Бакалавриат',
        'education_info.level_masters': 'Магистратура',
        'education_info.level_doctorate': 'Докторантура',
        'education_info.class_grade': '@grade класс',
        'education_info.select_field': 'Выберите @field',
        'education_info.initial_load_failed':
            'Не удалось загрузить начальные данные.',
        'education_info.countries_load_failed':
            'Не удалось загрузить список стран.',
        'education_info.city_data_failed':
            'Не удалось загрузить данные о городе и районе.',
        'education_info.middle_schools_failed':
            'Не удалось загрузить данные школы.',
        'education_info.high_schools_failed':
            'Не удалось загрузить данные старшей школы.',
        'education_info.higher_education_failed':
            'Не удалось загрузить данные высшего образования.',
        'education_info.saved_data_failed':
            'Не удалось загрузить сохраненные данные.',
        'education_info.level_load_failed':
            'Не удалось загрузить данные уровня.',
        'education_info.select_city_error': 'Выберите город.',
        'education_info.select_district_error': 'Выберите район.',
        'education_info.select_middle_school_error':
            'Выберите среднюю школу.',
        'education_info.select_high_school_error':
            'Выберите старшую школу.',
        'education_info.select_class_level_error':
            'Выберите уровень класса.',
        'education_info.select_university_error':
            'Выберите университет.',
        'education_info.select_faculty_error':
            'Выберите факультет.',
        'education_info.select_department_error':
            'Выберите отделение.',
        'education_info.saved': 'Сведения об образовании сохранены.',
        'education_info.save_failed': 'Не удалось сохранить данные.',
        'bank_info.title': 'Банковские данные',
        'bank_info.reset_menu': 'Сбросить мои банковские данные',
        'bank_info.reset_title': 'Вы уверены?',
        'bank_info.reset_body':
            'Ваши банковские данные будут сброшены. Это действие нельзя отменить.',
        'bank_info.reset_success': 'Банковские данные сброшены.',
        'bank_info.fast_title': 'Быстрый адрес (FAST)',
        'bank_info.fast_email': 'E-mail',
        'bank_info.fast_phone': 'Телефон',
        'bank_info.fast_iban': 'IBAN',
        'bank_info.bank_label': 'Банк',
        'bank_info.select_bank': 'Выберите банк',
        'bank_info.select_fast_type': 'Выберите тип быстрого адреса',
        'bank_info.load_failed': 'Не удалось загрузить данные.',
        'bank_info.missing_value':
            'Мы не можем продолжить без заполнения данных IBAN.',
        'bank_info.missing_bank':
            'Вы не выбрали банк для получения выплаты. Эта информация будет передана, если стипендия будет одобрена.',
        'bank_info.invalid_email':
            'Пожалуйста, введите корректный адрес электронной почты.',
        'bank_info.saved': 'Банковские данные сохранены.',
        'bank_info.save_failed': 'Не удалось сохранить данные.',
        'dormitory.title': 'Сведения об общежитии',
        'dormitory.reset_menu':
            'Сбросить мои сведения об общежитии',
        'dormitory.reset_title': 'Вы уверены?',
        'dormitory.reset_body':
            'Сведения об общежитии будут сброшены. Это действие нельзя отменить.',
        'dormitory.reset_success':
            'Сведения об общежитии сброшены.',
        'dormitory.current_info': 'Текущие сведения об общежитии',
        'dormitory.select_admin_type':
            'Выберите тип администрации',
        'dormitory.admin_public': 'Государственное',
        'dormitory.admin_private': 'Частное',
        'dormitory.select_dormitory': 'Выберите общежитие',
        'dormitory.not_found_for_filters':
            'Для этого города и типа администрации общежитие не найдено',
        'dormitory.saved': 'Сведения об общежитии сохранены.',
        'dormitory.save_failed': 'Не удалось сохранить данные.',
        'dormitory.select_or_enter':
            'Выберите общежитие или введите его название',
        'scholarship.application_start_date': 'Дата начала подачи заявок',
        'scholarship.application_end_date': 'Дата окончания подачи заявок',
        'scholarship.select_from_list': 'Выбрать из списка',
        'scholarship.image_missing': 'Изображение не найдено',
        'scholarship.amount_label': 'Сумма',
        'scholarship.student_count_label': 'Количество студентов',
        'scholarship.repayable_label': 'Возвратная',
        'scholarship.duplicate_status_label': 'Статус повторного получения',
        'scholarship.education_audience_label': 'Образовательная аудитория',
        'scholarship.target_audience_label': 'Целевая аудитория',
        'scholarship.country_label': 'Страна',
        'scholarship.cities_label': 'Города',
        'scholarship.universities_label': 'Университеты',
        'scholarship.published_at': 'Дата публикации',
        'scholarship.show_less': 'Показать меньше',
        'scholarship.show_all': 'Показать все',
        'scholarship.more_universities': '+еще @count университетов',
        'scholarship.other_info': 'Дополнительная информация',
        'scholarship.application_how': 'Как подать заявку?',
        'scholarship.application_via_turqapp_prefix':
            'Заявки через TurqApp ',
        'scholarship.application_received_status': 'ПРИНИМАЮТСЯ.',
        'scholarship.application_not_received_status': 'НЕ ПРИНИМАЮТСЯ.',
        'scholarship.edit_button': 'Редактировать стипендию',
        'scholarship.website_open_failed':
            'Не удалось открыть сайт. Пожалуйста, введите корректный URL.',
        'scholarship.checking_info': 'Проверка информации',
        'scholarship.user_data_missing':
            'Данные пользователя не найдены. Пожалуйста, заполните информацию о себе.',
        'scholarship.check_info_failed':
            'Произошла ошибка при проверке информации.',
        'scholarship.application_check_failed':
            'Произошла ошибка при проверке статуса заявки.',
        'scholarship.login_required': 'Пожалуйста, войдите в систему.',
        'scholarship.profile_missing':
            'Для этой стипендии нет информации профиля.',
        'scholarship.applied_success':
            'Ваша заявка на стипендию получена.',
        'scholarship.apply_failed': 'Не удалось сохранить заявку.',
        'scholarship.follow_limit_title': 'Лимит подписок',
        'scholarship.follow_limit_body':
            'Сегодня вы больше не можете подписываться на других пользователей.',
        'scholarship.follow_failed':
            'Не удалось выполнить действие подписки.',
        'scholarship.invalid': 'Недействительная стипендия.',
        'scholarship.delete_success':
            'Стипендия успешно удалена.',
        'scholarship.delete_failed':
            'Произошла ошибка при удалении стипендии.',
        'scholarship.cancel_success':
            'Ваша заявка на стипендию отменена.',
        'scholarship.cancel_failed': 'Не удалось отменить заявку.',
        'scholarship.info_missing_title': 'Недостаточно информации',
        'scholarship.info_missing_body':
            'Вы не можете подать заявку на стипендию, не заполнив личные, учебные и семейные данные.',
        'scholarship.update_my_info': 'Обновить мои данные',
        'scholarship.closed': 'Прием заявок закрыт',
        'scholarship.applied': 'Вы уже подали заявку',
        'scholarship.cancel_apply_title': 'Отменить заявку',
        'scholarship.cancel_apply_body':
            'Вы уверены, что хотите отменить эту заявку на стипендию?',
        'scholarship.cancel_apply_button': 'Отменить заявку',
        'scholarship.amount_hint': 'Сумма',
        'scholarship.student_count_hint': 'например, 4',
        'scholarship.amount_student_count_notice':
            'Сумма и количество студентов не отображаются на странице заявки.',
        'scholarship.degree_type_label': 'Тип степени',
        'scholarship.degree_type_select': 'Выберите тип степени',
        'scholarship.select_country': 'Выберите страну',
        'scholarship.select_country_first':
            'Сначала выберите страну.',
        'scholarship.select_city_first': 'Сначала выберите город.',
        'scholarship.select_university': 'Выберите университет',
        'scholarship.selected_universities':
            'Выбранные университеты:',
        'scholarship.logo_label': 'Выбрать логотип',
        'scholarship.logo_pick': 'Выберите логотип',
        'scholarship.custom_design_optional': 'Ваш дизайн (необязательно)',
        'scholarship.custom_image_pick': 'Выберите изображение',
        'scholarship.template_select': 'Выберите шаблон',
        'scholarship.file_copy_failed': 'Не удалось скопировать файл.',
        'scholarship.duplicate_status.can_receive': 'Может получать',
        'scholarship.duplicate_status.cannot_receive_except_kyk':
            'Не может получать (кроме KYK)',
        'scholarship.target.population': 'По населению',
        'scholarship.target.residence': 'По месту проживания',
        'scholarship.target.all_turkiye': 'Вся Турция',
        'scholarship.info.personal': 'Личное',
        'scholarship.info.school': 'Учеба',
        'scholarship.info.family': 'Семья',
        'scholarship.info.dormitory': 'Общежитие',
        'scholarship.education.all': 'Все',
        'scholarship.education.middle_school': 'Средняя школа',
        'scholarship.education.high_school': 'Старшая школа',
        'scholarship.education.undergraduate': 'Бакалавриат',
        'scholarship.degree.associate': 'Ассоциированная степень',
        'scholarship.degree.bachelor': 'Бакалавр',
        'scholarship.degree.master': 'Магистр',
        'scholarship.degree.phd': 'Докторская степень',
        'single_post.title': 'Посты',
        'edit_post.updating':
            'Пожалуйста, подождите. Ваш пост обновляется',
        'edit_profile.title': 'Данные профиля',
        'profile.copy_profile_link': 'Скопировать ссылку профиля',
        'profile.profile_share_title': 'Профиль TurqApp',
        'profile.private_account_title': 'Закрытый аккаунт',
        'profile.private_story_follow_required':
            'Сначала нужно подписаться на этот аккаунт, чтобы видеть истории.',
        'profile.unfollow_title': 'Отписаться',
        'profile.unfollow_body':
            'Вы уверены, что хотите отписаться от @{nickname}?',
        'profile.unfollow_confirm': 'Отписаться',
        'profile.following_status': 'Вы подписаны',
        'profile.follow_button': 'Подписаться',
        'profile.contact_options': 'Способы связи',
        'profile.unblock': 'Разблокировать',
        'profile.remove_highlight_title': 'Удалить highlight',
        'profile.remove_highlight_body':
            'Вы уверены, что хотите удалить этот highlight?',
        'profile.remove_highlight_confirm': 'Удалить',
        'social_profile.private_follow_to_see_posts':
            'Подпишитесь на этот аккаунт, чтобы видеть публикации.',
        'social_profile.blocked_user':
            'Вы заблокировали этого пользователя',
        'edit_profile.personal_info': 'Личная информация',
        'edit_profile.other_info': 'Дополнительная информация',
        'edit_profile.first_name_hint': 'Имя',
        'edit_profile.last_name_hint': 'Фамилия',
        'edit_profile.privacy': 'Приватность аккаунта',
        'edit_profile.links': 'Ссылки',
        'edit_profile.contact_info': 'Контактная информация',
        'edit_profile.address_info': 'Информация об адресе',
        'edit_profile.career_profile': 'Карьерный профиль',
        'edit_profile.update_success':
            'Данные вашего профиля обновлены!',
        'edit_profile.update_failed': 'Ошибка обновления: {error}',
        'edit_profile.remove_photo_title': 'Удалить фото профиля',
        'edit_profile.remove_photo_message':
            'Фото профиля будет удалено, и будет использован стандартный аватар. Продолжить?',
        'edit_profile.photo_removed': 'Фото профиля удалено.',
        'edit_profile.photo_remove_failed':
            'Произошла ошибка при удалении фото профиля.',
        'edit_profile.crop_use': 'Обрезать и использовать',
        'edit_profile.delete_account': 'Удалить аккаунт',
        'edit_profile.upload_failed_title': 'Ошибка загрузки!',
        'edit_profile.upload_failed_body':
            'Этот контент сейчас не может быть обработан. Попробуйте другой контент.',
        'delete_account.title': 'Удалить аккаунт',
        'delete_account.confirm_title': 'Подтверждение удаления аккаунта',
        'delete_account.confirm_body':
            'Перед удалением аккаунта мы отправим код подтверждения на ваш зарегистрированный e-mail в целях безопасности.',
        'delete_account.code_hint': '6-значный код подтверждения',
        'delete_account.resend': 'Отправить снова',
        'delete_account.send_code': 'Отправить код',
        'delete_account.validity_notice':
            'Код действует 1 час. Ваш запрос на удаление будет окончательно обработан через {days} дней.',
        'delete_account.processing': 'Обработка...',
        'delete_account.delete_my_account': 'Удалить мой аккаунт',
        'delete_account.no_email_title': 'Предупреждение',
        'delete_account.no_email_body':
            'У этого аккаунта нет e-mail. Вы можете сразу запустить запрос на удаление.',
        'delete_account.session_missing':
            'Сессия не найдена. Войдите снова.',
        'delete_account.code_sent_title': 'Код отправлен',
        'delete_account.code_sent_body':
            'Код подтверждения удаления отправлен на ваш e-mail.',
        'delete_account.send_failed': 'Не удалось отправить код.',
        'delete_account.invalid_code_title': 'Неверный код',
        'delete_account.invalid_code_body':
            'Введите 6-значный код.',
        'delete_account.verify_failed':
            'Не удалось подтвердить код.',
        'editor_nickname.title': 'Имя пользователя',
        'editor_nickname.hint': 'Создать имя пользователя',
        'editor_nickname.verified_locked':
            'Подтвержденные пользователи не могут менять имя пользователя',
        'editor_nickname.mimic_warning':
            'Имена пользователей, имитирующие реальных людей, могут быть изменены TurqApp для защиты сообщества.',
        'editor_nickname.tr_char_info':
            'Турецкие символы преобразуются автоматически. (ç→c, ğ→g, ı→i, ö→o, ş→s, ü→u)',
        'editor_nickname.min_length':
            'Должно быть не менее 8 символов',
        'editor_nickname.current_name':
            'Ваше текущее имя пользователя',
        'editor_nickname.edit_prompt':
            'Измените, чтобы внести правку',
        'editor_nickname.checking': 'Проверка…',
        'editor_nickname.taken': 'Это имя пользователя уже занято',
        'editor_nickname.available': 'Доступно',
        'editor_nickname.unavailable':
            'Не удалось проверить',
        'editor_nickname.cooldown_limit':
            'В первый час можно изменить только 3 раза',
        'editor_nickname.change_after_days':
            'Имя пользователя можно будет изменить снова через {days}д {hours}ч',
        'editor_nickname.change_after_hours':
            'Имя пользователя можно будет изменить снова через {hours}ч',
        'editor_nickname.error_min_length':
            'Имя пользователя должно содержать не менее 8 символов.',
        'editor_nickname.error_taken':
            'Это имя пользователя уже занято.',
        'editor_nickname.error_grace_limit':
            'В первый час его можно изменить только 3 раза.',
        'editor_nickname.error_cooldown':
            'Имя пользователя нельзя изменить повторно раньше чем через 15 дней.',
        'editor_nickname.error_update_failed':
            'Не удалось обновить имя пользователя.',
        'cv.title': 'Карьерный профиль',
        'cv.personal_info': 'Личная информация',
        'cv.education_info': 'Информация об образовании',
        'cv.other_info': 'Дополнительная информация',
        'cv.profile_title': 'Карьерный профиль',
        'cv.profile_body':
            'Сделайте карьерный профиль сильнее с помощью фото профиля и базовой информации.',
        'cv.first_name_hint': 'Имя',
        'cv.last_name_hint': 'Фамилия',
        'cv.email_hint': 'Адрес e-mail',
        'cv.phone_hint': 'Номер телефона',
        'cv.about_hint': 'Кратко расскажите о себе',
        'cv.add_school': 'Добавить учебное заведение',
        'cv.add_school_title': 'Добавить новое учебное заведение',
        'cv.edit_school_title': 'Изменить учебное заведение',
        'cv.school_name': 'Название учебного заведения',
        'cv.department': 'Отделение',
        'cv.graduation_year': 'Год окончания',
        'cv.currently_studying': 'Я еще учусь',
        'cv.missing_school_name':
            'Название учебного заведения не может быть пустым',
        'cv.invalid_year': 'Введите корректный год',
        'cv.skills': 'Навыки',
        'cv.add_skill_title': 'Добавить новый навык',
        'cv.skill_name_empty':
            'Название навыка не может быть пустым',
        'cv.skill_exists': 'Этот навык уже добавлен',
        'cv.skill_hint': 'Навык (например, Flutter, Photoshop)',
        'cv.add_language': 'Добавить язык',
        'cv.add_new_language': 'Добавить новый язык',
        'cv.add_language_title': 'Добавить новый язык',
        'cv.edit_language_title': 'Изменить язык',
        'cv.level': 'Уровень',
        'cv.add_experience': 'Добавить опыт работы',
        'cv.add_new_experience': 'Добавить новый опыт работы',
        'cv.add_experience_title': 'Добавить новый опыт работы',
        'cv.edit_experience_title': 'Изменить опыт работы',
        'cv.company_name': 'Название компании',
        'cv.position': 'Должность',
        'cv.description_optional': 'Описание обязанностей (необязательно)',
        'cv.start_year': 'Начало',
        'cv.end_year': 'Окончание',
        'cv.currently_working': 'Я все еще здесь работаю',
        'cv.ongoing': 'Продолжается',
        'cv.missing_company_position':
            'Название компании и должность обязательны',
        'cv.invalid_start_year':
            'Введите корректный год начала',
        'cv.invalid_end_year':
            'Введите корректный год окончания',
        'cv.add_reference': 'Добавить рекомендацию',
        'cv.add_new_reference': 'Добавить новую рекомендацию',
        'cv.add_reference_title': 'Добавить новую рекомендацию',
        'cv.edit_reference_title': 'Изменить рекомендацию',
        'cv.name_surname': 'Имя и фамилия',
        'cv.phone_example': 'Телефон (например, 05xx..)',
        'cv.missing_name_surname':
            'Имя и фамилия не могут быть пустыми',
        'cv.save': 'Сохранить',
        'cv.created_title': 'CV создано!',
        'cv.created_body':
            'Теперь вы можете откликаться на вакансии намного быстрее',
        'cv.save_failed':
            'Не удалось сохранить CV. Попробуйте еще раз.',
        'cv.not_signed_in': 'Вы не вошли в систему.',
        'cv.missing_field': 'Отсутствует поле',
        'cv.invalid_format': 'Неверный формат',
        'cv.missing_first_name':
            'Нельзя сохранить без имени',
        'cv.missing_last_name':
            'Нельзя сохранить без фамилии',
        'cv.missing_email':
            'Нельзя сохранить без адреса e-mail',
        'cv.invalid_email':
            'Введите корректный адрес e-mail',
        'cv.missing_phone':
            'Нельзя сохранить без номера телефона',
        'cv.invalid_phone':
            'Введите корректный номер телефона',
        'cv.missing_about':
            'Нужно добавить краткую информацию о себе',
        'cv.missing_school':
            'Нельзя сохранить без добавления хотя бы одного учебного заведения',
        'qr.title': 'Личный QR-код',
        'qr.profile_subject': 'Профиль TurqApp',
        'qr.link_copied_title': 'Ссылка скопирована',
        'qr.link_copied_body': 'Ссылка на профиль скопирована',
        'qr.permission_required': 'Требуется разрешение',
        'qr.gallery_permission_body':
            'Для сохранения нужно разрешить доступ к галерее.',
        'qr.data_failed': 'Не удалось создать данные QR-кода.',
        'qr.saved': 'QR-код сохранен в галерею.',
        'qr.save_failed': 'Не удалось сохранить QR-код.',
        'qr.download_failed': 'Во время загрузки произошла ошибка.',
        'signup.create_account_title': 'Создайте аккаунт',
        'signup.policy_short':
            'Я принимаю договоры и политики.',
        'signup.email': 'E-mail',
        'signup.username': 'Имя пользователя',
        'signup.password': 'Пароль',
        'signup.personal_info': 'Личная информация',
        'signup.first_name': 'Имя',
        'signup.last_name_optional': 'Фамилия (необязательно)',
        'signup.next': 'Далее',
        'signup.verification_title': 'Подтверждение',
        'notifications.title': 'Уведомления',
        'notifications.categories': 'Категории',
        'notifications.device_notice':
            'Чтобы видеть уведомления на экране блокировки, оставьте разрешение включенным в настройках устройства.',
        'notifications.pause_all': 'Приостановить все',
        'notifications.sleep_mode': 'Режим сна',
        'notifications.messages': 'Сообщения',
        'notifications.posts_comments': 'Посты и комментарии',
        'notifications.comments': 'Комментарии',
        'comments.delete_message':
            'Вы уверены, что хотите удалить этот комментарий?',
        'comments.delete_failed': 'Не удалось удалить комментарий.',
        'comments.title': 'Комментарии',
        'comments.empty': 'Оставьте первый комментарий...',
        'comments.reply': 'Ответить',
        'comments.replying_to': 'Ответ для @nickname',
        'comments.sending': 'Отправляется',
        'comments.community_violation_title':
            'Нарушение правил сообщества',
        'comments.community_violation_body':
            'Использованный язык не соответствует нашим правилам сообщества. Пожалуйста, используйте уважительный тон.',
        'post_sharers.empty': 'Этот пост еще никто не поделился',
        'notifications.follows': 'Подписки',
        'notifications.direct_messages': 'Личные сообщения',
        'notifications.opportunities': 'Объявления и заявки',
        'support.title': 'Написать нам',
        'support.card_title': 'Сообщение в поддержку',
        'support.direct_admin': 'Ваше сообщение отправляется напрямую админу.',
        'support.topic': 'Тема',
        'support.topic.account': 'Аккаунт',
        'support.topic.payment': 'Оплата',
        'support.topic.technical': 'Техническая проблема',
        'support.topic.content': 'Жалоба на контент',
        'support.topic.suggestion': 'Предложение',
        'support.message_hint': 'Опишите вашу проблему или запрос...',
        'support.send': 'Отправить сообщение',
        'support.empty_title': 'Недостаточно информации',
        'support.empty_body': 'Пожалуйста, напишите сообщение.',
        'support.sent_title': 'Отправлено',
        'support.sent_body': 'Ваше сообщение отправлено админу.',
        'support.error_title': 'Ошибка',
        'liked_posts.no_posts': 'Нет публикаций',
        'saved_posts.posts_tab': 'Публикации',
        'saved_posts.series_tab': 'Серия',
        'saved_posts.no_saved_posts':
            'Нет сохраненных публикаций',
        'saved_posts.no_saved_series': 'Нет сохраненных серий',
        'editor_email.title': 'Подтверждение e-mail',
        'editor_email.email_hint':
            'Ваш адрес электронной почты аккаунта',
        'editor_email.send_code':
            'Отправить код подтверждения',
        'editor_email.resend_in':
            'Повторная отправка через {seconds}s',
        'editor_email.note':
            'Это подтверждение нужно для безопасности. Вы можете продолжать пользоваться приложением даже без подтверждения.',
        'editor_email.code_hint': '6-значный код подтверждения',
        'editor_email.verify_confirm':
            'Подтвердить код и подтвердить e-mail',
        'editor_email.wait':
            'Пожалуйста, подождите {seconds} секунд.',
        'editor_email.session_missing':
            'Сессия не найдена. Пожалуйста, войдите снова.',
        'editor_email.email_missing':
            'В вашем аккаунте не найден адрес e-mail.',
        'editor_email.code_sent':
            'Код подтверждения отправлен на ваш e-mail.',
        'editor_email.code_send_failed':
            'Не удалось отправить код подтверждения.',
        'editor_email.enter_code':
            'Введите 6-значный код подтверждения.',
        'editor_email.verified':
            'Ваш адрес e-mail подтвержден.',
        'editor_email.verify_failed':
            'Не удалось подтвердить адрес e-mail.',
        'editor_phone.title': 'Номер телефона',
        'editor_phone.phone_hint': 'Номер телефона',
        'editor_phone.send_approval':
            'Отправить письмо подтверждения',
        'editor_phone.resend_in':
            'Повторная отправка через {seconds}s',
        'editor_phone.code_hint': '6-значный код подтверждения',
        'editor_phone.verify_update':
            'Подтвердить код и обновить',
        'editor_phone.wait':
            'Пожалуйста, подождите {seconds} секунд.',
        'editor_phone.invalid_phone':
            'Введите 10-значный номер телефона, начинающийся с 5.',
        'editor_phone.session_missing':
            'Сессия не найдена. Пожалуйста, войдите снова.',
        'editor_phone.email_missing':
            'Нет e-mail для подтверждения этого изменения.',
        'editor_phone.code_sent':
            'Код подтверждения отправлен на ваш e-mail.',
        'editor_phone.code_send_failed':
            'Не удалось отправить код подтверждения.',
        'editor_phone.enter_code':
            'Введите 6-значный код подтверждения.',
        'editor_phone.update_failed':
            'Не удалось обновить номер телефона.',
        'editor_phone.updated':
            'Ваш номер телефона обновлен.',
        'address.title': 'Адрес',
        'address.hint': 'Адрес офиса или компании',
        'biography.title': 'Биография',
        'biography.hint': 'Расскажите немного о себе..',
        'profile_contact.title': 'Контакты',
        'profile_contact.call': 'Звонок',
        'profile_contact.email': 'E-mail',
        'job_selector.title': 'Профессия и категория',
        'job_selector.subtitle':
            'Категория помогает вашему профилю легче находиться.',
        'job_selector.search_hint': 'Поиск',
        'legacy_language.title': 'Язык приложения',
        'statistics.title': 'Статистика',
        'statistics.you': 'Вы',
        'statistics.notice':
            'Ваша статистика регулярно обновляется на основе активности за последние 30 дней.',
        'statistics.post_views_pct': 'Процент просмотров постов',
        'statistics.follower_growth_pct':
            'Процент роста подписчиков',
        'statistics.profile_visits_30d': 'Посещения профиля (30 дней)',
        'statistics.post_views': 'Просмотры постов',
        'statistics.post_count': 'Количество постов',
        'statistics.story_count': 'Количество историй',
        'statistics.follower_growth': 'Рост подписчиков',
        'interests.personalize_feed': 'Настройте свою ленту',
        'interests.selection_range':
            'Выберите минимум {min} и максимум {max} интересов.',
        'interests.selected_count': 'Выбрано {selected}/{max}',
        'interests.ready': 'Готово',
        'interests.search_hint': 'Поиск интересов',
        'interests.limit_title': 'Лимит выбора',
        'interests.limit_body':
            'Можно выбрать не более {max} интересов.',
        'interests.min_title': 'Недостаточно выбора',
        'interests.min_body':
            'Нужно выбрать минимум {min} интересов.',
        'view_changer.title': 'Вид',
        'view_changer.classic': 'Классический вид',
        'view_changer.modern': 'Современный вид',
        'social_links.title': 'Ссылки ({count})',
        'social_links.add': 'Добавить',
        'social_links.add_title': 'Добавить ссылку',
        'tests.create_title': 'Создать тест',
        'tests.edit_title': 'Редактировать тест',
        'tests.create_data_missing':
            'Данные не найдены.\nСсылки приложения или вопросы теста не удалось загрузить.',
        'tests.create_upload_failed':
            'Этот контент сейчас не может быть обработан. Попробуйте другой контент.',
        'tests.select_branch': 'Выбрать направление',
        'tests.select_language': 'Выбрать язык',
        'tests.cover_select': 'Выбрать обложку',
        'tests.name_hint': 'Название экзамена',
        'tests.post_exam_status': 'После экзамена @status',
        'tests.types': 'Типы экзаменов',
        'tests.date_duration': 'Дата и длительность экзамена',
        'tests.duration_select': 'Выбрать длительность экзамена',
        'tests.create_description_hint':
            '9 класс Показательные и корневые выражения',
        'tests.share_status': 'Для всех: @status',
        'tests.status.open': 'Открыто',
        'tests.status.closed': 'Закрыто',
        'tests.share_public_info':
            'В соответствии с цифровой этикой тесты, защищенные авторским правом, не должны распространяться.\nПожалуйста, используйте и публикуйте тесты, которые могут решать все и которые не содержат материалов, защищенных авторским правом.',
        'tests.share_private_info':
            'Этот тест можно делиться только с вашими учениками. Только ученики, которые введут предоставленный вами ID, смогут получить доступ к опубликованному тесту и решить его.',
        'tests.test_id': 'ID теста: @id',
        'tests.test_type': 'Тип теста',
        'tests.subjects': 'Предметы',
        'tests.exam_prep': 'Подготовка к экзаменам',
        'tests.foreign_language': 'Иностранный язык',
        'tests.delete_test': 'Удалить тест',
        'tests.prepare_test': 'Подготовить тест',
        'tests.join_title': 'Присоединиться к тесту',
        'tests.search_title': 'Поиск теста',
        'tests.search_id_hint': 'Найти ID теста',
        'tests.join_help':
            'Вы можете начать тест, введя ID теста, которым поделился ваш учитель.',
        'tests.join_not_found':
            'Тест не найден.\nНе найден тест с введенным ID.',
        'tests.join_button': 'Присоединиться к тесту',
        'tests.no_shared': 'Нет общих тестов.',
        'tests.my_tests_title': 'Мои тесты',
        'tests.my_tests_empty':
            'Результаты не найдены.\nВы еще не создавали тесты.',
        'tests.completed_title': 'Вы завершили тест!',
        'tests.completed_body':
            'Вы можете посмотреть свой балл и соотношение правильных и неправильных ответов в разделе Мои результаты.',
        'tests.completed_short': 'Вы завершили тест!',
        'tests.action_select': 'Выбрать действие',
        'tests.action_select_body':
            'Если вы хотите выполнить действие для этого теста, выберите один из вариантов ниже.',
        'tests.copy_test_id': 'Скопировать ID теста',
        'tests.solve_title': 'Решить тест',
        'tests.delete_confirm':
            'Вы уверены, что хотите удалить этот тест?',
        'tests.id_copied': 'ID теста скопирован',
        'tests.share_test_id_text':
            'Тест @type\n\nСкачайте TurqApp, чтобы присоединиться к тесту. Ваш необходимый ID теста: @id\n\nПолучите приложение сейчас:\n\nAppStore: @appStore\nPlay Store: @playStore\n\nЧтобы присоединиться к тесту, введите ID теста с экрана Тесты в ученическом разделе и начните решать сразу.',
        'tests.type.middle_school': 'Средняя школа',
        'tests.type.high_school': 'Старшая школа',
        'tests.type.prep': 'Подготовка',
        'tests.type.language': 'Язык',
        'tests.type.branch': 'Направление',
        'tests.lesson.turkish': 'Турецкий',
        'tests.lesson.literature': 'Литература',
        'tests.lesson.math': 'Математика',
        'tests.lesson.geometry': 'Геометрия',
        'tests.lesson.physics': 'Физика',
        'tests.lesson.chemistry': 'Химия',
        'tests.lesson.biology': 'Биология',
        'tests.lesson.history': 'История',
        'tests.lesson.geography': 'География',
        'tests.lesson.philosophy': 'Философия',
        'tests.lesson.psychology': 'Психология',
        'tests.lesson.sociology': 'Социология',
        'tests.lesson.logic': 'Логика',
        'tests.lesson.religion': 'Религиозная культура',
        'tests.lesson.science': 'Естественные науки',
        'tests.lesson.revolution_history': 'История революции',
        'tests.lesson.foreign_language': 'Иностранный язык',
        'tests.lesson.basic_math': 'Базовая математика',
        'tests.lesson.social_sciences': 'Социальные науки',
        'tests.lesson.literature_social_1':
            'Литература - Социальные науки 1',
        'tests.lesson.social_sciences_2': 'Социальные науки 2',
        'tests.lesson.general_ability': 'Общие способности',
        'tests.lesson.general_culture': 'Общая культура',
        'tests.language.english': 'Английский',
        'tests.language.german': 'Немецкий',
        'tests.language.arabic': 'Арабский',
        'tests.language.french': 'Французский',
        'tests.language.russian': 'Русский',
        'tests.lesson_based_title': 'Тесты @type',
        'tests.none_in_category': 'Тестов нет',
        'tests.add_question': 'Добавить вопрос',
        'tests.no_questions_added':
            'Вопросы не найдены.\nДля этого теста пока не добавлено ни одного вопроса.',
        'tests.level_easy': 'Легко',
        'tests.title': 'Тесты',
        'tests.report_title': 'О тесте',
        'tests.report_wrong_answers':
            'В тесте есть неверные ответы',
        'tests.report_wrong_section':
            'Тест находится не в том разделе',
        'tests.question_content_failed':
            'Не удалось загрузить содержимое вопроса.\nПожалуйста, попробуйте снова.',
        'tests.capture_and_upload': 'Снять и загрузить',
        'tests.capture_and_upload_body':
            'Сфотографируйте вопрос, выберите правильный ответ и легко подготовьте его!',
        'tests.select_from_gallery': 'Выбрать из галереи',
        'tests.upload_from_camera': 'Загрузить с камеры',
        'tests.nsfw_check_failed':
            'Проверка безопасности изображения не может быть завершена.',
        'tests.nsfw_detected': 'Обнаружено неподходящее изображение.',
        'practice.title': 'Онлайн-экзамен',
        'practice.search_title': 'Поиск пробного экзамена',
        'practice.empty_title': 'Пробных экзаменов пока нет',
        'practice.empty_body':
            'Сейчас в системе нет пробных экзаменов. Новые экзамены появятся здесь после добавления.',
        'practice.search_empty_title':
            'По вашему запросу экзамен не найден',
        'practice.search_empty_body_empty':
            'Сейчас в системе нет пробных экзаменов. Новые экзамены появятся здесь после добавления.',
        'practice.search_empty_body_query':
            'Попробуйте другое ключевое слово.',
        'practice.results_title': 'Мои результаты экзаменов',
        'practice.saved_empty': 'Нет сохраненных пробных экзаменов.',
        'practice.preview_no_questions':
            'Для этого экзамена не найдено вопросов. Проверьте содержимое экзамена или добавьте новые вопросы.',
        'practice.preview_no_results':
            'Для этого экзамена не найдено результатов. Проверьте ответы или решите экзамен снова.',
        'practice.lesson_header': 'Предметы',
        'practice.answers_load_failed':
            'Не удалось загрузить ответы.',
        'practice.lesson_results_load_failed':
            'Не удалось загрузить результаты по предметам.',
        'practice.results_empty_title':
            'Вы еще не сдавали экзамен',
        'practice.results_empty_body':
            'Вы еще не участвовали ни в одном пробном экзамене. Результаты появятся здесь после участия.',
        'practice.published_empty':
            'Вы еще не публиковали онлайн-экзамен.',
        'practice.user_session_missing':
            'Сессия пользователя не найдена.',
        'practice.school_info_failed':
            'Не удалось загрузить данные школы.',
        'practice.load_failed': 'Не удалось загрузить данные.',
        'practice.slider_management': 'Управление слайдером',
        'practice.create_disabled_title':
            'Только для желтого значка и выше',
        'practice.create_disabled_body':
            'Чтобы создать онлайн-экзамен, нужен подтвержденный аккаунт с желтым значком или выше.',
        'practice.preview_title': 'Детали экзамена',
        'practice.report_exam': 'Пожаловаться на экзамен',
        'practice.user_load_failed':
            'Не удалось загрузить данные пользователя.',
        'practice.user_load_failed_body':
            'Не удалось загрузить данные пользователя. Повторите попытку или проверьте владельца экзамена.',
        'practice.invalidity_load_failed':
            'Не удалось загрузить статус недействительности.',
        'practice.cover_load_failed':
            'Не удалось загрузить обложку.',
        'practice.no_description':
            'Для этого экзамена не добавлено описание.',
        'practice.exam_info': 'Информация об экзамене',
        'practice.exam_type': 'Тип экзамена',
        'practice.exam_suffix': 'Экзамен @type',
        'practice.exam_datetime': 'Дата и время экзамена',
        'practice.exam_duration': 'Длительность экзамена',
        'practice.duration_minutes': '@minutes мин',
        'practice.application_count': 'Заявки',
        'practice.people_count': '@count человек',
        'practice.owner': 'Владелец экзамена',
        'practice.apply_now': 'Подать заявку',
        'practice.applied_short': 'Заявка подана',
        'practice.closed_starts_in':
            'Прием заявок закрыт.\nНачнется через @minutes мин.',
        'practice.started': 'Экзамен начался',
        'practice.start_now': 'Начать сейчас',
        'practice.finished_short': 'Экзамен завершен',
        'practice.not_started': 'Экзамен не начался',
        'practice.application_closed_title':
            'Прием заявок закрыт!',
        'practice.application_closed_body':
            'Прием заявок закрывается за 15 минут до начала экзамена.',
        'practice.not_applied_title': 'Вы не подали заявку!',
        'practice.not_applied_body':
            'Вы не можете участвовать без заявки. Участвовать могут только подавшие заявку.',
        'practice.not_allowed_title':
            'Вы не можете войти в экзамен!',
        'practice.not_allowed_body':
            'У вас нет доступа к этому экзамену. Ранее вы были признаны недействительным участником этого экзамена и не можете войти снова до его завершения.',
        'practice.finished_title': 'Экзамен завершен!',
        'practice.finished_body':
            'Вы можете подать заявку на следующие экзамены. Этот экзамен завершен.',
        'practice.result_unavailable':
            'Не удалось рассчитать результат.',
        'practice.result_summary':
            'Верно: @correct   •   Неверно: @wrong   •   Пусто: @blank   •   Нетто: @net',
        'practice.congrats_title': 'Поздравляем!',
        'practice.removed_title':
            'Вы были удалены с экзамена!',
        'practice.removed_body':
            'Мы предупреждали вас несколько раз. К сожалению, из-за нарушения правил ваш экзамен был признан недействительным.',
        'practice.applied_title': 'Ваша заявка получена!',
        'practice.applied_body':
            'Ваша заявка успешно получена. Сейчас от вас больше ничего не требуется.',
        'practice.apply_completed_title':
            'Ваша заявка завершена!',
        'practice.apply_completed_body':
            'Мы отправим вам напоминания перед экзаменом. Удачи!',
        'practice.apply_failed': 'Не удалось подать заявку.',
        'practice.application_check_failed':
            'Не удалось проверить заявку.',
        'practice.question_image_failed':
            'Не удалось загрузить изображение вопроса.',
        'practice.exam_started_title': 'Экзамен начался!',
        'practice.exam_started_body':
            'Мы верим, что ваша внимательность и усилия помогут вам добиться успеха. Удачи!',
        'practice.rules_title': 'Правила экзамена',
        'practice.rule_1':
            'Пожалуйста, отключите интернет на телефоне. После завершения экзамена вы сможете снова включить его и отправить ответы.',
        'practice.rule_2':
            'Если вы выйдете из экзамена, все ответы будут считаться недействительными, а результат не будет сохранен. Пожалуйста, хорошо подумайте перед подтверждением.',
        'practice.rule_3':
            'Если вы отправите приложение в фон, экзамен будет признан недействительным. Пожалуйста, не переводите приложение в фон.',
        'practice.start_exam': 'Начать экзамен',
        'practice.finish_exam': 'Завершить экзамен',
        'practice.background_warning':
            'В критических ситуациях, например при переводе приложения в фон, экзамен будет признан недействительным. Пожалуйста, будьте внимательны и соблюдайте правила.',
        'practice.questions_load_failed':
            'Не удалось загрузить вопросы.',
        'practice.answers_save_failed':
            'Не удалось сохранить ответы.',
        'past_questions.no_results': 'Результатов нет.',
        'past_questions.title': 'Пробные экзамены',
        'past_questions.mock_fallback': 'Пробный',
        'past_questions.search_empty':
            'Подходящих пробных экзаменов не найдено.',
        'past_questions.results_suffix': 'Результаты @title',
        'past_questions.local_result_summary':
            'Решено @count вопросов. Результат хранится локально; на этом экране показывается только итоговое нетто.',
        'past_questions.mock_label': 'Пробный @index',
        'past_questions.question_count': '@count Вопросов',
        'past_questions.net_label': 'Нетто',
        'past_questions.tests_by_year': 'Тесты @type @year',
        'past_questions.languages_title': 'Языки @type',
        'past_questions.tests_by_type': 'Тесты @type',
        'past_questions.select_exam': 'Выбрать экзамен',
        'past_questions.questions_title': 'Вопросы',
        'past_questions.continue_solving': 'Продолжить решать вопросы',
        'past_questions.oabt_short': 'ÖABT',
        'past_questions.exam_type.associate': 'Среднее специальное',
        'past_questions.exam_type.undergraduate': 'Бакалавриат',
        'past_questions.exam_type.middle_school': 'Среднее образование',
        'past_questions.branch.general_ability_culture':
            'Общие способности и общая культура',
        'past_questions.branch.group_a': 'Группа A',
        'past_questions.branch.education_sciences':
            'Педагогические науки',
        'past_questions.branch.field_knowledge': 'Профильные знания',
        'past_questions.sessions_by_year': 'Сессии @year',
        'past_questions.teaching.title': 'Преподавательские направления',
        'past_questions.teaching.suffix': 'преподавание',
        'past_questions.teaching.primary_math_short': 'Н. матем.',
        'past_questions.teaching.high_school_math_short': 'С. матем.',
        'past_questions.teaching.german': 'Преподавание немецкого',
        'past_questions.teaching.physical_education':
            'Преподавание физкультуры',
        'past_questions.teaching.biology': 'Преподавание биологии',
        'past_questions.teaching.geography': 'Преподавание географии',
        'past_questions.teaching.religious_culture':
            'Преподавание религиозной культуры',
        'past_questions.teaching.literature': 'Преподавание литературы',
        'past_questions.teaching.science': 'Преподавание естественных наук',
        'past_questions.teaching.physics': 'Преподавание физики',
        'past_questions.teaching.chemistry': 'Преподавание химии',
        'past_questions.teaching.high_school_math': 'Математика старшей школы',
        'past_questions.teaching.preschool': 'Дошкольное образование',
        'past_questions.teaching.guidance': 'Консультирование',
        'past_questions.teaching.social_studies':
            'Преподавание обществознания',
        'past_questions.teaching.classroom': 'Классное преподавание',
        'past_questions.teaching.history': 'Преподавание истории',
        'past_questions.teaching.turkish': 'Преподавание турецкого',
        'past_questions.teaching.primary_math': 'Математика начальной школы',
        'past_questions.teaching.imam_hatip': 'Имам хатип',
        'past_questions.teaching.english': 'Преподавание английского',
        'social_links.label_title': 'Заголовок',
        'social_links.username_hint': 'Имя пользователя',
        'social_links.remove_title': 'Удалить ссылку',
        'social_links.remove_message':
            'Вы уверены, что хотите удалить эту ссылку?',
        'social_links.save_permission_error':
            'Ошибка доступа: у вас нет прав для сохранения ссылки.',
        'social_links.save_failed': 'Произошла ошибка.',
        'post_creator.title_new': 'Подготовить публикацию',
        'post_creator.title_edit': 'Редактировать публикацию',
        'post_creator.publish': 'Опубликовать',
        'post_creator.uploading': 'Загрузка...',
        'post_creator.saving': 'Сохранение...',
        'post_creator.placeholder': 'Что нового?',
        'post_creator.processing_wait':
            'Пожалуйста, подождите. Видео обрабатывается...',
        'post_creator.video_processing': 'Обработка видео',
        'post_creator.look.original': 'Оригинал',
        'post_creator.look.clear': 'Чистый',
        'post_creator.look.cinema': 'Кино',
        'post_creator.look.vibe': 'Яркий',
        'post_creator.comments.everyone': 'Все',
        'post_creator.comments.verified': 'Подтвержденные аккаунты',
        'post_creator.comments.following': 'Аккаунты, на которые вы подписаны',
        'post_creator.comments.closed': 'Комментарии отключены',
        'post_creator.comments.title': 'Кто может ответить?',
        'post_creator.comments.subtitle':
            'Выберите, кто может отвечать на эту публикацию.',
        'post_creator.reshare.everyone': 'Все',
        'post_creator.reshare.verified': 'Подтвержденные аккаунты',
        'post_creator.reshare.following': 'Аккаунты, на которые вы подписаны',
        'post_creator.reshare.closed': 'Репост отключен',
        'post_creator.reshare_privacy_title':
            'Конфиденциальность репоста',
        'post_creator.reshare_everyone_desc':
            'Все могут делать репост.',
        'post_creator.reshare_followers_desc':
            'Только мои подписчики могут делать репост.',
        'post_creator.reshare_closed_desc':
            'Репост отключен.',
        'post_creator.warning_title': 'Предупреждение',
        'post_creator.success_title': 'Успешно!',
        'pasaj.closed': 'Pasaj сейчас закрыт',
        'pasaj.common.my_applications': 'Мои заявки',
        'pasaj.common.post_listing': 'Разместить объявление',
        'pasaj.common.all_turkiye': 'Вся Турция',
        'pasaj.job_finder.tab.explore': 'Обзор',
        'pasaj.job_finder.tab.create': 'Создать объявление',
        'pasaj.job_finder.tab.applications': 'Мои отклики',
        'pasaj.job_finder.tab.career_profile': 'Карьерный профиль',
        'pasaj.tabs.market': 'Мобильный рынок',
        'pasaj.tabs.practice_exams': 'Экзамены',
        'pasaj.tabs.tutoring': 'Частные уроки',
        'pasaj.tabs.job_finder': 'Работа',
        'pasaj.job_finder.title': 'Работа',
        'pasaj.job_finder.search_hint': 'Какую работу вы ищете?',
        'pasaj.job_finder.nearby_listings':
            'Ближайшие к вам объявления',
        'pasaj.job_finder.no_search_result':
            'По вашему запросу ничего не найдено',
        'pasaj.job_finder.no_city_listing':
            'В вашем городе пока нет объявлений',
        'pasaj.job_finder.sort_high_salary': 'Высокая зарплата',
        'pasaj.job_finder.sort_low_salary': 'Низкая зарплата',
        'pasaj.job_finder.sort_nearest': 'Ближе всего',
        'pasaj.job_finder.career_profile': 'Карьерный профиль',
        'pasaj.job_finder.detail_title': 'Детали объявления',
        'pasaj.job_finder.no_description':
            'Для этого объявления описание не добавлено.',
        'pasaj.job_finder.job_info': 'Описание работы',
        'pasaj.job_finder.listing_info': 'Информация об объявлении',
        'pasaj.job_finder.application_count': 'Количество заявок',
        'pasaj.job_finder.work_type': 'Тип работы',
        'pasaj.job_finder.work_days': 'Рабочие дни',
        'pasaj.job_finder.work_hours': 'Рабочие часы',
        'pasaj.job_finder.personnel_count':
            'Количество сотрудников для найма',
        'pasaj.job_finder.benefits': 'Преимущества',
        'pasaj.job_finder.passive': 'Пассивно',
        'pasaj.job_finder.salary_not_specified': 'Не указано',
        'pasaj.job_finder.edit_listing': 'Редактировать',
        'pasaj.job_finder.applications': 'Заявки',
        'pasaj.job_finder.apply': 'Откликнуться',
        'pasaj.job_finder.applied': 'Заявка отправлена',
        'pasaj.job_finder.cv_required': 'Требуется резюме',
        'pasaj.job_finder.cv_required_body':
            'Вам нужно заполнить резюме перед откликом.',
        'pasaj.job_finder.create_cv': 'Создать резюме',
        'pasaj.job_finder.application_sent':
            'Ваша заявка отправлена.',
        'pasaj.job_finder.application_failed':
            'Возникла проблема при отправке заявки.',
        'pasaj.job_finder.finding_platform':
            'Платформа поиска работы',
        'pasaj.job_finder.looking_for_job': 'Ищу работу',
        'pasaj.job_finder.professional_profile':
            'Профессиональный профиль',
        'pasaj.job_finder.experience': 'Опыт работы',
        'pasaj.job_finder.education': 'Образование',
        'pasaj.job_finder.languages': 'Языки',
        'pasaj.job_finder.skills': 'Навыки',
        'pasaj.market.title': 'Маркет',
        'pasaj.market.contact_phone': 'Телефон',
        'pasaj.market.contact_message': 'Сообщение',
        'pasaj.market.all_listings': 'Все объявления',
        'pasaj.market.main_categories': 'Основные категории',
        'pasaj.market.category_search_hint':
            'Искать основную категорию, подкатегорию, бренд',
        'pasaj.market.call_now': 'Позвонить сейчас',
        'pasaj.market.inspect': 'Посмотреть',
        'pasaj.market.empty_filtered':
            'По этому фильтру объявления не найдены.',
        'pasaj.market.add_listing': 'Добавить объявление',
        'pasaj.market.my_listings': 'Мои объявления',
        'pasaj.market.saved_items': 'Избранное',
        'pasaj.market.my_offers': 'Мои предложения',
        'pasaj.market.detail_title': 'Детали объявления',
        'pasaj.market.report_listing': 'Пожаловаться на объявление',
        'pasaj.market.no_description':
            'Для этого объявления описание не добавлено.',
        'pasaj.market.listing_info': 'Информация об объявлении',
        'pasaj.market.saved_count': 'Сохранений',
        'pasaj.market.offer_count': 'Предложения',
        'pasaj.market.messages': 'Сообщения',
        'pasaj.market.offers': 'Предложения',
        'pasaj.market.related_listings': 'Похожие объявления',
        'pasaj.market.no_related':
            'В этой категории другие объявления не найдены.',
        'pasaj.market.custom_offer':
            'Укажите свою цену сами',
        'pasaj.market.reviews': 'Отзывы',
        'pasaj.market.rate': 'Оценить',
        'pasaj.job_finder.no_applications':
            'Вы еще не откликались ни на одно объявление',
        'pasaj.job_finder.default_job_title': 'Вакансия',
        'pasaj.job_finder.default_company': 'Компания',
        'pasaj.job_finder.cancel_apply_title':
            'Отменить отклик',
        'pasaj.job_finder.cancel_apply_body':
            'Вы уверены, что хотите отменить этот отклик?',
        'pasaj.job_finder.saved_jobs': 'Сохраненные',
        'pasaj.job_finder.no_saved_jobs':
            'Нет сохраненных объявлений.',
        'pasaj.job_finder.my_ads': 'Мои объявления',
        'pasaj.job_finder.published_tab': 'Опубликованные',
        'pasaj.job_finder.expired_tab': 'Истекшие',
        'pasaj.job_finder.no_my_ads':
            'Объявления не найдены',
        'pasaj.job_finder.finding_how':
            'Как работает платформа поиска работы?',
        'pasaj.job_finder.finding_body':
            'Ваше резюме передается работодателям с вашего согласия. До публикации объявления работодатели могут через нашу систему просматривать подходящих кандидатов для своих открытых позиций. Так работодатели быстрее находят нужных сотрудников, а соискатели быстрее получают доступ к возможностям. Наша цель - сделать процесс найма быстрее и эффективнее для обеих сторон.',
        'pasaj.job_finder.edit_cv': 'Редактировать резюме',
        'pasaj.job_finder.no_cv_title':
            'Вы еще не создали резюме',
        'pasaj.job_finder.no_cv_body':
            'Создайте резюме, чтобы ускорить отклики',
        'pasaj.job_finder.applicants': 'Кандидаты',
        'pasaj.job_finder.no_applicants':
            'Пока нет заявок',
        'pasaj.job_finder.unknown_user': 'Неизвестный пользователь',
        'pasaj.job_finder.view_cv': 'Открыть резюме',
        'pasaj.job_finder.review': 'Рассмотреть',
        'pasaj.job_finder.accept': 'Принять',
        'pasaj.job_finder.reject': 'Отклонить',
        'pasaj.job_finder.cv_not_found_title':
            'Резюме не найдено',
        'pasaj.job_finder.cv_not_found_body':
            'Для этого пользователя не найдено сохраненное резюме.',
        'pasaj.job_finder.status.pending': 'Ожидает',
        'pasaj.job_finder.status.reviewing': 'На рассмотрении',
        'pasaj.job_finder.status.accepted': 'Принята',
        'pasaj.job_finder.status.rejected': 'Отклонена',
        'pasaj.job_finder.status_updated':
            'Статус заявки обновлен.',
        'pasaj.job_finder.status_update_failed':
            'Не удалось обновить статус заявки.',
        'pasaj.job_finder.relogin_required':
            'Пожалуйста, войдите снова, чтобы продолжить.',
        'pasaj.job_finder.save_failed':
            'Не удалось завершить сохранение.',
        'pasaj.job_finder.share_auth_required':
            'Делиться могут только админы и владельцы объявления.',
        'pasaj.job_finder.review_relogin_required':
            'Пожалуйста, войдите снова, чтобы оставить отзыв.',
        'pasaj.job_finder.review_own_forbidden':
            'Вы не можете оценивать свое объявление.',
        'pasaj.job_finder.review_saved':
            'Ваш отзыв сохранен.',
        'pasaj.job_finder.review_save_failed':
            'Не удалось сохранить отзыв.',
        'pasaj.job_finder.review_deleted':
            'Ваш отзыв удален.',
        'pasaj.job_finder.review_delete_failed':
            'Не удалось удалить отзыв.',
        'pasaj.job_finder.open_in_maps': 'Открыть в Картах',
        'pasaj.job_finder.open_google_maps':
            'Открыть в Google Maps',
        'pasaj.job_finder.open_apple_maps':
            'Открыть в Apple Maps',
        'pasaj.job_finder.open_yandex_maps':
            'Открыть в Yandex Maps',
        'pasaj.job_finder.map_load_failed':
            'Не удалось загрузить карту',
        'pasaj.job_finder.open_maps_help':
            'Нажмите, чтобы открыть местоположение в Картах.',
        'pasaj.job_finder.listing_not_found':
            'Объявление не найдено',
        'pasaj.job_finder.reactivated':
            'Объявление снова опубликовано.',
        'pasaj.job_finder.sort_title': 'Сортировка',
        'pasaj.job_finder.sort_newest': 'Сначала новые',
        'pasaj.job_finder.sort_nearest_me': 'Рядом со мной',
        'pasaj.job_finder.sort_most_viewed': 'Самые просматриваемые',
        'pasaj.job_finder.clear_filters': 'Очистить фильтры',
        'pasaj.job_finder.select_city': 'Выбрать город',
        'pasaj.market.saved_success': 'Объявление сохранено.',
        'pasaj.market.unsaved':
            'Объявление удалено из сохраненных.',
        'pasaj.market.save_failed':
            'Не удалось завершить сохранение.',
        'pasaj.market.report_received_title':
            'Ваше сообщение получено!',
        'pasaj.market.report_received_body':
            'Объявление отправлено на проверку. Спасибо.',
        'pasaj.market.report_failed':
            'Не удалось отправить жалобу на объявление.',
        'pasaj.market.invalid_offer':
            'Выберите корректное предложение.',
        'pasaj.market.offer_sent': 'Предложение отправлено.',
        'pasaj.market.offer_own_forbidden':
            'Нельзя делать предложение на собственное объявление.',
        'pasaj.market.offer_daily_limit':
            'Вы можете отправлять не более 20 предложений в день.',
        'pasaj.market.offer_failed':
            'Не удалось отправить предложение.',
        'pasaj.market.review_edit': 'Редактировать',
        'pasaj.market.no_reviews':
            'Пока нет отзывов.',
        'pasaj.market.sign_in_to_review':
            'Войдите, чтобы оставить отзыв.',
        'pasaj.market.review_comment_hint':
            'Напишите комментарий',
        'pasaj.market.select_rating':
            'Пожалуйста, выберите оценку.',
        'pasaj.market.review_saved':
            'Ваш отзыв сохранен.',
        'pasaj.market.review_updated':
            'Ваш отзыв обновлен.',
        'pasaj.market.review_own_forbidden':
            'Вы не можете оценивать свое объявление.',
        'pasaj.market.review_failed':
            'Не удалось отправить отзыв.',
        'pasaj.market.review_deleted':
            'Ваш отзыв удален.',
        'pasaj.market.review_delete_failed':
            'Не удалось удалить отзыв.',
        'pasaj.market.location_missing':
            'Местоположение не указано',
        'pasaj.market.status.sold': 'Продано',
        'pasaj.market.status.draft': 'Черновик',
        'pasaj.market.status.archived': 'Архивировано',
        'pasaj.market.status.reserved': 'Зарезервировано',
        'pasaj.market.status.active': 'Активно',
      });

    return base;
  }
}
