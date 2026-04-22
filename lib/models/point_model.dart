class UserPoint {
  final int currentPoints;
  final String rankName;
  final int nextTarget;

  UserPoint({required this.currentPoints, required this.rankName, required this.nextTarget});

  factory UserPoint.fromJson(Map<String, dynamic> json) {
    return UserPoint(
      currentPoints: json['current_points'] ?? 0,
      rankName: json['rank_name'] ?? 'Guru',
      nextTarget: json['next_target'] ?? 1000,
    );
  }
}