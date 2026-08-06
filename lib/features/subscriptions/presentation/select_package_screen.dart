import 'package:flutter/material.dart';
import 'package:subscription_track/features/subscriptions/domain/preset_package.dart';
import 'package:subscription_track/features/subscriptions/domain/preset_package_catalog.dart';
import 'package:subscription_track/features/subscriptions/presentation/widgets/preset_package_grid.dart';
import 'package:subscription_track/features/subscriptions/presentation/widgets/preset_search_field.dart';

class SelectPackageScreen extends StatefulWidget {
  const SelectPackageScreen({super.key});

  @override
  State<SelectPackageScreen> createState() => _SelectPackageScreenState();
}

class _SelectPackageScreenState extends State<SelectPackageScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  List<PresetPackage> get _visiblePackages {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return presetPackageCatalog;
    return presetPackageCatalog
        .where((package) => package.name.toLowerCase().contains(query))
        .toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                child: PresetPackageGrid(
                  packages: _visiblePackages,
                  onSelected: (package) => Navigator.pop(context, package),
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
