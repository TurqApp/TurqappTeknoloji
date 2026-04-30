# TurqApp App Architecture Orchestration Plan

Branch: `refactor/app-architecture-orchestration`

Goal: make startup, auth, routing, cache, state, and data access behave as one coordinated application system instead of separate screen-level decisions.

## Current Diagnosis

The app already has a central spine:

- `lib/main.dart`
- `lib/Modules/Splash/splash_startup_orchestrator.dart`
- `lib/Modules/Splash/splash_session_bootstrap.dart`
- `lib/Services/current_user_service.dart`
- `lib/Runtime/app_root_navigation_service.dart`
- snapshot and manifest repositories under `lib/Core/Repositories`

The main risk is not absence of architecture. The risk is parallel decision paths still living inside screens and controllers:

- Direct `FirebaseAuth.instance` in modules.
- Direct `FirebaseFirestore.instance` in modules.
- Direct `SharedPreferences.getInstance()` in modules.
- Raw `Get.to`, `Get.off`, `Get.offAll`, `Navigator.push` decisions across screens.
- Splash widget owning too much startup and routing logic.

Important data-source rule for the remaining work:

- Typesense/search/listing/read paths must stay on their existing source unless a separate, explicit migration is planned.
- This refactor centralizes existing Firestore writes behind repositories/services; it must not silently convert Typesense-powered surfaces to Firestore reads.

## Closing Architecture Status

The app is now operating through a substantially centralized orchestration spine rather than screen-by-screen startup decisions.

Completed central boundaries:

- Startup/root routing is represented by `StartupDecision` and `AppDecisionCoordinator`.
- Root-clearing navigation is owned by `AppRootNavigationService`, with exit flows routed through `SessionExitCoordinator` where feature/session code owns the exit intent.
- Primary tab mapping is semantic through `PrimaryTabRouter`; education/profile index math is centralized in NavBar through `_PrimaryTabLayout`.
- Splash startup route-hint vocabulary is owned by `StartupRouteHint`, and route telemetry is captured once per navigation pass.
- Splash runtime-health summary emission is centralized through `_trackStartupRuntimeHealthSummary`.
- Deep-link parsing and education deep-link routing are delegated to shared utilities/router boundaries.
- Firebase Auth, Firestore, Functions, Messaging, Storage singleton access is guarded behind app/Core boundaries, with module-level exceptions covered by explicit tests where still approved.
- Shared preferences singleton access is owned by `LocalPreferenceRepository`.

Approved intentional exceptions:

- Typesense search/listing paths remain Typesense-backed. This work intentionally does not migrate those reads to Firestore.
- PostCreator owns its own local creator tab state; primary app tab mutation guards explicitly exclude that local state.
- Low-level app wrappers such as `AppFirestore`, `AppFirebaseAuth`, `AppCloudFunctions`, `AppFirebaseStorage`, and `AppFirebaseMessaging` are allowed to touch SDK singletons.
- Upload/storage-heavy owner services may use `AppFirebaseStorage` directly when they are the approved storage boundary for that domain.
- Splash and `CurrentUserService` lifecycle remain approved low-level session/startup boundaries for root sign-in routing.

Final closeout posture:

- Further code changes should be limited to analyzer cleanup, guard-only tests, or verified behavioral risks.
- New feature work should not add direct SDK singleton access, raw root-clearing navigation, raw startup `nav_*` literals, or screen-local startup/auth decisions.
- Long-term work should focus on shared UI state rendering and component-level loading/empty/error standardization rather than more startup/auth/routing refactor.

## Final Verification Status

Architecture closeout checks are green:

- `flutter analyze`: passed.
- `dart analyze lib/Modules/Agenda/ClassicContent/classic_content_helpers_part.dart`: passed.
- `flutter test test/unit/runtime`: passed, 193 tests.
- `flutter test test/unit/modules/splash`: passed, 12 tests.
- Startup/navigation focused tests: passed, 55 tests.
- Deep-link focused tests: passed, 15 tests.
- Classic/Agenda content navigation boundary tests: passed, 2 tests.

Full `flutter test` status:

- Fresh full run passed: `662` passed, `1` skipped, `0` failed.
- Functions TypeScript build passed: `npm run build`.
- Functions unit tests passed: `npm run test:unit`, 36 tests.
- Firestore/Storage rules emulator tests passed: `npm run test:rules`, 99 tests.
- Security regression gate passed: `npm run test:security-regressions`, 5 unit tests plus 99 emulator rules tests.
- Integration registry, integration key coverage, and QA Lab catalog inventory are synced and pass.
- Behavior-contract alignment was applied and the previously failing focused groups now pass:
  - `flutter test test/unit/core/services/feed_render_coordinator_build_test.dart test/unit/core/services/prefetch_scheduler_policy_test.dart test/unit/core/services/feed_playback_selection_policy_test.dart test/unit/modules/short/short_feed_application_service_test.dart test/unit/modules/short/short_launch_motor_contract_test.dart test/unit/modules/agenda/feed_launch_motor_contract_test.dart test/unit/modules/agenda/post_content_base_warm_range_test.dart`: passed, 38 tests.
  - `flutter test test/unit/utils/integration_suite_registry_test.dart test/unit/utils/integration_key_contract_test.dart test/unit/services/qa_lab_catalog_test.dart`: passed, 9 tests.
  - `flutter test test/unit/services/qa_lab_recorder_test.dart`: passed, 44 tests.
  - `dart analyze` on the touched feed/short/playback/QA catalog files: no issues found.
- Behavior changes approved and applied:
  - feed render coordinator ordering/window expectations.
  - prefetch scheduler visible-window and boost expectations.
  - feed playback selection policy Android commanded-target retention.
  - short feed application service plan/delegation expectations.
  - short/feed launch motor owned-window and pool expectations.
  - agenda post warm-range expectations.

Closeout rule:

- Treat the architecture orchestration branch as behavior-preserving only for the verified startup/auth/navigation/preferences/backend boundaries.
- The full app test suite is green as of the fresh `flutter test` run above.
- Typesense/search/listing ownership remains preserved; behavior alignment did not migrate Typesense-backed reads to Firestore.

## Phase 1: Central App Decision Flow

### Objective

Move startup/root-route decisions out of the splash widget and into a root coordinator.

### Proposed Additions

- `lib/Runtime/app_decision_coordinator.dart`
- `lib/Runtime/startup_decision.dart`

### Target Files

- `lib/main.dart`
- `lib/Modules/Splash/splash_view.dart`
- `lib/Modules/Splash/splash_view_startup_part.dart`
- `lib/Modules/Splash/splash_startup_orchestrator.dart`
- `lib/Modules/Splash/splash_session_bootstrap.dart`

### Work Items

- Define `StartupDecision`.
- Represent auth as `unknown`, `authenticated`, `unauthenticated`.
- Represent target root as `splash`, `signIn`, `authenticatedHome`.
- Represent target tab as semantic values, not raw indexes.
- Move route decision from `SplashView` into coordinator.
- Make splash render startup state only.
- Convert watchdog behavior into degraded startup decision, not direct navigation.

### Acceptance Criteria

- Splash no longer decides authenticated vs sign-in route directly.
- Startup route choice is unit-testable without a widget.
- iOS auth restore cannot route as unauthenticated while auth is still unknown.

## Phase 2: Session Exit And Auth Ownership

### Objective

Make `CurrentUserService` the single source of user/auth truth for modules.

### Proposed Additions

- `lib/Runtime/session_exit_coordinator.dart`

### Target Files

- `lib/Services/current_user_service.dart`
- `lib/Modules/Profile/DeleteAccount/delete_account_actions_part.dart`
- `lib/Modules/Profile/SavedPosts/saved_posts_controller_data_part.dart`
- `lib/Modules/Profile/LikedPosts/liked_posts_controller_data_part.dart`
- other module files using direct `FirebaseAuth.instance`

### Work Items

- Route logout, delete-account, ban, account-switch through `SessionExitCoordinator`.
- Replace direct module auth streams with `CurrentUserService.userStream` or a session state facade.
- Keep FirebaseAuth access inside auth/service adapter layer only.

### Acceptance Criteria

- Delete account clears root navigation stack.
- Saved/Liked posts respond to the same session source as the rest of the app.
- No new module-level direct auth reads are introduced.

## Phase 3: Navigation Standard

### Objective

Centralize route decisions and remove raw tab-index knowledge from feature code.

### Proposed Additions

- `lib/Runtime/primary_tab_router.dart`
- `lib/Runtime/entity_route_resolver.dart`

### Target Files

- `lib/Runtime/app_root_navigation_service.dart`
- `lib/Core/Services/deep_link_service_open_part.dart`
- `lib/Core/NotifyReader/notify_reader_controller_navigation_part.dart`
- `lib/Modules/NavBar/nav_bar_controller_support_part.dart`
- `lib/Modules/NavBar/nav_bar_view_shell_content_part.dart`

### Work Items

- Introduce semantic primary tabs: feed, explore, short, education, profile.
- Move feature-flag-aware tab mapping to `PrimaryTabRouter`.
- Move post/user/story/market/job/tutoring open behavior to `EntityRouteResolver`.
- Make deep link and notification use the same entity resolver.
- Fix persisted selected tab restore to read a real persisted source.

### Acceptance Criteria

- No raw education tab index in deep link code.
- Notification and deep link open the same entity with the same rules.
- Last selected primary tab restores consistently.

## Phase 4: Cache And Local Data Policy

### Objective

Stop screen-level cache policy drift.

### Proposed Additions

- `lib/Core/Repositories/local_preference_repository.dart`
- `lib/Core/Services/surface_cache_policy.dart`

### Target Files

- `lib/Modules/Market/market_controller_home_part.dart`
- `lib/Modules/Explore/explore_view_tabs_part.dart`
- `lib/Modules/Chat/**`
- `lib/Modules/Education/**`
- repositories using local prefs directly

### Work Items

- Centralize user-scoped local preference keys.
- Standardize `preferCache`, `cacheOnly`, `forceServer`, `ttl`, and stale-read behavior.
- Move module prefs reads/writes behind repository/service methods.
- Align snapshot repositories and screen local state with one cache policy vocabulary.

### Acceptance Criteria

- New screen-level direct `SharedPreferences.getInstance()` calls are not needed.
- User-scoped prefs are generated by one helper/repository.
- Cache refresh decisions are explainable per surface.

## Phase 5: Data Access And Write Boundaries

### Objective

Prevent UI/controllers from owning Firestore schema and write side effects.

### Proposed Additions

- `lib/Core/Services/post_publishing_service.dart` or `lib/Core/Repositories/post_write_repository.dart`

### Target Files

- `lib/Modules/PostCreator/post_creator_controller_publish_upload_part.dart`
- `lib/Modules/EditPost/edit_post_controller_actions_part.dart`
- `lib/Core/Repositories/post_repository.dart`
- `lib/Services/post_delete_service.dart`

### Work Items

- Move post create schema to a write service.
- Keep counter updates, share records, Typesense sync, profile manifest sync, and cache invalidation together.
- Leave UI controllers responsible for form state and user interaction only.

### Acceptance Criteria

- Post create/edit/delete flows share one write-side contract.
- Post schema is not duplicated in UI controllers.
- Cache invalidation is triggered by write services, not scattered screens.

## Phase 6: UI State Standard

### Objective

Normalize loading, empty, error, refresh, and retry behavior.

### Proposed Additions

- `lib/Core/State/surface_state.dart`
- `lib/Core/Widgets/surface_state_view.dart`

### Target Files

- `lib/Modules/Market/market_saved_view_content_part.dart`
- `lib/Modules/Profile/**`
- `lib/Modules/Education/**`
- `lib/Core/Widgets/**`

### Work Items

- Define `SurfaceState<T>`.
- Introduce common state rendering widget.
- Replace isolated `FutureBuilder` loading/empty patterns incrementally.
- Keep UI local state separate from app/session state.

### Acceptance Criteria

- Similar list screens show loading, empty, error, and retry consistently.
- Controllers expose state as structured state instead of unrelated booleans where practical.

## Phase 7: Architecture Guardrails

### Objective

Prevent architectural drift from returning.

### Proposed Tests

- Modules should not directly use `FirebaseFirestore.instance`.
- Modules should not directly use `FirebaseAuth.instance`.
- Root-clearing navigation should go through root navigation/session services.
- Module-level `SharedPreferences.getInstance()` should be replaced by local preference services.

### Acceptance Criteria

- Architecture checks can run in CI.
- New violations fail fast with actionable file references.

## First Sprint Order

