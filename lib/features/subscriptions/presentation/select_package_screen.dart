import 'package:flutter/material.dart';

/// Preset view model retained during the path-only migration.
class PresetPackage {
  final String name;
  final double price;
  final String billingPeriod;
  final IconData iconData;
  final Color iconColor;

  const PresetPackage({
    required this.name,
    required this.price,
    required this.billingPeriod,
    required this.iconData,
    required this.iconColor,
  });
}

class SelectPackageScreen extends StatefulWidget {
  const SelectPackageScreen({super.key});

  @override
  State<SelectPackageScreen> createState() => _SelectPackageScreenState();
}

class _SelectPackageScreenState extends State<SelectPackageScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<PresetPackage> _presets = const [
    PresetPackage(
      name: 'Netflix Premium',
      price: 419.0,
      billingPeriod: 'Monthly',
      iconData: Icons.play_circle_fill,
      iconColor: Color(0xFFE50914), // Netflix Red
    ),
    PresetPackage(
      name: 'Spotify Premium',
      price: 139.0,
      billingPeriod: 'Monthly',
      iconData: Icons.music_note,
      iconColor: Color(0xFF1DB954), // Spotify Green
    ),
    PresetPackage(
      name: 'ChatGPT Plus',
      price: 750.0,
      billingPeriod: 'Monthly',
      iconData: Icons.chat_bubble,
      iconColor: Color(0xFF10A37F), // OpenAI Green
    ),
    PresetPackage(
      name: 'Disney+ Hotstar',
      price: 289.0,
      billingPeriod: 'Monthly',
      iconData: Icons.movie_filter,
      iconColor: Color(0xFF0063E5), // Disney Blue
    ),
    PresetPackage(
      name: 'YouTube Premium',
      price: 179.0,
      billingPeriod: 'Monthly',
      iconData: Icons.play_arrow_rounded,
      iconColor: Color(0xFFFF0000), // YouTube Red
    ),
    PresetPackage(
      name: 'Apple One',
      price: 369.0,
      billingPeriod: 'Monthly',
      iconData: Icons.apple,
      iconColor: Color(0xFFFA243C), // Apple Red
    ),
    PresetPackage(
      name: 'Canva Pro',
      price: 229.0,
      billingPeriod: 'Monthly',
      iconData: Icons.design_services,
      iconColor: Color(0xFF00C4CC), // Canva Cyan
    ),
    PresetPackage(
      name: 'Adobe Creative Cloud',
      price: 1200.0,
      billingPeriod: 'Monthly',
      iconData: Icons.palette,
      iconColor: Color(0xFFFF3C00), // Adobe Orange-Red
    ),
    PresetPackage(
      name: 'Microsoft 365 Personal',
      price: 209.0,
      billingPeriod: 'Monthly',
      iconData: Icons.cloud_done,
      iconColor: Color(0xFF0078D4), // MS Blue
    ),
    PresetPackage(
      name: 'PlayStation Plus Deluxe',
      price: 370.0,
      billingPeriod: 'Monthly',
      iconData: Icons.sports_esports,
      iconColor: Color(0xFF003087), // PlayStation Blue
    ),
    PresetPackage(
      name: 'Nintendo Switch Online',
      price: 69.0,
      billingPeriod: 'Monthly',
      iconData: Icons.gamepad,
      iconColor: Color(0xFFE60012), // Nintendo Red
    ),
    PresetPackage(
      name: 'iCloud+ 200GB',
      price: 99.0,
      billingPeriod: 'Monthly',
      iconData: Icons.cloud,
      iconColor: Color(0xFF29B6F6), // iCloud Blue
    ),
  ];

  List<PresetPackage> get _filteredPresets {
    if (_searchQuery.isEmpty) {
      return _presets;
    }
    return _presets
        .where(
          (preset) =>
              preset.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0A0F1D,
      ), // Dark background matching the main app
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F1D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'เลือกแพ็กเกจแนะนำ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'ค้นหาแพ็กเกจ เช่น Netflix, Spotify...',
                  hintStyle: const TextStyle(color: Color(0xFF64748B)),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF64748B),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: Color(0xFF64748B),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF131C2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF243049)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF243049)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'แพ็กเกจยอดนิยม',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Grid list
              Expanded(
                child: _filteredPresets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 64,
                              color: const Color(0xFF64748B).withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'ไม่พบแพ็กเกจที่ต้องการค้นหา',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'คุณสามารถกดเพิ่มเองแบบกำหนดเองในหน้าก่อนหน้าได้',
                              style: TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        itemCount: _filteredPresets.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.1,
                            ),
                        itemBuilder: (context, index) {
                          final preset = _filteredPresets[index];
                          return InkWell(
                            onTap: () {
                              Navigator.pop(context, preset);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF131C2E),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF243049),
                                  width: 1.5,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // Background accent glow
                                  Positioned(
                                    top: -20,
                                    right: -20,
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: preset.iconColor.withOpacity(
                                          0.12,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Icon
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: preset.iconColor.withOpacity(
                                              0.15,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            preset.iconData,
                                            color: preset.iconColor,
                                            size: 24,
                                          ),
                                        ),
                                        const Spacer(),
                                        // Package Name
                                        Text(
                                          preset.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        // Price
                                        Text(
                                          '฿${preset.price.toStringAsFixed(0)} / ${preset.billingPeriod == 'Monthly' ? 'เดือน' : 'ปี'}',
                                          style: const TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
