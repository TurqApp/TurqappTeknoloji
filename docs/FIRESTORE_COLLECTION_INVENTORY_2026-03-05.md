# Firestore Collection Inventory (App + Functions)

Date: 2026-03-05
Scope: `/lib` + `/functions/src`
Method: static code scan (`collection(...)`, `doc(...)`, `collectionGroup(...)`)

## 1) Top Collections by Usage Count (Code References)
- `users`: 354
- `Posts`: 168
- `conversations`: 44
- `stories`: 37
- `educators`: 32
- `practiceExams`: 30
- `TakipEdilenler`: 29
- `Testler`: 28
- `Yorumlar`: 21
- `Yanitlar`: 21
- `questionBank`: 20
- `books`: 19
- `Takipciler`: 19
- `scholarships`: 18
- `messages`: 17
- `likes`: 17
- `notifications`: 16

Note: counts are reference counts in source files, not runtime query counts.

## 2) `users/{uid}` Current Real Structure (Observed)
Hot fields actively used in code:
- identity/profile: `nickname`, `firstName`, `lastName`, `displayName`, `username`, `pfImage`, `photoURL`, `avatarUrl`, `profileImageUrl`
- privacy/status: `gizliHesap`, `deletedAccount`, `accountStatus`
- counters: `takipciSayisi`, `takipEdilenSayisi`, `gonderSayisi`, `followerCount`, `followingCount`, `postCount`
- metadata: `createdDate`, `role`, `admin`

Subcollections actively used:
- `Takipciler`, `TakipEdilenler`, `notifications`
- `liked_posts`, `saved_posts`, `commented_posts`, `reshared_posts`
- `qProgress`, `qAnswers`, `qSaved`, `qViews`
- `DeletedStories`, `myTutoringApplications`, `examResults`, `bookletResults`, `Stats`

## 3) Scholarship/Burs Chain (High Impact Area)
Primary collections in burs flow:
- `scholarships` (listing/create/update/apply/like/bookmark/share)
- `users/{uid}` profile fields used to enrich scholarship cards

Main burs write paths:
- Create: `CreateScholarshipController` -> `scholarships.add(...)` then merge counters
- Edit: `CreateScholarshipController` -> `scholarships/{id}.update(...)`
- Like/Bookmark: `scholarships/{id}.update(...)` with arrays/counters
- Apply: `ScholarshipDetail/Applications` controllers -> scholarship application update + user-level links

## 4) Risk Summary (Schema Migration)
- User schema is currently mixed (legacy + new names).
- Main break risk is not collection absence; it is field-name mismatch during reads/writes.
- Scholarship flows depend on user profile fields for display and filtering.

## 5) Migration Safety Rule
During cutover, keep collection paths unchanged first.
Only standardize user field names and service/model bindings in controlled phases.

