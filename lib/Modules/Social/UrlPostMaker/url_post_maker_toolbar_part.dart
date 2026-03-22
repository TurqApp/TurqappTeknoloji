part of 'url_post_maker.dart';

extension UrlPostMakerToolbarPart on _UrlPostMakerState {
  Widget toolbar() {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  IconButton(
                    onPressed: controller.goToLocationMap,
                    icon: const Icon(
                      CupertinoIcons.map_pin_ellipse,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    onPressed: controller.showCommentOptions,
                    icon: const Icon(
                      CupertinoIcons.ellipses_bubble,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
