# UI Audit Report

Generated at: 2026-03-07 22:48:25 +03
Scope: `lib/**`

## Summary Counts
- TextOverflow.ellipsis: **95**
- maxLines:1: **90**
- fixed height literals: **805**
- fixed width literals: **459**
- Positioned widgets: **143**
- shrinkWrap:true: **55**
- NeverScrollableScrollPhysics: **49**

## Top Files (Text Clipping Risk)
```text
  13 lib/Modules/JobFinder/JobContent/job_content.dart
  12 lib/Modules/Agenda/ClassicContent/classic_content.dart
   9 lib/Modules/Education/CikmisSorular/cikmis_soru_olustur.dart
   7 lib/Modules/Education/Scholarships/scholarships_view.dart
   7 lib/Core/nickname_with_text_line.dart
   6 lib/Modules/Education/Antreman3/AntremanScore/antreman_score.dart
   6 lib/Modules/Chat/chat.dart
   6 lib/Modules/Chat/MessageContent/message_content.dart
   5 lib/Modules/Education/Tests/TestsGrid/tests_grid.dart
   5 lib/Modules/Education/Scholarships/SavedItems/saved_items_view.dart
   5 lib/Modules/Education/Scholarships/MyScholarship/my_scholarship_view.dart
   5 lib/Modules/Education/PracticeExams/DenemeGrid/deneme_grid.dart
   5 lib/Modules/Agenda/AgendaContent/agenda_content.dart
   4 lib/Modules/Profile/MyProfile/profile_view.dart
   4 lib/Modules/JobFinder/JobDetails/job_details.dart
   4 lib/Modules/Education/Tutoring/tutoring_widget_builder.dart
   4 lib/Modules/Education/Tutoring/TutoringDetail/tutoring_detail.dart
   4 lib/Modules/Education/PracticeExams/DenemeGecmisSonucContent/deneme_gecmis_sonuc_content.dart
   4 lib/Modules/Education/AnswerKey/BookletResultPreview/booklet_result_preview.dart
   3 lib/hls_player/hls_player_example.dart
```

## Top Files (Small Screen Risk)
```text
   9 lib/Modules/Education/CikmisSorular/cikmis_soru_olustur.dart
   8 lib/Modules/JobFinder/JobCreator/job_creator.dart
   6 lib/Modules/Social/ShareOfPost/share_of_post.dart
   6 lib/Modules/Education/Scholarships/Applications/applications_view.dart
   6 lib/Core/Widgets/skeleton_loader.dart
   4 lib/Modules/Splash/splash_view.dart
   4 lib/Modules/Education/Scholarships/CreateScholarship/scholarship_preview_view.dart
   4 lib/Modules/Education/AnswerKey/CreateBook/create_book.dart
   3 lib/Modules/Education/Tutoring/TutoringDetail/tutoring_detail.dart
   2 lib/Services/current_user_test_widget.dart
   2 lib/Modules/RecommendedUserList/recommended_user_list.dart
   2 lib/Modules/RecommendedUserList/RecommendedUserContent/recommended_user_content.dart
   2 lib/Modules/Profile/EditProfile/edit_profile.dart
   2 lib/Modules/Education/Scholarships/SavedItems/saved_items_view.dart
   2 lib/Modules/Education/PracticeExams/SinavHazirla/sinav_hazirla.dart
   2 lib/Modules/Education/Antreman3/AntremanComments/antreman_comments.dart
   2 lib/Core/Widgets/error_report_widget.dart
   2 lib/Core/Helpers/QRCode/qr_scanner_view.dart
   1 lib/Modules/Story/StoryRow/story_row.dart
   1 lib/Modules/Profile/MyProfile/profile_view.dart
```

## Notes
- This audit is static. It does not change app behavior.
- Prioritize files that are high in both sections above.
- Validate final fixes on:
  - <=360dp
  - 361-412dp
  - >412dp
  - text scale 1.0 / 1.3 / 1.6
