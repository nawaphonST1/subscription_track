import 'package:flutter/material.dart';

class ServiceIcon extends StatelessWidget {
  const ServiceIcon({
    required this.serviceName,
    required this.category,
    this.size,
    super.key,
  });

  final String serviceName;
  final String category;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      serviceIconData(serviceName: serviceName, category: category),
      color: serviceIconColor(serviceName: serviceName, category: category),
      size: size,
    );
  }
}

IconData serviceIconData({
  required String serviceName,
  required String category,
}) {
  final name = serviceName.toLowerCase();
  final normalizedCategory = category.toLowerCase();
  if (name.contains('netflix') ||
      normalizedCategory.contains('entertainment')) {
    return Icons.play_circle_fill;
  }
  if (name.contains('spotify') || normalizedCategory.contains('music')) {
    return Icons.music_note;
  }
  if (name.contains('chatgpt') || normalizedCategory.contains('ai')) {
    return Icons.chat_bubble;
  }
  if (name.contains('google') || normalizedCategory.contains('cloud')) {
    return Icons.cloud;
  }
  if (name.contains('adobe') || normalizedCategory.contains('design')) {
    return Icons.palette;
  }
  return Icons.subscriptions;
}

Color serviceIconColor({
  required String serviceName,
  required String category,
}) {
  final name = serviceName.toLowerCase();
  final normalizedCategory = category.toLowerCase();
  if (name.contains('netflix') ||
      normalizedCategory.contains('entertainment')) {
    return const Color(0xFF3B82F6);
  }
  if (name.contains('spotify') || normalizedCategory.contains('music')) {
    return const Color(0xFF10B981);
  }
  if (name.contains('chatgpt') || normalizedCategory.contains('ai')) {
    return const Color(0xFF8B5CF6);
  }
  if (name.contains('google') || normalizedCategory.contains('cloud')) {
    return const Color(0xFFF59E0B);
  }
  if (name.contains('adobe') || normalizedCategory.contains('design')) {
    return const Color(0xFFEF4444);
  }
  return const Color(0xFF6366F1);
}
