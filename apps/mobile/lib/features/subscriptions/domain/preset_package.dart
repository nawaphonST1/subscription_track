import 'package:subscription_track/core/utils/logger.dart';

class PresetPackage {
  const PresetPackage({
    required this.name,
    required this.price,
    required this.billingPeriod,
    required this.category,
    this.id,
    this.brandColor,
    this.iconUrl,
    this.description,
  });

  final String? id;
  final String name;
  final double price;
  final String billingPeriod;
  final String category;
  final String? brandColor;
  final String? iconUrl;
  final String? description;

  static String _normalizeBillingPeriod(dynamic raw) {
    if (raw == null) return 'Monthly';
    final s = raw.toString().trim().toLowerCase();
    switch (s) {
      case 'monthly':
        return 'Monthly';
      case 'yearly':
        return 'Yearly';
      case 'weekly':
        return 'Weekly';
      default:
        logger.w(
          'PresetPackage: unrecognized billing_cycle "$raw", falling back to "Monthly"',
        );
        return 'Monthly';
    }
  }

  factory PresetPackage.fromJson(Map<String, dynamic> json) {
    final priceVal = json['default_price'] ?? json['price'];
    final billingVal = json['billing_cycle'] ?? json['billingPeriod'];

    return PresetPackage(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      price: (priceVal as num?)?.toDouble() ?? 0.0,
      billingPeriod: _normalizeBillingPeriod(billingVal),
      category: (json['category'] as String?)?.toLowerCase() ?? 'entertainment',
      brandColor: json['brand_color'] as String? ?? json['brandColor'] as String?,
      iconUrl: json['icon_url'] as String? ?? json['iconUrl'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    'default_price': price,
    'billing_cycle': billingPeriod.toUpperCase(),
    'category': category,
    if (brandColor != null) 'brand_color': brandColor,
    if (iconUrl != null) 'icon_url': iconUrl,
    if (description != null) 'description': description,
  };
}

