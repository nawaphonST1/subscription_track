import 'package:flutter/material.dart';
import 'package:subscription_track/models/subscription.dart';
import 'package:subscription_track/screens/subscription/select_package_screen.dart';

class AddSubscriptionScreen extends StatefulWidget {
  const AddSubscriptionScreen({super.key});

  @override
  State<AddSubscriptionScreen> createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends State<AddSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String _billingPeriod = 'Monthly';
  UsageStatus _usageStatus = UsageStatus.frequent;
  
  // Icon and color selection
  IconData _selectedIcon = Icons.play_circle_fill;
  Color _selectedColor = const Color(0xFF3B82F6);

  final List<IconData> _availableIcons = [
    Icons.play_circle_fill,
    Icons.music_note,
    Icons.chat_bubble,
    Icons.cloud,
    Icons.palette,
    Icons.movie_filter,
    Icons.gamepad,
    Icons.shopping_cart,
    Icons.credit_card,
    Icons.laptop,
    Icons.phone_android,
    Icons.star,
  ];

  final List<Color> _availableColors = [
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF10B981), // Green
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFF59E0B), // Yellow/Amber
    const Color(0xFFEF4444), // Red
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFFEC4899), // Pink
    const Color(0xFF64748B), // Slate/Grey
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // Navigate to Preset Packages Screen and receive selected package
  Future<void> _pickFromPresets() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectPackageScreen(),
      ),
    );

    if (result != null && result is PresetPackage) {
      setState(() {
        _nameController.text = result.name;
        _priceController.text = result.price.toStringAsFixed(0);
        _billingPeriod = result.billingPeriod;
        _selectedIcon = result.iconData;
        _selectedColor = result.iconColor;
      });
    }
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      final String name = _nameController.text.trim();
      final double price = double.parse(_priceController.text.trim());

      String category = 'other';
      if (_selectedIcon == Icons.play_circle_fill || _selectedIcon == Icons.movie_filter) {
        category = 'entertainment';
      } else if (_selectedIcon == Icons.music_note) {
        category = 'music';
      } else if (_selectedIcon == Icons.chat_bubble) {
        category = 'ai';
      } else if (_selectedIcon == Icons.cloud) {
        category = 'cloud';
      } else if (_selectedIcon == Icons.palette) {
        category = 'design';
      }

      final newSubscription = SubscriptionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        price: price,
        confidence: 100, // Manual additions have 100% confidence
        usageStatus: _usageStatus.nameValue,
        billingPeriod: _billingPeriod.toLowerCase(),
        category: category,
      );

      Navigator.pop(context, newSubscription);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F1D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'เพิ่มการสมัครสมาชิก',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Preset Selector Button (Pick from List)
                InkWell(
                  onTap: _pickFromPresets,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2563EB).withOpacity(0.15),
                          const Color(0xFF1D4ED8).withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF2563EB).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.dashboard_customize_rounded,
                            color: Color(0xFF60A5FA),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'เลือกจากแพ็กเกจแนะนำ (Preset)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Netflix, Spotify, ChatGPT และอื่นๆ อีกมากมาย',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Color(0xFF64748B),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // SECTION TITLE: General Info
                const Text(
                  'กรอกรายละเอียดสัญญา',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 16),

                // Name Input
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'ชื่อบริการ / ร้านค้า',
                    labelStyle: const TextStyle(color: Color(0xFF64748B)),
                    floatingLabelStyle: const TextStyle(color: Color(0xFF3B82F6)),
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
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFEF4444)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกชื่อบริการ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Price Input
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  decoration: InputDecoration(
                    labelText: 'ราคา (บาท)',
                    labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.normal),
                    floatingLabelStyle: const TextStyle(color: Color(0xFF3B82F6)),
                    prefixText: '฿ ',
                    prefixStyle: const TextStyle(color: Colors.white, fontSize: 18),
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
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFEF4444)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกราคา';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'กรุณากรอกราคาที่มากกว่า 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Billing Period Choices
                const Text(
                  'รอบชำระเงิน',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildChoiceChip(
                        label: 'รายเดือน (Monthly)',
                        isSelected: _billingPeriod == 'Monthly',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _billingPeriod = 'Monthly';
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildChoiceChip(
                        label: 'รายปี (Yearly)',
                        isSelected: _billingPeriod == 'Yearly',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _billingPeriod = 'Yearly';
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Usage Status Choices
                const Text(
                  'ระดับการใช้งานในปัจจุบัน',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Column(
                  children: [
                    _buildStatusOption(
                      status: UsageStatus.frequent,
                      title: 'ใช้งานบ่อย (Frequent)',
                      desc: 'เปิดใช้งานเกือบทุกวัน คุ้มค่ากับราคา',
                      color: const Color(0xFF10B981),
                    ),
                    const SizedBox(height: 10),
                    _buildStatusOption(
                      status: UsageStatus.moderate,
                      title: 'ใช้งานปานกลาง (Moderate)',
                      desc: 'เปิดใช้งานบ้างสัปดาห์ละ 1-2 ครั้ง',
                      color: const Color(0xFFD97706),
                    ),
                    const SizedBox(height: 10),
                    _buildStatusOption(
                      status: UsageStatus.unused,
                      title: 'ไม่ได้ใช้งานเลย (Unused)',
                      desc: 'ไม่ได้เข้าใช้งานเลย แนะนำให้ยกเลิกบริการ',
                      color: const Color(0xFFEF4444),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Icon selection
                const Text(
                  'เลือกไอคอนสำหรับบริการ',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _availableIcons.length,
                    itemBuilder: (context, index) {
                      final icon = _availableIcons[index];
                      final isSelected = _selectedIcon == icon;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIcon = icon;
                          });
                        },
                        child: Container(
                          width: 50,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _selectedColor.withOpacity(0.2)
                                : const Color(0xFF131C2E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? _selectedColor : const Color(0xFF243049),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: isSelected ? _selectedColor : const Color(0xFF94A3B8),
                            size: 24,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Color selection
                const Text(
                  'เลือกสีธีม',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _availableColors.length,
                    itemBuilder: (context, index) {
                      final color = _availableColors[index];
                      final isSelected = _selectedColor == color;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 42,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.6),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : [],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _saveForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                      shadowColor: const Color(0xFF3B82F6).withOpacity(0.4),
                    ),
                    child: const Text(
                      'บันทึกบริการ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required Function(bool) onSelected,
  }) {
    return ChoiceChip(
      label: Container(
        alignment: Alignment.center,
        height: 36,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: const Color(0xFF131C2E),
      side: BorderSide(
        color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF243049),
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildStatusOption({
    required UsageStatus status,
    required String title,
    required String desc,
    required Color color,
  }) {
    final bool isSelected = _usageStatus == status;
    return InkWell(
      onTap: () {
        setState(() {
          _usageStatus = status;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF131C2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF243049),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : const Color(0xFF475569),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
