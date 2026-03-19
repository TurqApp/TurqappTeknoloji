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
          'saved_posts.no_saved_posts': 'Kaydedilen gönderi yok',
          'saved_posts.no_saved_series': 'Kaydedilen dizi yok',
          'blocked_users.empty': 'Hiç kimseyi engellemedin',
          'blocked_users.unblock': 'Engeli Kaldır',
          'interests.personalize_feed': 'Akışını kişiselleştir',
          'interests.selection_range':
              'En az {min}, en fazla {max} ilgi alanı seç.',
          'interests.selected_count': '{selected}/{max} seçildi',
          'interests.ready': 'Hazır',
          'interests.search_hint': 'İlgi alanı ara',
          'pasaj.closed': 'Pasaj şu anda kapalı',
          'pasaj.common.slider_admin': 'Slider Yönetimi',
          'pasaj.common.my_results': 'Sonuçlarım',
          'pasaj.common.published': 'Yayınladıklarım',
          'pasaj.common.my_applications': 'Başvurularım',
          'pasaj.common.post_listing': 'İlan Ver',
          'pasaj.common.all_turkiye': 'Tüm Türkiye',
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
          'common.edit': 'Düzenle',
          'common.update': 'Güncelle',
          'common.publish': 'Yayınla',
          'common.loading': 'Yükleniyor...',
          'common.info': 'Bilgi',
          'common.error': 'Hata',
          'common.message': 'Mesaj',
          'common.phone': 'Telefon',
          'common.description': 'Açıklama',
          'common.location': 'Konum',
          'common.category': 'Kategori',
          'common.status': 'Durum',
          'common.features': 'Özellikler',
          'common.contact': 'İletişim',
          'common.city': 'Şehir',
          'common.district': 'İlçe',
          'common.price': 'Fiyat',
          'common.views': 'Görüntülenme',
          'common.company': 'Şirket',
          'common.salary': 'Ücret',
          'common.address': 'Adres',
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
          'post_creator.use_address': 'Bu adresi kullan',
          'post_creator.poll_title': 'Anket',
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
          'post_creator.uploading_media': 'Medya dosyaları yükleniyor...',
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
          'saved_posts.no_saved_posts': 'No saved posts',
          'saved_posts.no_saved_series': 'No saved series',
          'blocked_users.empty': 'You have not blocked anyone',
          'blocked_users.unblock': 'Remove Block',
          'interests.personalize_feed': 'Personalize your feed',
          'interests.selection_range':
              'Select at least {min} and at most {max} interests.',
          'interests.selected_count': '{selected}/{max} selected',
          'interests.ready': 'Ready',
          'interests.search_hint': 'Search interests',
          'pasaj.closed': 'Pasaj is currently closed',
          'pasaj.common.slider_admin': 'Slider Management',
          'pasaj.common.my_results': 'My Results',
          'pasaj.common.published': 'Published',
          'pasaj.common.my_applications': 'My Applications',
          'pasaj.common.post_listing': 'Post Listing',
          'pasaj.common.all_turkiye': 'All Turkey',
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
          'common.edit': 'Edit',
          'common.update': 'Update',
          'common.publish': 'Publish',
          'common.loading': 'Loading...',
          'common.info': 'Info',
          'common.error': 'Error',
          'common.message': 'Message',
          'common.phone': 'Phone',
          'common.description': 'Description',
          'common.location': 'Location',
          'common.category': 'Category',
          'common.status': 'Status',
          'common.features': 'Features',
          'common.contact': 'Contact',
          'common.city': 'City',
          'common.district': 'District',
          'common.price': 'Price',
          'common.views': 'Views',
          'common.company': 'Company',
          'common.salary': 'Salary',
          'common.address': 'Address',
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
          'post_creator.use_address': 'Use this address',
          'post_creator.poll_title': 'Poll',
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
          'post_creator.uploading_media': 'Uploading media files...',
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
          'saved_posts.no_saved_posts': 'Keine gespeicherten Beiträge',
          'saved_posts.no_saved_series': 'Keine gespeicherten Serien',
          'blocked_users.empty': 'Du hast niemanden blockiert',
          'blocked_users.unblock': 'Blockierung aufheben',
          'interests.personalize_feed': 'Personalisiere deinen Feed',
          'interests.selection_range':
              'Wähle mindestens {min} und höchstens {max} Interessen aus.',
          'interests.selected_count': '{selected}/{max} ausgewählt',
          'interests.ready': 'Bereit',
          'interests.search_hint': 'Interessen suchen',
          'pasaj.closed': 'Pasaj ist derzeit geschlossen',
          'pasaj.common.slider_admin': 'Slider-Verwaltung',
          'pasaj.common.my_results': 'Meine Ergebnisse',
          'pasaj.common.published': 'Veröffentlichte',
          'pasaj.common.my_applications': 'Meine Bewerbungen',
          'pasaj.common.post_listing': 'Inserat erstellen',
          'pasaj.common.all_turkiye': 'Ganz Türkei',
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
          'common.edit': 'Bearbeiten',
          'common.update': 'Aktualisieren',
          'common.publish': 'Veröffentlichen',
          'common.loading': 'Wird geladen...',
          'common.info': 'Info',
          'common.error': 'Fehler',
          'common.message': 'Nachricht',
          'common.phone': 'Telefon',
          'common.description': 'Beschreibung',
          'common.location': 'Standort',
          'common.category': 'Kategorie',
          'common.status': 'Status',
          'common.features': 'Merkmale',
          'common.contact': 'Kontakt',
          'common.city': 'Stadt',
          'common.district': 'Bezirk',
          'common.price': 'Preis',
          'common.views': 'Aufrufe',
          'common.company': 'Unternehmen',
          'common.salary': 'Gehalt',
          'common.address': 'Adresse',
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
          'post_creator.use_address': 'Diese Adresse verwenden',
          'post_creator.poll_title': 'Umfrage',
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
          'post_creator.uploading_media':
              'Mediendateien werden hochgeladen...',
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
