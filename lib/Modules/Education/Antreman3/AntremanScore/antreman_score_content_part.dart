part of 'antreman_score.dart';

extension AntremanScoreContentPart on _AntremanScoreState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                BackButtons(
                  text: 'training.monthly_scoreboard'
                      .trParams({'month': controller.monthName}),
                ),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return Center(child: CupertinoActivityIndicator());
                    }
                    if (controller.leaderboard.isEmpty) {
                      return _buildEmptyState(context);
                    }
                    return _buildLeaderboardList(context);
                  }),
                ),
              ],
            ),
            ScrollTotopButton(
              scrollController: _scrollController,
              visibilityThreshold: 350,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: Colors.black,
      onRefresh: () => controller.fetchLeaderboard(),
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height:
                (MediaQuery.of(context).size.height * 0.22).clamp(130.0, 180.0),
          ),
          Center(child: Text('training.leaderboard_empty'.tr)),
          const SizedBox(height: 8),
          Center(
            child: Text('training.leaderboard_empty_body'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(BuildContext context) {
    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: Colors.black,
      onRefresh: () => controller.fetchLeaderboard(),
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildPodiumSection(context),
          const SizedBox(height: 2),
          ...controller.leaderboard.skip(3).map((user) {
            return Column(
              children: [
                _buildUserItem(
                  context,
                  user,
                  user['rank'],
                  isCurrentUser: user['userID'] == currentUserID,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPodiumSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          if (controller.leaderboard.isNotEmpty)
            _buildPodiumItem(
              context,
              controller.leaderboard[0],
              'assets/images/gold.webp',
              124,
              76,
              15,
            ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (controller.leaderboard.length >= 2) ...[
                _buildPodiumItem(
                  context,
                  controller.leaderboard[1],
                  'assets/images/silver.webp',
                  124,
                  76,
                  15,
                ),
                const SizedBox(width: 28),
              ],
              if (controller.leaderboard.length >= 3)
                _buildPodiumItem(
                  context,
                  controller.leaderboard[2],
                  'assets/images/bronz.webp',
                  124,
                  76,
                  15,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
