import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/features/subscriptions/data/remote_package_repository.dart';
import 'package:subscription_track/features/subscriptions/presentation/widgets/preset_package_grid.dart';
import 'package:subscription_track/features/subscriptions/presentation/widgets/preset_search_field.dart';

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
              const SizedBox(height: 24),
              Text(
                'แพ็กเกจยอดนิยม',
                style: TextStyle(
                  color: theme.textTheme.titleMedium?.color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
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
                    final visiblePackages = query.isEmpty
                        ? packages
                        : packages
                            .where((p) => p.name.toLowerCase().contains(query))
                            .toList(growable: false);

                    return PresetPackageGrid(
                      packages: visiblePackages,
                      onSelected: (package) => Navigator.pop(context, package),
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

