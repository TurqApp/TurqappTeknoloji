part of 'test_entry.dart';

extension _TestEntryResultPart on _TestEntryState {
  Widget _buildResultCard() {
    final model = controller.model.value!;
    return SizedBox(
      height: 75,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            height: 75,
            width: 75,
            child: AspectRatio(
              aspectRatio: 1,
              child: model.img.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: model.img,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Center(child: CupertinoActivityIndicator()),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.broken_image),
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        color: Colors.indigo,
                        strokeWidth: 0.5,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'tests.type_test'.trParams({
                    'type': controller.localizedTestType(model.testTuru),
                  }),
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: 'MontserratBold',
                  ),
                ),
                Text(
                  model.aciklama,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: 'MontserratMedium',
                  ),
                ),
                Text(
                  controller.localizedLessons(model.dersler),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 15,
                    fontFamily: 'MontserratMedium',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
