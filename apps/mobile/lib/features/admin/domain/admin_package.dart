class AdminPackage {
  final String id;
  final String name;
  final String category;
  final double defaultPrice;
  final String billingCycle;
  final String brandColor;
  final String? iconUrl;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;

  const AdminPackage({
    required this.id,
    required this.name,
    required this.category,
    required this.defaultPrice,
    this.billingCycle = 'MONTHLY',
    this.brandColor = '#3B82F6',
    this.iconUrl,
    this.description,
    this.isActive = true,
    this.createdAt,
  });

  factory AdminPackage.fromJson(Map<String, dynamic> json) {
    return AdminPackage(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      defaultPrice: (json['defaultPrice'] as num?)?.toDouble() ?? 0.0,
      billingCycle: json['billingCycle'] as String? ?? 'MONTHLY',
      brandColor: json['brandColor'] as String? ?? '#3B82F6',
      iconUrl: json['iconUrl'] as String?,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  AdminPackage copyWith({
    String? id,
    String? name,
    String? category,
    double? defaultPrice,
    String? billingCycle,
    String brandColor = '#3B82F6',
    String? iconUrl,
    String? description,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return AdminPackage(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      defaultPrice: defaultPrice ?? this.defaultPrice,
      billingCycle: billingCycle ?? this.billingCycle,
      brandColor: brandColor,
      iconUrl: iconUrl ?? this.iconUrl,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

