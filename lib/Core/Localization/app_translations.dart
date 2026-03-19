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
          'common.delete': 'Sil',
          'common.search': 'Ara',
          'common.create': 'Oluştur',
          'common.saved': 'Kaydedilenler',
          'common.clear': 'Temizle',
          'common.share': 'Paylaş',
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
          'common.remove': 'Kaldır',
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
          'social_profile.private_follow_to_see_posts':
              'Gönderileri görmek için takip et.',
          'social_profile.blocked_user': 'Bu kullanıcıyı engellediniz',
          'profile.no_posts': 'Gönderi Yok',
          'profile.no_photos': 'Fotoğraf Yok',
          'profile.no_videos': 'Video Yok',
          'profile.no_reshares': 'Yeniden paylaşım yok',
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
          'common.download': 'İndir',
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
          'short.next_post': 'Sonraki Gönderiye Geç',
          'short.publish_as_post': 'Gönderi olarak yayınla',
          'short.add_to_story': 'Hikayene ekle',
          'short.shared_as_post_by': 'Gönderi olarak paylaşanlar',
          'story.seens_title': 'Görüntüleme (@count)',
          'story.no_seens': 'Kimse hikayeni görüntülemedi',
          'story.comments_title': 'Yorumlar (@count)',
          'story.no_comments': 'Kimse yorum yapmadı',
          'story.add_comment_for': '@nickname için yorum ekle..',
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
          'scholarship.applications_title': 'Başvurular (@count)',
          'scholarship.no_applications': 'Henüz başvuru bulunmamaktadır',
          'scholarship.my_listings': 'Burs İlanlarım',
          'scholarship.no_my_listings': 'Burs İlanınız Bulunmamaktadır!',
          'scholarship.applications_suffix': '@title BURS BAŞVURULARI',
          'single_post.title': 'Gönderiler',
          'edit_post.updating': 'Lütfen Bekle. Gönderiniz güncelleniyor',
          'common.district': 'İlçe',
          'common.price': 'Fiyat',
          'common.views': 'Görüntülenme',
          'common.company': 'Şirket',
          'common.salary': 'Ücret',
          'common.address': 'Adres',
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
          'common.delete': 'Delete',
          'common.search': 'Search',
          'common.create': 'Create',
          'common.saved': 'Saved',
          'common.clear': 'Clear',
          'common.share': 'Share',
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
          'common.remove': 'Remove',
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
          'social_profile.private_follow_to_see_posts':
              'Follow this account to view posts.',
          'social_profile.blocked_user': 'You blocked this user',
          'profile.no_posts': 'No Posts',
          'profile.no_photos': 'No Photos',
          'profile.no_videos': 'No Videos',
          'profile.no_reshares': 'No reshares',
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
          'common.download': 'Download',
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
          'short.next_post': 'Go to next post',
          'short.publish_as_post': 'Publish as post',
          'short.add_to_story': 'Add to your story',
          'short.shared_as_post_by': 'Shared as posts by',
          'story.seens_title': 'Views (@count)',
          'story.no_seens': 'No one has viewed your story yet',
          'story.comments_title': 'Comments (@count)',
          'story.no_comments': 'No one has commented yet',
          'story.add_comment_for': 'Add a comment for @nickname..',
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
          'scholarship.applications_title': 'Applications (@count)',
          'scholarship.no_applications': 'There are no applications yet',
          'scholarship.my_listings': 'My Scholarship Listings',
          'scholarship.no_my_listings': 'You do not have any scholarship listings!',
          'scholarship.applications_suffix': '@title SCHOLARSHIP APPLICATIONS',
          'single_post.title': 'Posts',
          'edit_post.updating': 'Please wait. Your post is being updated',
          'common.district': 'District',
          'common.price': 'Price',
          'common.views': 'Views',
          'common.company': 'Company',
          'common.salary': 'Salary',
          'common.address': 'Address',
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
          'common.delete': 'Löschen',
          'common.search': 'Suchen',
          'common.create': 'Erstellen',
          'common.saved': 'Gespeichert',
          'common.clear': 'Zurücksetzen',
          'common.share': 'Teilen',
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
          'common.remove': 'Entfernen',
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
          'common.download': 'Herunterladen',
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
          'short.next_post': 'Zum nächsten Beitrag',
          'short.publish_as_post': 'Als Beitrag veröffentlichen',
          'short.add_to_story': 'Zu deiner Story hinzufügen',
          'short.shared_as_post_by': 'Als Beitrag geteilt von',
          'story.seens_title': 'Aufrufe (@count)',
          'story.no_seens': 'Niemand hat deine Story angesehen',
          'story.comments_title': 'Kommentare (@count)',
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
          'story_music.title': 'Musik',
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
          'scholarship.applications_title': 'Bewerbungen (@count)',
          'scholarship.no_applications': 'Es gibt noch keine Bewerbungen',
          'scholarship.my_listings': 'Meine Stipendienanzeigen',
          'scholarship.no_my_listings': 'Du hast keine Stipendienanzeigen!',
          'scholarship.applications_suffix': '@title STIPENDIENBEWERBUNGEN',
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
        'common.delete': 'Supprimer',
        'common.search': 'Rechercher',
        'common.create': 'Creer',
        'common.saved': 'Enregistre',
        'common.clear': 'Effacer',
        'common.share': 'Partager',
        'common.user': 'Utilisateur',
        'common.info': 'Info',
        'common.cancel': 'Annuler',
        'common.close': 'Fermer',
        'profile_photo.camera': 'Prendre une photo',
        'profile_photo.gallery': 'Choisir dans la galerie',
        'common.now': 'maintenant',
        'common.download': 'Telecharger',
        'common.copy_link': 'Copier le lien',
        'common.copied': 'Copie',
        'common.link_copied': 'Le lien a ete copie dans le presse-papiers',
        'common.archive': 'Archiver',
        'common.unarchive': 'Retirer des archives',
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
        'short.next_post': 'Passer a la publication suivante',
        'short.publish_as_post': 'Publier comme post',
        'short.add_to_story': 'Ajouter a votre story',
        'short.shared_as_post_by': 'Partage comme publication par',
        'story.seens_title': 'Vues (@count)',
        'story.no_seens': 'Personne n a vu votre story',
        'story.comments_title': 'Commentaires (@count)',
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
        'scholarship.applications_title': 'Candidatures (@count)',
        'scholarship.no_applications': 'Aucune candidature pour le moment',
        'scholarship.my_listings': 'Mes annonces de bourse',
        'scholarship.no_my_listings':
            'Vous n avez aucune annonce de bourse !',
        'scholarship.applications_suffix': 'CANDIDATURES BOURSE @title',
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
        'common.delete': 'Elimina',
        'common.search': 'Cerca',
        'common.create': 'Crea',
        'common.saved': 'Salvato',
        'common.clear': 'Pulisci',
        'common.share': 'Condividi',
        'common.user': 'Utente',
        'common.info': 'Info',
        'common.cancel': 'Annulla',
        'common.close': 'Chiudi',
        'profile_photo.camera': 'Scatta una foto',
        'profile_photo.gallery': 'Scegli dalla galleria',
        'common.now': 'ora',
        'common.download': 'Scarica',
        'common.copy_link': 'Copia link',
        'common.copied': 'Copiato',
        'common.link_copied': 'Il link e stato copiato negli appunti',
        'common.archive': 'Archivia',
        'common.unarchive': 'Rimuovi dall archivio',
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
        'short.next_post': 'Vai al post successivo',
        'short.publish_as_post': 'Pubblica come post',
        'short.add_to_story': 'Aggiungi alla tua storia',
        'short.shared_as_post_by': 'Condiviso come post da',
        'story.seens_title': 'Visualizzazioni (@count)',
        'story.no_seens': 'Nessuno ha visto la tua storia',
        'story.comments_title': 'Commenti (@count)',
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
        'scholarship.applications_title': 'Candidature (@count)',
        'scholarship.no_applications': 'Non ci sono ancora candidature',
        'scholarship.my_listings': 'I miei annunci di borsa',
        'scholarship.no_my_listings':
            'Non hai alcun annuncio di borsa!',
        'scholarship.applications_suffix': 'CANDIDATURE BORSA @title',
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
        'common.delete': 'Удалить',
        'common.search': 'Поиск',
        'common.create': 'Создать',
        'common.saved': 'Сохранено',
        'common.clear': 'Очистить',
        'common.share': 'Поделиться',
        'common.user': 'Пользователь',
        'common.info': 'Инфо',
        'common.cancel': 'Отмена',
        'common.close': 'Закрыть',
        'profile_photo.camera': 'Сделать фото',
        'profile_photo.gallery': 'Выбрать из галереи',
        'common.now': 'сейчас',
        'common.download': 'Скачать',
        'common.copy_link': 'Копировать ссылку',
        'common.copied': 'Скопировано',
        'common.link_copied': 'Ссылка скопирована в буфер обмена',
        'common.archive': 'Архивировать',
        'common.unarchive': 'Убрать из архива',
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
        'short.next_post': 'Перейти к следующему посту',
        'short.publish_as_post': 'Опубликовать как пост',
        'short.add_to_story': 'Добавить в историю',
        'short.shared_as_post_by': 'Поделившиеся как постом',
        'story.seens_title': 'Просмотры (@count)',
        'story.no_seens': 'Никто не посмотрел вашу историю',
        'story.comments_title': 'Комментарии (@count)',
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
        'scholarship.applications_title': 'Заявки (@count)',
        'scholarship.no_applications': 'Пока нет заявок',
        'scholarship.my_listings': 'Мои объявления о стипендии',
        'scholarship.no_my_listings':
            'У вас нет объявлений о стипендии!',
        'scholarship.applications_suffix': 'ЗАЯВКИ НА СТИПЕНДИЮ @title',
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
