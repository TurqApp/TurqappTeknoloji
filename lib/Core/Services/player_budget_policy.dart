enum PlayerSurfaceKind {
  shortFullscreen,
  feedInline,
  exploreInline,
}

class PlayerBudgetPolicy {
  const PlayerBudgetPolicy({
    required this.maxActivePlayers,
    required this.maxWarmPlayers,
    required this.maxPreparedNeighbors,
  });

  final int maxActivePlayers;
  final int maxWarmPlayers;
  final int maxPreparedNeighbors;

  static PlayerBudgetPolicy forSurface(
    PlayerSurfaceKind surface, {
    bool lowMemoryDevice = false,
  }) {
    switch (surface) {
      case PlayerSurfaceKind.shortFullscreen:
        if (lowMemoryDevice) {
          return const PlayerBudgetPolicy(
            maxActivePlayers: 1,
            maxWarmPlayers: 1,
            maxPreparedNeighbors: 1,
          );
        }
        return const PlayerBudgetPolicy(
          maxActivePlayers: 1,
          maxWarmPlayers: 2,
          maxPreparedNeighbors: 2,
        );
      case PlayerSurfaceKind.feedInline:
        return const PlayerBudgetPolicy(
          maxActivePlayers: 1,
          maxWarmPlayers: 1,
          maxPreparedNeighbors: 1,
        );
      case PlayerSurfaceKind.exploreInline:
        return const PlayerBudgetPolicy(
          maxActivePlayers: 1,
          maxWarmPlayers: 0,
          maxPreparedNeighbors: 1,
        );
    }
  }
}
