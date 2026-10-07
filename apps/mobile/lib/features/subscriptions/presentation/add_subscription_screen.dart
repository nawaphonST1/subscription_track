import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/core/widgets/service_icon.dart';
import 'package:subscription_track/features/profile/application/payment_card_linking_controller.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_form_validator.dart';
import 'package:subscription_track/features/subscriptions/domain/preset_package.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription.dart';
import 'package:subscription_track/features/subscriptions/presentation/select_package_screen.dart';
import 'package:subscription_track/features/subscriptions/presentation/widgets/payment_card_selector.dart';
import 'package:subscription_track/features/subscriptions/presentation/widgets/preset_picker_card.dart';
import 'package:subscription_track/features/subscriptions/presentation/widgets/subscription_appearance_selector.dart';
import 'package:subscription_track/features/subscriptions/presentation/widgets/subscription_general_fields.dart';
import 'package:subscription_track/features/subscriptions/presentation/widgets/usage_status_selector.dart';

class AddSubscriptionScreen extends ConsumerStatefulWidget {
  const AddSubscriptionScreen({super.key});

  @override
  ConsumerState<AddSubscriptionScreen> createState() =>
      _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState
    extends ConsumerState<AddSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  String _billingPeriod = 'Monthly';
  String _category = 'entertainment';
  UsageStatus _usageStatus = UsageStatus.frequent;
  IconData _selectedIcon = Icons.play_circle_fill;
  Color _selectedColor = const Color(0xFF3B82F6);
  String? _selectedCardId;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickFromPresets() async {
    final result = await Navigator.push<PresetPackage>(
      context,
      MaterialPageRoute(builder: (_) => const SelectPackageScreen()),
    );
    if (result == null || !mounted) return;

    setState(() {
      _nameController.text = result.name;
      _priceController.text = result.price.toStringAsFixed(0);
      _billingPeriod = result.billingPeriod;
      _category = result.category;
      _selectedIcon = serviceIconData(
        serviceName: result.name,
        category: result.category,
      );
      _selectedColor = serviceIconColor(
        serviceName: result.name,
        category: result.category,
      );
    });
  }

  void _saveForm() {
    // validate() ของ Form เช็ค PaymentCardSelector ด้วย (มี validator ของตัวเอง)
    // แต่เช็ค _selectedCardId == null ซ้ำตรงนี้อีกชั้นเผื่อ cards ว่างเปล่า
    // (ตอนนั้น PaymentCardSelector ไม่ได้ render DropdownButtonFormField เลย
    // จึงไม่มี FormField ให้ validate）
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCardId == null) return;

    final subscription = Subscription(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      confidence: 100,
      usageStatus: _usageStatus.nameValue,
      billingPeriod: _billingPeriod.toLowerCase(),
      category: _category,
      paymentCardId: _selectedCardId,
    );
    Navigator.pop(context, subscription);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linkedCards = ref.watch(linkedPaymentCardsProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'เพิ่มการสมัครสมาชิก',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PresetPickerCard(onTap: _pickFromPresets),
                const SizedBox(height: 28),
                SubscriptionGeneralFields(
                  nameController: _nameController,
                  priceController: _priceController,
                  billingPeriod: _billingPeriod,
                  nameValidator: SubscriptionFormValidator.validateName,
                  priceValidator: SubscriptionFormValidator.validatePrice,
                  onBillingPeriodChanged: (value) {
                    setState(() => _billingPeriod = value);
                  },
                ),
                const SizedBox(height: 24),
                linkedCards.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Text('โหลดข้อมูลบัตรไม่สำเร็จ'),
                  data: (cards) => PaymentCardSelector(
                    cards: cards,
                    selectedCardId: _selectedCardId,
                    onChanged: (value) =>
                        setState(() => _selectedCardId = value),
                  ),
                ),
                const SizedBox(height: 24),
                UsageStatusSelector(
                  selectedStatus: _usageStatus,
                  onChanged: (value) => setState(() => _usageStatus = value),
                ),
                const SizedBox(height: 28),
                SubscriptionAppearanceSelector(
                  selectedIcon: _selectedIcon,
                  selectedColor: _selectedColor,
                  onIconSelected: (selection) => setState(() {
                    _selectedIcon = selection.icon;
                    _category = selection.category;
                  }),
                  onColorSelected: (color) {
                    setState(() => _selectedColor = color);
                  },
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: linkedCards.value?.isNotEmpty ?? false
                        ? _saveForm
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'บันทึกบริการ',
                      style: TextStyle(
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
}
