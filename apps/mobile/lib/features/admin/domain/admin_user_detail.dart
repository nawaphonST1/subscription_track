class AdminUserCardDetail {
  final String id;
  final String? nickname;
  final String? brand;
  final String? last4;
  final String? bankName;
  final double balance;
  final String currency;
  final bool isActive;

  const AdminUserCardDetail({
    required this.id,
    this.nickname,
    this.brand,
    this.last4,
    this.bankName,
    this.balance = 0.0,
    this.currency = 'THB',
    this.isActive = true,
  });

  factory AdminUserCardDetail.fromJson(Map<String, dynamic> json) {
    return AdminUserCardDetail(
      id: json['id'] as String? ?? '',
      nickname: json['nickname'] as String?,
      brand: json['brand'] as String?,
      last4: json['last4'] as String?,
      bankName: json['bankName'] as String?,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'THB',
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class AdminUserSubscriptionDetail {
  final String id;
  final String name;
  final String category;
  final double price;
  final String billingCycle;
  final DateTime? startDate;
  final DateTime? nextRenewalDate;
  final String status;
  final String usageStatus;
  final String? brandColor;
  final String? notes;
  final Map<String, dynamic>? paymentCard;

  const AdminUserSubscriptionDetail({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.billingCycle,
    this.startDate,
    this.nextRenewalDate,
    required this.status,
    this.usageStatus = 'FREQUENT',
    this.brandColor,
    this.notes,
    this.paymentCard,
  });

  factory AdminUserSubscriptionDetail.fromJson(Map<String, dynamic> json) {
    return AdminUserSubscriptionDetail(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'Other',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      billingCycle: json['billingCycle'] as String? ?? 'MONTHLY',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
      nextRenewalDate: json['nextRenewalDate'] != null
          ? DateTime.tryParse(json['nextRenewalDate'].toString())
          : null,
      status: json['status'] as String? ?? 'ACTIVE',
      usageStatus: json['usageStatus'] as String? ?? 'FREQUENT',
      brandColor: json['brandColor'] as String?,
      notes: json['notes'] as String?,
      paymentCard: json['paymentCard'] as Map<String, dynamic>?,
    );
  }
}

class AdminUserDetail {
  final String id;
  final String email;
  final String? name;
  final String role;
  final double monthlyIncome;
  final DateTime createdAt;
  final List<AdminUserSubscriptionDetail> subscriptions;
  final List<AdminUserCardDetail> paymentCards;

  const AdminUserDetail({
    required this.id,
    required this.email,
    this.name,
    this.role = 'USER',
    this.monthlyIncome = 0.0,
    required this.createdAt,
    this.subscriptions = const [],
    this.paymentCards = const [],
  });

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) {
    final subList = json['subscriptions'] as List?;
    final cardList = json['paymentCards'] as List?;

    return AdminUserDetail(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String?,
      role: json['role'] as String? ?? 'USER',
      monthlyIncome: (json['monthlyIncome'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      subscriptions: subList != null
          ? subList
              .map((s) => AdminUserSubscriptionDetail.fromJson(
                  s as Map<String, dynamic>))
              .toList()
          : const [],
      paymentCards: cardList != null
          ? cardList
              .map((c) =>
                  AdminUserCardDetail.fromJson(c as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }
}
