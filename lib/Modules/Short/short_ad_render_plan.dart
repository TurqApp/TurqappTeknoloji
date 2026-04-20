import 'package:turqappv2/Models/posts_model.dart';

const int kShortAdInsertionFrequency = 5;

class ShortRenderEntry {
  const ShortRenderEntry.post({
    required this.post,
    required this.organicIndex,
    required this.renderIndex,
  }) : adOrdinal = null;

  const ShortRenderEntry.ad({
    required this.adOrdinal,
    required this.renderIndex,
  })  : post = null,
        organicIndex = null;

  final PostsModel? post;
  final int? organicIndex;
  final int? adOrdinal;
  final int renderIndex;

  bool get isAd => post == null;
}

class ShortAdRenderPlan {
  const ShortAdRenderPlan.empty() : entries = const <ShortRenderEntry>[];

  const ShortAdRenderPlan._(this.entries);

  final List<ShortRenderEntry> entries;

  int get length => entries.length;

  int renderIndexForOrganicIndex(int organicIndex) {
    if (organicIndex <= 0) return 0;
    for (final entry in entries) {
      if (entry.organicIndex == organicIndex) {
        return entry.renderIndex;
      }
    }
    return organicIndex.clamp(0, entries.isEmpty ? 0 : entries.length - 1);
  }

  int? organicIndexForRenderIndex(int renderIndex) {
    if (renderIndex < 0 || renderIndex >= entries.length) {
      return null;
    }
    return entries[renderIndex].organicIndex;
  }

  int clampRenderIndex(int renderIndex) {
    if (entries.isEmpty) return 0;
    return renderIndex.clamp(0, entries.length - 1);
  }
}

ShortAdRenderPlan buildShortAdRenderPlan(
  List<PostsModel> posts, {
  required bool adReady,
  int insertionFrequency = kShortAdInsertionFrequency,
}) {
  if (posts.isEmpty) {
    return const ShortAdRenderPlan._(<ShortRenderEntry>[]);
  }

  final entries = <ShortRenderEntry>[];
  var adOrdinal = 0;
  for (var i = 0; i < posts.length; i++) {
    entries.add(
      ShortRenderEntry.post(
        post: posts[i],
        organicIndex: i,
        renderIndex: entries.length,
      ),
    );
    final reachedInsertionBoundary =
        adReady && insertionFrequency > 0 && (i + 1) % insertionFrequency == 0;
    final hasMoreOrganicContent = i < posts.length - 1;
    if (reachedInsertionBoundary && hasMoreOrganicContent) {
      adOrdinal++;
      entries.add(
        ShortRenderEntry.ad(
          adOrdinal: adOrdinal,
          renderIndex: entries.length,
        ),
      );
    }
  }

  return ShortAdRenderPlan._(List<ShortRenderEntry>.unmodifiable(entries));
}
