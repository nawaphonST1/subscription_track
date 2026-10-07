import 'package:flutter/material.dart';
import 'package:subscription_track/core/widgets/service_icon.dart';
import 'package:subscription_track/features/subscriptions/domain/preset_package.dart';

class PresetPackageGrid extends StatelessWidget {
  const PresetPackageGrid({
    required this.packages,
    required this.onSelected,
    super.key,
  });

  final List<PresetPackage> packages;
  final ValueChanged<PresetPackage> onSelected;

  @override
  Widget build(BuildContext context) {
    if (packages.isEmpty) return const _PresetEmptyState();
    return GridView.builder(
      itemCount: packages.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final package = packages[index];
        return PresetPackageCard(
          package: package,
          onTap: () => onSelected(package),
        );
      },
    );
  }
}

Color? _parseBrandColor(String? hexString) {
  if (hexString == null || hexString.isEmpty) return null;
  var hex = hexString.replaceFirst('#', '').trim();
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8) return null;
  final val = int.tryParse(hex, radix: 16);
  return val != null ? Color(val) : null;
}

class PresetPackageCard extends StatelessWidget {
  const PresetPackageCard({super.key, required this.package, required this.onTap});

  final PresetPackage package;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _parseBrandColor(package.brandColor) ??
        serviceIconColor(
          serviceName: package.name,
          category: package.category,
        );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: package.plans.isNotEmpty
                ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                : theme.dividerColor,
            width: package.plans.isNotEmpty ? 1.5 : 1.2,
          ),
          boxShadow: theme.brightness == Brightness.dark
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: ServiceIcon(
                      serviceName: package.name,
                      category: package.category,
                      size: 24,
                    ),
                  ),
                ),
                if (package.plans.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 2),
                        Text(
                          '${package.plans.length} แพ็กเกจ',
                          style: const TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              package.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textTheme.titleMedium?.color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '฿${package.price.toStringAsFixed(0)} / '
              '${package.billingPeriod == 'Monthly' ? 'เดือน' : 'ปี'}',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetEmptyState extends StatelessWidget {
  const _PresetEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'ไม่พบแพ็กเกจที่ต้องการค้นหา',
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'คุณสามารถกดเพิ่มเองแบบกำหนดเองในหน้าก่อนหน้าได้',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
