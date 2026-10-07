class AdminStats {
  final int totalUsers;
  final int totalSubscriptions;
  final int totalCards;
  final int totalPackages;

  const AdminStats({
    this.totalUsers = 0,
    this.totalSubscriptions = 0,
    this.totalCards = 0,
    this.totalPackages = 0,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: json['totalUsers'] as int? ?? 0,
      totalSubscriptions: json['totalSubscriptions'] as int? ?? 0,
      totalCards: json['totalCards'] as int? ?? 0,
      totalPackages: json['totalPackages'] as int? ?? 0,
    );
  }
}