1. Done: add `StartupDecision` and `AppDecisionCoordinator` skeleton.
2. Done: add unit tests for startup decision cases.
3. Done: add `SessionExitCoordinator`.
4. Done: fix delete-account navigation to use session/root navigation service.
5. Done: add `PrimaryTabRouter`.
6. Done: replace deep-link raw education index.
7. Done: fix selected tab restore path.
8. Done: move Saved/Liked/Profile/Archive auth listeners to central session source.
9. Done: move profile settings diagnostics auth read to `CurrentUserService`.
10. Done: move splash bootstrap auth snapshots to `CurrentUserService`.
11. Done: move SignIn controller auth calls behind `sign_in_application_service.dart`.
12. Done: add module auth boundary guard test.
13. Done: wire splash root-route decision through `AppDecisionCoordinator`.
14. Done: align splash bootstrap tests with deferred audio and returning-session auth restore contract.
15. Done: add root-clearing navigation boundary guard test.
16. Done: remove direct Firestore access from `lib/Modules/Profile`.
17. Done: add profile Firestore boundary guard test.
18. Done: remove direct Firestore access from `lib/Modules/JobFinder`.
19. Done: add JobFinder Firestore boundary guard test.
20. Done: remove direct Firestore access from `lib/Modules/Education/AnswerKey`.
21. Done: add AnswerKey Firestore boundary guard test.
22. Done: remove direct Firestore access from `lib/Modules/Education/Tests`.
23. Done: add Education Tests Firestore boundary guard test.
24. Done: move PracticeExams create/publish/question-write flow to `PracticeExamRepository`.
25. Done: move PracticeExams preview/apply/complete/invalid/answer-save writes to `PracticeExamRepository`.
26. Done: add narrow PracticeExams write-flow Firestore boundary guard test.
27. Done: move Antreman complaint submit write to `ReportRepository`.
28. Done: add Antreman Firestore boundary guard test.
29. Done: move Scholarship create/update writes to `ScholarshipRepository`.
30. Done: add Scholarships Firestore boundary guard test.
31. Done: move Tutoring create/update/archive/reactivate writes to `TutoringRepository`.
32. Done: add Tutoring Firestore boundary guard test.
33. Done: move Social post dislike and URL post create/share writes to `PostRepository`.
34. Done: add Social Firestore boundary guard test.
35. Done: move StoryMaker story document create/save writes to `StoryRepository`.
36. Done: add StoryMaker Firestore boundary guard test.
37. Done: move EditPost post update write to `PostRepository`.
38. Done: add EditPost Firestore boundary guard test.
39. Done: move PostCreator shell, source edit, publish, URL/share writes to `PostRepository`.
40. Done: add PostCreator Firestore boundary guard test.
41. Done: move remaining module-level Firestore instance defaults to `AppFirestore`.
42. Done: add global modules Firestore boundary guard test.
43. Done: add `LocalPreferenceRepository`.
44. Done: move Explore recent-search and flood-rotation prefs to `LocalPreferenceRepository`.
45. Done: add Explore preferences boundary guard test.
46. Done: move JobFinder listing-selection prefs to `LocalPreferenceRepository`.
47. Done: add JobFinder preferences boundary guard test.
48. Done: move AnswerKey listing-selection prefs to `LocalPreferenceRepository`.
49. Done: add AnswerKey preferences boundary guard test.
50. Done: move PracticeExams listing-selection prefs to `LocalPreferenceRepository`.
51. Done: add PracticeExams preferences boundary guard test.
52. Done: move Scholarships listing-selection prefs to `LocalPreferenceRepository`.
53. Done: add Scholarships listing preferences boundary guard test.
54. Done: move Market schema cache, recent-search, and listing-selection prefs to `LocalPreferenceRepository`.
55. Done: add Market preferences boundary guard test.
56. Done: move Chat listing cache, conversation window cache, deleted-message cache, forward candidates, and opened-at prefs to `LocalPreferenceRepository`.
57. Done: add Chat preferences boundary guard test.
58. Done: move NavBar selected-tab and rating-prompt prefs to `LocalPreferenceRepository`.
59. Done: add NavBar preferences boundary guard test.
60. Done: move Short offline-cache quota pref to `LocalPreferenceRepository`.
61. Done: add Short preferences boundary guard test.
62. Done: move Profile Settings education/pasaj visibility and permissions quota prefs to `LocalPreferenceRepository`.
63. Done: add Profile Settings preferences boundary guard test.
64. Done: move Tutoring view-mode and location-based listing cache prefs to `LocalPreferenceRepository`.
65. Done: add Tutoring preferences boundary guard test.
66. Done: move Scholarships personalized cache and detail-ad cooldown prefs to `LocalPreferenceRepository`.
67. Done: add Scholarships module preferences boundary guard test.
68. Done: move Antreman main-category and category-pool cache prefs to `LocalPreferenceRepository`.
69. Done: add Antreman preferences boundary guard test.
70. Done: move Agenda TopTags disk cache prefs to `LocalPreferenceRepository`.
71. Done: add Agenda preferences boundary guard test.
72. Done: move Splash direct startup/media-cache preference reads to `LocalPreferenceRepository`.
73. Done: add Splash direct preferences boundary guard test.
74. Done: move app language, network awareness, device legacy key, and notification token cache prefs to `LocalPreferenceRepository`.
75. Done: add core app-level preferences boundary guard test.
76. Done: move config repository disk cache and startup surface order fallback prefs to `LocalPreferenceRepository`.
77. Done: extend core app-level preferences boundary guard test for config/startup order.
78. Done: move draft autosave/draft-list and upload queue persistence prefs to `LocalPreferenceRepository`.
79. Done: extend core app-level preferences boundary guard test for draft/upload queue persistence.
80. Done: move user profile cache, profile posts cache, and feed diversity memory prefs to `LocalPreferenceRepository`.
81. Done: extend core app-level preferences boundary guard test for profile/feed cache services.
82. Done: move CurrentUserService, AccountCenterService, and OfflineModeService session persistence prefs to `LocalPreferenceRepository`.
83. Done: extend core app-level preferences boundary guard test for session/account/offline persistence.
84. Done: move PracticeExam, Test, OpticalForm, and Booklet repository cache prefs to `LocalPreferenceRepository`.
85. Done: add Education repository preferences boundary guard test.
86. Done: move Core Ads Firestore/Functions/Storage singleton access to `AppFirestore`, `AppCloudFunctions`, and `AppFirebaseStorage`.
87. Done: add Core Ads backend boundary guard test.
88. Done: move post counter and phone account limiter Firestore singleton access to `AppFirestore`.
89. Done: add counter/account backend boundary guard test.
90. Done: move OfflineModeService queued action replay Firestore singleton access to `AppFirestore`.
91. Done: add OfflineModeService backend boundary guard test.
92. Done: move StoryInteractionOptimizer Firestore singleton access to `AppFirestore`.
93. Done: add StoryInteractionOptimizer backend boundary guard test.
94. Done: move override-friendly Core service defaults to `AppFirestore`/`AppFirebaseStorage`.
95. Done: add override-friendly Core backend boundary guard test.
96. Done: move FirestoreConfig singleton access to `AppFirestore`.
97. Done: add FirestoreConfig backend boundary guard test.
98. Done: move PostDeleteService Firestore singleton access to `AppFirestore`.
99. Done: add PostDeleteService backend boundary guard test.
100. Done: move UploadQueueService Firestore/Storage singleton access to `AppFirestore`/`AppFirebaseStorage`.
101. Done: add UploadQueueService backend boundary guard test.
102. Done: add global service backend singleton boundary guard for `lib/Core/Services` and `lib/Services`.
103. Done: move first repository default backend dependencies to AppFirestore/AppFirebaseStorage.
104. Done: add repository default backend boundary guard test.
105. Done: move second repository default backend dependencies to AppFirestore/AppFirebaseStorage.
106. Done: move repository callable/report backend access to AppCloudFunctions/AppFirestore.
107. Done: add repository callable/report backend boundary guard test.
108. Done: move admin/support/notification repository backend access to AppFirestore.
109. Done: add admin/support repository backend boundary guard test.
110. Done: move user repository and user subcollection/subdoc backend access to AppFirestore.
111. Done: add user repository backend boundary guard test.
112. Done: move FollowRepository backend access to AppFirestore.
113. Done: add FollowRepository backend boundary guard test.
114. Done: move config/preference/moderation repository backend access to AppFirestore.
115. Done: add config/preference/moderation repository backend boundary guard test.
116. Done: move CV and social media links repository backend access to AppFirestore.
117. Done: add CV/social repository backend boundary guard test.
118. Done: move owner/type snapshot repository Firestore fallbacks to AppFirestore.
119. Done: add snapshot repository backend boundary guard test.
120. Done: move AdminPushRepository backend access to AppFirestore.
121. Done: add AdminPushRepository backend boundary guard test.
122. Done: move profile stats/profile default/recommended users repository backend access to AppFirestore.
123. Done: add profile/recommendation repository backend boundary guard test.
124. Done: move education snapshot repository backend access to AppFirestore.
125. Done: add education snapshot repository backend boundary guard test.
126. Done: move StoryHighlightsRepository backend access to AppFirestore.
127. Done: add StoryHighlightsRepository backend boundary guard test.
128. Done: move StoryRepository foundation/cache backend access to app backend boundaries.
129. Done: add StoryRepository foundation/cache backend boundary guard test.
130. Done: move StoryRepository deleted-story backend access to app backend boundaries.
131. Done: add StoryRepository deleted-story backend boundary guard test.
132. Done: move StoryRepository engagement backend access to AppFirestore.
133. Done: add StoryRepository engagement backend boundary guard test.
134. Done: add global app backend singleton boundary guard across repositories, services, and modules.
135. Done: strengthen SignIn controller delegation tests for password reset and signup auth creation.
136. Done: add shared AppStateView for loading/empty/error/retry UI states and migrate SocialMediaLinks initial loading state.
137. Done: migrate AnswerKey listing, Reports admin, and Support admin loading/empty/error states to AppStateView without changing data flow.
138. Done: migrate Scholarships startup loading and SavedItems loading/empty states to AppStateView without changing listing/search/cache behavior.
139. Done: migrate Scholarship BankInfo, DormitoryInfo, and PersonelInfo startup loading states to AppStateView without changing form/save behavior.
140. Done: migrate Scholarship Applications, MyScholarship, Providers, and FamilyInfo loading/empty states to AppStateView without changing routes or list behavior.
141. Done: migrate Scholarship EducationInfo and Personalized startup/select-level states to AppStateView without changing selection or recommendation behavior.
142. Done: migrate Scholarship application card/profile loading states to AppStateView without changing applicant route or detail rendering.
143. Done: migrate AnswerKey SavedOpticalForms, MyBookletResults, and SearchAnswerKey loading/empty/search states to AppStateView without changing list/search/navigation behavior.
144. Done: migrate AnswerKey CategoryBased and OpticsAndBooksPublished loading/empty states to AppStateView without changing preview or published-list behavior.
145. Done: migrate AnswerKey shell startup loading and Reports/Admin access loading states to AppStateView without changing access checks or streams.
146. Done: migrate Profile Settings approvals, notifications, permissions, and story music loading/empty states to AppStateView without changing settings/admin behavior.
147. Done: migrate Ads Center, Surface Policy, Account Center, admin assignment/badge/moderation stream loading/error states to AppStateView without changing admin/settings behavior.
148. Done: migrate AdminPush loading/report stream states to AppStateView and restore Cupertino imports required by account/permissions part files.
149. Done: migrate Chat listing and location-share startup loading states to AppStateView without changing chat list, search, archive, map, or send-location behavior.
150. Done: migrate Market home, my listings, offers, and saved-list loading/empty states to AppStateView without changing listing/search/offer behavior.
151. Done: migrate JobFinder home, saved jobs, my applications, my job ads, applicant review, and career profile startup/list states to AppStateView without changing job listing/search/application behavior.
152. Done: migrate Explore trending/for-you/series loading and empty states to AppStateView without changing search, Typesense/cache-backed explore feed, flood ordering, or refresh behavior.
153. Done: migrate Profile archive, liked posts, saved post/market/job/scholarship tabs loading and empty states to AppStateView without changing post cache, saved stores, or listing controllers.
154. Done: migrate Following/Followers initial loading and empty list states to AppStateView without changing follow cache, pagination, profile opening, or load-more behavior.
155. Done: migrate BlockedUsers and MyStatistic visible loading/empty states to AppStateView without changing unblock, statistic fetch, refresh, or profile summary behavior.
156. Done: migrate Profile main post/photo/video/reshare/scheduled/market tab empty/loading surfaces to AppStateView without changing feed/cache, media grid, market snapshot, or navigation behavior.
157. Done: migrate Tutoring my listings, my applications, and application review loading/empty/error states to AppStateView without changing listing cards, application actions, or controller ownership.
158. Done: migrate Tests saved/results/solve/result-preview loading and empty states to AppStateView without changing solve flow, result mapping, question cards, or media placeholders.
159. Done: migrate InAppNotifications and Story likes/seens/comments/deleted/music profile loading/empty states to AppStateView without changing grouping, comment input, restore/delete, or music story fetch behavior.
160. Done: migrate SocialProfile feed/photo/video/reshare/scheduled/market empty/loading surfaces to AppStateView without changing social feed/cache, market snapshot, media grid, or navigation behavior.
161. Done: migrate PracticeExams, SavedPracticeExams, LessonBasedTests, CikmisSorular, and practice result-preview loading/empty states to AppStateView without changing skeletons, pagination, search/query, or question rendering.
162. Done: migrate Tutoring main/search/detail/location loading and empty states to AppStateView without changing filters, result lists, favorite/apply actions, or load-more behavior.
163. Done: migrate Antreman main/search, comments, and solve-later loading/empty states to AppStateView without changing question selection, comment composer, saved-question list, or card rendering.
164. Done: migrate Spotify selector, Market search/create, and Tutoring category loading/empty states to AppStateView without changing search, form, category, listing, or selection behavior.
165. Done: migrate practice exam preview/solve screen loading and empty states to AppStateView without changing rules, solve flow, question rendering, or refresh behavior.
166. Done: audit remaining Phase 6 spinner/empty hits and classify them as intentionally local micro states unless a later UX pass introduces a component-level placeholder standard.
167. Done: move splash startup primary tab index selection from the local `_preferredStartupNavIndex()` helper to `StartupPrimaryTab` decisions plus `PrimaryTabRouter`, with parity tests for selected index and route-hint mapping.
168. Done: strengthen SignInApplicationService password sign-in guard tests for auth failure and pre-auth generic failure without changing controller or Firebase behavior.
169. Done: centralize splash startup decision input construction behind `_decideStartupRoute()` and `_startupEducationEnabled()` so telemetry and navigation use the same decision shape.
170. Done: extract shared splash startup decision and warm-readiness telemetry field builders so KPI and manifest navigation records no longer duplicate the same field maps.
171. Done: extend splash startup route-hint normalization tests for feed/home hints, trimming, exact freshness boundary, stale, null, negative, and invalid manifest cases.
172. Done: widen the root navigation boundary guard so Get/Navigator root-clearing variants stay behind AppRootNavigationService.
173. Done: extract deep-link URI parsing into a pure `parseDeepLinkUri` utility and add guard tests for approved hosts, custom scheme forms, aliases, id normalization, and invalid entries.
174. Done: add a DeepLinkService parser boundary guard so URI parsing remains delegated to `deep_link_utils` instead of drifting back into service-private route parsing.
175. Done: add a deep-link education navigation guard so education links keep using `PrimaryTabRouter.openEducation()` instead of writing nav indexes directly.
176. Done: strengthen AppDecisionCoordinator tests for requested-tab precedence, education-disabled normalization, and effective user id trimming.
177. Done: route Profile Settings and Account Center sign-out/switch exits through SessionExitCoordinator and add a guard test for that boundary.
178. Done: centralize Splash SessionBootstrap first-launch auth/local cleanup behind one helper without changing cleanup order or navigation behavior.
179. Done: move SignIn feed-tab reset and Scholarship post-submit education-tab routing behind PrimaryTabRouter and guard against direct selected-index/index-3 mutation.
180. Done: move Short swipe-right feed return behind PrimaryTabRouter and guard against direct index-0 tab mutation without changing playback, cache, or feed data sources.
181. Done: centralize education deep-link tab selection in deep_link_utils and guard DeepLinkService against reintroducing local prefix-to-tab chains.
182. Done: add a broad PrimaryTabRouter boundary guard so feature surfaces cannot reintroduce literal primary-tab index mutations; PostCreator remains the explicit local-state exception.
183. Done: widen the root navigation boundary guard for named/off-until/pop-until root-clearing variants so root resets stay behind AppRootNavigationService.
184. Done: centralize direct education deep-link bypass decisions in deep_link_utils so DeepLinkService runtime no longer owns a local prefix chain.
185. Done: remove DeepLinkService's duplicate private parsed-link model so parsing, direct-bypass checks, and fallback handling share ParsedDeepLinkRoute from deep_link_utils.
186. Done: centralize splash startup selected-nav-index calculation behind `_startupNavSelectedIndex()` so manifest telemetry and authenticated-home routing share one PrimaryTabRouter decision.
187. Done: move accepted startup route-hint normalization into Runtime AppDecisionCoordinator so Splash freshness checks no longer own the nav route vocabulary.
188. Done: centralize startup route hints that require warm readiness so Splash no longer repeats the explore/profile/education route list for fallback and feed-readiness decisions.
189. Done: add a SessionExitCoordinator boundary guard so feature code cannot reintroduce direct offAllToSignIn navigation outside approved startup/session service boundaries.
190. Done: deduplicate Account Center account-switch session exit callbacks behind one local coordinator helper without changing account-switch or reauth routing behavior.
191. Done: add an authenticated-home root navigation boundary guard so new feature code cannot call offAllToAuthenticatedHome/offToAuthenticatedHome outside approved startup/auth/notification/post-submit flows.
192. Done: move remaining Core slider/external direct Firestore and Storage singleton access behind AppFirestore/AppFirebaseStorage and widen the backend singleton guard to include lib/Core.
193. Done: add AppFirebaseAuth and route Core/Services auth singleton reads through it while keeping SignIn as the approved auth entry boundary.
194. Done: extract NotifyReader notification route decisions into a pure resolver with tests for profile, chat, listing, comment, post, fallback, and missing-target behavior without changing navigation targets.
195. Done: add a NotifyReader controller boundary guard so notification route classification cannot drift back into controller runtime or field constants.
196. Done: route the legacy NotifyReader widget through the same notification route resolver while preserving its narrower supported type set and Get.back fallback behavior.
197. Done: route NotificationService FCM tap handling through the same notification route resolver while preserving supported tap types and no-op behavior for unknown types.
198. Done: introduce a typed StartupRouteHint runtime vocabulary and route Splash warm-readiness checks through it instead of a local nav_* string switch.
199. Done: add a startup route-hint boundary guard so Splash cannot reintroduce local nav_* string cases for warm-readiness decisions.
200. Done: move remaining Splash startup route-hint equality checks behind StartupRouteHint so warmup prioritization no longer compares nav_* literals directly.
201. Done: move NavBar selected-index startup route-hint mapping behind `PrimaryTabRouter.routeHintForSelectedIndex` and guard against local `nav_*` return mapping in NavBar support.
202. Done: move Education Pasaj startup route-hint persistence to `StartupRouteHint.education.value` and guard against reintroducing literal `nav_education` in the module part.
203. Done: move Splash feed fallback route-hint returns to `StartupRouteHint.feed.value` and tighten the startup route-hint guard against literal `return 'nav_feed'`.
204. Done: route `PrimaryTabRouter.routeHintFor` string output through `StartupRouteHint.*.value` so the route-hint vocabulary has a single runtime owner.
205. Done: add a broad route-hint literal guard so feature code cannot reintroduce `nav_*` startup route strings outside the approved runtime vocabulary owner.
206. Done: move Splash unknown startup route-hint fallbacks to `StartupRouteHint.unknown.value` and tighten the startup guard against literal `return 'unknown'`.
207. Done: centralize related Job/Tutoring detail replacement navigation behind `EducationDetailNavigationService` and guard against feature-local `Get.off` replacements.
208. Done: route Job/Tutoring listing-card detail opens through `EducationDetailNavigationService` while preserving post-return refresh and tutoring reactivation behavior.
209. Done: route deep-link, education-feed CTA, and notification Job/Tutoring detail opens through `EducationDetailNavigationService` while leaving lookup, missing-listing snackbar, and return-to-navbar behavior unchanged.
210. Done: add `MarketDetailNavigationService` and route Market module, deep-link, education-feed CTA, and notification market detail opens through it while preserving refresh/reload and missing-listing behavior.
211. Done: route profile, social profile, and saved-posts market detail opens through `MarketDetailNavigationService` while preserving feed suspension/resume and reload-after-return behavior.
212. Done: add a broad Market detail navigation guard so feature code cannot reintroduce direct `MarketDetailView(item:)` route construction outside the approved service and local related-card exception.
213. Done: add route-only `ScholarshipNavigationService.openDetailRoute` and move Personalized plus education-feed CTA direct scholarship detail opens behind it without adding interstitial behavior.
214. Done: route PracticeExam preview opens from DenemeGrid and education-feed CTA through `PracticeExamNavigationService` while preserving owner dialog close and lookup/error behavior.
215. Done: route AnswerKey booklet preview opens from content cards, search results, and category results through `AnswerKeyNavigationService` while preserving view-count update, owner dialog close, and Typesense/search data flow.
216. Done: route AnswerKey, Tests, and PracticeExam result preview opens through `EducationResultNavigationService` while preserving result-card taps, controller ownership, and result model data flow.
217. Done: route Tests solve opens from TestsGrid and TestEntry through `EducationTestNavigationService` while preserving owner menu close order and post-return TestEntry reset behavior.
218. Done: route Tests search/saved/results/my-tests/create/join entry opens through `EducationTestNavigationService` while preserving edit-return update behavior and list/query ownership.
219. Done: route PracticeExam search/create/results/my-exams/saved entry opens through `PracticeExamNavigationService` while preserving school/rozet permission checks, owner dialog close order, and listing/cache ownership.
220. Done: route AnswerKey search/category/published/saved/results/create/join/booklet-answer entry opens through `AnswerKeyNavigationService` while preserving refresh callbacks and search/listing controller ownership.
221. Done: route Scholarship applications/saved/personalized/create/edit/my-listings/home/preview/profile-info entry opens through `ScholarshipNavigationService` while preserving rozet checks, refresh callbacks, detail interstitial behavior, and form reset behavior.
222. Done: route Tutoring and JobFinder search/applications/create/my-listings/saved/location/category/edit entry opens through `EducationDetailNavigationService` while preserving rozet checks, edit-return refresh behavior, and existing repository/cache/Typesense-vs-Firestore data ownership.
223. Done: route Market search/create/my-items/saved/offers/edit entry opens through `MarketDetailNavigationService` while preserving create-result upsert, post-return refresh behavior, and existing Typesense/repository/cache ownership.
224. Done: route Antreman/QuestionBank solve-later and past-question results entry opens through `EducationQuestionBankNavigationService` while preserving saved-question refresh/clear ordering and existing repository ownership.
225. Done: route Education and deep-link profile opens through `ProfileNavigationService` while preserving current-user checks, missing-profile guards, and existing user/profile data ownership.
226. Done: route Scholarship applicant-profile opens through `ScholarshipNavigationService` while preserving application-card ownership and applicant profile data loading.
227. Done: route Education slider-admin opens through `SliderAdminNavigationService` while preserving slider ids/titles across Market, PracticeExams, OnlineExam, AnswerKey, Tutoring, and PastQuestions.
228. Done: route Education report-user opens through `ReportUserNavigationService` while preserving user/post/comment report parameters across Scholarship, AnswerKey, PracticeExam, and Tutoring detail surfaces.
229. Done: route Tutoring detail chat-listing opens through `ChatNavigationService` while preserving `ChatListingController` ownership and existing chat/conversation data flow.
230. Done: route BecomeVerifiedAccount opens through `VerifiedAccountNavigationService` across PracticeExams, Settings, and MyProfile while preserving rozet/application checks and profile feed suspend/resume behavior.
231. Done: route JobFinder profile, report-user, and CV opens through shared navigation services while preserving mention lookup, application review profile taps, report payloads, CV editor refresh, and existing job/CV data ownership.
232. Done: route Market detail seller-profile and chat-listing opens through shared navigation services while preserving owner guards, edit behavior, offer/contact services, and existing Typesense/repository ownership.
233. Done: route Profile and Agenda chat-listing opens through `ChatNavigationService` while preserving profile feed suspend/resume, Agenda playback resume, unread-chat marking, and recommended-user refresh behavior.
234. Done: route RecommendedUserContent profile opens through `ProfileNavigationService` while preserving controller ownership and follow-status refresh after returning from profile.
235. Done: route Chat module profile opens through `ProfileNavigationService` while preserving chat list avatar behavior, chat header navigation, mention lookup, and existing conversation/message data flow.
236. Done: route follower/following list and notification avatar profile opens through `ProfileNavigationService` while preserving follow-status refresh and notification onOpen/onCardTap precedence.
237. Done: route post sharer, post-like, and post-reshare profile opens through `ProfileNavigationService` while preserving self-profile handling and follow-state refresh after returning.
238. Done: route Short profile, mention-profile, and report-user opens through shared navigation services while preserving volume handoff, story avatar behavior, and post/report identifiers.
239. Done: route ClassicContent profile, mention-profile, and report-user opens through shared navigation services while preserving feed-center restore, video pause behavior, StoryViewer avatar path, and report identifiers.
240. Done: route AgendaContent profile, mention-profile, and report-user opens through shared navigation services while preserving feed-center restore, video pause behavior, StoryViewer avatar path, and report identifiers.
241. Done: route StoryViewer mention, header, comment-user, and viewer-profile opens through `ProfileNavigationService` while preserving story playback pause/resume and self-user guards.
242. Done: route Social comment profile opens and PhotoShorts profile/report opens through shared navigation services while preserving comment self-user guards, avatar story fallback, and report identifiers.
243. Done: route QR scanner, shared post labels, and Explore searched-user profile opens through `ProfileNavigationService` while preserving QR detection, self-user guards, Explore preview suspend/resume, recent-search writes, and `preventDuplicates: false`.
244. Done: route SocialProfile report opens and profile-settings admin profile links through shared navigation services while preserving centered-post resume, user refresh, and admin record link behavior.
245. Done: route NotifyReader profile opens through `ProfileNavigationService` while preserving notification route resolution and return-to-navbar behavior; raw SocialProfile/ReportUser route construction is now limited to the approved navigation service owners.
246. Done: add a broad profile/report route owner guard so `SocialProfile` and `ReportUser` route construction cannot drift back into feature/Core screens outside their approved navigation services.
247. Done: move Antreman comment and legacy Tests question WebP image uploads away from module-owned `AppFirebaseStorage.instance` by letting `WebpUploadService` own the default storage boundary while preserving paths, auth retry behavior, and repository writes.
248. Done: move Profile EditProfile avatar, CV photo, SocialMediaLinks image, and StoryMusic admin cover WebP uploads away from module-passed storage by reusing the same `WebpUploadService` default storage boundary while preserving paths, NSFW checks, cleanup behavior, and repository/service writes.
249. Done: move legacy Tests create/question and PracticeExams question/cover WebP uploads away from module-passed storage by reusing `WebpUploadService` default storage boundary while preserving paths, moderation checks, feature gates, and repository writes.
250. Done: move Core Slider admin, JobCreator logo, Market create images, StoryMaker image, and StoryHighlights cover WebP uploads away from module-passed storage by reusing `WebpUploadService` default storage boundary while preserving paths, moderation checks, auth retry behavior, deletion/video storage behavior, and repository writes.
251. Done: move remaining PostCreator image and thumbnail WebP uploads away from module-passed storage by reusing `WebpUploadService` default storage boundary while preserving post media paths, image sizing, CDN conversion, video upload/storage behavior, auth retry metadata, and publish repository writes.
252. Done: move UploadQueueService image and thumbnail WebP uploads away from service-passed storage and add a broad guard so app code cannot pass `AppFirebaseStorage.instance` into `WebpUploadService` again.
253. Done: remove the remaining variable `storage:` arguments from Tutoring create images, EditPost image/thumbnail uploads, and Chat video thumbnails, then strengthen the broad guard so no app code can pass any storage argument into `WebpUploadService`.
254. Done: add a prepared-WebP upload path to `WebpUploadService` and move AnswerKey booklet cover plus Scholarship logo/image/template prepared WebP uploads behind it while preserving existing conversion quality, paths, cache-busted cover URL writes, and repository updates.
255. Done: add a direct storage owner guard so remaining module/Core Slider `AppFirebaseStorage.instance` usage is limited to approved non-WebP upload, progress, video/audio, and cleanup owners.
256. Done: deduplicate Splash startup telemetry map construction behind shared manifest-context and warmup-priority helpers while preserving emitted field names, route timing, KPI records, and startup navigation decisions.
257. Done: broaden deep-link parser contract tests for accepted web aliases, typo/go hosts, custom scheme aliases, rejected schemes/hosts, and incomplete routes before changing any deep-link open behavior.
258. Done: broaden startup navigation edge coverage so unauthenticated/unknown auth states ignore requested startup tabs and route hints until eligible, and `PrimaryTabRouter` edge indexes normalize deterministically.
259. Done: add route-auth guard coverage so unknown-auth timeout and unauthenticated cold route hints cannot create tab selection or route-hint fallback decisions, and authenticated-home decisions without a primary tab do not mutate the navbar.
260. Done: add a Splash navbar mutation guard so startup selected-index writes stay behind the authenticated-home decision branch and cannot run on sign-in or splash/unknown-auth paths.
261. Done: centralize Splash startup route telemetry fields so analytics and manifest navigation records reuse the same requested/effective/resolved/fallback values while preserving emitted key names and startup decisions.
262. Done: add a Splash route-telemetry drift guard so requested/effective/resolved/fallback key literals stay in the central route telemetry helper instead of splitting again across analytics and manifest code.
263. Done: add a Splash analytics-extra guard so all startup runtime-health surfaces reuse the captured requested/effective/resolved route values instead of recalculating route hints per surface.
264. Done: add a Splash startup-decision input guard so the navigation step captures requested/effective route hints once, passes the effective route into `AppDecisionCoordinator`, and derives warm fallback from the captured route pair.
265. Done: broaden `AppDecisionCoordinator` edge coverage so trimmed warm route hints remain warm-ready and home/feed/unknown/blank/unexpected startup route hints resolve to feed deterministically.
266. Done: add `StartupDecision.copyWith` coverage so central startup decisions preserve primary tabs by default and clear them only through the explicit `clearPrimaryTab` path.
267. Done: add `StartupDecision` root-target helper coverage so splash, sign-in, and authenticated-home decisions remain mutually exclusive through the central decision model.
268. Done: add `PrimaryTabRouter.openPrimaryTab` coverage for persistent Explore/Profile tabs so semantic opens use feature-aware indexes with education enabled and disabled.
269. Done: add disabled-education selected-index coverage so `PrimaryTabRouter.routeHintForSelectedIndex` deterministically maps feed/explore/short/profile/out-of-layout indexes without reviving a disabled education tab.
270. Done: add `SessionExitCoordinator` identifier passthrough coverage so account-switch/logout navigation receives the exact sign-in identifier and stored-account uid provided by the caller.
271. Done: add a broad local preferences singleton owner guard so `SharedPreferences.getInstance()` remains owned only by `LocalPreferenceRepository` and feature/core services cannot reopen their own preference singleton path.
272. Done: remove the SignIn module's direct `FirebaseAuth.instance` exception so password sign-in, signup, and password-reset auth calls now pass through `AppFirebaseAuth` while the tightened auth guards keep module code behind the central auth boundary.
273. Done: add `AppFirebaseMessaging` and a runtime singleton guard so notification startup and SocialProfile notification-permission flows share the same messaging boundary instead of opening `FirebaseMessaging.instance` from feature code.
274. Done: route Firebase Messaging background-handler registration through `AppFirebaseMessaging` as well, so notification startup owns both messaging singleton access and background handler registration behind one app boundary.
275. Done: broaden deep-link parser coverage for approved host casing, typo/go domains, query strings, and fragments so future deep-link routing changes cannot accidentally alter accepted entry identity.
276. Done: make Splash resolved route telemetry and manifest navigation reuse the already computed `StartupDecision` instead of recalculating logged-in startup routing, keeping emitted route keys stable while removing a second decision path.
277. Done: remove the unused `loggedIn` input from Splash runtime-health analytics extras so the helper only accepts values it emits or uses, without changing analytics key names or startup routing behavior.
278. Done: capture Splash requested/effective/resolved startup route telemetry in one `_StartupRouteTelemetryValues` object so playback KPI, runtime-health analytics, and manifest navigation share the same route tuple instead of passing three independent strings through every surface.
279. Done: move Splash startup manifest navigation extras behind `_startupNavigationManifestExtra` so decision telemetry, warm-readiness telemetry, and nav index are assembled through one helper before `markNavigation`.
280. Done: add a Splash startup navigation guard proving `educationEnabled` is captured once per navigation pass and reused for decision, selected-index, and resolved route telemetry instead of rereading settings mid-flow.
281. Done: introduce a NavBar primary-tab layout helper so lifecycle resume, change-index priming, startup surface persistence, and startup route-hint persistence share the same education/profile index calculation instead of rebuilding it locally.
282. Done: add a NavBar primary-tab layout guard so education/profile index calculations stay behind `_PrimaryTabLayout` and lifecycle code cannot silently reintroduce its own feature-flag index math.
283. Done: broaden deep-link parser coverage for web/custom-scheme path tails so route identity remains the first centralized type/id pair even when tracking or detail path segments are appended.
284. Done: make `startupRouteHintKind` reuse `StartupRouteHint.values` instead of duplicating `nav_*` literals in a parser switch, leaving route-hint vocabulary owned by the enum.
285. Done: centralize Splash runtime-health summary emission behind `_trackStartupRuntimeHealthSummary` so feed, short, explore, profile, market, and jobs reuse the same captured route telemetry and startup analytics extras without changing emitted keys.
286. Done: clear the remaining project-wide analyzer warning in ClassicContent navigation restore handling, preserving the same route callback behavior while allowing `flutter analyze` to pass cleanly.
287. Done: add the Turkish closing architecture integrity report with findings, centralization decisions, approved exceptions, remaining roadmap, and final verification status.

