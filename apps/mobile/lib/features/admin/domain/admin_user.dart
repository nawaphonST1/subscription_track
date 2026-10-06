class AdminUser {
  final String id;
  final String email;
  final String? name;
  final double monthlyIncome;
  final int subscriptionsCount;
  final int cardsCount;
  final DateTime createdAt;

  const AdminUser({
    required this.id,
    required this.email,
    this.name,
    this.monthlyIncome = 0.0,
    this.subscriptionsCount = 0,
    this.cardsCount = 0,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String?,
      monthlyIncome: (json['monthlyIncome'] as num?)?.toDouble() ?? 0.0,
      subscriptionsCount: json['subscriptionsCount'] as int? ?? 0,
      cardsCount: json['cardsCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
