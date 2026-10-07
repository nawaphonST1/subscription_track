import 'package:flutter/material.dart';

class PackageFeatureChips extends StatelessWidget {
  const PackageFeatureChips({
    required this.features,
    required this.accentColor,
    super.key,
  });

  final List<String> features;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    if (features.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final feature in features)
          Chip(
            avatar: Icon(Icons.check_circle, size: 16, color: accentColor),
            label: Text(feature, style: const TextStyle(fontSize: 12)),
            backgroundColor: accentColor.withValues(alpha: 0.08),
            side: BorderSide(color: accentColor.withValues(alpha: 0.24)),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
      ],
    );
  }
}
