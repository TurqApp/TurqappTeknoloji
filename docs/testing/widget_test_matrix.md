# Widget Test Matrix

Generated from `tool/generate_widget_test_matrix.dart`.

## Summary

- Total widget classes: 409
- Public widget classes: 347
- Private widget classes: 62
- Directly referenced by current widget tests: 14
- Planned / not yet directly covered: 395

## Tier Definitions

- `P0`: core user surfaces; requires render, interaction, semantics, text-scale, and platform variation
- `P1`: important secondary widgets; requires render, interaction, semantics
- `P2`: support widgets; requires render and semantics at minimum

## Matrix

| Status | Tier | Widget | Type | Module | Path | Existing widget tests | Required checks |
| --- | --- | --- | --- | --- | --- | --- | --- |
| planned | P0 | `ChatCameraCaptureView` | StatefulWidget | Core/Camera | `lib/Core/Camera/chat_camera_capture_view.dart` | — | render, semantics, interaction |
| planned | P0 | `ImagePreview` | StatefulWidget | Core/Helpers | `lib/Core/Helpers/ImagePreview/image_preview.dart` | — | render, semantics, interaction |
| planned | P0 | `QrScannerView` | StatefulWidget | Core/Helpers | `lib/Core/Helpers/QRCode/qr_scanner_view.dart` | — | render, semantics, interaction |
| planned | P0 | `LocationFinderView` | StatefulWidget | Core/LocationFinderView | `lib/Core/LocationFinderView/location_finder_view.dart` | — | render, semantics, interaction |
| planned | P0 | `SliderAdminView` | StatefulWidget | Core/Slider | `lib/Core/Slider/slider_admin_view.dart` | — | render, semantics, interaction |
| planned | P0 | `PostViewTracker` | StatefulWidget | Core/Widgets | `lib/Core/Widgets/post_interaction_widget.dart` | — | render, semantics, interaction, textScale |
| covered | P0 | `FullScreenImageViewer` | StatelessWidget | Core/full_screen_image_viewer.dart | `lib/Core/full_screen_image_viewer.dart` | `test/widget/p0/full_screen_image_viewer_widget_test.dart` | render, semantics |
| planned | P0 | `AgendaView` | StatelessWidget | Modules/Agenda | `lib/Modules/Agenda/agenda_view.dart` | — | render, semantics, interaction, textScale, platform |
| covered | P0 | `FeedCreateFab` | StatelessWidget | Modules/Agenda | `lib/Modules/Agenda/widgets/feed_create_fab.dart` | `test/widget/components/feed_header_actions_widget_test.dart` | render, semantics, interaction, textScale, platform |
| covered | P0 | `FeedInboxActionsRow` | StatelessWidget | Modules/Agenda | `lib/Modules/Agenda/widgets/feed_inbox_actions_row.dart` | `test/widget/components/feed_header_actions_widget_test.dart`<br>`test/widget/flows/accessibility_semantics_smoke_test.dart` | render, semantics, interaction, textScale, platform |
| planned | P0 | `FloodListing` | StatefulWidget | Modules/Agenda | `lib/Modules/Agenda/FloodListing/flood_listing.dart` | — | render, semantics, interaction, textScale, platform |
| covered | P0 | `PostArchivedMessage` | StatelessWidget | Modules/Agenda | `lib/Modules/Agenda/Components/post_state_messages.dart` | `test/widget/p0/post_state_messages_widget_test.dart` | render, semantics, interaction, textScale, platform |
| planned | P0 | `PostContentBase` | StatefulWidget | Modules/Agenda | `lib/Modules/Agenda/Common/post_content_base.dart` | — | render, semantics, interaction, textScale, platform |
| covered | P0 | `PostDeletedMessage` | StatelessWidget | Modules/Agenda | `lib/Modules/Agenda/Components/post_state_messages.dart` | `test/widget/p0/post_state_messages_widget_test.dart` | render, semantics, interaction, textScale, platform |
| covered | P0 | `PostHiddenMessage` | StatelessWidget | Modules/Agenda | `lib/Modules/Agenda/Components/post_state_messages.dart` | `test/widget/p0/post_state_messages_widget_test.dart` | render, semantics, interaction, textScale, platform |
| planned | P0 | `PostLikeContent` | StatefulWidget | Modules/Agenda | `lib/Modules/Agenda/PostLikeListing/PostLikeContent/post_like_content.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `PostLikeListing` | StatefulWidget | Modules/Agenda | `lib/Modules/Agenda/PostLikeListing/post_like_listing.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `PostReshareContent` | StatefulWidget | Modules/Agenda | `lib/Modules/Agenda/PostReshareListing/PostReshareContent/post_reshare_content.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `PostReshareListing` | StatefulWidget | Modules/Agenda | `lib/Modules/Agenda/PostReshareListing/post_reshare_listing.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `ReshareAttribution` | StatefulWidget | Modules/Agenda | `lib/Modules/Agenda/Common/reshare_attribution.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `SinglePost` | StatefulWidget | Modules/Agenda | `lib/Modules/Agenda/SinglePost/single_post.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `SmartMiniVideoPlayer` | StatefulWidget | Modules/Agenda | `lib/Modules/Agenda/TagPosts/tag_media_widgets.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `TagPosts` | StatefulWidget | Modules/Agenda | `lib/Modules/Agenda/TagPosts/tag_posts.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `TopTags` | StatefulWidget | Modules/Agenda | `lib/Modules/Agenda/TopTags/top_tags.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_DeferredNotificationInboxActions` | StatefulWidget | Modules/Agenda | `lib/Modules/Agenda/agenda_view_header_part.dart` | — | render, semantics, interaction, textScale, platform |
| covered | P0 | `ChatListing` | StatefulWidget | Modules/Chat | `lib/Modules/Chat/ChatListing/chat_listing.dart` | `test/widget/screens/chat_search_widget_test.dart` | render, semantics, interaction, textScale, platform |
| planned | P0 | `ChatListingContent` | StatelessWidget | Modules/Chat | `lib/Modules/Chat/ChatListingContent/chat_listing_content.dart` | — | render, semantics, interaction, textScale, platform |
| covered | P0 | `ChatSearchField` | StatelessWidget | Modules/Chat | `lib/Modules/Chat/ChatListing/chat_search_field.dart` | `test/widget/screens/chat_search_widget_test.dart` | render, semantics, interaction, textScale, platform |
| planned | P0 | `ChatView` | StatelessWidget | Modules/Chat | `lib/Modules/Chat/chat.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `CreateChat` | StatefulWidget | Modules/Chat | `lib/Modules/Chat/CreateChat/create_chat.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `CreateChatContent` | StatefulWidget | Modules/Chat | `lib/Modules/Chat/CreateChat/CreateChatContent/create_chat_content.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `LocationShareViewChat` | StatefulWidget | Modules/Chat | `lib/Modules/Chat/LocationShareView/location_share_view_chat.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `MessageContent` | StatelessWidget | Modules/Chat | `lib/Modules/Chat/MessageContent/message_content.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_AudioPlayerWidget` | StatefulWidget | Modules/Chat | `lib/Modules/Chat/MessageContent/message_content_media_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_ChatTextField` | StatefulWidget | Modules/Chat | `lib/Modules/Chat/chat_input_widgets_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_ChatTrailingButton` | StatelessWidget | Modules/Chat | `lib/Modules/Chat/chat_input_widgets_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_EmptyChatsState` | StatelessWidget | Modules/Chat | `lib/Modules/Chat/ChatListing/chat_listing_content_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_FullScreenVideoPlayer` | StatefulWidget | Modules/Chat | `lib/Modules/Chat/MessageContent/message_content_media_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_PendingVideoPreview` | StatefulWidget | Modules/Chat | `lib/Modules/Chat/chat_input_widgets_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_SwipeActionTile` | StatefulWidget | Modules/Chat | `lib/Modules/Chat/ChatListing/chat_listing_content_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_TopTab` | StatelessWidget | Modules/Chat | `lib/Modules/Chat/ChatListing/chat_listing_content_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `AddTestQuestion` | StatefulWidget | Modules/Education | `lib/Modules/Education/Tests/AddTestQuestion/add_test_question.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `AnswerKey` | StatelessWidget | Modules/Education | `lib/Modules/Education/AnswerKey/answer_key.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `AnswerKeyContent` | StatefulWidget | Modules/Education | `lib/Modules/Education/AnswerKey/AnswerKeyContent/answer_key_content.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `AnswerKeyCreatingOption` | StatefulWidget | Modules/Education | `lib/Modules/Education/AnswerKey/AnswerKeyCreatingOption/answer_key_creating_option.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `AntremanComments` | StatefulWidget | Modules/Education | `lib/Modules/Education/Antreman3/AntremanComments/antreman_comments.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `AntremanScore` | StatefulWidget | Modules/Education | `lib/Modules/Education/Antreman3/AntremanScore/antreman_score.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `AntremanView2` | StatelessWidget | Modules/Education | `lib/Modules/Education/Antreman3/antreman_view.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `ApplicantProfile` | StatefulWidget | Modules/Education | `lib/Modules/Education/Scholarships/ScholarshipApplicationsContent/applicant_profile.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `ApplicationsView` | StatefulWidget | Modules/Education | `lib/Modules/Education/Scholarships/Applications/applications_view.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `BankInfoView` | StatefulWidget | Modules/Education | `lib/Modules/Education/Scholarships/BankInfo/bank_info_view.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `BookletAnswer` | StatefulWidget | Modules/Education | `lib/Modules/Education/AnswerKey/BookletAnswer/booklet_answer.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `BookletPreview` | StatefulWidget | Modules/Education | `lib/Modules/Education/AnswerKey/BookletPreview/booklet_preview.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `BookletResultContent` | StatefulWidget | Modules/Education | `lib/Modules/Education/AnswerKey/BookletResultContent/booklet_result_content.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `BookletResultPreview` | StatefulWidget | Modules/Education | `lib/Modules/Education/AnswerKey/BookletResultPreview/booklet_result_preview.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `CategoryBasedAnswerKey` | StatefulWidget | Modules/Education | `lib/Modules/Education/AnswerKey/CategoryBasedAnswerKey/category_based_answer_key.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `CikmisSoruOlustur` | StatefulWidget | Modules/Education | `lib/Modules/Education/CikmisSorular/cikmis_soru_olustur.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `CikmisSoruSonucPreview` | StatefulWidget | Modules/Education | `lib/Modules/Education/CikmisSorular/cikmis_soru_sonuc_preview.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `CikmisSoruSonuclar` | StatefulWidget | Modules/Education | `lib/Modules/Education/CikmisSorular/cikmis_soru_sonuclar.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `CikmisSorular` | StatefulWidget | Modules/Education | `lib/Modules/Education/CikmisSorular/cikmis_sorular.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `CikmisSorularAltDalSectirme` | StatefulWidget | Modules/Education | `lib/Modules/Education/CikmisSorular/cikmis_sorular_alt_dal_sectirme.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `CikmisSorularBaslik2Secimi` | StatefulWidget | Modules/Education | `lib/Modules/Education/CikmisSorular/cikmis_sorular_baslik2_secimi.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `CikmisSorularBaslik3Secimi` | StatefulWidget | Modules/Education | `lib/Modules/Education/CikmisSorular/cikmis_sorular_baslik3_secimi.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `CikmisSorularBransSectirme` | StatefulWidget | Modules/Education | `lib/Modules/Education/CikmisSorular/cikmis_sorular_brans_sectirme.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `CikmisSorularDilSectirmeYDT` | StatefulWidget | Modules/Education | `lib/Modules/Education/CikmisSorular/cikmis_sorular_dil_sectirme_y_d_t.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `CikmisSorularGrid` | StatefulWidget | Modules/Education | `lib/Modules/Education/CikmisSorular/cikmis_sorular_grid.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `CikmisSorularPreview` | StatefulWidget | Modules/Education | `lib/Modules/Education/CikmisSorular/cikmis_sorular_preview.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `CikmisSorularRoad` | StatefulWidget | Modules/Education | `lib/Modules/Education/CikmisSorular/cikmis_sorular_road.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `CikmisSorularSonucContent` | StatefulWidget | Modules/Education | `lib/Modules/Education/CikmisSorular/cikmis_sorular_sonuc_content.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `CikmisSorularYilSectirme` | StatefulWidget | Modules/Education | `lib/Modules/Education/CikmisSorular/cikmis_sorular_yil_sectirme.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `ComplaintBottomSheet` | StatefulWidget | Modules/Education | `lib/Modules/Education/Antreman3/Complaint/complaint.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `CreateAnswerKey` | StatefulWidget | Modules/Education | `lib/Modules/Education/AnswerKey/CreateAnswerKey/create_answer_key.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `CreateBook` | StatefulWidget | Modules/Education | `lib/Modules/Education/AnswerKey/CreateBook/create_book.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `CreateBookAnswerKey` | StatefulWidget | Modules/Education | `lib/Modules/Education/AnswerKey/CreateBook/create_book_answer_key_part.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `CreateScholarshipView` | StatefulWidget | Modules/Education | `lib/Modules/Education/Scholarships/CreateScholarship/create_scholarship_view.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `CreateTest` | StatefulWidget | Modules/Education | `lib/Modules/Education/Tests/CreateTest/create_test.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `CreateTestQuestionContent` | StatefulWidget | Modules/Education | `lib/Modules/Education/Tests/CreateTestQuestionContent/create_test_question_content.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `CreateTutoringView` | StatefulWidget | Modules/Education | `lib/Modules/Education/Tutoring/CreateTutoring/create_tutoring_view.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `DenemeGecmisSonucContent` | StatelessWidget | Modules/Education | `lib/Modules/Education/PracticeExams/DenemeGecmisSonucContent/deneme_gecmis_sonuc_content.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `DenemeGrid` | StatelessWidget | Modules/Education | `lib/Modules/Education/PracticeExams/DenemeGrid/deneme_grid.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `DenemeSinaviPreview` | StatefulWidget | Modules/Education | `lib/Modules/Education/PracticeExams/DenemeSinaviPreview/deneme_sinavi_preview.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `DenemeSinaviYap` | StatefulWidget | Modules/Education | `lib/Modules/Education/PracticeExams/DenemeSinaviYap/deneme_sinavi_yap.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `DenemeSinavlari` | StatelessWidget | Modules/Education | `lib/Modules/Education/PracticeExams/deneme_sinavlari.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `DenemeTurleriListesi` | StatefulWidget | Modules/Education | `lib/Modules/Education/PracticeExams/DenemeTurleriListesi/deneme_turleri_listesi.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `DormitoryInfoView` | StatefulWidget | Modules/Education | `lib/Modules/Education/Scholarships/DormitoryInfo/dormitory_info_view.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `DropdownField` | StatelessWidget | Modules/Education | `lib/Modules/Education/Scholarships/PersonelInfo/personel_info_view_content_part.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `DropdownField` | StatelessWidget | Modules/Education | `lib/Modules/Education/Scholarships/EducationInfo/education_info_view_fields_part.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `EducationInfoView` | StatefulWidget | Modules/Education | `lib/Modules/Education/Scholarships/EducationInfo/education_info_view.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `EducationView` | StatelessWidget | Modules/Education | `lib/Modules/Education/education_view.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `FamilyInfoView` | StatefulWidget | Modules/Education | `lib/Modules/Education/Scholarships/FamilyInfo/family_info_view.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `LessonBasedTests` | StatefulWidget | Modules/Education | `lib/Modules/Education/Tests/LessonsBasedTests/lesson_based_tests.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `LocationBasedTutoring` | StatefulWidget | Modules/Education | `lib/Modules/Education/Tutoring/LocationBasedTutoring/location_based_tutoring.dart` | — | render, semantics, interaction, textScale |
| covered | P0 | `MarketTopActionButton` | StatelessWidget | Modules/Education | `lib/Modules/Education/widgets/market_top_action_button.dart` | `test/widget/components/market_top_actions_widget_test.dart`<br>`test/widget/flows/accessibility_semantics_smoke_test.dart` | render, semantics, interaction, textScale |
| planned | P0 | `MyBookletResults` | StatefulWidget | Modules/Education | `lib/Modules/Education/AnswerKey/MyBookletResults/my_booklet_results.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `MyPastTestResultsPreview` | StatefulWidget | Modules/Education | `lib/Modules/Education/Tests/MyPastTestResultsPreview.dart/my_past_test_results_preview.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `MyPracticeExams` | StatefulWidget | Modules/Education | `lib/Modules/Education/PracticeExams/MyPracticeExams/my_practice_exams.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `MyScholarshipView` | StatefulWidget | Modules/Education | `lib/Modules/Education/Scholarships/MyScholarship/my_scholarship_view.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `MyStatisticView` | StatefulWidget | Modules/Education | `lib/Modules/Education/Antreman3/MyStatistic/my_statistic_view.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `MyTestResults` | StatefulWidget | Modules/Education | `lib/Modules/Education/Tests/MyTestResults/my_test_results.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `MyTests` | StatefulWidget | Modules/Education | `lib/Modules/Education/Tests/MyTests/my_tests.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `MyTutoringApplications` | StatefulWidget | Modules/Education | `lib/Modules/Education/Tutoring/MyTutoringApplications/my_tutoring_applications.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `MyTutorings` | StatefulWidget | Modules/Education | `lib/Modules/Education/Tutoring/MyTutorings/my_tutorings.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `OpticalFormContent` | StatefulWidget | Modules/Education | `lib/Modules/Education/AnswerKey/OpticalFormContent/optical_form_content.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `OpticalFormEntry` | StatefulWidget | Modules/Education | `lib/Modules/Education/AnswerKey/OpticalFormEntry/optical_form_entry.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `OpticalPreview` | StatefulWidget | Modules/Education | `lib/Modules/Education/AnswerKey/OpticalPreview/optical_preview.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `OpticsAndBooksPublished` | StatefulWidget | Modules/Education | `lib/Modules/Education/AnswerKey/OpticsAndBooksPublished/optics_and_books_published.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `PersonalizedContent` | StatelessWidget | Modules/Education | `lib/Modules/Education/Scholarships/Personalized/personalized_content.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `PersonalizedView` | StatefulWidget | Modules/Education | `lib/Modules/Education/Scholarships/Personalized/personalized_view.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `PersonelInfoView` | StatefulWidget | Modules/Education | `lib/Modules/Education/Scholarships/PersonelInfo/personel_info_view.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `PreviousQuestions` | StatefulWidget | Modules/Education | `lib/Modules/Education/PreviousQuestions/previous_questions.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `QuestionContent` | StatelessWidget | Modules/Education | `lib/Modules/Education/Antreman3/question_content.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `ResultsAndAnswers` | StatefulWidget | Modules/Education | `lib/Modules/Education/AnswerKey/ResultsAndAnswers/results_and_answers.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `SavedItemsView` | StatefulWidget | Modules/Education | `lib/Modules/Education/Scholarships/SavedItems/saved_items_view.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `SavedOpticalForms` | StatefulWidget | Modules/Education | `lib/Modules/Education/AnswerKey/SavedOpticalForms/saved_optical_forms.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `SavedPracticeExams` | StatefulWidget | Modules/Education | `lib/Modules/Education/PracticeExams/SavedPracticeExams/saved_practice_exams.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `SavedTests` | StatefulWidget | Modules/Education | `lib/Modules/Education/Tests/SavedTests/saved_tests.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `SavedTutorings` | StatefulWidget | Modules/Education | `lib/Modules/Education/Tutoring/SavedTutorings/saved_tutorings.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `ScholarshipApplicationsContent` | StatefulWidget | Modules/Education | `lib/Modules/Education/Scholarships/ScholarshipApplicationsContent/scholarship_applications_content.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `ScholarshipApplicationsList` | StatefulWidget | Modules/Education | `lib/Modules/Education/Scholarships/ScholarshipApplicationsList/scholarship_applications_list.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `ScholarshipPreviewView` | StatelessWidget | Modules/Education | `lib/Modules/Education/Scholarships/CreateScholarship/scholarship_preview_view.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `ScholarshipProvidersView` | StatefulWidget | Modules/Education | `lib/Modules/Education/Scholarships/ScholarshipProviders/scholarship_providers_view.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `ScholarshipsView` | StatefulWidget | Modules/Education | `lib/Modules/Education/Scholarships/scholarships_view.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `SearchAnswerKey` | StatefulWidget | Modules/Education | `lib/Modules/Education/AnswerKey/SearchAnswerKey/search_answer_key.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `SearchDeneme` | StatefulWidget | Modules/Education | `lib/Modules/Education/PracticeExams/SearchDeneme/search_deneme.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `SearchTests` | StatefulWidget | Modules/Education | `lib/Modules/Education/Tests/SearchTests/search_tests.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `SinavHazirla` | StatefulWidget | Modules/Education | `lib/Modules/Education/PracticeExams/SinavHazirla/sinav_hazirla.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `SinavSonuclariPreview` | StatefulWidget | Modules/Education | `lib/Modules/Education/PracticeExams/SinavSonuclariPreview/sinav_sonuclari_preview.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `SinavSonuclarim` | StatefulWidget | Modules/Education | `lib/Modules/Education/PracticeExams/SinavSonuclarim/sinav_sonuclarim.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `SinavSorusuHazirla` | StatefulWidget | Modules/Education | `lib/Modules/Education/PracticeExams/SinavSorusuHazirla/sinav_sorusu_hazirla.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `SolveTest` | StatefulWidget | Modules/Education | `lib/Modules/Education/Tests/SolveTest/solve_test.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `SoruContent` | StatefulWidget | Modules/Education | `lib/Modules/Education/PracticeExams/SoruContent/soru_content.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `Speedometer` | StatefulWidget | Modules/Education | `lib/Modules/Education/AnswerKey/ResultsAndAnswers/results_and_answers_speedometer_part.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `TestEntry` | StatefulWidget | Modules/Education | `lib/Modules/Education/Tests/TestEntry/test_entry.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `TestPastResultContent` | StatefulWidget | Modules/Education | `lib/Modules/Education/Tests/TestPastResultContent/test_past_result_content.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `Tests` | StatefulWidget | Modules/Education | `lib/Modules/Education/Tests/tests.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `TestsGrid` | StatefulWidget | Modules/Education | `lib/Modules/Education/Tests/TestsGrid/tests_grid.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `ThenSolve` | StatelessWidget | Modules/Education | `lib/Modules/Education/Antreman3/ThenSolve/then_solve.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `TopBar` | StatelessWidget | Modules/Education | `lib/Modules/Education/Tutoring/top_bar.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `TutoringApplicationReview` | StatefulWidget | Modules/Education | `lib/Modules/Education/Tutoring/TutoringApplicationReview/tutoring_application_review.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `TutoringCategoryWidget` | StatelessWidget | Modules/Education | `lib/Modules/Education/Tutoring/tutoring_category.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `TutoringContent` | StatelessWidget | Modules/Education | `lib/Modules/Education/Tutoring/tutoring_content.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `TutoringDetail` | StatelessWidget | Modules/Education | `lib/Modules/Education/Tutoring/TutoringDetail/tutoring_detail.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `TutoringFilterBottomSheet` | StatelessWidget | Modules/Education | `lib/Modules/Education/Tutoring/FilterBottomSheet/tutoring_filter_bottom_sheet.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `TutoringSearch` | StatefulWidget | Modules/Education | `lib/Modules/Education/Tutoring/TutoringSearch/tutoring_search.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `TutoringView` | StatelessWidget | Modules/Education | `lib/Modules/Education/Tutoring/tutoring_view.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `TutoringWidgetBuilder` | StatelessWidget | Modules/Education | `lib/Modules/Education/Tutoring/tutoring_widget_builder.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `_JoinButtonText` | StatelessWidget | Modules/Education | `lib/Modules/Education/Tests/TestEntry/test_entry_shell_part.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `_QuestionItem` | StatelessWidget | Modules/Education | `lib/Modules/Education/AnswerKey/BookletAnswer/booklet_answer_shell_part.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `ExploreView` | StatefulWidget | Modules/Explore | `lib/Modules/Explore/explore_view.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `ApplicationReview` | StatefulWidget | Modules/JobFinder | `lib/Modules/JobFinder/ApplicationReview/application_review.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `MaintenanceView` | StatefulWidget | Modules/Maintenance | `lib/Modules/Maintenance/maintenance_view.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `MarketCategorySheet` | StatefulWidget | Modules/Market | `lib/Modules/Market/market_category_sheet.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `MarketCreateView` | StatefulWidget | Modules/Market | `lib/Modules/Market/market_create_view.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `MarketDetailView` | StatefulWidget | Modules/Market | `lib/Modules/Market/market_detail_view.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `MarketFilterSheet` | StatefulWidget | Modules/Market | `lib/Modules/Market/market_filter_sheet.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `MarketMyItemsView` | StatefulWidget | Modules/Market | `lib/Modules/Market/market_my_items_view.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `MarketOffersView` | StatefulWidget | Modules/Market | `lib/Modules/Market/market_offers_view.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `MarketSavedView` | StatefulWidget | Modules/Market | `lib/Modules/Market/market_saved_view.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `MarketSearchView` | StatefulWidget | Modules/Market | `lib/Modules/Market/market_search_view.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `MarketView` | StatelessWidget | Modules/Market | `lib/Modules/Market/market_view.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `_MarketGridMedia` | StatefulWidget | Modules/Market | `lib/Modules/Market/market_view_media_part.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `NavBarView` | StatelessWidget | Modules/NavBar | `lib/Modules/NavBar/nav_bar_view.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `_AvatarWithRing` | StatefulWidget | Modules/NavBar | `lib/Modules/NavBar/nav_bar_view_avatar_part.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `AboutProfile` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/AboutProfile/about_profile.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `AccountCenterView` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/account_center_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `AddSocialMediaBottomSheet` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/SocialMediaLinks/add_social_media_bottom_sheet.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `AddressSelector` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/AddressSelector/address_selector.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `AdminApprovalsView` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/Settings/admin_approvals_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `AdminPushView` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/Settings/admin_push_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `AdminTaskAssignmentsView` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/Settings/admin_task_assignments_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `AdsCampaignEditorView` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/Settings/AdsCenter/ads_campaign_editor_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `AdsCampaignListView` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/AdsCenter/ads_campaign_list_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `AdsCenterHomeView` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/Settings/AdsCenter/ads_center_home_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `AdsCreativeReviewView` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/AdsCenter/ads_creative_review_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `AdsDashboardView` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/AdsCenter/ads_dashboard_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `AdsDeliveryMonitorView` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/AdsCenter/ads_delivery_monitor_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `AdsPreviewScreen` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/Settings/AdsCenter/ads_preview_screen.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `Archives` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/Archives/archives.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `BadgeAdminView` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/Settings/badge_admin_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `BecomeVerifiedAccount` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/BecomeVerifiedAccount/become_verified_account.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `BiographyMaker` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/BiographyMaker/biography_maker.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `BlockedUsers` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/BlockedUsers/blocked_users.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `Cv` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/Cv/cv.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `DeleteAccount` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/DeleteAccount/delete_account.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `EditProfile` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/EditProfile/edit_profile.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `EditorEmail` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/EditorEmail/editor_email.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `EditorNickname` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/EditorNickname/editor_nickname.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `EditorPhoneNumber` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/EditorPhoneNumber/editor_phone_number.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `FollowerContent` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/FollowingFollowers/follower_content.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `FollowingFollowers` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/FollowingFollowers/following_followers.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `Interests` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/Interests/interests.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `JobSelector` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/JobSelector/job_selector.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `LangSelector` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/LangSelector/lang_selector.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `LanguageSettingsView` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/language_settings_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `LikedPosts` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/LikedPosts/liked_posts.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `ModerationSettingsView` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/Settings/moderation_settings_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `MyAdminApprovalResultsView` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/my_admin_approval_results_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `MyQRCode` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/MyQRCode/my_q_r_code.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `MyStatisticView` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/MyStatistic/my_statistic_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `NotificationSettingsView` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/Settings/notification_settings_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `PasajSettingsView` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/Settings/pasaj_settings_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `PermissionsView` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/Settings/permissions_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `Policies` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/Policies/policies.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `PolicyDetailView` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Policies/policy_detail_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `ProfileContact` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/ProfileContact/profile_contact.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `ProfileView` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/MyProfile/profile_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `QALabView` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/Settings/qa_lab_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `ReportsAdminView` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/Settings/reports_admin_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `SavedPosts` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/SavedPosts/saved_posts.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `SettingsView` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/Settings/settings.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `SocialMediaContent` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/SocialMediaLinks/social_media_content.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `SocialMediaLinks` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/SocialMediaLinks/social_media_links.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `StoryMusicAdminView` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/Settings/story_music_admin_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `SupportAdminView` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/Settings/support_admin_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `SupportContactView` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/Settings/support_contact_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `ViewChanger` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/ViewChanger/view_changer.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_AccountRow` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/account_center_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_AdminPushMenuTile` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/Settings/settings_sections_admin_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_ApplicationCard` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/Settings/badge_admin_view_applications_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_ApplicationsSection` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/badge_admin_view_applications_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_ApprovalCard` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/Settings/admin_approvals_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_ApprovalResultTile` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/my_admin_approval_results_view_tile_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_AssignmentCard` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/admin_task_assignments_view_content_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_BadgeMenuRow` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/badge_admin_view_content_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_BanChip` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/moderation_settings_view_ban_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_ContactDetailsView` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/account_center_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_ContactStatusRow` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/account_center_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_LanguageHeader` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/language_settings_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_LanguageOptionTile` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/language_settings_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_LinkChip` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/badge_admin_view_applications_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_ModerationThresholdList` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/moderation_settings_view_content_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_NavTile` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/notification_settings_view_components_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_NotificationCategoryView` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/Settings/notification_settings_view_category_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_PasajToggleTile` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/pasaj_settings_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_PermissionDetailView` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/Settings/permissions_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_PersonalDetailRow` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/account_center_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_PersonalDetailsCard` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/account_center_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_PersonalDetailsSection` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/account_center_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_PolicyAccordionTile` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Policies/policies_content_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_PolicyTab` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Policies/policies_content_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_ReportAggregateCard` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/reports_admin_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_ResultCard` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/badge_admin_view_content_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_SectionCard` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Policies/policy_detail_view_content_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_SectionLabel` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/notification_settings_view_components_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_SessionSecuritySection` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/account_center_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_StatusChip` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/admin_approvals_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_StatusChip` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/my_admin_approval_results_view_tile_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_SwitchTile` | StatelessWidget | Modules/Profile | `lib/Modules/Profile/Settings/notification_settings_view_components_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_UserBanSection` | StatefulWidget | Modules/Profile | `lib/Modules/Profile/Settings/moderation_settings_view_ban_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `DynamicShortView` | StatefulWidget | Modules/Short | `lib/Modules/Short/dynamic_short_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `ShortView` | StatefulWidget | Modules/Short | `lib/Modules/Short/short_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `ShortsContent` | StatefulWidget | Modules/Short | `lib/Modules/Short/short_content.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `SingleShortView` | StatefulWidget | Modules/Short | `lib/Modules/Short/single_short_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_ShortProgressBar` | StatelessWidget | Modules/Short | `lib/Modules/Short/short_view_ui_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_SingleShortProgressBar` | StatelessWidget | Modules/Short | `lib/Modules/Short/single_short_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `SignIn` | StatefulWidget | Modules/SignIn | `lib/Modules/SignIn/sign_in.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `_LoginBrandTypewriter` | StatefulWidget | Modules/SignIn | `lib/Modules/SignIn/sign_in_auth_part.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `SplashView` | StatefulWidget | Modules/Splash | `lib/Modules/Splash/splash_view.dart` | — | render, semantics, interaction, textScale |
| planned | P0 | `DeletedStoriesView` | StatefulWidget | Modules/Story | `lib/Modules/Story/DeletedStories/deleted_stories.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `DrawingScreen` | StatefulWidget | Modules/Story | `lib/Modules/Story/StoryMaker/drawing_screen.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `HighlightPickerSheet` | StatefulWidget | Modules/Story | `lib/Modules/Story/StoryHighlights/highlight_picker_sheet.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `StoryCircle` | StatefulWidget | Modules/Story | `lib/Modules/Story/StoryRow/story_circle.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `StoryCommentUser` | StatefulWidget | Modules/Story | `lib/Modules/Story/StoryViewer/StoryComments/StoryCommentUser/story_comment_user.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `StoryComments` | StatefulWidget | Modules/Story | `lib/Modules/Story/StoryViewer/StoryComments/story_comments.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `StoryContentProfiles` | StatefulWidget | Modules/Story | `lib/Modules/Story/StoryViewer/StoryContentProfiles/story_content_profiles.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `StoryGifWidget` | StatelessWidget | Modules/Story | `lib/Modules/Story/StoryViewer/story_elements.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `StoryHighlightCircle` | StatelessWidget | Modules/Story | `lib/Modules/Story/StoryHighlights/story_highlight_circle.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `StoryImageWidget` | StatelessWidget | Modules/Story | `lib/Modules/Story/StoryViewer/story_elements.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `StoryLikes` | StatefulWidget | Modules/Story | `lib/Modules/Story/StoryViewer/StoryLikes/story_likes.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `StoryMaker` | StatefulWidget | Modules/Story | `lib/Modules/Story/StoryMaker/story_maker.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `StoryMusicProfileView` | StatefulWidget | Modules/Story | `lib/Modules/Story/StoryMusic/story_music_profile_view.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `StoryRow` | StatefulWidget | Modules/Story | `lib/Modules/Story/StoryRow/story_row.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `StoryRowPlaceholder` | StatefulWidget | Modules/Story | `lib/Modules/Story/StoryRow/story_row_placeholder_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `StorySeens` | StatefulWidget | Modules/Story | `lib/Modules/Story/StoryViewer/StorySeens/story_seens.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `StoryTextWidget` | StatelessWidget | Modules/Story | `lib/Modules/Story/StoryViewer/story_elements.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `StoryUploadingRing` | StatefulWidget | Modules/Story | `lib/Modules/Story/StoryRow/story_circle_painter_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `StoryVideo` | StatefulWidget | Modules/Story | `lib/Modules/Story/StoryMaker/story_video.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `StoryVideoWidget` | StatefulWidget | Modules/Story | `lib/Modules/Story/StoryViewer/story_video_widget.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `StoryViewer` | StatefulWidget | Modules/Story | `lib/Modules/Story/StoryViewer/story_viewer.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `TextEditorSheet` | StatefulWidget | Modules/Story | `lib/Modules/Story/StoryMaker/text_editor_sheet.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `UserStoryContent` | StatefulWidget | Modules/Story | `lib/Modules/Story/StoryViewer/user_story_content.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_EmptyState` | StatelessWidget | Modules/Story | `lib/Modules/Story/DeletedStories/deleted_stories_grid_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_GridContent` | StatefulWidget | Modules/Story | `lib/Modules/Story/DeletedStories/deleted_stories_grid_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_ShimmerCircle` | StatelessWidget | Modules/Story | `lib/Modules/Story/StoryRow/story_row_placeholder_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_StoryCard` | StatelessWidget | Modules/Story | `lib/Modules/Story/DeletedStories/deleted_stories_grid_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_TabbedContent` | StatelessWidget | Modules/Story | `lib/Modules/Story/DeletedStories/deleted_stories_grid_part.dart` | — | render, semantics, interaction, textScale, platform |
| planned | P0 | `_VerticalStrip` | StatefulWidget | Modules/Story | `lib/Modules/Story/DeletedStories/deleted_stories_strip_part.dart` | — | render, semantics, interaction, textScale, platform |
| covered | P0 | `MyApp` | StatelessWidget | lib/main.dart | `lib/main.dart` | `test/widget/screens/sign_in_test.dart` | render, semantics |
| planned | P1 | `AppBottomSheet` | StatefulWidget | Core/BottomSheets | `lib/Core/BottomSheets/app_bottom_sheet.dart` | — | render, semantics, interaction |
| planned | P1 | `AppSheetActionTile` | StatelessWidget | Core/BottomSheets | `lib/Core/BottomSheets/app_sheet_action_tile.dart` | — | render, semantics, interaction |
| planned | P1 | `AppSheetHeader` | StatelessWidget | Core/BottomSheets | `lib/Core/BottomSheets/app_sheet_header.dart` | — | render, semantics, interaction |
| planned | P1 | `DatePickerBottomSheet` | StatelessWidget | Core/BottomSheets | `lib/Core/BottomSheets/date_picker_bottom_sheet.dart` | — | render, semantics, interaction |
| planned | P1 | `DurationPickerBottomSheet` | StatelessWidget | Core/BottomSheets | `lib/Core/BottomSheets/duration_picker_bottom_sheet.dart` | — | render, semantics, interaction |
| planned | P1 | `FutureDatePickerBottomSheet` | StatelessWidget | Core/BottomSheets | `lib/Core/BottomSheets/future_date_picker_bottom_sheet.dart` | — | render, semantics, interaction |
| planned | P1 | `FutureTimePickerBottomSheet` | StatelessWidget | Core/BottomSheets | `lib/Core/BottomSheets/time_picker_bottom_sheet.dart` | — | render, semantics, interaction |
| planned | P1 | `ListBottomSheet` | StatefulWidget | Core/BottomSheets | `lib/Core/BottomSheets/list_bottom_sheet.dart` | — | render, semantics, interaction |
| planned | P1 | `MultiSelectBottomSheet2` | StatelessWidget | Core/BottomSheets | `lib/Core/BottomSheets/multiple_choice_bottom_sheet2.dart` | — | render, semantics, interaction |
| planned | P1 | `MultipleChoiceBottomSheet` | StatelessWidget | Core/BottomSheets | `lib/Core/BottomSheets/multiple_choice_bottom_sheet.dart` | — | render, semantics, interaction |
| planned | P1 | `_MultiSelectBottomSheet2Content` | StatefulWidget | Core/BottomSheets | `lib/Core/BottomSheets/multiple_choice_bottom_sheet2_content_part.dart` | — | render, semantics, interaction |
| covered | P1 | `ActionButton` | StatefulWidget | Core/Buttons | `lib/Core/Buttons/action_button.dart` | `test/widget/components/market_top_actions_widget_test.dart`<br>`test/widget/flows/accessibility_semantics_smoke_test.dart` | render, semantics, interaction, textScale |
| planned | P1 | `BackButtons` | StatelessWidget | Core/Buttons | `lib/Core/Buttons/back_buttons.dart` | — | render, semantics, interaction, textScale |
| planned | P1 | `SaveButton` | StatelessWidget | Core/Buttons | `lib/Core/Buttons/container_buttons.dart` | — | render, semantics, interaction, textScale |
| planned | P1 | `ScrollTotopButton` | StatelessWidget | Core/Buttons | `lib/Core/Buttons/scroll_to_top_button.dart` | — | render, semantics, interaction, textScale |
| planned | P1 | `TurqAppButton` | StatelessWidget | Core/Buttons | `lib/Core/Buttons/turq_app_button.dart` | — | render, semantics, interaction, textScale |
| planned | P1 | `TurqAppToggle` | StatelessWidget | Core/Buttons | `lib/Core/Buttons/turq_app_toggle.dart` | — | render, semantics, interaction, textScale |
| planned | P1 | `ActionButtonContent` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/animated_action_button.dart` | — | render, semantics, textScale |
| planned | P1 | `AdRenderer` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/Ads/ad_renderer.dart` | — | render, semantics, textScale |
| planned | P1 | `AnimatedActionButton` | StatefulWidget | Core/Widgets | `lib/Core/Widgets/animated_action_button.dart` | — | render, semantics, interaction, textScale |
| planned | P1 | `AppBackButton` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/app_header_action_button.dart` | — | render, semantics, textScale |
| planned | P1 | `AppHeaderActionButton` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/app_header_action_button.dart` | — | render, semantics, textScale |
| planned | P1 | `AppHealthDashboard` | StatefulWidget | Core/Widgets | `lib/Core/Widgets/app_health_dashboard.dart` | — | render, semantics, interaction, textScale |
| planned | P1 | `AppIconSurface` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/app_icon_surface.dart` | — | render, semantics, textScale |
| planned | P1 | `AppPageTitle` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/app_header_action_button.dart` | — | render, semantics, textScale |
| planned | P1 | `CachedUserAvatar` | StatefulWidget | Core/Widgets | `lib/Core/Widgets/cached_user_avatar.dart` | — | render, semantics, interaction, textScale |
| planned | P1 | `CachedUserAvatarWithName` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/cached_user_avatar_support_part.dart` | — | render, semantics, textScale |
| planned | P1 | `CircularProgressWithText` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/progress_indicators.dart` | — | render, semantics, textScale |
| planned | P1 | `DefaultAvatar` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/cached_user_avatar_support_part.dart` | — | render, semantics, textScale |
| planned | P1 | `EducationActionIconButton` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/education_share_icon_button.dart` | — | render, semantics, textScale |
| planned | P1 | `EducationFeedShareIconButton` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/education_share_icon_button.dart` | — | render, semantics, textScale |
| planned | P1 | `EducationGridSkeleton` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/skeleton_loader.dart` | — | render, semantics, textScale |
| planned | P1 | `EducationListSkeleton` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/skeleton_loader.dart` | — | render, semantics, textScale |
| planned | P1 | `EducationShareIconButton` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/education_share_icon_button.dart` | — | render, semantics, textScale |
| planned | P1 | `EnhancedTextEditor` | StatefulWidget | Core/Widgets | `lib/Core/Widgets/enhanced_text_editor.dart` | — | render, semantics, interaction, textScale |
| planned | P1 | `ErrorReportWidget` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/error_report_widget.dart` | — | render, semantics, textScale |
| planned | P1 | `ExploreAdPlacementHook` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/Ads/ad_placement_hooks.dart` | — | render, semantics, textScale |
| planned | P1 | `FeedAdPlacementHook` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/Ads/ad_placement_hooks.dart` | — | render, semantics, textScale |
| planned | P1 | `FeedPostSkeleton` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/skeleton_loader.dart` | — | render, semantics, textScale |
| planned | P1 | `FeedSkeleton` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/skeleton_loader.dart` | — | render, semantics, textScale |
| planned | P1 | `FormattingToolbar` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/enhanced_text_editor_support_part.dart` | — | render, semantics, textScale |
| planned | P1 | `LinearProgressWithLabels` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/progress_indicators.dart` | — | render, semantics, textScale |
| planned | P1 | `OfflineIndicator` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/offline_indicator.dart` | — | render, semantics, textScale |
| planned | P1 | `OptimizedCircleAvatar` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/optimized_image.dart` | — | render, semantics, textScale |
| planned | P1 | `OptimizedImage` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/optimized_image.dart` | — | render, semantics, textScale |
| planned | P1 | `OptimizedNetworkImage` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/optimized_image.dart` | — | render, semantics, textScale |
| planned | P1 | `PasajGridCard` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/pasaj_grid_card.dart` | — | render, semantics, textScale |
| planned | P1 | `PasajSelectionChip` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/pasaj_selection_chip.dart` | — | render, semantics, textScale |
| planned | P1 | `PostInteractionWidget` | StatefulWidget | Core/Widgets | `lib/Core/Widgets/post_interaction_widget.dart` | — | render, semantics, interaction, textScale |
| planned | P1 | `ProfileGridSkeleton` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/skeleton_loader.dart` | — | render, semantics, textScale |
| planned | P1 | `RingUploadProgressIndicator` | StatefulWidget | Core/Widgets | `lib/Core/Widgets/ring_upload_progress_indicator.dart` | — | render, semantics, interaction, textScale |
| planned | P1 | `ScaleTap` | StatefulWidget | Core/Widgets | `lib/Core/Widgets/scale_tap.dart` | — | render, semantics, interaction, textScale |
| planned | P1 | `SharedPostLabel` | StatefulWidget | Core/Widgets | `lib/Core/Widgets/shared_post_label.dart` | — | render, semantics, interaction, textScale |
| planned | P1 | `ShortVideoSkeleton` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/skeleton_loader.dart` | — | render, semantics, textScale |
| planned | P1 | `ShortsAdPlacementHook` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/Ads/ad_placement_hooks.dart` | — | render, semantics, textScale |
| planned | P1 | `SkeletonLoader` | StatefulWidget | Core/Widgets | `lib/Core/Widgets/skeleton_loader.dart` | — | render, semantics, interaction, textScale |
| planned | P1 | `SlimSendIcon` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/slim_send_icon.dart` | — | render, semantics, textScale |
| planned | P1 | `StepProgressIndicator` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/progress_indicators.dart` | — | render, semantics, textScale |
| planned | P1 | `StoryRowSkeleton` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/skeleton_loader.dart` | — | render, semantics, textScale |
| planned | P1 | `SuggestionPanel` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/enhanced_text_editor_support_part.dart` | — | render, semantics, textScale |
| planned | P1 | `TurqSearchBar` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/turq_search_bar.dart` | — | render, semantics, textScale |
| planned | P1 | `UploadLimitInfo` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/upload_progress_indicator.dart` | — | render, semantics, textScale |
| planned | P1 | `UploadProgressIndicator` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/upload_progress_indicator.dart` | — | render, semantics, textScale |
| planned | P1 | `UploadProgressWidget` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/progress_indicators.dart` | — | render, semantics, textScale |
| planned | P1 | `_CardSkeleton` | StatelessWidget | Core/Widgets | `lib/Core/Widgets/skeleton_loader.dart` | — | render, semantics, textScale |
| planned | P1 | `SearchUserContent` | StatelessWidget | Modules/Explore | `lib/Modules/Explore/SearchedUser/search_user_content.dart` | — | render, semantics, interaction, textScale |
| covered | P1 | `InAppNotifications` | StatefulWidget | Modules/InAppNotifications | `lib/Modules/InAppNotifications/in_app_notifications.dart` | `test/widget/components/notifications_menu_widget_test.dart`<br>`test/widget/flows/accessibility_semantics_smoke_test.dart` | render, semantics, interaction, textScale |
| covered | P1 | `NotificationActionsSheetContent` | StatelessWidget | Modules/InAppNotifications | `lib/Modules/InAppNotifications/notification_actions_sheet_content.dart` | `test/widget/components/notifications_menu_widget_test.dart`<br>`test/widget/flows/accessibility_semantics_smoke_test.dart` | render, semantics, interaction, textScale |
| planned | P1 | `NotificationContent` | StatefulWidget | Modules/InAppNotifications | `lib/Modules/InAppNotifications/notification_content.dart` | — | render, semantics, interaction, textScale |
| planned | P1 | `_NotificationActionTile` | StatelessWidget | Modules/InAppNotifications | `lib/Modules/InAppNotifications/notification_actions_sheet_content.dart` | — | render, semantics, interaction, textScale |
| planned | P1 | `RecommendedUserContent` | StatefulWidget | Modules/RecommendedUserList | `lib/Modules/RecommendedUserList/RecommendedUserContent/recommended_user_content.dart` | — | render, semantics, interaction, textScale |
| planned | P1 | `RecommendedUserList` | StatefulWidget | Modules/RecommendedUserList | `lib/Modules/RecommendedUserList/recommended_user_list.dart` | — | render, semantics, interaction, textScale |
| planned | P2 | `AdmobKare` | StatefulWidget | Ads/admob_kare.dart | `lib/Ads/admob_kare.dart` | — | render, semantics, interaction |
| planned | P2 | `AdmobTesting` | StatelessWidget | Ads/admob_testing.dart | `lib/Ads/admob_testing.dart` | — | render, semantics |
| planned | P2 | `ClickableTextContent` | StatefulWidget | Core/Helpers | `lib/Core/Helpers/clickable_text_content.dart` | — | render, semantics, interaction |
| planned | P2 | `GlobalLoader` | StatelessWidget | Core/Helpers | `lib/Core/Helpers/GlobalLoader/global_loader.dart` | — | render, semantics |
| planned | P2 | `Hashtaglister` | StatefulWidget | Core/Helpers | `lib/Core/Helpers/HashtagLister/hashtag_lister.dart` | — | render, semantics, interaction |
| planned | P2 | `RoadToTop` | StatelessWidget | Core/Helpers | `lib/Core/Helpers/RoadToTop/road_to_top.dart` | — | render, semantics |
| planned | P2 | `SeenCountLabel` | StatefulWidget | Core/Helpers | `lib/Core/Helpers/seen_count_label.dart` | — | render, semantics, interaction |
| planned | P2 | `NotifyReader` | StatefulWidget | Core/NotifyReader | `lib/Core/NotifyReader/notify_reader.dart` | — | render, semantics, interaction |
| planned | P2 | `CacheDebugOverlay` | StatefulWidget | Core/Services | `lib/Core/Services/SegmentCache/debug_overlay.dart` | — | render, semantics, interaction |
| planned | P2 | `_GifGridTile` | StatelessWidget | Core/Services | `lib/Core/Services/giphy_picker_service.dart` | — | render, semantics |
| planned | P2 | `EducationSlider` | StatefulWidget | Core/Slider | `lib/Core/Slider/education_slider.dart` | — | render, semantics, interaction |
| planned | P2 | `EmptyRow` | StatelessWidget | Core/empty_row.dart | `lib/Core/empty_row.dart` | — | render, semantics |
| planned | P2 | `Infomessage` | StatelessWidget | Core/info_message.dart | `lib/Core/info_message.dart` | — | render, semantics |
| planned | P2 | `NicknameWithTextLine` | StatefulWidget | Core/nickname_with_text_line.dart | `lib/Core/nickname_with_text_line.dart` | — | render, semantics, interaction |
| planned | P2 | `_NotificationOpeningOverlay` | StatelessWidget | Core/notification_service.dart | `lib/Core/notification_service.dart` | — | render, semantics |
| planned | P2 | `OpeningOverlay` | StatefulWidget | Core/opening_overlay.dart | `lib/Core/opening_overlay.dart` | — | render, semantics, interaction |
| planned | P2 | `PageLineBar` | StatefulWidget | Core/page_line_bar.dart | `lib/Core/page_line_bar.dart` | — | render, semantics, interaction |
| planned | P2 | `RozetContent` | StatefulWidget | Core/rozet_content.dart | `lib/Core/rozet_content.dart` | — | render, semantics, interaction |
| planned | P2 | `EditPost` | StatefulWidget | Modules/EditPost | `lib/Modules/EditPost/edit_post.dart` | — | render, semantics, interaction, textScale |
| planned | P2 | `CareerProfile` | StatefulWidget | Modules/JobFinder | `lib/Modules/JobFinder/CareerProfile/career_profile.dart` | — | render, semantics, interaction, textScale |
| planned | P2 | `FindingJobApply` | StatefulWidget | Modules/JobFinder | `lib/Modules/JobFinder/FindingJobApply/finding_job_apply.dart` | — | render, semantics, interaction, textScale |
| planned | P2 | `JobContent` | StatefulWidget | Modules/JobFinder | `lib/Modules/JobFinder/JobContent/job_content.dart` | — | render, semantics, interaction, textScale |
| planned | P2 | `JobCreator` | StatefulWidget | Modules/JobFinder | `lib/Modules/JobFinder/JobCreator/job_creator.dart` | — | render, semantics, interaction, textScale |
| planned | P2 | `JobDetails` | StatefulWidget | Modules/JobFinder | `lib/Modules/JobFinder/JobDetails/job_details.dart` | — | render, semantics, interaction, textScale |
| planned | P2 | `JobFinder` | StatelessWidget | Modules/JobFinder | `lib/Modules/JobFinder/job_finder.dart` | — | render, semantics, interaction, textScale |
| planned | P2 | `MyApplications` | StatefulWidget | Modules/JobFinder | `lib/Modules/JobFinder/MyApplications/my_applications.dart` | — | render, semantics, interaction, textScale |
| planned | P2 | `MyJobAds` | StatefulWidget | Modules/JobFinder | `lib/Modules/JobFinder/MyJobAds/my_job_ads.dart` | — | render, semantics, interaction, textScale |
| planned | P2 | `SavedJobs` | StatefulWidget | Modules/JobFinder | `lib/Modules/JobFinder/SavedJobs/saved_jobs.dart` | — | render, semantics, interaction, textScale |
| planned | P2 | `CreatorContent` | StatelessWidget | Modules/PostCreator | `lib/Modules/PostCreator/CreatorContent/creator_content.dart` | — | render, semantics, interaction, textScale |
| planned | P2 | `PostCreator` | StatelessWidget | Modules/PostCreator | `lib/Modules/PostCreator/post_creator.dart` | — | render, semantics, interaction, textScale |
| planned | P2 | `ShareGrid` | StatefulWidget | Modules/ShareGrid | `lib/Modules/ShareGrid/share_grid.dart` | — | render, semantics, interaction, textScale |
| covered | P2 | `CommentComposerBar` | StatelessWidget | Modules/Social | `lib/Modules/Social/Comments/comment_composer_bar.dart` | `test/widget/components/comments_input_widget_test.dart`<br>`test/widget/flows/accessibility_semantics_smoke_test.dart` | render, semantics, interaction, textScale |
| planned | P2 | `HashtagTextVideoPost` | StatelessWidget | Modules/Social | `lib/Modules/Social/hashtag_text_post.dart` | — | render, semantics, interaction, textScale |
| planned | P2 | `PhotoShortContent` | StatefulWidget | Modules/Social | `lib/Modules/Social/PhotoShorts/photo_short_content.dart` | — | render, semantics, interaction, textScale |
| planned | P2 | `PhotoShorts` | StatefulWidget | Modules/Social | `lib/Modules/Social/PhotoShorts/photo_shorts.dart` | — | render, semantics, interaction, textScale |
| planned | P2 | `PostCommentContent` | StatefulWidget | Modules/Social | `lib/Modules/Social/Comments/post_comment_content.dart` | — | render, semantics, interaction, textScale |
| planned | P2 | `PostComments` | StatefulWidget | Modules/Social | `lib/Modules/Social/Comments/post_comments.dart` | — | render, semantics, interaction, textScale |
| planned | P2 | `PostSharers` | StatefulWidget | Modules/Social | `lib/Modules/Social/PostSharers/post_sharers.dart` | — | render, semantics, interaction, textScale |
| planned | P2 | `UrlPostMaker` | StatefulWidget | Modules/Social | `lib/Modules/Social/UrlPostMaker/url_post_maker.dart` | — | render, semantics, interaction, textScale |
| planned | P2 | `_PostSharerTile` | StatefulWidget | Modules/Social | `lib/Modules/Social/PostSharers/post_sharers_tile_part.dart` | — | render, semantics, interaction, textScale |
| planned | P2 | `ReportUser` | StatefulWidget | Modules/SocialProfile | `lib/Modules/SocialProfile/ReportUser/report_user.dart` | — | render, semantics, interaction, textScale |
| planned | P2 | `SocialProfile` | StatefulWidget | Modules/SocialProfile | `lib/Modules/SocialProfile/social_profile.dart` | — | render, semantics, interaction, textScale |
| planned | P2 | `SocialProfileFollowers` | StatefulWidget | Modules/SocialProfile | `lib/Modules/SocialProfile/SocialProfileFollowers/social_profile_followers.dart` | — | render, semantics, interaction, textScale |
| planned | P2 | `SocialQrCode` | StatefulWidget | Modules/SocialProfile | `lib/Modules/SocialProfile/SocialQrCode/social_qr_code.dart` | — | render, semantics, interaction, textScale |
| planned | P2 | `SpotifySelector` | StatefulWidget | Modules/SpotifySelector | `lib/Modules/SpotifySelector/spotify_selector.dart` | — | render, semantics, interaction, textScale |
| planned | P2 | `TypewriterText` | StatefulWidget | Modules/TypeWriter | `lib/Modules/TypeWriter/type_writer.dart` | — | render, semantics, interaction, textScale |
| planned | P2 | `HLSPlayer` | StatefulWidget | hls_player/hls_player.dart | `lib/hls_player/hls_player.dart` | — | render, semantics, interaction |
| planned | P2 | `_HLSPlayerControls` | StatefulWidget | hls_player/hls_player.dart | `lib/hls_player/hls_player.dart` | — | render, semantics, interaction |
| planned | P2 | `HLSPlayerExample` | StatefulWidget | hls_player/hls_player_example.dart | `lib/hls_player/hls_player_example.dart` | — | render, semantics, interaction |