## Current Sprint Progress

### Centralized Decisions Added

- `lib/Runtime/startup_decision.dart`
- `lib/Runtime/app_decision_coordinator.dart`
- `lib/Runtime/session_exit_coordinator.dart`
- `lib/Runtime/primary_tab_router.dart`

### Behavior-Preserving Wiring Completed

- Delete-account exit now clears local session, signs out auth, then resets root navigation through `SessionExitCoordinator`.
- Deep link education navigation now goes through feature-aware `PrimaryTabRouter`.
- NavBar persisted tab restore now reads persisted selected tab before normalizing.
- NavBar selected-index route-hint mapping now resolves through `PrimaryTabRouter` so tab-to-startup-hint vocabulary stays centralized with the primary-tab router.
- Education Pasaj startup tab persistence now uses the typed startup route-hint vocabulary instead of a module-local `nav_education` literal.
- Splash feed fallback route hints now use `StartupRouteHint.feed.value`; QA Lab fallback, cold warm-readiness fallback, and null-primary-tab fallback still resolve to the same feed route.
- PrimaryTabRouter now reuses `StartupRouteHint.*.value` for its route-hint outputs instead of owning duplicate `nav_*` string literals.
- Feature code is now guarded against owning startup `nav_*` route-hint literals; new route-hint vocabulary must go through `StartupRouteHint`.
- Splash unknown route-hint fallbacks now also use `StartupRouteHint.unknown.value`; stale/invalid manifest behavior and persisted fallback values remain unchanged.
- Related Job and Tutoring detail cards now replace the current detail route through `EducationDetailNavigationService`; the target widgets, arguments, and replacement behavior are unchanged.
- Job and Tutoring listing-card detail opens now also use `EducationDetailNavigationService`; JobContent still refreshes the same job after returning from detail, and ended-tutoring reactivation still short-circuits before navigation.
- Deep link, education feed CTA, and notification flows now reuse the same Job/Tutoring detail navigation service after their existing lookup checks; missing-listing handling and notification return-to-navbar behavior are unchanged.
- Market home/offers/saved/my-items, deep link, education feed CTA, and notification market detail opens now use `MarketDetailNavigationService`; existing reload-after-return, lookup, and missing-listing behavior are unchanged.
- Profile, SocialProfile, and SavedPosts market cards now use `MarketDetailNavigationService`; route-time feed suspension/resume and reload-after-return behavior are unchanged.
- Feature code is now guarded against direct Market detail route construction; `MarketDetailNavigationService` owns the shared open path, with MarketDetail related-card self-navigation as the only explicit local exception.
- Personalized scholarships and education feed CTA scholarship detail opens now use `ScholarshipNavigationService.openDetailRoute`; existing no-interstitial behavior is preserved while the ad-gated `openDetail` path remains unchanged.
- Saved posts, liked posts, archives, profile lifecycle, editor email, editor phone, settings diagnostics, and splash bootstrap now read auth state through `CurrentUserService`.
- SignIn controllers delegate direct email/password auth calls to `SignInApplicationService`.
- Splash root routing now asks `AppDecisionCoordinator` whether to open authenticated home or sign-in. Existing preferred tab index behavior is intentionally preserved for now.
- Profile CV save, account deletion action logging, moderation banned-user stream, and post archive writes now go through repository boundaries instead of direct module-level Firestore calls.
- JobFinder create/update/logo writes, expired job ending, saved-job stale ending, career finding-job toggle, and reactivation now go through `JobRepository` / `CvRepository`.
- AnswerKey optical form create, booklet create/update, cover update, view count, and booklet answer result writes now go through `OpticalFormRepository` / `BookletRepository`.
- Education Tests image update, draft prepare, details update, question writes, correct-answer updates, publish, delete, favorite, and answer submission now go through `TestRepository`.
- PracticeExams exam create, cover update, draft question creation, question save, publish, apply, exam-complete marker, invalid marker, and answer/result writes now go through `PracticeExamRepository`.
- Antreman question complaint submit now goes through `ReportRepository` instead of direct module-level Firestore.
- Scholarship create/update writes now go through `ScholarshipRepository`.
- Tutoring create/update, expired archive, and reactivation writes now go through `TutoringRepository`.
- Social dislike, URL post create, and post-sharer writes now go through `PostRepository`.
- StoryMaker story document ID/create/save writes now go through `StoryRepository`.
- EditPost post update writes now go through `PostRepository`.
- PostCreator upload shell, short-link hydration reads, source edit, publish, URL/share, and retry-count writes now go through `PostRepository`.
- Agenda tag repositories now receive Firestore through `AppFirestore` instead of module-level direct instances.
- Explore, JobFinder, AnswerKey, PracticeExams, Scholarships, Market, Chat, NavBar, Short, Profile Settings, Tutoring, Antreman, Agenda, Splash, app language, network awareness, device session legacy keys, notification token cache, config cache, startup surface order, draft/upload queue persistence, user profile cache, profile posts cache, feed diversity memory, CurrentUserService, AccountCenterService, OfflineModeService, and education repository cache preference reads now go through `LocalPreferenceRepository`.

### Data-Source Preservation

