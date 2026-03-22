part of 'personalized_controller.dart';

extension PersonalizedControllerScorePart on PersonalizedController {
  void _processScholarshipsData(List<Map<String, dynamic>> docs) {
    try {
      final allItems = <IndividualScholarshipsModel>[];
      for (final doc in docs) {
        final model = IndividualScholarshipsModel.fromJson(doc);
        allItems.add(model);
        final docId = (doc['docId'] ?? '').toString().trim();
        if (docId.isNotEmpty) {
          docIdByTimestamp[model.timeStamp] = docId;
        }
      }

      final scored = allItems
          .map((item) => MapEntry(item, _scoreScholarship(item)))
          .where((e) => e.value > 0)
          .toList();

      scored.sort((a, b) => b.value.compareTo(a.value));
      final filtered = scored.map((e) => e.key).toList();

      if (filtered.isEmpty && allItems.isNotEmpty) {
        list.value = allItems;
        usedFallback.value = true;
      } else {
        list.value = filtered;
        usedFallback.value = false;
      }

      _saveCachedList(allItems);
      count.value = list.length;
      isLoading.value = false;
    } catch (_) {
      isLoading.value = false;
    }
  }

  int _scoreScholarship(IndividualScholarshipsModel item) {
    int score = 0;
    final locationCity = locationSehir.value.isNotEmpty
        ? locationSehir.value
        : ikametSehir.value;
    final hasLocation = locationCity.trim().isNotEmpty;
    final hasSchoolCity = hasSchoolInfo.value && schoolCity.value.isNotEmpty;

    if (hasLocation && _matchesTargetCity(item, locationCity)) {
      score += 3;
    }
    if (hasSchoolCity && _matchesTargetCity(item, schoolCity.value)) {
      score += 2;
    }
    if (_matchesTargetAudience(item)) {
      score += 1;
    }

    return score;
  }

  bool _matchesTargetCity(IndividualScholarshipsModel item, String city) {
    final normalizedTarget = normalizeCityText(city);

    bool cityMatch(List<String> list) {
      for (final raw in list) {
        final normalized = normalizeCityText(raw);
        if (normalized == normalizedTarget) return true;
        if (normalized.contains(normalizedTarget) ||
            normalizedTarget.contains(normalized)) {
          return true;
        }
      }
      return false;
    }

    return cityMatch(item.sehirler) || cityMatch(item.liseOrtaOkulSehirler);
  }

  bool _matchesTargetAudience(IndividualScholarshipsModel item) {
    final level = educationLevel.value.trim();
    if (level.isEmpty) return false;

    final normLevel = normalizeCityText(level);
    final hedef = normalizeCityText(item.hedefKitle);
    if (hedef.contains(normLevel) || normLevel.contains(hedef)) return true;

    final egitim = normalizeCityText(item.egitimKitlesi);
    if (egitim.contains(normLevel) || normLevel.contains(egitim)) return true;

    for (final alt in item.altEgitimKitlesi) {
      final n = normalizeCityText(alt);
      if (n.contains(normLevel) || normLevel.contains(n)) return true;
    }

    return false;
  }
}
