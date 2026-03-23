part of 'profile_view.dart';

extension _ProfileViewMetricsPart on _ProfileViewState {
  Widget textInfoBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$_myDisplayFirstName $_myDisplayLastName'.trim(),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratBold",
                ),
              ),
              4.pw,
              if (!_hasVerifiedRozet)
                GestureDetector(
                  onTap: () {
                    _suspendProfileFeedForRoute();
                    Get.to(() => BecomeVerifiedAccount())?.then((_) {
                      _resumeProfileFeedAfterRoute();
                    });
                  },
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.checkmark_seal_fill,
                        color: Colors.blueAccent,
                        size: 15,
                      ),
                      4.pw,
                      Text(
                        "settings.become_verified".tr,
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (_myDisplayMeslek.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                _myDisplayMeslek,
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),
          if (_myDisplayBio.isNotEmpty)
            GestureDetector(
              onTap: () {
                _suspendProfileFeedForRoute();
                Get.to(() => BiographyMaker())?.then((_) {
                  _resumeProfileFeedAfterRoute();
                  _refreshUserState();
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  _myDisplayBio,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: "Montserrat",
                  ),
                ),
              ),
            ),
          if (_myDisplayAdres.isNotEmpty)
            GestureDetector(
              onTap: () {
                showMapsSheetWithAdres(_myDisplayAdres);
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  _myDisplayAdres,
                  style: const TextStyle(
                    color: Colors.indigo,
                    fontSize: 12,
                    fontFamily: "Montserrat",
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