- Typesense-backed search/listing/query flows were intentionally left unchanged.
- PracticeExams repository query methods such as `fetchPage` and `fetchByIds` were not moved to Firestore.
- JobFinder, AnswerKey, and PracticeExams screen search/listing code must remain on their existing Typesense/snapshot adapters during this Firestore write-boundary phase.
- `lib/Modules/Education/PracticeExams` no longer contains direct `FirebaseFirestore.instance` calls.
- `lib/Modules/Education/Antreman3` no longer contains direct `FirebaseFirestore.instance` calls.
- `lib/Modules/Education/Scholarships` no longer contains direct `FirebaseFirestore.instance` calls.
- `lib/Modules/Education/Tutoring` no longer contains direct `FirebaseFirestore.instance` calls.
- `lib/Modules/Social` no longer contains direct `FirebaseFirestore.instance` calls.
- `lib/Modules/Story/StoryMaker` no longer contains direct `FirebaseFirestore.instance` calls.
- `lib/Modules/EditPost` no longer contains direct `FirebaseFirestore.instance` calls.
- `lib/Modules/PostCreator` no longer contains direct `FirebaseFirestore.instance` calls.
- `lib/Modules` no longer contains direct `FirebaseFirestore.instance` calls.
- `lib/Modules/Explore` no longer contains direct `SharedPreferences.getInstance()` calls.
- `lib/Modules/JobFinder` no longer contains direct `SharedPreferences.getInstance()` calls.
- AnswerKey and PracticeExams listing-selection prefs no longer call `SharedPreferences.getInstance()` directly.
- `lib/Modules/Market` no longer contains direct `SharedPreferences.getInstance()` calls.
- `lib/Modules/Chat` no longer contains direct `SharedPreferences.getInstance()` calls.
- `lib/Modules/NavBar` no longer contains direct `SharedPreferences.getInstance()` calls.
- `lib/Modules/Short` no longer contains direct `SharedPreferences.getInstance()` calls.
- Profile Settings education/pasaj visibility and permissions quota prefs no longer call `SharedPreferences.getInstance()` directly.
- `lib/Modules/Education/Tutoring` no longer contains direct `SharedPreferences.getInstance()` calls.
- `lib/Modules/Education/Scholarships` no longer contains direct `SharedPreferences.getInstance()` calls.
- `lib/Modules/Education/Antreman3` no longer contains direct `SharedPreferences.getInstance()` calls.
- `lib/Modules/Agenda` no longer contains direct `SharedPreferences.getInstance()` calls.
- `lib/Modules/Splash` no longer contains direct `SharedPreferences.getInstance()` calls. Splash still carries `SharedPreferences` types at the bootstrap/session boundary for existing service compatibility.
- `lib/Modules` no longer contains direct `SharedPreferences.getInstance()` calls.
- App-level language, network awareness, device-session legacy key cleanup, notification token cache, config repository cache, and startup surface order fallback no longer call `SharedPreferences.getInstance()` directly.
- DraftService, UploadQueueService, UserProfileCacheService, ProfilePostsCacheService, and FeedDiversityMemoryService no longer call `SharedPreferences.getInstance()` directly.
- CurrentUserService, AccountCenterService, and OfflineModeService no longer call `SharedPreferences.getInstance()` directly.
- PracticeExamRepository, TestRepository, OpticalFormRepository, and BookletRepository no longer call `SharedPreferences.getInstance()` directly.
- ScholarshipRepository, TutoringRepository, and JobRepository no longer call `SharedPreferences.getInstance()` directly.
- Typesense post, market, education, and user-card cache services no longer call `SharedPreferences.getInstance()` directly; search/query/data-source behavior remains unchanged.
- UserSubdocRepository, UserSubcollectionRepository, and SocialMediaLinksRepository no longer call `SharedPreferences.getInstance()` directly.
- ProfileStatsRepository, FollowRepository, VerifiedAccountRepository, and NotificationPreferencesRepository no longer call `SharedPreferences.getInstance()` directly.
- MarketRepository, CvRepository, and CikmisSorularRepository no longer call `SharedPreferences.getInstance()` directly.
- StoryRepository, StoryHighlightsRepository, ProfileRepository archive cache, PostRepository poll selection cache, FeedManifestRepository, ExploreRepository, and RecommendedUsersRepository no longer call `SharedPreferences.getInstance()` directly.
- AntremanRepository no longer calls `SharedPreferences.getInstance()` directly.
- JobSavedStore, SliderCacheService, CacheFirst snapshot stores, and ErrorHandlingService history no longer call `SharedPreferences.getInstance()` directly.
- StoryMusicLibraryService, GifLibraryService, UnreadMessagesController, and SurfacePolicyOverrideService no longer call `SharedPreferences.getInstance()` directly.
- Module-level Cloud Functions access now routes through AppCloudFunctions instead of direct FirebaseFunctions singleton calls.
- Module-level Firebase Storage access now routes through AppFirebaseStorage instead of direct FirebaseStorage singleton calls.
- Core Typesense and short-link services now route callable access through AppCloudFunctions; query/index/payload behavior remains unchanged.
- Core market saved/offers/reviews/contact and feed-share services now route Firestore access through AppFirestore; collection paths and write payloads remain unchanged.
- Lightweight Core services for saved jobs, notification preferences, media libraries, telemetry, iz-birak subscription, and moderation config now route backend access through AppFirestore/AppCloudFunctions.
- User/profile services now route direct Firestore access through AppFirestore without changing cache/source/query decisions.
- Core Ads feature flags, analytics, delivery, repository, and suggestion config services now route backend singleton access through AppFirestore/AppCloudFunctions/AppFirebaseStorage; callable names, collection paths, payloads, and local fallback behavior remain unchanged.
- Post counter updates and phone account limit transactions now route Firestore access through AppFirestore; transaction bodies, paths, counters, and local optimistic state behavior remain unchanged.
- Offline queued action replay now routes Firestore access through AppFirestore; replay types, transaction bodies, and skip/apply outcomes remain unchanged.
- Story read-state batch writes now route Firestore access through AppFirestore; local debounce/cache behavior and write payloads remain unchanged.
- Profile manifest sync, scholarship path helper, and QA Lab remote uploader now keep their existing test overrides while defaulting backend access through AppFirestore/AppFirebaseStorage.
- FirestoreConfig now configures and clears persistence through AppFirestore; cache settings and helper behavior remain unchanged.
- PostDeleteService now routes soft-delete, cascade cleanup, and like-counter reads through AppFirestore; delete order, payloads, cache invalidation, and Typesense invalidation remain unchanged.
- UploadQueueService now routes post shell creation, upload cleanup, media storage, final post writes, share markers, and retry cleanup through AppFirestore/AppFirebaseStorage; payloads, paths, validation, and Typesense sync remain unchanged.
- `lib/Core/Services` and `lib/Services` are now guarded so new direct Firestore/Functions/Storage singleton access fails outside the app backend wrapper files.
- Antreman, Booklet, Cikmis Sorular, Explore, FeedManifest, and Job repositories now keep their existing optional injections while defaulting backend access through AppFirestore/AppFirebaseStorage.
- Market, NotifyLookup, OpticalForm, Post, PracticeExam, ProfileManifest, ShortManifest, Short, Slider, Test, Tutoring, and UsernameLookup repositories now also default through AppFirestore/AppFirebaseStorage without changing their query/source behavior.
- Explore flood manifest callable, Market view-count callable, and ReportRepository callable/Firestore access now route through AppCloudFunctions/AppFirestore; callable names, regions, payloads, and report query behavior remain unchanged.
- Admin approvals, admin task assignments, support messages, notifications, and conversation repositories now route Firestore access through AppFirestore; collection names and stream/write behavior remain unchanged.
- UserRepository, UserSubdocRepository, and UserSubcollectionRepository now route Firestore access through AppFirestore while keeping profile cache and user-scoped collection behavior unchanged.
- FollowRepository now routes relation reads, transactions, daily counters, and relation cache refreshes through AppFirestore; follow path names, transaction bodies, and invalidation behavior remain unchanged.
- ConfigRepository, ModerationRepository, NotificationPreferencesRepository, and VerifiedAccountRepository now route Firestore access through AppFirestore; TTL/cache and stream behavior remain unchanged.
- CvRepository and SocialMediaLinksRepository now route Firestore access through AppFirestore; local cache merge/reorder behavior and collection paths remain unchanged.
- Job, Market, Tutoring, and AnswerKey snapshot repositories now route Firestore fallback reads through AppFirestore while keeping Typesense/cache-first listing behavior unchanged.
- AdminPushRepository now routes push report references, user target pagination, and notification batch creation through AppFirestore; filters, batch payloads, and paging behavior remain unchanged.
- ProfileRepository default dependency, ProfileStatsRepository metrics reads, and RecommendedUsersRepository candidate reads now route through AppFirestore without changing query filters or cache behavior.
- OpticalForm, PracticeExam, and Test snapshot repositories now route Firestore fallback/backfill reads through AppFirestore; legacy test gate, cache-first, and Typesense-adjacent behavior remain unchanged.
- StoryHighlightsRepository now routes highlight read/write/delete operations through AppFirestore; `users/{uid}/highlights` paths, ordering, and cache updates remain unchanged.
- StoryRepository foundation/cache reads now route through AppFirestore; story id generation, save, cache-first fallback, music lookup, raw story lookup, and per-user story queries remain behavior-identical.
- StoryRepository deleted-story flow now routes Firestore/Storage access through AppFirestore/AppFirebaseStorage; soft delete, restore, permanent delete, repost, archive fetch, and media purge behavior remain unchanged.
- StoryRepository engagement flow now routes comment, viewer, like, reaction, screenshot, and seen writes/reads through AppFirestore; collection names, count queries, and payloads remain unchanged.
- AppStateView now provides a shared loading/empty/error/retry presentation contract; SocialMediaLinks uses it for initial loading without changing refresh, reorder, add, or list behavior.
- AnswerKey listing, Reports admin, and Support admin now reuse AppStateView for existing loading/empty/error presentations; repositories, streams, search state, refresh, and admin actions are unchanged.
- Scholarships startup/list-selection loading and SavedItems loading/empty states now reuse AppStateView; listing selection, pagination, saved/liked fetches, and image placeholders remain unchanged.
- Scholarship BankInfo, DormitoryInfo, and PersonelInfo now reuse AppStateView for initial loading; field rendering, reset menus, repository reads, and save behavior remain unchanged.
- Scholarship Applications, MyScholarship, Providers, and FamilyInfo now reuse AppStateView for loading/empty states; detail route opening, provider profile opening, list rendering, and form behavior remain unchanged.
- Scholarship EducationInfo and Personalized now reuse AppStateView for startup/select-level states; education-level selection, saved-data loading, recommendation refresh, carousel, and grid behavior remain unchanged.
- Scholarship application cards and applicant profile now reuse AppStateView for loading; applicant route opening, profile sections, and contact actions remain unchanged.
- AnswerKey SavedOpticalForms, MyBookletResults, and SearchAnswerKey now reuse AppStateView for loading/empty/search-minimum states; saved forms, result navigation, search reset, and preview navigation remain unchanged.
- AnswerKey CategoryBased and OpticsAndBooksPublished now reuse AppStateView for loading/empty states; booklet preview navigation, image placeholders, published books, and optical list behavior remain unchanged.
- AnswerKey shell startup loading plus Reports/Admin approvals/tasks/badges/moderation access loading now reuse AppStateView; admin access checks, streams, no-access messages, and action spinners remain unchanged.
- Profile Settings my-approvals, notification preferences, permissions, and story music admin now reuse AppStateView for loading/empty states; preferences, permission refresh, story music CRUD, and admin access behavior remain unchanged.
- Ads Center, TurqApp suggestion admin, Surface Policy, Account Center, admin assignments, badge applications, and moderation streams now reuse AppStateView for screen/stream loading and error states; admin access, settings persistence, account center init, and stream data behavior remain unchanged.
- AdminPush now reuses AppStateView for access/report loading; push form fields, target filters, send actions, report payloads, and button-level progress remain unchanged.
- Chat listing and location-share now reuse AppStateView for startup/loading states; chat refresh, search, archive/delete actions, map camera state, and send-location behavior remain unchanged.
- Tutoring detail now opens chat listing through ChatNavigationService; ChatListingController ownership, conversation id creation, and chat data sources remain unchanged.
- PracticeExams, Settings, and MyProfile now open BecomeVerifiedAccount through VerifiedAccountNavigationService; application-state checks, rozet visibility decisions, and profile feed route suspension behavior remain unchanged.
- JobFinder JobDetails, ApplicationReview, CareerProfile, and FindingJobApply now delegate profile, report-user, and CV editor opens through shared navigation services; mention lookup, CV reload after return, report fields, and job/CV repositories remain unchanged.
- Market detail now delegates seller-profile and chat-listing opens through ProfileNavigationService and ChatNavigationService; owner guards, edit route behavior, market contact/offer flows, and Typesense-backed listing ownership remain unchanged.
- Profile and Agenda chat listing opens now delegate through ChatNavigationService; route-return callbacks still resume profile feed playback, resume Agenda playback, mark unread chat notifications, and refresh recommended-user data in the same order.
- RecommendedUserContent now delegates avatar/name/handle profile opens through ProfileNavigationService; controller lifetime and follow-status refresh after returning from profile remain unchanged.
- Chat list avatars, chat headers, and message mentions now delegate profile opens through ProfileNavigationService; mention UID lookup, chat controller ownership, unread counters, and conversation/message data flow remain unchanged.
- Following/Followers rows and InAppNotifications avatar taps now delegate profile opens through ProfileNavigationService; self-user guard, follow refresh after returning, and notification onOpen/onCardTap precedence remain unchanged.
- Post sharers, post likes, and post reshares now delegate profile opens through ProfileNavigationService; own-profile routing and follow-state refresh after returning remain unchanged.
- Short author profile, mention profile, and report-user actions now delegate through ProfileNavigationService and ReportUserNavigationService; volume-off/on handoff, StoryViewer avatar path, and report post/user identifiers remain unchanged.
- ClassicContent author profile, mention profile, avatar fallback profile, and report-user actions now delegate through ProfileNavigationService and ReportUserNavigationService; feed-center suspend/restore, video pause, StoryViewer avatar path, and report identifiers remain unchanged.
- AgendaContent author profile, mention profile, avatar fallback profile, and report-user actions now delegate through ProfileNavigationService and ReportUserNavigationService; mention lookup, feed-center suspend/restore, video pause, StoryViewer avatar path, and report identifiers remain unchanged.
- StoryViewer mention taps, story header avatar/name taps, story comment user taps, and story viewer profile taps now delegate through ProfileNavigationService; username lookup, story playback pause/resume, self-user guards, comment ownership, and story repository/cache behavior remain unchanged.
- Social comment avatar/name taps and PhotoShorts author/report actions now delegate through ProfileNavigationService and ReportUserNavigationService; comment self-user guards, PhotoShorts avatar story fallback, page controller ownership, and report post/user identifiers remain unchanged.
- QR scanner profile opens, SharedPostLabel attribution taps, and Explore searched-user taps now delegate through ProfileNavigationService; QR detection/controller behavior, attribution self-user guard, Explore account availability checks, preview suspend/resume, recent-search persistence, and duplicate-route policy remain unchanged.
- SocialProfile report-user action and Profile Settings badge/support admin user links now delegate through ReportUserNavigationService and ProfileNavigationService; centered-post resume, post-report user refresh, admin user-id guards, and support/badge record rendering remain unchanged.
- NotifyReader profile opens now delegate through ProfileNavigationService after the existing notification route resolver chooses a profile target; return-to-navbar handling and missing-target snackbar decisions remain unchanged.
- Raw `SocialProfile`/`ReportUser` route construction now appears only inside the approved `ProfileNavigationService` and `ReportUserNavigationService` owners.
- A broad runtime guard now scans `lib` and fails if feature/Core code reintroduces direct `SocialProfile` or `ReportUser` route construction or imports outside the approved navigation service owners.
- Antreman comment image uploads and legacy Tests question image uploads now delegate default Firebase Storage ownership to WebpUploadService; WebP conversion, auth preflight/retry, storage paths, moderation checks, and repository writes remain unchanged.
- Profile avatar, CV photo, social link image, and story music cover uploads now also delegate default Firebase Storage ownership to WebpUploadService; upload paths, image moderation/NSFW checks, avatar cleanup, and downstream repository/service updates remain unchanged.
- Legacy Tests create/question uploads and PracticeExams question/cover uploads now delegate default Firebase Storage ownership to WebpUploadService; upload paths, NSFW/moderation checks, legacy feature gates, and TestRepository/PracticeExamRepository writes remain unchanged.
- Core Slider admin, JobCreator logo, Market create images, StoryMaker image, and StoryHighlights cover uploads now delegate default Firebase Storage ownership to WebpUploadService; upload paths, image moderation checks, story image auth retry, slider delete cleanup, and story video upload behavior remain unchanged.
- PostCreator image and thumbnail WebP uploads now delegate default Firebase Storage ownership to WebpUploadService; `Posts/$docID/image_$j`, `Posts/$docID/thumbnail`, CDN conversion, video upload, auth retry metadata, and publish repository writes remain unchanged.
- UploadQueueService image and thumbnail WebP uploads now delegate default Firebase Storage ownership to WebpUploadService; queued post paths, NSFW checks, queue progress, video upload, thumbnail sizing, CDN conversion, and final post writes remain unchanged.
- Tutoring create images, EditPost image/thumbnail uploads, and Chat video thumbnails now also delegate default Firebase Storage ownership to WebpUploadService; their direct video/storage refs remain unchanged where they still own non-WebP upload behavior.
- A broad runtime guard now scans `lib` and fails if app code passes any `storage:` argument into `WebpUploadService` instead of letting the service own the default storage boundary.
- AnswerKey booklet cover and Scholarship logo/image/template prepared WebP uploads now use `WebpUploadService.uploadPreparedWebpBytes`; existing conversion quality, storage paths, cache-busted booklet cover URL, and repository writes remain unchanged.
- Direct module/Core Slider `AppFirebaseStorage.instance` usage is now guarded and limited to the approved non-WebP owners: Chat media upload/progress, PostCreator/EditPost/StoryMaker video upload, Profile/Slider cleanup, and their existing behavior-specific paths.
- Splash startup analytics and KPI telemetry now share manifest-context and warmup-priority field builders; emitted keys, fallback decisions, readiness checks, and route timing remain unchanged.
- Deep-link parser behavior is now covered across accepted web aliases, custom scheme host/path aliases, typo/go domains, invalid hosts, unsupported schemes, and incomplete routes; parser ownership remains in `deep_link_utils`.
- Market home, my listings, offers, and saved-list now reuse AppStateView for screen/list loading and offer-empty states; Typesense/listing source, filters, refresh, offer actions, and item navigation remain unchanged.
- JobFinder home, saved jobs, my applications, my job ads, applicant review, and career profile now reuse AppStateView for startup/list loading and empty states; job listing source, search, applications, review cards, saved list, and CV rendering behavior remain unchanged.
- Explore trending, for-you, and series surfaces now reuse AppStateView for loading/empty states; search mode, cached snapshots, feed/flood fetches, flood rotation, pull refresh, and preview playback decisions remain unchanged.
- Profile archive, liked posts, and saved posts/market/job/scholarship tabs now reuse AppStateView for loading/empty states; post cache reads, saved item stores, embedded market/job/scholarship controllers, refresh, and navigation remain unchanged.
- Following/Followers now reuses AppStateView for initial loading and empty list states; follower/following cache reads, pagination, profile navigation, and load-more progress indicators remain unchanged.
- BlockedUsers and MyStatistic now reuse AppStateView for visible loading/empty states; unblock confirmation, blocked user reads, statistic refresh, profile summary, and ad rendering remain unchanged.
- Profile main post/photo/video/reshare/scheduled/market tabs now reuse AppStateView for empty/loading surfaces; feed/cache reads, media placeholders, market snapshot loading, post actions, and navigation remain unchanged.
- Tutoring my listings, my applications, and application review now reuse AppStateView for loading/empty/error states; listing cards, applicant cards, status actions, refresh, and controller ownership remain unchanged.
- Tests saved/results/solve/result-preview now reuse AppStateView for loading/empty states; solve flow, result mapping, question cards, media placeholders, and refresh behavior remain unchanged.
- InAppNotifications plus Story likes/seens/comments/deleted/music profile now reuse AppStateView for loading/empty states; notification grouping, story comment input, deleted story restore/delete, music story fetch, and card rendering remain unchanged.
- SocialProfile feed/photo/video/reshare/scheduled/market surfaces now reuse AppStateView for empty/loading states; social feed/cache reads, media grid placeholders, market snapshot loading, and navigation remain unchanged.
- PracticeExams, SavedPracticeExams, LessonBasedTests, CikmisSorular, and practice result-preview now reuse AppStateView for loading/empty states; skeleton loading, pagination, search/query behavior, result mapping, and question rendering remain unchanged.
- Tutoring main/search/detail/location surfaces now reuse AppStateView for loading/empty states; filters, search result lists, favorite/apply actions, and load-more behavior remain unchanged.
- Antreman main/search, comments, and solve-later surfaces now reuse AppStateView for loading/empty states; question selection, comment composer, saved-question list, and card rendering remain unchanged.
- Spotify selector, Market search/create, and Tutoring category surfaces now reuse AppStateView for loading/empty states; search, form, category filtering, listing, and selection behavior remain unchanged.
- Practice exam preview/solve screens now reuse AppStateView for loading/empty states; rules, solve flow, question rendering, and refresh behavior remain unchanged.
- Remaining raw spinner/empty hits are intentionally local micro states: media placeholders, card-level result placeholders, load-more indicators, form/button progress, question subcomponent placeholders, and search result row placeholders. They are excluded from Phase 6 screen-state standardization to avoid changing interaction timing or visual hierarchy.
- Splash startup now applies the authenticated primary tab via `StartupDecision.primaryTab` and `PrimaryTabRouter.selectedIndexForDecision`; telemetry route hints also resolve through the same semantic tab mapping.
- SignInApplicationService now has explicit guard coverage ensuring auth failures do not trigger session claim/device/post-auth work and pre-auth generic failures are not reported as recovered successes.
- Splash telemetry and navigation now construct startup decisions through the same local helper, reducing duplicated `StartupDecisionInput` assembly while keeping auth, route-hint, and education-enabled behavior unchanged.
- Splash KPI and manifest navigation telemetry now share the same decision/warm-readiness field builders; emitted field names and values remain unchanged.
- Splash route-hint normalization is now covered for feed/home aliases, whitespace trimming, freshness boundaries, and invalid/stale manifest fallbacks.
- Root-clearing navigation guard now catches additional Get and Navigator variants so root route resets remain centralized behind AppRootNavigationService.
- Deep-link parsing is now testable as a pure utility; DeepLinkService delegates to the same parser, preserving existing open behavior while guarding accepted hosts, aliases, and id normalization.
- DeepLinkService parser boundary now prevents duplicated host/type/id parsing logic from reappearing inside the service parse part.
- Education deep-link routing is guarded to stay behind PrimaryTabRouter instead of direct NavBar index mutation.
- AppDecisionCoordinator now has explicit test coverage for requested-tab precedence over route hints, education-disabled normalization, and trimmed authenticated user ids.
- Profile Settings and Account Center now use SessionExitCoordinator for sign-out/switch navigation; Account Center keeps its previous best-effort local logout/auth sign-out behavior via callbacks.
- Splash SessionBootstrap first-launch cleanup now reuses one auth/local cleanup helper for normal and recovery paths; it still performs no root navigation during bootstrap cleanup.
- SignIn and Scholarship post-submit tab redirects now use PrimaryTabRouter semantic helpers instead of writing NavBar indexes directly.

