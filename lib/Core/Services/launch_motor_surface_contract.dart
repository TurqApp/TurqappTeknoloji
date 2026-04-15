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
    <int>[0, 19, 26, 45, 52],
    <int>[1, 14, 33, 40, 59],
    <int>[2, 21, 28, 47, 54],
    <int>[3, 16, 35, 42, 49],
    <int>[4, 23, 30, 37, 56],
    <int>[5, 18, 25, 44, 51],
    <int>[6, 13, 32, 39, 58],
    <int>[7, 20, 27, 46, 53],
    <int>[8, 15, 34, 41, 48],
    <int>[9, 22, 29, 36, 55],
    <int>[10, 12, 31, 43, 50],
    <int>[11, 17, 24, 38, 57],
  ],
);

const LaunchMotorSurfaceContract shortLaunchMotorContract =
    LaunchMotorSurfaceContract(
  window: Duration(days: 7),
  bandMinutes: 5,
  subsliceMs: 200,
  minuteSets: <List<int>>[
    <int>[4, 23, 30, 37, 56],
    <int>[5, 18, 25, 44, 51],
    <int>[6, 13, 32, 39, 58],
    <int>[7, 20, 27, 46, 53],
    <int>[8, 15, 34, 41, 48],
    <int>[9, 22, 29, 36, 55],
    <int>[10, 12, 31, 43, 50],
    <int>[11, 17, 24, 38, 57],
    <int>[0, 19, 26, 45, 52],
    <int>[1, 14, 33, 40, 59],
    <int>[2, 21, 28, 47, 54],
    <int>[3, 16, 35, 42, 49],
  ],
);

const LaunchMotorSurfaceContract shortQuotaLaunchMotorContract =
    LaunchMotorSurfaceContract(
  window: Duration(days: 7),
  bandMinutes: 5,
  subsliceMs: 200,
  minuteSets: <List<int>>[
    <int>[1, 14, 33, 40, 59],
    <int>[2, 21, 28, 47, 54],
    <int>[3, 16, 35, 42, 49],
    <int>[4, 23, 30, 37, 56],
    <int>[5, 18, 25, 44, 51],
    <int>[6, 13, 32, 39, 58],
    <int>[7, 20, 27, 46, 53],
    <int>[8, 15, 34, 41, 48],
    <int>[9, 22, 29, 36, 55],
    <int>[10, 12, 31, 43, 50],
    <int>[11, 17, 24, 38, 57],
    <int>[0, 19, 26, 45, 52],
  ],
);
