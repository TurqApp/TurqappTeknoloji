part of 'tutoring_application_review.dart';

extension _TutoringApplicationReviewActionsPart
    on _TutoringApplicationReviewState {
  void _openProfile(String userId) {
    Get.to(() => SocialProfile(userID: userId));
  }

  Widget _buildFallbackAvatar() {
    return SvgPicture.asset(kDefaultAvatarAsset, fit: BoxFit.cover);
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case 'reviewing':
        bgColor = const Color(0xFFEAF2FF);
        textColor = const Color(0xFF2F6FED);
        break;
      case 'accepted':
        bgColor = const Color(0xFFEAF7EE);
        textColor = const Color(0xFF2D8A45);
        break;
      case 'rejected':
        bgColor = const Color(0xFFFCECEC);
        textColor = const Color(0xFFC64242);
        break;
      default:
        bgColor = const Color(0xFFFCF4E4);
        textColor = const Color(0xFFB57911);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        TutoringApplicationModel.statusText(status),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontFamily: 'MontserratMedium',
        ),
      ),
    );
  }

  String _formatDate(int timestamp) {
    if (timestamp == 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