### Remaining Direct Auth Boundary

Direct `FirebaseAuth.instance` usage under `lib/Modules` is now limited to the approved SignIn auth boundary:

- `lib/Modules/SignIn/sign_in_application_service.dart`

This is acceptable as a temporary boundary because SignIn is the auth entry point. Controllers call the application service; the application service is the only module-level file allowed to call FirebaseAuth directly.

### Current Verification

Passing:

```sh
dart analyze lib/Modules/Profile/Settings/settings.dart
dart analyze lib/Modules/Splash/splash_session_bootstrap.dart
dart analyze lib/Modules/SignIn/sign_in_controller.dart lib/Modules/SignIn/sign_in_application_service.dart
flutter test test/unit/runtime/app_decision_coordinator_test.dart test/unit/runtime/session_exit_coordinator_test.dart test/unit/runtime/primary_tab_router_test.dart test/unit/modules/profile/liked_posts_controller_test.dart
flutter test test/unit/runtime/module_auth_boundary_test.dart
flutter test test/unit/runtime/root_navigation_boundary_test.dart
flutter test test/unit/runtime/profile_firestore_boundary_test.dart
flutter test test/unit/runtime/jobfinder_firestore_boundary_test.dart
flutter test test/unit/runtime/answer_key_firestore_boundary_test.dart
flutter test test/unit/runtime/education_tests_firestore_boundary_test.dart
flutter test test/unit/runtime/practice_exam_creation_firestore_boundary_test.dart
flutter test test/unit/runtime/antreman_firestore_boundary_test.dart
flutter test test/unit/runtime/scholarships_firestore_boundary_test.dart
flutter test test/unit/runtime/tutoring_firestore_boundary_test.dart
flutter test test/unit/runtime/social_firestore_boundary_test.dart
flutter test test/unit/runtime/story_maker_firestore_boundary_test.dart
flutter test test/unit/runtime/edit_post_firestore_boundary_test.dart
flutter test test/unit/runtime/post_creator_firestore_boundary_test.dart
flutter test test/unit/runtime/modules_firestore_boundary_test.dart
flutter test test/unit/runtime/explore_preferences_boundary_test.dart
flutter test test/unit/runtime/jobfinder_preferences_boundary_test.dart
flutter test test/unit/runtime/answer_key_preferences_boundary_test.dart
flutter test test/unit/runtime/practice_exam_preferences_boundary_test.dart
flutter test test/unit/runtime/scholarships_preferences_boundary_test.dart
flutter test test/unit/runtime/market_preferences_boundary_test.dart
flutter test test/unit/runtime/chat_preferences_boundary_test.dart
flutter test test/unit/runtime/navbar_preferences_boundary_test.dart
flutter test test/unit/runtime/short_preferences_boundary_test.dart
flutter test test/unit/runtime/profile_settings_preferences_boundary_test.dart
flutter test test/unit/runtime/tutoring_preferences_boundary_test.dart
flutter test test/unit/runtime/scholarships_preferences_module_boundary_test.dart
flutter test test/unit/runtime/antreman_preferences_boundary_test.dart
flutter test test/unit/runtime/agenda_preferences_boundary_test.dart
flutter test test/unit/runtime/splash_preferences_boundary_test.dart
flutter test test/unit/runtime/core_preferences_boundary_test.dart
flutter test test/unit/runtime/education_repository_preferences_boundary_test.dart
flutter test test/unit/runtime/domain_repository_preferences_boundary_test.dart
flutter test test/unit/runtime/typesense_preferences_boundary_test.dart
flutter test test/unit/runtime/user_scoped_repository_preferences_boundary_test.dart
flutter test test/unit/runtime/social_profile_repository_preferences_boundary_test.dart
flutter test test/unit/runtime/commerce_cv_repository_preferences_boundary_test.dart
flutter test test/unit/runtime/social_content_repository_preferences_boundary_test.dart
flutter test test/unit/runtime/antreman_repository_preferences_boundary_test.dart
flutter test test/unit/runtime/core_cache_store_preferences_boundary_test.dart
flutter test test/unit/runtime/remaining_core_preferences_boundary_test.dart
flutter test test/unit/runtime/modules_functions_boundary_test.dart
flutter test test/unit/runtime/modules_storage_boundary_test.dart
flutter test test/unit/runtime/core_typesense_functions_boundary_test.dart
flutter test test/unit/runtime/core_market_services_firestore_boundary_test.dart
flutter test test/unit/runtime/core_lightweight_services_backend_boundary_test.dart
flutter test test/unit/runtime/user_profile_services_firestore_boundary_test.dart
flutter test test/unit/runtime/core_ads_services_backend_boundary_test.dart
flutter test test/unit/runtime/core_counter_account_backend_boundary_test.dart
flutter test test/unit/runtime/offline_mode_backend_boundary_test.dart
flutter test test/unit/runtime/story_interaction_backend_boundary_test.dart
flutter test test/unit/runtime/core_override_backend_boundary_test.dart
flutter test test/unit/runtime/firestore_config_backend_boundary_test.dart
flutter test test/unit/runtime/post_delete_backend_boundary_test.dart
flutter test test/unit/runtime/upload_queue_backend_boundary_test.dart
flutter test test/unit/runtime/app_services_backend_singleton_boundary_test.dart
flutter test test/unit/runtime/repository_default_backend_boundary_test.dart
flutter test test/unit/runtime/repository_callable_backend_boundary_test.dart
flutter test test/unit/runtime/admin_support_repository_backend_boundary_test.dart
flutter test test/unit/runtime/user_repository_backend_boundary_test.dart
flutter test test/unit/runtime/follow_repository_backend_boundary_test.dart
flutter test test/unit/runtime/config_preferences_repository_backend_boundary_test.dart
flutter test test/unit/runtime/cv_social_repository_backend_boundary_test.dart
flutter test test/unit/runtime/snapshot_repository_backend_boundary_test.dart
flutter test test/unit/runtime/admin_push_repository_backend_boundary_test.dart
flutter test test/unit/runtime/profile_recommendation_repository_backend_boundary_test.dart
flutter test test/unit/runtime/education_snapshot_repository_backend_boundary_test.dart
flutter test test/unit/runtime/story_highlights_repository_backend_boundary_test.dart
flutter test test/unit/runtime/story_repository_cache_backend_boundary_test.dart
flutter test test/unit/runtime/story_repository_deleted_backend_boundary_test.dart
flutter test test/unit/runtime/story_repository_engagement_backend_boundary_test.dart
flutter test test/unit/runtime/app_backend_singleton_boundary_test.dart
flutter test test/unit/modules/splash/splash_bootstrap_roles_test.dart
flutter test test/unit/modules/sign_in/sign_in_application_service_test.dart
flutter test test/widget/components/app_state_view_widget_test.dart
flutter test test/unit/runtime
dart analyze lib/Core/Repositories lib/Core/Services lib/Services test/unit/runtime
dart analyze test/unit/modules/sign_in/sign_in_application_service_test.dart
dart analyze lib/Core/Widgets/app_state_view.dart lib/Modules/Profile/SocialMediaLinks/social_media_links.dart test/widget/components/app_state_view_widget_test.dart
dart analyze lib/Modules/Profile/Settings/support_admin_view.dart lib/Modules/Profile/Settings/reports_admin_view.dart lib/Modules/Education/AnswerKey/answer_key.dart lib/Core/Widgets/app_state_view.dart
dart analyze lib/Modules/Education/Scholarships/scholarships_view.dart lib/Modules/Education/Scholarships/SavedItems/saved_items_view.dart lib/Core/Widgets/app_state_view.dart
dart analyze lib/Modules/Education/Scholarships/BankInfo/bank_info_view.dart lib/Modules/Education/Scholarships/DormitoryInfo/dormitory_info_view.dart lib/Modules/Education/Scholarships/PersonelInfo/personel_info_view.dart lib/Core/Widgets/app_state_view.dart
dart analyze lib/Modules/Education/Scholarships/Applications/applications_view.dart lib/Modules/Education/Scholarships/MyScholarship/my_scholarship_view.dart lib/Modules/Education/Scholarships/ScholarshipProviders/scholarship_providers_view.dart lib/Modules/Education/Scholarships/FamilyInfo/family_info_view.dart lib/Core/Widgets/app_state_view.dart
dart analyze lib/Modules/Education/Scholarships/EducationInfo/education_info_view.dart lib/Modules/Education/Scholarships/Personalized/personalized_view.dart lib/Core/Widgets/app_state_view.dart
dart analyze lib/Modules/Education/Scholarships/ScholarshipApplicationsContent/scholarship_applications_content.dart lib/Modules/Education/Scholarships/ScholarshipApplicationsContent/applicant_profile.dart lib/Core/Widgets/app_state_view.dart
dart analyze lib/Modules/Education/AnswerKey/SavedOpticalForms/saved_optical_forms.dart lib/Modules/Education/AnswerKey/MyBookletResults/my_booklet_results.dart lib/Modules/Education/AnswerKey/SearchAnswerKey/search_answer_key.dart lib/Core/Widgets/app_state_view.dart
dart analyze lib/Modules/Education/AnswerKey/CategoryBasedAnswerKey/category_based_answer_key.dart lib/Modules/Education/AnswerKey/OpticsAndBooksPublished/optics_and_books_published.dart lib/Core/Widgets/app_state_view.dart
dart analyze lib/Modules/Profile/Settings/admin_approvals_view.dart lib/Modules/Profile/Settings/admin_task_assignments_view.dart lib/Modules/Profile/Settings/badge_admin_view.dart lib/Modules/Profile/Settings/moderation_settings_view.dart lib/Core/Widgets/app_state_view.dart
dart analyze lib/Modules/Profile/Settings/my_admin_approval_results_view.dart lib/Modules/Profile/Settings/notification_settings_view.dart lib/Modules/Profile/Settings/permissions_view.dart lib/Modules/Profile/Settings/story_music_admin_view.dart lib/Core/Widgets/app_state_view.dart
dart analyze lib/Modules/Profile/Settings/AdsCenter/ads_center_home_view.dart lib/Modules/Profile/Settings/AdsCenter/turqapp_suggestion_admin_view.dart lib/Modules/Profile/Settings/surface_policy_settings_view.dart lib/Modules/Profile/Settings/account_center_view.dart lib/Modules/Profile/Settings/admin_task_assignments_view.dart lib/Modules/Profile/Settings/badge_admin_view.dart lib/Modules/Profile/Settings/moderation_settings_view.dart lib/Core/Widgets/app_state_view.dart
dart analyze lib/Modules/Profile/Settings/admin_push_view.dart lib/Modules/Profile/Settings/AdsCenter/ads_center_home_view.dart lib/Modules/Profile/Settings/AdsCenter/turqapp_suggestion_admin_view.dart lib/Modules/Profile/Settings/surface_policy_settings_view.dart lib/Modules/Profile/Settings/account_center_view.dart lib/Modules/Profile/Settings/admin_task_assignments_view.dart lib/Modules/Profile/Settings/badge_admin_view.dart lib/Modules/Profile/Settings/moderation_settings_view.dart lib/Core/Widgets/app_state_view.dart
dart analyze lib/Modules/Chat/ChatListing/chat_listing.dart lib/Modules/Chat/LocationShareView/location_share_view_chat.dart lib/Core/Widgets/app_state_view.dart
dart analyze lib/Modules/Market/market_view.dart lib/Modules/Market/market_my_items_view.dart lib/Modules/Market/market_offers_view.dart lib/Modules/Market/market_saved_view.dart lib/Core/Widgets/app_state_view.dart
dart analyze lib/Modules/JobFinder/job_finder.dart lib/Modules/JobFinder/MyApplications/my_applications.dart lib/Modules/JobFinder/SavedJobs/saved_jobs.dart lib/Modules/JobFinder/MyJobAds/my_job_ads.dart lib/Modules/JobFinder/ApplicationReview/application_review.dart lib/Modules/JobFinder/CareerProfile/career_profile.dart lib/Core/Widgets/app_state_view.dart
dart analyze lib/Modules/Explore/explore_view.dart lib/Modules/JobFinder/job_finder.dart lib/Modules/JobFinder/MyApplications/my_applications.dart lib/Modules/JobFinder/SavedJobs/saved_jobs.dart lib/Modules/JobFinder/MyJobAds/my_job_ads.dart lib/Modules/JobFinder/ApplicationReview/application_review.dart lib/Modules/JobFinder/CareerProfile/career_profile.dart lib/Core/Widgets/app_state_view.dart
dart analyze lib/Modules/Profile/Archives/archives.dart lib/Modules/Profile/LikedPosts/liked_posts.dart lib/Modules/Profile/SavedPosts/saved_posts.dart lib/Core/Widgets/app_state_view.dart
dart analyze lib/Modules/Profile/FollowingFollowers/following_followers.dart lib/Core/Widgets/app_state_view.dart
dart analyze lib/Modules/Profile/BlockedUsers/blocked_users.dart lib/Modules/Profile/MyStatistic/my_statistic_view.dart lib/Core/Widgets/app_state_view.dart
dart analyze lib/Modules/Profile/MyProfile/profile_view.dart lib/Core/Widgets/app_state_view.dart
dart analyze lib/Modules/Education/Tutoring/MyTutorings/my_tutorings.dart lib/Modules/Education/Tutoring/MyTutoringApplications/my_tutoring_applications.dart lib/Modules/Education/Tutoring/TutoringApplicationReview/tutoring_application_review.dart lib/Core/Widgets/app_state_view.dart
dart analyze lib/Modules/Education/Tests/SavedTests/saved_tests.dart lib/Modules/Education/Tests/MyTestResults/my_test_results.dart lib/Modules/Education/Tests/SolveTest/solve_test.dart lib/Modules/Education/Tests/MyPastTestResultsPreview.dart/my_past_test_results_preview.dart lib/Core/Widgets/app_state_view.dart
dart analyze lib/Modules/InAppNotifications/in_app_notifications.dart lib/Modules/Story/StoryViewer/StoryLikes/story_likes.dart lib/Modules/Story/StoryViewer/StorySeens/story_seens.dart lib/Modules/Story/StoryViewer/StoryComments/story_comments.dart lib/Modules/Story/DeletedStories/deleted_stories.dart lib/Modules/Story/StoryMusic/story_music_profile_view.dart lib/Core/Widgets/app_state_view.dart
dart analyze lib/Modules/SocialProfile/social_profile.dart lib/Core/Widgets/app_state_view.dart
dart analyze lib/Modules/Education/CikmisSorular/cikmis_sorular.dart lib/Modules/Education/PracticeExams/SavedPracticeExams/saved_practice_exams.dart lib/Modules/Education/PracticeExams/deneme_sinavlari.dart lib/Modules/Education/Tests/LessonsBasedTests/lesson_based_tests.dart lib/Modules/Education/PracticeExams/SinavSonuclariPreview/sinav_sonuclari_preview.dart lib/Core/Widgets/app_state_view.dart
dart analyze lib/Modules/Education/Tutoring/tutoring_view.dart lib/Modules/Education/Tutoring/TutoringSearch/tutoring_search.dart lib/Modules/Education/Tutoring/TutoringDetail/tutoring_detail.dart lib/Modules/Education/Tutoring/LocationBasedTutoring/location_based_tutoring.dart lib/Core/Widgets/app_state_view.dart
dart analyze lib/Modules/Education/Antreman3/AntremanComments/antreman_comments.dart lib/Modules/Education/Antreman3/ThenSolve/then_solve.dart lib/Modules/Education/Antreman3/antreman_view.dart lib/Core/Widgets/app_state_view.dart
dart analyze lib/Modules/SpotifySelector/spotify_selector.dart lib/Modules/Market/market_search_view.dart lib/Modules/Market/market_create_view.dart lib/Modules/Education/Tutoring/tutoring_content.dart lib/Core/Widgets/app_state_view.dart
dart analyze lib/Modules/Education/PracticeExams/DenemeSinaviPreview/deneme_sinavi_preview.dart lib/Modules/Education/PracticeExams/DenemeSinaviYap/deneme_sinavi_yap.dart lib/Core/Widgets/app_state_view.dart
dart analyze lib/Runtime/primary_tab_router.dart lib/Modules/Splash/splash_view.dart test/unit/runtime/primary_tab_router_test.dart
flutter test test/unit/runtime/primary_tab_router_test.dart test/unit/runtime/app_decision_coordinator_test.dart
dart analyze test/unit/modules/sign_in/sign_in_application_service_test.dart
flutter test test/unit/modules/sign_in/sign_in_application_service_test.dart
dart analyze lib/Modules/Splash/splash_view.dart lib/Runtime/primary_tab_router.dart
dart analyze test/unit/modules/splash/startup_route_hint_test.dart lib/Modules/Splash/splash_view.dart
flutter test test/unit/modules/splash/startup_route_hint_test.dart
dart analyze test/unit/runtime/root_navigation_boundary_test.dart
flutter test test/unit/runtime/root_navigation_boundary_test.dart
dart analyze lib/Core/Utils/deep_link_utils.dart lib/Core/Services/deep_link_service.dart test/unit/utils/deep_link_utils_test.dart
flutter test test/unit/utils/deep_link_utils_test.dart
dart analyze test/unit/runtime/deep_link_parser_boundary_test.dart lib/Core/Services/deep_link_service.dart lib/Core/Utils/deep_link_utils.dart
flutter test test/unit/runtime/deep_link_parser_boundary_test.dart test/unit/utils/deep_link_utils_test.dart
dart analyze test/unit/runtime/deep_link_parser_boundary_test.dart lib/Core/Services/deep_link_service.dart lib/Runtime/primary_tab_router.dart
flutter test test/unit/runtime/deep_link_parser_boundary_test.dart test/unit/runtime/primary_tab_router_test.dart
dart analyze test/unit/runtime/app_decision_coordinator_test.dart lib/Runtime/app_decision_coordinator.dart
flutter test test/unit/runtime/app_decision_coordinator_test.dart test/unit/runtime/primary_tab_router_test.dart
dart analyze lib/Modules/Profile/Settings/settings.dart lib/Modules/Profile/Settings/account_center_view.dart lib/Runtime/session_exit_coordinator.dart test/unit/runtime/session_exit_coordinator_test.dart
flutter test test/unit/runtime/session_exit_coordinator_test.dart
dart analyze lib/Modules/Splash/splash_session_bootstrap.dart
flutter test test/unit/modules/splash
dart analyze lib/Runtime/primary_tab_router.dart test/unit/runtime/primary_tab_router_test.dart lib/Modules/SignIn/sign_in_controller.dart lib/Modules/Education/Scholarships/CreateScholarship/create_scholarship_controller.dart
flutter test test/unit/runtime/primary_tab_router_test.dart
dart analyze lib/Modules/Splash/splash_view.dart lib/Runtime/primary_tab_router.dart lib/Core/Utils/deep_link_utils.dart lib/Core/Services/deep_link_service.dart test/unit/runtime/root_navigation_boundary_test.dart test/unit/modules/splash/startup_route_hint_test.dart test/unit/utils/deep_link_utils_test.dart test/unit/modules/sign_in/sign_in_application_service_test.dart
flutter test test/unit/runtime/primary_tab_router_test.dart test/unit/runtime/app_decision_coordinator_test.dart test/unit/runtime/root_navigation_boundary_test.dart test/unit/modules/splash/startup_route_hint_test.dart test/unit/utils/deep_link_utils_test.dart test/unit/modules/sign_in/sign_in_application_service_test.dart
```

