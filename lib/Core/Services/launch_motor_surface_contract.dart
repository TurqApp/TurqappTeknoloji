class LaunchMotorSurfaceContract {
  const LaunchMotorSurfaceContract({
    required this.window,
    required this.bandMinutes,
    required this.subsliceMs,
    required this.minuteSets,
  });

  final Duration window;
  final int bandMinutes;
  final int subsliceMs;
  final List<List<int>> minuteSets;
}

const LaunchMotorSurfaceContract feedLaunchMotorContract =
    LaunchMotorSurfaceContract(
  window: Duration(days: 7),
  bandMinutes: 5,
  subsliceMs: 200,
  minuteSets: <List<int>>[
    <int>[0, 13, 26, 39, 52],
    <int>[1, 14, 27, 40, 53],
    <int>[2, 15, 28, 41, 54],
    <int>[3, 16, 29, 36, 49],
    <int>[4, 12, 30, 37, 50],
    <int>[5, 18, 25, 44, 51],
    <int>[6, 19, 32, 45, 58],
    <int>[7, 20, 33, 46, 59],
    <int>[8, 21, 34, 47, 48],
    <int>[9, 22, 35, 42, 55],
    <int>[10, 23, 31, 43, 56],
    <int>[11, 17, 24, 38, 57],
  ],
);

const LaunchMotorSurfaceContract shortLaunchMotorContract =
    LaunchMotorSurfaceContract(
  window: Duration(days: 7),
  bandMinutes: 5,
  subsliceMs: 200,
  minuteSets: <List<int>>[
    <int>[4, 12, 30, 37, 50],
    <int>[5, 18, 25, 44, 51],
    <int>[0, 13, 26, 39, 52],
    <int>[1, 14, 27, 40, 53],
    <int>[2, 15, 28, 41, 54],
    <int>[9, 22, 29, 36, 55],
    <int>[10, 23, 31, 43, 56],
    <int>[11, 17, 24, 38, 57],
    <int>[6, 19, 32, 45, 58],
    <int>[7, 20, 33, 46, 59],
    <int>[8, 21, 34, 47, 48],
    <int>[3, 16, 35, 42, 49],
  ],
);

const LaunchMotorSurfaceContract shortQuotaLaunchMotorContract =
    LaunchMotorSurfaceContract(
  window: Duration(days: 7),
  bandMinutes: 10,
  subsliceMs: 200,
  minuteSets: <List<int>>[
    <int>[1, 7, 14, 20, 27, 33, 40, 46, 53, 59],
    <int>[2, 8, 15, 21, 28, 34, 41, 47, 48, 54],
    <int>[3, 9, 16, 22, 29, 35, 36, 42, 49, 55],
    <int>[4, 10, 12, 23, 30, 31, 37, 43, 50, 56],
    <int>[5, 11, 17, 18, 24, 25, 38, 44, 51, 57],
    <int>[0, 6, 13, 19, 26, 32, 39, 45, 52, 58],
  ],
);
