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
        return _PresetPackageCard(
          package: package,
          onTap: () => onSelected(package),
        );
      },
    );
  }
}

class _PresetPackageCard extends StatelessWidget {
  const _PresetPackageCard({required this.package, required this.onTap});

  final PresetPackage package;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = serviceIconColor(
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
          border: Border.all(color: theme.dividerColor, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