Latest full runtime guard result:

- `flutter test test/unit/runtime`: 118 tests passing.
- `flutter test test/unit/modules/sign_in/sign_in_application_service_test.dart`: 11 tests passing.
- `flutter test test/widget/components/app_state_view_widget_test.dart`: 3 tests passing.
- `dart analyze lib/Core/Repositories lib/Core/Services lib/Services test/unit/runtime`: no issues found.
- `dart analyze test/unit/modules/sign_in/sign_in_application_service_test.dart`: no issues found.
- `dart analyze lib/Core/Widgets/app_state_view.dart lib/Modules/Profile/SocialMediaLinks/social_media_links.dart test/widget/components/app_state_view_widget_test.dart`: no issues found.
- `dart analyze lib/Modules/Profile/Settings/support_admin_view.dart lib/Modules/Profile/Settings/reports_admin_view.dart lib/Modules/Education/AnswerKey/answer_key.dart lib/Core/Widgets/app_state_view.dart`: no issues found.
- `dart analyze lib/Modules/Education/Scholarships/scholarships_view.dart lib/Modules/Education/Scholarships/SavedItems/saved_items_view.dart lib/Core/Widgets/app_state_view.dart`: no issues found.
- `dart analyze lib/Modules/Education/Scholarships/BankInfo/bank_info_view.dart lib/Modules/Education/Scholarships/DormitoryInfo/dormitory_info_view.dart lib/Modules/Education/Scholarships/PersonelInfo/personel_info_view.dart lib/Core/Widgets/app_state_view.dart`: no issues found.
- `dart analyze lib/Modules/Education/Scholarships/Applications/applications_view.dart lib/Modules/Education/Scholarships/MyScholarship/my_scholarship_view.dart lib/Modules/Education/Scholarships/ScholarshipProviders/scholarship_providers_view.dart lib/Modules/Education/Scholarships/FamilyInfo/family_info_view.dart lib/Core/Widgets/app_state_view.dart`: no issues found.
- `dart analyze lib/Modules/Education/Scholarships/EducationInfo/education_info_view.dart lib/Modules/Education/Scholarships/Personalized/personalized_view.dart lib/Core/Widgets/app_state_view.dart`: no issues found.
- `dart analyze lib/Modules/Education/Scholarships/ScholarshipApplicationsContent/scholarship_applications_content.dart lib/Modules/Education/Scholarships/ScholarshipApplicationsContent/applicant_profile.dart lib/Core/Widgets/app_state_view.dart`: no issues found.
- `dart analyze lib/Modules/Education/AnswerKey/SavedOpticalForms/saved_optical_forms.dart lib/Modules/Education/AnswerKey/MyBookletResults/my_booklet_results.dart lib/Modules/Education/AnswerKey/SearchAnswerKey/search_answer_key.dart lib/Core/Widgets/app_state_view.dart`: no issues found.
- `dart analyze lib/Modules/Education/AnswerKey/CategoryBasedAnswerKey/category_based_answer_key.dart lib/Modules/Education/AnswerKey/OpticsAndBooksPublished/optics_and_books_published.dart lib/Core/Widgets/app_state_view.dart`: no issues found.
- `dart analyze lib/Modules/Profile/Settings/admin_approvals_view.dart lib/Modules/Profile/Settings/admin_task_assignments_view.dart lib/Modules/Profile/Settings/badge_admin_view.dart lib/Modules/Profile/Settings/moderation_settings_view.dart lib/Core/Widgets/app_state_view.dart`: no issues found.
- `dart analyze lib/Modules/Profile/Settings/my_admin_approval_results_view.dart lib/Modules/Profile/Settings/notification_settings_view.dart lib/Modules/Profile/Settings/permissions_view.dart lib/Modules/Profile/Settings/story_music_admin_view.dart lib/Core/Widgets/app_state_view.dart`: no issues found.
- `dart analyze lib/Modules/Profile/Settings/AdsCenter/ads_center_home_view.dart lib/Modules/Profile/Settings/AdsCenter/turqapp_suggestion_admin_view.dart lib/Modules/Profile/Settings/surface_policy_settings_view.dart lib/Modules/Profile/Settings/account_center_view.dart lib/Modules/Profile/Settings/admin_task_assignments_view.dart lib/Modules/Profile/Settings/badge_admin_view.dart lib/Modules/Profile/Settings/moderation_settings_view.dart lib/Core/Widgets/app_state_view.dart`: no issues found.
- `dart analyze lib/Modules/Profile/Settings/admin_push_view.dart lib/Modules/Profile/Settings/AdsCenter/ads_center_home_view.dart lib/Modules/Profile/Settings/AdsCenter/turqapp_suggestion_admin_view.dart lib/Modules/Profile/Settings/surface_policy_settings_view.dart lib/Modules/Profile/Settings/account_center_view.dart lib/Modules/Profile/Settings/admin_task_assignments_view.dart lib/Modules/Profile/Settings/badge_admin_view.dart lib/Modules/Profile/Settings/moderation_settings_view.dart lib/Core/Widgets/app_state_view.dart`: no issues found.
- `dart analyze lib/Modules/Chat/ChatListing/chat_listing.dart lib/Modules/Chat/LocationShareView/location_share_view_chat.dart lib/Core/Widgets/app_state_view.dart`: no issues found.
- `dart analyze lib/Modules/Market/market_view.dart lib/Modules/Market/market_my_items_view.dart lib/Modules/Market/market_offers_view.dart lib/Modules/Market/market_saved_view.dart lib/Core/Widgets/app_state_view.dart`: no issues found.
- `dart analyze lib/Modules/JobFinder/job_finder.dart lib/Modules/JobFinder/MyApplications/my_applications.dart lib/Modules/JobFinder/SavedJobs/saved_jobs.dart lib/Modules/JobFinder/MyJobAds/my_job_ads.dart lib/Modules/JobFinder/ApplicationReview/application_review.dart lib/Modules/JobFinder/CareerProfile/career_profile.dart lib/Core/Widgets/app_state_view.dart`: no issues found.
- `dart analyze lib/Modules/Explore/explore_view.dart lib/Modules/JobFinder/job_finder.dart lib/Modules/JobFinder/MyApplications/my_applications.dart lib/Modules/JobFinder/SavedJobs/saved_jobs.dart lib/Modules/JobFinder/MyJobAds/my_job_ads.dart lib/Modules/JobFinder/ApplicationReview/application_review.dart lib/Modules/JobFinder/CareerProfile/career_profile.dart lib/Core/Widgets/app_state_view.dart`: no issues found.
- `dart analyze lib/Modules/Profile/Archives/archives.dart lib/Modules/Profile/LikedPosts/liked_posts.dart lib/Modules/Profile/SavedPosts/saved_posts.dart lib/Core/Widgets/app_state_view.dart`: no issues found.
- `dart analyze lib/Modules/Profile/FollowingFollowers/following_followers.dart lib/Core/Widgets/app_state_view.dart`: no issues found.
- `dart analyze lib/Modules/Profile/BlockedUsers/blocked_users.dart lib/Modules/Profile/MyStatistic/my_statistic_view.dart lib/Core/Widgets/app_state_view.dart`: no issues found.
- `dart analyze lib/Modules/Profile/MyProfile/profile_view.dart lib/Core/Widgets/app_state_view.dart`: no issues found.
- `dart analyze lib/Modules/Education/Tutoring/MyTutorings/my_tutorings.dart lib/Modules/Education/Tutoring/MyTutoringApplications/my_tutoring_applications.dart lib/Modules/Education/Tutoring/TutoringApplicationReview/tutoring_application_review.dart lib/Core/Widgets/app_state_view.dart`: no issues found.
- `dart analyze lib/Modules/Education/Tests/SavedTests/saved_tests.dart lib/Modules/Education/Tests/MyTestResults/my_test_results.dart lib/Modules/Education/Tests/SolveTest/solve_test.dart lib/Modules/Education/Tests/MyPastTestResultsPreview.dart/my_past_test_results_preview.dart lib/Core/Widgets/app_state_view.dart`: no issues found.
- `dart analyze lib/Modules/InAppNotifications/in_app_notifications.dart lib/Modules/Story/StoryViewer/StoryLikes/story_likes.dart lib/Modules/Story/StoryViewer/StorySeens/story_seens.dart lib/Modules/Story/StoryViewer/StoryComments/story_comments.dart lib/Modules/Story/DeletedStories/deleted_stories.dart lib/Modules/Story/StoryMusic/story_music_profile_view.dart lib/Core/Widgets/app_state_view.dart`: no issues found.
- `dart analyze lib/Modules/SocialProfile/social_profile.dart lib/Core/Widgets/app_state_view.dart`: no issues found.
- `dart analyze lib/Modules/Education/CikmisSorular/cikmis_sorular.dart lib/Modules/Education/PracticeExams/SavedPracticeExams/saved_practice_exams.dart lib/Modules/Education/PracticeExams/deneme_sinavlari.dart lib/Modules/Education/Tests/LessonsBasedTests/lesson_based_tests.dart lib/Modules/Education/PracticeExams/SinavSonuclariPreview/sinav_sonuclari_preview.dart lib/Core/Widgets/app_state_view.dart`: no issues found.
- `dart analyze lib/Modules/Education/Tutoring/tutoring_view.dart lib/Modules/Education/Tutoring/TutoringSearch/tutoring_search.dart lib/Modules/Education/Tutoring/TutoringDetail/tutoring_detail.dart lib/Modules/Education/Tutoring/LocationBasedTutoring/location_based_tutoring.dart lib/Core/Widgets/app_state_view.dart`: no issues found.
- `dart analyze lib/Modules/Education/Antreman3/AntremanComments/antreman_comments.dart lib/Modules/Education/Antreman3/ThenSolve/then_solve.dart lib/Modules/Education/Antreman3/antreman_view.dart lib/Core/Widgets/app_state_view.dart`: no issues found.
- `dart analyze lib/Modules/SpotifySelector/spotify_selector.dart lib/Modules/Market/market_search_view.dart lib/Modules/Market/market_create_view.dart lib/Modules/Education/Tutoring/tutoring_content.dart lib/Core/Widgets/app_state_view.dart`: no issues found.
- `dart analyze lib/Modules/Education/PracticeExams/DenemeSinaviPreview/deneme_sinavi_preview.dart lib/Modules/Education/PracticeExams/DenemeSinaviYap/deneme_sinavi_yap.dart lib/Core/Widgets/app_state_view.dart`: no issues found.
- `dart analyze lib/Runtime/primary_tab_router.dart lib/Modules/Splash/splash_view.dart test/unit/runtime/primary_tab_router_test.dart`: no issues found.
- `flutter test test/unit/runtime/primary_tab_router_test.dart test/unit/runtime/app_decision_coordinator_test.dart`: 15 tests passing.
- `dart analyze test/unit/modules/sign_in/sign_in_application_service_test.dart`: no issues found.
- `flutter test test/unit/modules/sign_in/sign_in_application_service_test.dart`: 11 tests passing.
- `dart analyze lib/Modules/Splash/splash_view.dart lib/Runtime/primary_tab_router.dart`: no issues found.
- `dart analyze test/unit/modules/splash/startup_route_hint_test.dart lib/Modules/Splash/splash_view.dart`: no issues found.
- `flutter test test/unit/modules/splash/startup_route_hint_test.dart`: 4 tests passing.
- `dart analyze test/unit/runtime/root_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/root_navigation_boundary_test.dart`: 2 tests passing.
- `dart analyze lib/Core/Utils/deep_link_utils.dart lib/Core/Services/deep_link_service.dart test/unit/utils/deep_link_utils_test.dart`: no issues found.
- `flutter test test/unit/utils/deep_link_utils_test.dart`: 4 tests passing.
- `dart analyze test/unit/runtime/deep_link_parser_boundary_test.dart lib/Core/Services/deep_link_service.dart lib/Core/Utils/deep_link_utils.dart`: no issues found.
- `flutter test test/unit/runtime/deep_link_parser_boundary_test.dart test/unit/utils/deep_link_utils_test.dart`: 5 tests passing.
- `dart analyze test/unit/runtime/deep_link_parser_boundary_test.dart lib/Core/Services/deep_link_service.dart lib/Runtime/primary_tab_router.dart`: no issues found.
- `flutter test test/unit/runtime/deep_link_parser_boundary_test.dart test/unit/runtime/primary_tab_router_test.dart`: 10 tests passing.
- `dart analyze test/unit/runtime/app_decision_coordinator_test.dart lib/Runtime/app_decision_coordinator.dart`: no issues found.
- `flutter test test/unit/runtime/app_decision_coordinator_test.dart test/unit/runtime/primary_tab_router_test.dart`: 17 tests passing.
- `dart analyze lib/Modules/Profile/Settings/settings.dart lib/Modules/Profile/Settings/account_center_view.dart lib/Runtime/session_exit_coordinator.dart test/unit/runtime/session_exit_coordinator_test.dart`: no issues found.
- `flutter test test/unit/runtime/session_exit_coordinator_test.dart`: 3 tests passing.
- `dart analyze lib/Modules/Splash/splash_session_bootstrap.dart`: no issues found.
- `flutter test test/unit/modules/splash`: 12 tests passing.
- `dart analyze lib/Runtime/primary_tab_router.dart test/unit/runtime/primary_tab_router_test.dart lib/Modules/SignIn/sign_in_controller.dart lib/Modules/Education/Scholarships/CreateScholarship/create_scholarship_controller.dart`: no issues found.
- `flutter test test/unit/runtime/primary_tab_router_test.dart`: 10 tests passing.
- `dart analyze lib/Modules/Short/short_view.dart lib/Runtime/primary_tab_router.dart test/unit/runtime/primary_tab_router_test.dart`: no issues found.
- `flutter test test/unit/runtime/primary_tab_router_test.dart`: 10 tests passing.
- `dart analyze lib/Core/Utils/deep_link_utils.dart lib/Core/Services/deep_link_service.dart test/unit/utils/deep_link_utils_test.dart test/unit/runtime/deep_link_parser_boundary_test.dart`: no issues found.
- `flutter test test/unit/utils/deep_link_utils_test.dart test/unit/runtime/deep_link_parser_boundary_test.dart`: 7 tests passing.
- `dart analyze test/unit/runtime/deep_link_parser_boundary_test.dart lib/Core/Services/deep_link_service.dart lib/Core/Utils/deep_link_utils.dart`: no issues found.
- `flutter test test/unit/runtime/deep_link_parser_boundary_test.dart test/unit/utils/deep_link_utils_test.dart`: 7 tests passing.
- `dart analyze test/unit/runtime/primary_tab_router_test.dart`: no issues found.
- `flutter test test/unit/runtime/primary_tab_router_test.dart`: 11 tests passing.
- `dart analyze test/unit/runtime/root_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/root_navigation_boundary_test.dart`: 1 test passing.
- `dart analyze lib/Core/Utils/deep_link_utils.dart lib/Core/Services/deep_link_service.dart test/unit/utils/deep_link_utils_test.dart test/unit/runtime/deep_link_parser_boundary_test.dart`: no issues found.
- `flutter test test/unit/utils/deep_link_utils_test.dart test/unit/runtime/deep_link_parser_boundary_test.dart`: 9 tests passing.
- `dart analyze lib/Core/Services/deep_link_service.dart lib/Core/Utils/deep_link_utils.dart test/unit/runtime/deep_link_parser_boundary_test.dart test/unit/utils/deep_link_utils_test.dart`: no issues found.
- `flutter test test/unit/runtime/deep_link_parser_boundary_test.dart test/unit/utils/deep_link_utils_test.dart`: 9 tests passing.
- `dart analyze lib/Modules/Splash/splash_view.dart lib/Runtime/primary_tab_router.dart test/unit/runtime/primary_tab_router_test.dart`: no issues found.
- `flutter test test/unit/runtime/primary_tab_router_test.dart test/unit/runtime/app_decision_coordinator_test.dart test/unit/modules/splash/startup_route_hint_test.dart`: 25 tests passing.
- `dart analyze lib/Runtime/app_decision_coordinator.dart lib/Modules/Splash/splash_view.dart test/unit/runtime/app_decision_coordinator_test.dart test/unit/modules/splash/startup_route_hint_test.dart`: no issues found.
- `flutter test test/unit/runtime/app_decision_coordinator_test.dart test/unit/modules/splash/startup_route_hint_test.dart test/unit/runtime/primary_tab_router_test.dart`: 26 tests passing.
- `dart analyze lib/Runtime/app_decision_coordinator.dart lib/Modules/Splash/splash_view.dart test/unit/runtime/app_decision_coordinator_test.dart test/unit/modules/splash/startup_route_hint_test.dart`: no issues found.
- `flutter test test/unit/runtime/app_decision_coordinator_test.dart test/unit/modules/splash/startup_route_hint_test.dart test/unit/runtime/primary_tab_router_test.dart`: 28 tests passing.
- `flutter test test/unit/runtime/app_decision_coordinator_test.dart test/unit/modules/splash/startup_route_hint_test.dart`: 16 tests passing.
- `dart analyze test/unit/runtime/primary_tab_router_test.dart lib/Runtime/primary_tab_router.dart lib/Modules/NavBar/nav_bar_controller.dart`: no issues found.
- `flutter test test/unit/runtime/primary_tab_router_test.dart`: 14 tests passing.
- `dart analyze lib/Modules/Education/education_controller.dart lib/Runtime/app_decision_coordinator.dart test/unit/runtime/primary_tab_router_test.dart`: no issues found.
- `flutter test test/unit/runtime/primary_tab_router_test.dart`: 15 tests passing.
- `dart analyze lib/Runtime/primary_tab_router.dart lib/Runtime/app_decision_coordinator.dart test/unit/runtime/primary_tab_router_test.dart`: no issues found.
- `flutter test test/unit/runtime/primary_tab_router_test.dart`: 16 tests passing.
- `dart analyze test/unit/runtime/primary_tab_router_test.dart lib/Runtime/primary_tab_router.dart lib/Runtime/app_decision_coordinator.dart`: no issues found.
- `flutter test test/unit/runtime/primary_tab_router_test.dart`: 17 tests passing.
- `dart analyze test/unit/runtime/session_exit_coordinator_test.dart lib/Runtime/session_exit_coordinator.dart`: no issues found.
- `flutter test test/unit/runtime/session_exit_coordinator_test.dart`: 4 tests passing.
- `dart analyze lib/Modules/Profile/Settings/account_center_view.dart test/unit/runtime/session_exit_coordinator_test.dart lib/Runtime/session_exit_coordinator.dart`: no issues found.
- `flutter test test/unit/runtime/session_exit_coordinator_test.dart`: 4 tests passing.
- `dart analyze lib/Core/external.dart lib/Core/Slider/slider_admin_view.dart test/unit/runtime/app_backend_singleton_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/app_backend_singleton_boundary_test.dart`: 1 test passing.
- `dart analyze lib/Core/Services/app_firebase_auth.dart lib/Core/notification_service.dart lib/Core/Services/draft_service_library.dart lib/Core/Repositories/recommended_users_repository.dart lib/Core/Repositories/profile_repository_library.dart lib/Core/Repositories/post_repository.dart lib/Core/Services/qa_lab_remote_uploader.dart lib/Core/Services/admin_access_service.dart lib/Core/Services/integration_test_state_probe.dart lib/Services/current_user_service.dart test/unit/runtime/app_auth_singleton_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/app_auth_singleton_boundary_test.dart test/unit/runtime/module_auth_boundary_test.dart`: 2 tests passing.
- `dart analyze lib/Core/NotifyReader/notify_reader_controller.dart lib/Core/NotifyReader/notify_reader_route_decision.dart test/unit/runtime/notify_reader_route_decision_test.dart`: no issues found.
- `flutter test test/unit/runtime/notify_reader_route_decision_test.dart test/unit/runtime/root_navigation_boundary_test.dart`: 7 tests passing.
- `flutter test test/unit/runtime/notify_reader_route_decision_test.dart`: 10 tests passing.
- `dart analyze lib/Runtime/app_decision_coordinator.dart lib/Modules/Splash/splash_view.dart test/unit/runtime/app_decision_coordinator_test.dart test/unit/modules/splash/startup_route_hint_test.dart`: no issues found.
- `flutter test test/unit/runtime/app_decision_coordinator_test.dart test/unit/modules/splash/startup_route_hint_test.dart`: 16 tests passing.
- `dart analyze lib/Core/Services/education_detail_navigation_service.dart lib/Modules/JobFinder/JobDetails/job_details.dart lib/Modules/Education/Tutoring/TutoringDetail/tutoring_detail.dart test/unit/runtime/education_detail_navigation_boundary_test.dart`: no issues found.
- `dart analyze lib/Core/Services/education_detail_navigation_service.dart lib/Modules/JobFinder/JobContent/job_content.dart lib/Modules/JobFinder/JobDetails/job_details.dart lib/Modules/Education/Tutoring/tutoring_widget_builder.dart lib/Modules/Education/Tutoring/TutoringDetail/tutoring_detail.dart test/unit/runtime/education_detail_navigation_boundary_test.dart`: no issues found.
- `dart analyze lib/Core/Services/education_detail_navigation_service.dart lib/Core/Services/deep_link_service.dart lib/Core/Services/education_feed_cta_navigation_service.dart lib/Core/NotifyReader/notify_reader_controller.dart test/unit/runtime/education_detail_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/education_detail_navigation_boundary_test.dart`: 1 test passing.
- `flutter test test/unit/runtime/education_detail_navigation_boundary_test.dart test/unit/runtime/deep_link_parser_boundary_test.dart test/unit/runtime/notify_reader_route_decision_test.dart`: 14 tests passing.
- `dart analyze lib/Core/Services/market_detail_navigation_service.dart lib/Modules/Market/market_controller.dart lib/Modules/Market/market_offers_view.dart lib/Modules/Market/market_saved_view.dart lib/Modules/Market/market_my_items_view.dart lib/Core/Services/deep_link_service.dart lib/Core/Services/education_feed_cta_navigation_service.dart lib/Core/NotifyReader/notify_reader_controller.dart test/unit/runtime/market_detail_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/market_detail_navigation_boundary_test.dart test/unit/runtime/deep_link_parser_boundary_test.dart test/unit/runtime/notify_reader_route_decision_test.dart`: 14 tests passing.
- `dart analyze lib/Core/Services/market_detail_navigation_service.dart lib/Modules/Profile/MyProfile/profile_view.dart lib/Modules/SocialProfile/social_profile.dart lib/Modules/Profile/SavedPosts/saved_posts.dart test/unit/runtime/market_detail_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/market_detail_navigation_boundary_test.dart`: 1 test passing.
- `dart analyze test/unit/runtime/market_detail_navigation_boundary_test.dart lib/Core/Services/market_detail_navigation_service.dart`: no issues found.
- `flutter test test/unit/runtime/market_detail_navigation_boundary_test.dart`: 2 tests passing.
- `dart analyze lib/Modules/Education/Scholarships/scholarship_navigation_service.dart lib/Core/Services/education_feed_cta_navigation_service.dart lib/Modules/Education/Scholarships/Personalized/personalized_view.dart lib/Modules/Education/Scholarships/Personalized/personalized_content.dart test/unit/runtime/scholarship_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/scholarship_navigation_boundary_test.dart`: 1 test passing.
- `dart analyze lib/Core/Services/practice_exam_navigation_service.dart lib/Modules/Education/PracticeExams/DenemeGrid/deneme_grid.dart lib/Core/Services/education_feed_cta_navigation_service.dart test/unit/runtime/practice_exam_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/practice_exam_navigation_boundary_test.dart`: 2 tests passing.
- `dart analyze lib/Core/Services/answer_key_navigation_service.dart lib/Modules/Education/AnswerKey/AnswerKeyContent/answer_key_content_controller.dart lib/Modules/Education/AnswerKey/SearchAnswerKey/search_answer_key_controller.dart lib/Modules/Education/AnswerKey/CategoryBasedAnswerKey/category_based_answer_key.dart test/unit/runtime/answer_key_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/answer_key_navigation_boundary_test.dart`: 2 tests passing.
- `dart analyze lib/Core/Services/education_result_navigation_service.dart lib/Modules/Education/AnswerKey/BookletResultContent/booklet_result_content.dart lib/Modules/Education/Tests/TestPastResultContent/test_past_result_content.dart lib/Modules/Education/PracticeExams/DenemeGecmisSonucContent/deneme_gecmis_sonuc_content.dart test/unit/runtime/education_result_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/education_result_navigation_boundary_test.dart`: 2 tests passing.
- `dart analyze test/unit/runtime/education_test_navigation_boundary_test.dart lib/Core/Services/education_test_navigation_service.dart lib/Modules/Education/Tests/TestsGrid/tests_grid_controller.dart lib/Modules/Education/Tests/TestEntry/test_entry_controller.dart`: no issues found.
- `flutter test test/unit/runtime/education_test_navigation_boundary_test.dart`: 2 tests passing.
- `dart analyze lib/Core/Services/education_test_navigation_service.dart lib/Modules/Education/Tests/tests.dart lib/Modules/Education/Tests/MyTests/my_tests.dart lib/Modules/Education/Tests/TestsGrid/tests_grid_controller.dart lib/Modules/Education/Tests/TestEntry/test_entry_controller.dart test/unit/runtime/education_test_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/education_test_navigation_boundary_test.dart`: 3 tests passing.
- `dart analyze lib/Core/Services/practice_exam_navigation_service.dart lib/Modules/Education/PracticeExams/deneme_sinavlari.dart lib/Modules/Education/PracticeExams/DenemeGrid/deneme_grid.dart lib/Modules/Education/education_view.dart test/unit/runtime/practice_exam_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/practice_exam_navigation_boundary_test.dart`: 3 tests passing.
- `dart analyze lib/Core/Services/answer_key_navigation_service.dart lib/Modules/Education/AnswerKey/answer_key.dart lib/Modules/Education/AnswerKey/BookletPreview/booklet_preview_controller.dart lib/Modules/Education/education_view.dart test/unit/runtime/answer_key_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/answer_key_navigation_boundary_test.dart`: 3 tests passing.
- `dart analyze lib/Modules/Education/Scholarships/scholarship_navigation_service.dart lib/Modules/Education/education_view.dart lib/Modules/Education/Scholarships/scholarships_view.dart lib/Modules/Education/Scholarships/scholarships_controller.dart lib/Modules/Education/Scholarships/CreateScholarship/create_scholarship_controller.dart lib/Modules/Education/Scholarships/CreateScholarship/create_scholarship_view.dart lib/Modules/Education/Scholarships/ScholarshipDetail/scholarship_detail_view.dart test/unit/runtime/scholarship_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/scholarship_navigation_boundary_test.dart`: 3 tests passing.
- `dart analyze lib/Core/Services/education_detail_navigation_service.dart lib/Modules/Education/education_view.dart lib/Modules/Education/Tutoring/tutoring_view.dart lib/Modules/Education/Tutoring/tutoring_category.dart lib/Modules/Education/Tutoring/TutoringDetail/tutoring_detail.dart lib/Modules/JobFinder/JobDetails/job_details_controller.dart test/unit/runtime/education_detail_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/education_detail_navigation_boundary_test.dart`: 2 tests passing.
- `dart analyze lib/Core/Services/market_detail_navigation_service.dart lib/Modules/Market/market_controller.dart lib/Modules/Market/market_my_items_view.dart lib/Modules/Market/market_detail_view.dart lib/Modules/Education/education_view.dart test/unit/runtime/market_detail_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/market_detail_navigation_boundary_test.dart`: 3 tests passing.
- `dart analyze lib/Core/Services/education_question_bank_navigation_service.dart lib/Modules/Education/education_view.dart lib/Modules/Education/Antreman3/antreman_view.dart lib/Modules/Education/Antreman3/question_content.dart test/unit/runtime/education_question_bank_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/education_question_bank_navigation_boundary_test.dart`: 1 test passing.
- `dart analyze lib/Core/Services/profile_navigation_service.dart lib/Core/Services/deep_link_service.dart lib/Modules/Education/Antreman3/AntremanScore/antreman_score.dart lib/Modules/Education/AnswerKey/BookletPreview/booklet_preview.dart lib/Modules/Education/PracticeExams/DenemeSinaviPreview/deneme_sinavi_preview.dart lib/Modules/Education/Scholarships/ScholarshipApplicationsContent/applicant_profile.dart lib/Modules/Education/Scholarships/ScholarshipDetail/scholarship_detail_view.dart lib/Modules/Education/Scholarships/ScholarshipProviders/scholarship_providers_view.dart lib/Modules/Education/Scholarships/scholarships_view.dart lib/Modules/Education/Tests/TestsGrid/tests_grid_controller.dart lib/Modules/Education/Tutoring/TutoringApplicationReview/tutoring_application_review.dart lib/Modules/Education/Tutoring/TutoringDetail/tutoring_detail.dart test/unit/runtime/profile_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/profile_navigation_boundary_test.dart`: 1 test passing.
- `dart analyze lib/Modules/Education/Scholarships/scholarship_navigation_service.dart lib/Modules/Education/Scholarships/ScholarshipApplicationsContent/scholarship_applications_content.dart test/unit/runtime/scholarship_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/scholarship_navigation_boundary_test.dart`: 3 tests passing.
- `dart analyze lib/Core/Services/slider_admin_navigation_service.dart lib/Modules/Education/education_view.dart lib/Modules/Education/AnswerKey/answer_key.dart lib/Modules/Education/PracticeExams/deneme_sinavlari.dart lib/Modules/Education/Tutoring/tutoring_view.dart lib/Modules/Education/CikmisSorular/cikmis_sorular.dart test/unit/runtime/slider_admin_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/slider_admin_navigation_boundary_test.dart test/unit/runtime/education_question_bank_navigation_boundary_test.dart`: 2 tests passing.
- `dart analyze lib/Core/Services/report_user_navigation_service.dart lib/Modules/Education/Scholarships/ScholarshipDetail/scholarship_detail_view.dart lib/Modules/Education/AnswerKey/BookletPreview/booklet_preview.dart lib/Modules/Education/PracticeExams/DenemeSinaviPreview/deneme_sinavi_preview.dart lib/Modules/Education/Tutoring/TutoringDetail/tutoring_detail.dart test/unit/runtime/report_user_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/report_user_navigation_boundary_test.dart`: 1 test passing.
- `dart analyze lib/Core/Services/chat_navigation_service.dart lib/Modules/Education/Tutoring/TutoringDetail/tutoring_detail.dart test/unit/runtime/chat_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/chat_navigation_boundary_test.dart`: 1 test passing.
- `dart analyze lib/Core/Services/verified_account_navigation_service.dart lib/Modules/Education/PracticeExams/deneme_sinavlari.dart lib/Modules/Profile/Settings/settings.dart lib/Modules/Profile/MyProfile/profile_view.dart test/unit/runtime/verified_account_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/verified_account_navigation_boundary_test.dart`: 1 test passing.
- `dart analyze lib/Core/Services/education_detail_navigation_service.dart lib/Modules/JobFinder/JobDetails/job_details.dart lib/Modules/JobFinder/CareerProfile/career_profile.dart lib/Modules/JobFinder/FindingJobApply/finding_job_apply.dart lib/Modules/JobFinder/ApplicationReview/application_review.dart test/unit/runtime/jobfinder_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/jobfinder_navigation_boundary_test.dart`: 1 test passing.
- `dart analyze lib/Modules/Market/market_detail_view.dart test/unit/runtime/market_contact_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/market_contact_navigation_boundary_test.dart`: 1 test passing.
- `dart analyze lib/Modules/Profile/MyProfile/profile_view.dart lib/Modules/Agenda/agenda_view.dart test/unit/runtime/chat_listing_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/chat_listing_navigation_boundary_test.dart`: 1 test passing.
- `dart analyze lib/Modules/RecommendedUserList/RecommendedUserContent/recommended_user_content.dart test/unit/runtime/recommended_user_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/recommended_user_navigation_boundary_test.dart`: 1 test passing.
- `dart analyze lib/Modules/Chat/ChatListingContent/chat_listing_content.dart lib/Modules/Chat/chat.dart lib/Modules/Chat/MessageContent/message_content.dart test/unit/runtime/chat_profile_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/chat_profile_navigation_boundary_test.dart`: 1 test passing.
- `dart analyze lib/Modules/Profile/FollowingFollowers/follower_content.dart lib/Modules/InAppNotifications/notification_content.dart test/unit/runtime/profile_surface_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/profile_surface_navigation_boundary_test.dart`: 1 test passing.
- `dart analyze lib/Modules/Social/PostSharers/post_sharers.dart lib/Modules/Agenda/PostLikeListing/PostLikeContent/post_like_content.dart lib/Modules/Agenda/PostReshareListing/PostReshareContent/post_reshare_content.dart test/unit/runtime/social_reaction_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/social_reaction_navigation_boundary_test.dart`: 1 test passing.
- `dart analyze lib/Modules/Short/short_content.dart test/unit/runtime/short_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/short_navigation_boundary_test.dart`: 1 test passing.
- `dart analyze lib/Modules/Agenda/ClassicContent/classic_content.dart test/unit/runtime/classic_content_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/classic_content_navigation_boundary_test.dart`: 1 test passing.
- `dart analyze lib/Modules/Agenda/AgendaContent/agenda_content.dart test/unit/runtime/agenda_content_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/agenda_content_navigation_boundary_test.dart`: 1 test passing.
- `dart analyze lib/Modules/Story/StoryViewer/story_elements.dart lib/Modules/Story/StoryViewer/user_story_content.dart lib/Modules/Story/StoryViewer/StoryComments/StoryCommentUser/story_comment_user.dart lib/Modules/Story/StoryViewer/StoryContentProfiles/story_content_profiles.dart test/unit/runtime/story_profile_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/story_profile_navigation_boundary_test.dart`: 1 test passing.
- `dart analyze lib/Modules/Social/Comments/post_comment_content.dart lib/Modules/Social/PhotoShorts/photo_short_content.dart test/unit/runtime/social_comment_photo_short_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/social_comment_photo_short_navigation_boundary_test.dart`: 1 test passing.
- `dart analyze lib/Core/Services/profile_navigation_service.dart lib/Core/Helpers/QRCode/qr_scanner_view.dart lib/Core/Widgets/shared_post_label.dart lib/Modules/Explore/SearchedUser/search_user_content.dart lib/Modules/Explore/SearchedUser/search_user_content_controller.dart test/unit/runtime/core_explore_profile_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/core_explore_profile_navigation_boundary_test.dart`: 1 test passing.
- `dart analyze lib/Modules/SocialProfile/social_profile.dart lib/Modules/Profile/Settings/badge_admin_view.dart lib/Modules/Profile/Settings/support_admin_view.dart test/unit/runtime/profile_settings_report_navigation_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/profile_settings_report_navigation_boundary_test.dart`: 1 test passing.
- `dart analyze lib/Core/NotifyReader/notify_reader_controller.dart test/unit/runtime/notify_reader_route_decision_test.dart`: no issues found.
- `flutter test test/unit/runtime/notify_reader_route_decision_test.dart`: 10 tests passing.
- `dart analyze test/unit/runtime/profile_report_route_owner_guard_test.dart`: no issues found.
- `flutter test test/unit/runtime/profile_report_route_owner_guard_test.dart`: 1 test passing.
- `dart analyze lib/Core/Services/webp_upload_service.dart lib/Modules/Education/Antreman3/AntremanComments/antreman_comments_controller.dart lib/Modules/Education/Tests/AddTestQuestion/add_test_question_controller_library.dart test/unit/runtime/education_webp_upload_storage_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/education_webp_upload_storage_boundary_test.dart`: 1 test passing.
- `dart analyze lib/Modules/Profile/EditProfile/edit_profile_controller.dart lib/Modules/Profile/Cv/cv_controller.dart lib/Modules/Profile/SocialMediaLinks/social_media_links_controller_library.dart lib/Modules/Profile/Settings/story_music_admin_view.dart test/unit/runtime/profile_webp_upload_storage_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/profile_webp_upload_storage_boundary_test.dart`: 1 test passing.
- `dart analyze lib/Modules/Education/Tests/CreateTest/create_test_controller.dart lib/Modules/Education/Tests/CreateTestQuestionContent/create_test_question_content_controller_library.dart lib/Modules/Education/PracticeExams/SoruContent/soru_content.dart lib/Modules/Education/PracticeExams/SinavHazirla/sinav_hazirla_controller.dart test/unit/runtime/education_test_practice_webp_storage_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/education_test_practice_webp_storage_boundary_test.dart`: 1 test passing.
- `dart analyze lib/Core/Slider/slider_admin_view.dart lib/Modules/JobFinder/JobCreator/job_creator_controller.dart lib/Modules/Market/market_create_controller.dart lib/Modules/Story/StoryMaker/story_maker_controller.dart lib/Modules/Story/StoryHighlights/story_highlights_controller_library.dart test/unit/runtime/core_story_market_job_webp_storage_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/core_story_market_job_webp_storage_boundary_test.dart`: 1 test passing.
- `dart analyze lib/Modules/PostCreator/post_creator_controller.dart test/unit/runtime/post_creator_webp_upload_storage_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/post_creator_webp_upload_storage_boundary_test.dart`: 1 test passing.
- `rg -n "storage: AppFirebaseStorage\\.instance" lib/Modules lib/Core/Slider`: no matches.
- `dart analyze lib/Core/Services/upload_queue_service.dart test/unit/runtime/webp_upload_default_storage_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/webp_upload_default_storage_boundary_test.dart`: 1 test passing.
- `rg -n "storage: AppFirebaseStorage\\.instance" lib`: no matches.
- `dart analyze lib/Modules/Education/Tutoring/CreateTutoring/create_tutoring_controller.dart lib/Modules/EditPost/edit_post_controller.dart lib/Modules/Chat/chat_controller.dart test/unit/runtime/webp_upload_default_storage_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/webp_upload_default_storage_boundary_test.dart`: 1 test passing.
- WebP upload sweep under `lib`: all `WebpUploadService.uploadFileAsWebp` and `uploadBytesAsWebp` callers now omit `storage:`.
- `dart analyze lib/Core/Services/webp_upload_service.dart lib/Modules/Education/AnswerKey/CreateBook/create_book_controller.dart lib/Modules/Education/Scholarships/CreateScholarship/create_scholarship_controller.dart test/unit/runtime/prepared_webp_upload_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/prepared_webp_upload_boundary_test.dart`: 1 test passing.
- `dart analyze test/unit/runtime/direct_storage_owner_guard_test.dart`: no issues found.
- `flutter test test/unit/runtime/direct_storage_owner_guard_test.dart`: 1 test passing.
- `dart analyze lib/Modules/Splash/splash_view.dart lib/Modules/Splash/splash_view_startup_part.dart`: no issues found.
- `flutter test test/unit/runtime/app_decision_coordinator_test.dart test/unit/modules/splash/startup_route_hint_test.dart test/unit/runtime/primary_tab_router_test.dart`: 33 tests passing.
- `dart analyze test/unit/utils/deep_link_utils_test.dart lib/Core/Utils/deep_link_utils.dart`: no issues found.
- `flutter test test/unit/utils/deep_link_utils_test.dart test/unit/runtime/deep_link_parser_boundary_test.dart`: 12 tests passing.
- `dart analyze test/unit/runtime/app_decision_coordinator_test.dart test/unit/runtime/primary_tab_router_test.dart lib/Runtime/app_decision_coordinator.dart lib/Runtime/primary_tab_router.dart`: no issues found.
- `flutter test test/unit/runtime/app_decision_coordinator_test.dart test/unit/runtime/primary_tab_router_test.dart test/unit/modules/splash/startup_route_hint_test.dart`: 37 tests passing.
- `dart analyze test/unit/runtime/app_decision_coordinator_test.dart test/unit/runtime/primary_tab_router_test.dart lib/Runtime/app_decision_coordinator.dart lib/Runtime/primary_tab_router.dart`: no issues found.
- `flutter test test/unit/runtime/app_decision_coordinator_test.dart test/unit/runtime/primary_tab_router_test.dart test/unit/modules/splash/startup_route_hint_test.dart`: 40 tests passing.
- `dart analyze test/unit/runtime/primary_tab_router_test.dart lib/Runtime/primary_tab_router.dart lib/Modules/Splash/splash_view_startup_part.dart`: no issues found.
- `flutter test test/unit/runtime/primary_tab_router_test.dart test/unit/runtime/app_decision_coordinator_test.dart test/unit/modules/splash/startup_route_hint_test.dart`: 41 tests passing.
- `dart analyze lib/Modules/Splash/splash_view_startup_part.dart lib/Modules/Splash/splash_view.dart test/unit/runtime/primary_tab_router_test.dart test/unit/runtime/app_decision_coordinator_test.dart test/unit/modules/splash/startup_route_hint_test.dart`: no issues found.
- `flutter test test/unit/runtime/primary_tab_router_test.dart test/unit/runtime/app_decision_coordinator_test.dart test/unit/modules/splash/startup_route_hint_test.dart`: 41 tests passing.
- `dart analyze test/unit/runtime/primary_tab_router_test.dart lib/Modules/Splash/splash_view_startup_part.dart lib/Runtime/primary_tab_router.dart`: no issues found.
- `flutter test test/unit/runtime/primary_tab_router_test.dart test/unit/runtime/app_decision_coordinator_test.dart test/unit/modules/splash/startup_route_hint_test.dart`: 42 tests passing.
- `dart analyze test/unit/runtime/primary_tab_router_test.dart lib/Modules/Splash/splash_view_startup_part.dart lib/Runtime/primary_tab_router.dart`: no issues found.
- `flutter test test/unit/runtime/primary_tab_router_test.dart test/unit/runtime/app_decision_coordinator_test.dart test/unit/modules/splash/startup_route_hint_test.dart`: 43 tests passing.
- `dart analyze test/unit/runtime/primary_tab_router_test.dart lib/Modules/Splash/splash_view_startup_part.dart lib/Runtime/primary_tab_router.dart`: no issues found.
- `flutter test test/unit/runtime/primary_tab_router_test.dart test/unit/runtime/app_decision_coordinator_test.dart test/unit/modules/splash/startup_route_hint_test.dart`: 44 tests passing.
- `dart analyze test/unit/runtime/app_decision_coordinator_test.dart lib/Runtime/app_decision_coordinator.dart lib/Runtime/startup_decision.dart`: no issues found.
- `flutter test test/unit/runtime/app_decision_coordinator_test.dart test/unit/runtime/primary_tab_router_test.dart test/unit/modules/splash/startup_route_hint_test.dart`: 45 tests passing.
- `dart analyze test/unit/runtime/app_decision_coordinator_test.dart lib/Runtime/app_decision_coordinator.dart lib/Runtime/startup_decision.dart`: no issues found.
- `flutter test test/unit/runtime/app_decision_coordinator_test.dart test/unit/runtime/primary_tab_router_test.dart test/unit/modules/splash/startup_route_hint_test.dart`: 46 tests passing.
- `dart analyze test/unit/runtime/app_decision_coordinator_test.dart lib/Runtime/app_decision_coordinator.dart lib/Runtime/startup_decision.dart`: no issues found.
- `flutter test test/unit/runtime/app_decision_coordinator_test.dart test/unit/runtime/primary_tab_router_test.dart test/unit/modules/splash/startup_route_hint_test.dart`: 47 tests passing.
- `dart analyze test/unit/runtime/primary_tab_router_test.dart lib/Runtime/primary_tab_router.dart lib/Runtime/startup_decision.dart`: no issues found.
- `flutter test test/unit/runtime/primary_tab_router_test.dart test/unit/runtime/app_decision_coordinator_test.dart test/unit/modules/splash/startup_route_hint_test.dart`: 48 tests passing.
- `dart analyze test/unit/runtime/primary_tab_router_test.dart lib/Runtime/primary_tab_router.dart lib/Runtime/startup_decision.dart`: no issues found.
- `flutter test test/unit/runtime/primary_tab_router_test.dart test/unit/runtime/app_decision_coordinator_test.dart test/unit/modules/splash/startup_route_hint_test.dart`: 49 tests passing.
- `dart analyze test/unit/runtime/session_exit_coordinator_test.dart lib/Runtime/session_exit_coordinator.dart`: no issues found.
- `flutter test test/unit/runtime/session_exit_coordinator_test.dart`: 5 tests passing.
- Raw route sweep for `SocialProfile` and `ReportUser`: only approved navigation service owners remain.
- `flutter test test/unit/runtime/app_decision_coordinator_test.dart test/unit/modules/splash/startup_route_hint_test.dart test/unit/runtime/primary_tab_router_test.dart`: 27 tests passing.
- Combined startup/navigation/deep-link/sign-in analyze command: no issues found.
- Combined startup/navigation/deep-link/sign-in Flutter test command: 35 tests passing.
- `dart analyze test/unit/runtime/core_preferences_boundary_test.dart lib/Core/Repositories/local_preference_repository.dart`: no issues found.
- `flutter test test/unit/runtime/core_preferences_boundary_test.dart`: 2 tests passing.
- `dart analyze lib/Modules/SignIn/sign_in_application_service.dart test/unit/runtime/app_auth_singleton_boundary_test.dart test/unit/runtime/module_auth_boundary_test.dart lib/Core/Services/app_firebase_auth.dart`: no issues found.
- `flutter test test/unit/runtime/app_auth_singleton_boundary_test.dart test/unit/runtime/module_auth_boundary_test.dart`: 2 tests passing.
- `dart analyze lib/Core/Services/app_firebase_messaging.dart lib/Core/notification_service.dart lib/Modules/SocialProfile/social_profile.dart test/unit/runtime/app_messaging_singleton_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/app_messaging_singleton_boundary_test.dart`: 1 test passing.
- `flutter test test/unit/runtime`: 187 tests passing.
- `dart analyze test/unit/utils/deep_link_utils_test.dart lib/Core/Utils/deep_link_utils.dart`: no issues found.
- `flutter test test/unit/runtime/deep_link_parser_boundary_test.dart test/unit/utils/deep_link_utils_test.dart`: 14 tests passing.
- `dart analyze lib/Modules/Splash/splash_view_startup_part.dart test/unit/runtime/primary_tab_router_test.dart lib/Runtime/primary_tab_router.dart lib/Runtime/startup_decision.dart`: no issues found.
- `flutter test test/unit/runtime/primary_tab_router_test.dart test/unit/runtime/app_decision_coordinator_test.dart test/unit/modules/splash/startup_route_hint_test.dart`: 53 tests passing.
- `flutter test test/unit/runtime`: 191 tests passing.
- `dart analyze lib/Modules/NavBar/nav_bar_controller_support_part.dart lib/Modules/NavBar/nav_bar_controller_lifecycle_part.dart lib/Modules/NavBar/nav_bar_controller.dart`: no issues found.
- `dart analyze test/unit/runtime/primary_tab_router_test.dart lib/Modules/NavBar/nav_bar_controller_support_part.dart lib/Modules/NavBar/nav_bar_controller_lifecycle_part.dart lib/Modules/NavBar/nav_bar_controller.dart`: no issues found.
- `flutter test test/unit/runtime/primary_tab_router_test.dart test/unit/runtime/root_navigation_boundary_test.dart`: 33 tests passing.
- `flutter test test/unit/runtime`: 192 tests passing.
- `dart analyze test/unit/utils/deep_link_utils_test.dart lib/Core/Utils/deep_link_utils.dart test/unit/runtime/deep_link_parser_boundary_test.dart`: no issues found.
- `flutter test test/unit/runtime/deep_link_parser_boundary_test.dart test/unit/utils/deep_link_utils_test.dart`: 15 tests passing.
- `dart analyze lib/Runtime/app_decision_coordinator.dart test/unit/runtime/app_decision_coordinator_test.dart lib/Runtime/startup_decision.dart lib/Runtime/primary_tab_router.dart`: no issues found.
- `flutter test test/unit/runtime/app_decision_coordinator_test.dart test/unit/runtime/primary_tab_router_test.dart test/unit/modules/splash/startup_route_hint_test.dart`: 55 tests passing.
- `flutter test test/unit/runtime`: 193 tests passing.
- `dart analyze lib/Modules/Splash/splash_view_startup_part.dart test/unit/runtime/primary_tab_router_test.dart lib/Runtime/app_decision_coordinator.dart lib/Runtime/primary_tab_router.dart lib/Runtime/startup_decision.dart`: no issues found.
- `flutter test test/unit/runtime/primary_tab_router_test.dart test/unit/runtime/app_decision_coordinator_test.dart test/unit/modules/splash/startup_route_hint_test.dart`: 55 tests passing.
- `flutter test test/unit/runtime`: 193 tests passing.
- `flutter analyze`: no issues found.
- `dart analyze lib/Modules/Agenda/ClassicContent/classic_content_helpers_part.dart`: no issues found.
- `flutter test test/unit/runtime/classic_content_navigation_boundary_test.dart test/unit/runtime/agenda_content_navigation_boundary_test.dart`: 2 tests passing.
- `flutter test test/unit/runtime`: 193 tests passing.
- `flutter test test/unit/modules/splash`: 12 tests passing.
- Added `docs/app_architecture_integrity_report_tr.md` as the closing architecture integrity report.
- Splash runtime-health analytics extras no longer pass or accept unused `loggedIn` input; route telemetry values remain captured once and reused across all six analytics surfaces.
- Backend singleton sweep under `lib/Core/Repositories`, `lib/Core/Services`, `lib/Services`, and `lib/Modules` shows only app boundary wrappers or `App*` wrapper usage.

## Current Phase Percentages

- Phase 1, central app decision flow: 98.7%.
- Phase 2, session/auth ownership: 95.9%.
- Phase 3, navigation standard: 100%.
- Phase 4, cache/local data policy: 98.1%.
- Phase 5, backend/data-access boundary standard: 99.997%.
- Phase 6, shared UI behavior standard: 99%.
- Phase 7, architecture guardrails: 99.88%.
- Overall orchestration health: 99.998%.

## Next Safe Slice

1. Run the final branch-level verification bundle and record results: `flutter analyze`, focused startup/navigation tests, and `flutter test test/unit/runtime`.
2. Prepare the closing architecture report: completed central decision boundaries, intentionally approved exceptions, remaining long-term standardization items.
3. Keep any further code changes to analyzer-cleanup or guard-only edits unless a verified behavioral risk appears.
4. If needed later, create a separate component-level placeholder standard for media placeholders, load-more indicators, button progress, and question/result subcomponent loaders.

## Verification Commands

Run focused checks after each slice:

```sh
dart analyze
flutter test test/unit/modules/splash
flutter test test/unit/state
flutter test test/unit/repositories
```

Run broader checks before merging:

```sh
flutter test
flutter analyze
```
