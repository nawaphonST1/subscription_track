import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/core/widgets/service_icon.dart';
import 'package:subscription_track/features/subscriptions/application/select_package_controller.dart';
import 'package:subscription_track/features/subscriptions/data/remote_package_repository.dart';
import 'package:subscription_track/features/subscriptions/domain/billing_cycle.dart';
import 'package:subscription_track/features/subscriptions/domain/preset_package.dart';
import 'package:subscription_track/features/subscriptions/presentation/widgets/package_feature_chips.dart';
import 'package:subscription_track/features/subscriptions/presentation/widgets/preset_package_grid.dart';
import 'package:subscription_track/features/subscriptions/presentation/widgets/preset_search_field.dart';
import 'package:subscription_track/features/subscriptions/presentation/widgets/preset_tier_selector.dart';
import 'package:subscription_track/features/subscriptions/presentation/widgets/slot_sharing_stepper.dart';

class SelectPackageScreen extends ConsumerStatefulWidget {
  const SelectPackageScreen({super.key});

  @override
  ConsumerState<SelectPackageScreen> createState() => _SelectPackageScreenState();
}

class _SelectPackageScreenState extends ConsumerState<SelectPackageScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSelected(
    BuildContext context,
    PresetPackage package,
  ) async {
    if (!package.hasMultiplePlans) {
      Navigator.pop(context, package);
      return;
    }

    final draft = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PlanSelectionSheet(package: package),
    );

    if (draft == null || !context.mounted) return;
    Navigator.pop(context, draft);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final packagesAsync = ref.watch(packagesProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'เลือกแพ็กเกจแนะนำ',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              PresetSearchField(
                controller: _searchController,
                query: _searchQuery,
                onChanged: (value) => setState(() => _searchQuery = value),
                onClear: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),
              Expanded(
                child: packagesAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'ไม่สามารถโหลดข้อมูลแพ็กเกจได้',
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => ref.invalidate(packagesProvider),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('ลองใหม่อีกครั้ง'),
                        ),
                      ],
                    ),
                  ),
                  data: (packages) {
                    final query = _searchQuery.trim().toLowerCase();
                    if (query.isNotEmpty) {
                      final visiblePackages = packages
                          .where((p) => p.name.toLowerCase().contains(query))
                          .toList(growable: false);
                      return PresetPackageGrid(
                        packages: visiblePackages,
                        onSelected: (package) =>
                            _handleSelected(context, package),
                      );
                    }

                    final recommendedPackages =
                        packages.where((p) => p.plans.isNotEmpty).toList();
                    final centralPackages =
                        packages.where((p) => p.plans.isEmpty).toList();

                    return ListView(
                      children: [
                        if (recommendedPackages.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                color: Color(0xFFF59E0B),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'แพ็กเกจแนะนำใหม่ (${recommendedPackages.length})',
                                style: TextStyle(
                                  color: theme.textTheme.titleMedium?.color,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'บริการที่มีหลายแพ็กเกจย่อยและระดับสมาชิกให้เลือกใช้งาน',
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: recommendedPackages.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.1,
                            ),
                            itemBuilder: (context, index) {
                              final pkg = recommendedPackages[index];
                              return PresetPackageCard(
                                package: pkg,
                                onTap: () => _handleSelected(context, pkg),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                        Row(
                          children: [
                            const Icon(
                              Icons.hub_rounded,
                              color: Color(0xFF3B82F6),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'บริการกลางทั้งหมด (${centralPackages.length})',
                              style: TextStyle(
                                color: theme.textTheme.titleMedium?.color,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'บริการมาตรฐานกลางที่พร้อมเพิ่มในรายการของคุณ',
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: centralPackages.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.1,
                          ),
                          itemBuilder: (context, index) {
                            final pkg = centralPackages[index];
                            return PresetPackageCard(
                              package: pkg,
                              onTap: () => _handleSelected(context, pkg),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
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

class _PlanSelectionSheet extends ConsumerWidget {
  const _PlanSelectionSheet({required this.package});

  final PresetPackage package;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(selectPackageControllerProvider(package));
    final notifier = ref.read(selectPackageControllerProvider(package).notifier);
    final accent = _parseBrandColor(package.brandColor) ??
        serviceIconColor(serviceName: package.name, category: package.category);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ServiceIcon(
                  serviceName: package.name,
                  category: package.category,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    package.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PresetTierSelector(
              plans: package.plans,
              selectedTier: state.selectedPlan.tier,
              brandColor: accent,
              onSelected: notifier.selectPlan,
            ),
            const SizedBox(height: 20),
            PackageFeatureChips(
              features: state.selectedPlan.features,
              accentColor: accent,
            ),
            if (state.selectedPlan.features.isNotEmpty)
              const SizedBox(height: 20),
            if (state.selectedPlan.yearlyPrice != null) ...[
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('รายเดือน'),
                    selected: state.billingCycle == BillingCycle.monthly,
                    onSelected: (_) =>
                        notifier.toggleBillingCycle(BillingCycle.monthly),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('รายปี'),
                    selected: state.billingCycle == BillingCycle.yearly,
                    onSelected: (_) =>
                        notifier.toggleBillingCycle(BillingCycle.yearly),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
            SlotSharingStepper(
              sharedMembers: state.sharedMembers,
              maxSlots: state.selectedPlan.maxSlots,
              costPerSlot: state.calculatedCostPerSlot,
              accentColor: accent,
              onChanged: notifier.setSharedMembers,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.pop(context, notifier.toSubscriptionDraft()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'เลือกแพ็กเกจนี้ (฿${state.calculatedTotalPrice.toStringAsFixed(0)})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

