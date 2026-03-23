part of 'deneme_gecmis_sonuc_content.dart';

extension DenemeGecmisSonucContentBodyPart on DenemeGecmisSonucContent {
  Widget _buildResultCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          children: [
            _buildCoverImage(),
            const SizedBox(width: 12),
            Expanded(child: _buildResultTexts()),
            const SizedBox(width: 12),
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.pink,
                  size: 15,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(4)),
      child: SizedBox(
        width: 78,
        height: 78,
        child: CachedNetworkImage(
          imageUrl: model.cover,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              const Center(child: CupertinoActivityIndicator()),
          errorWidget: (context, url, error) => const Icon(
            Icons.image_not_supported,
            size: 50,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildResultTexts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          model.sinavAdi,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontFamily: "MontserratBold",
          ),
        ),
        Text(
          model.sinavTuru,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.pink,
            fontSize: 15,
            fontFamily: "MontserratMedium",
          ),
        ),
        Text(
          'tests.description_test'
              .trParams({'description': model.sinavAciklama}),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontFamily: "MontserratMedium",
          ),
        ),
      ],
    );
  }
}
