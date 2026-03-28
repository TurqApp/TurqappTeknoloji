# F3-004 Feed Playback Hot Cluster Secici Sadelestirme

Tarih: `2026-03-28`

## Kapsam

Bu is, cache tarafindaki canli calismaya girmeden Feed/Playback sicak kumesinde dusuk riskli mekanik giris parcalarini sadeleştirir.

Secilen dosyalar:

- `lib/Modules/Agenda/agenda_controller.dart`
- `lib/Modules/Short/short_controller.dart`
- `lib/Modules/Agenda/FloodListing/flood_listing_controller.dart`
- `lib/Modules/Agenda/TopTags/top_tags_contoller_library.dart`
- `lib/Modules/Story/StoryHighlights/story_highlights_controller_library.dart`

## Yapilan sadeleştirme

- `AgendaController` icindeki `base`, `class` ve `facade` mikro parcalari ana dosyaya tasindi
- `ShortController` icindeki `base`, `class` ve `facade` mikro parcalari ana dosyaya tasindi
- `FloodListingController` icindeki `class` ve `facade` mikro parcalari ana dosyaya tasindi
- `TopTagsController` icindeki `base` ve `facade` mikro parcalari ana dosyaya tasindi
- `StoryHighlightsController` icindeki `base`, `class` ve `facade` mikro parcalari ana dosyaya tasindi

## Sayisal etki

- Secilen mekanik giris dosyasi yuzeyi: `18 -> 5`
- Kaldirilan mikro part sayisi: `13`

Kaldirilan dosyalar:

- `lib/Modules/Agenda/agenda_controller_base_part.dart`
- `lib/Modules/Agenda/agenda_controller_class_part.dart`
- `lib/Modules/Agenda/agenda_controller_facade_part.dart`
- `lib/Modules/Short/short_controller_base_part.dart`
- `lib/Modules/Short/short_controller_class_part.dart`
- `lib/Modules/Short/short_controller_facade_part.dart`
- `lib/Modules/Agenda/FloodListing/flood_listing_controller_class_part.dart`
- `lib/Modules/Agenda/FloodListing/flood_listing_controller_facade_part.dart`
- `lib/Modules/Agenda/TopTags/top_tags_contoller_base_part.dart`
- `lib/Modules/Agenda/TopTags/top_tags_contoller_facade_part.dart`
- `lib/Modules/Story/StoryHighlights/story_highlights_controller_base_part.dart`
- `lib/Modules/Story/StoryHighlights/story_highlights_controller_class_part.dart`
- `lib/Modules/Story/StoryHighlights/story_highlights_controller_facade_part.dart`

## Neler duzeldi

- Feed/Playback sicak kumesindeki mekanik controller girisleri daha az dosyaya dagildi
- `Agenda`, `Short`, `FloodListing`, `TopTags` ve `StoryHighlights` tarafinda ayni davranisi okumak icin gereksiz dosya gecisi azaldi
- Davranis part'lari yerinde birakildigi icin riskli buyuk refactor acilmadan yapisal sadeleştirme saglandi

## Dogrulama

- Hedefli `dart analyze`
- `git diff --check`
- docs single-source guard
- architecture guard

## Bilincli olarak dokunulmayan alanlar

- `CacheFirst` ve snapshot repository tarafindaki canli cache calismasi
- Feed/Playback davranis part'lari
- Daha genis playback/runtime cluster refactor'u
