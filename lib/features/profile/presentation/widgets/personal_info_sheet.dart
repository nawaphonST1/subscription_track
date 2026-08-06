import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/features/profile/application/personal_info_controller.dart';

Future<void> showPersonalInfoSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF151D31),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _PersonalInfoSheet(),
  );
}

class _PersonalInfoSheet extends ConsumerStatefulWidget {
  const _PersonalInfoSheet();

  @override
  ConsumerState<_PersonalInfoSheet> createState() => _PersonalInfoSheetState();
}

class _PersonalInfoSheetState extends ConsumerState<_PersonalInfoSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _nationalIdController;
  DateTime? _selectedBirthDate;

  @override
  void initState() {
    super.initState();
    final currentInfo = ref.read(personalInfoProvider);
    _firstNameController = TextEditingController(text: currentInfo.firstName);
    _lastNameController = TextEditingController(text: currentInfo.lastName);
    _phoneController = TextEditingController(text: currentInfo.phoneNumber);
    _nationalIdController = TextEditingController(text: currentInfo.nationalId);
    _selectedBirthDate = currentInfo.birthDate;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }

  int get _calculatedAge {
    if (_selectedBirthDate == null) return 0;
    final today = DateTime.now();
    int age = today.year - _selectedBirthDate!.year;
    if (today.month < _selectedBirthDate!.month ||
        (today.month == _selectedBirthDate!.month && today.day < _selectedBirthDate!.day)) {
      age--;
    }
    return age;
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: const Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF151D31),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedBirthDate = pickedDate;
      });
    }
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกวันเดือนปีเกิด')),
      );
      return;
    }

    ref.read(personalInfoProvider.notifier).updateInfo(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          nationalId: _nationalIdController.text.trim(),
          birthDate: _selectedBirthDate,
        );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('บันทึกข้อมูลส่วนตัวสำเร็จ')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = _selectedBirthDate == null
        ? 'ยังไม่ได้เลือก'
        : '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year + 543}'; // แสดงเป็นปี พ.ศ.

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'แก้ไขข้อมูลส่วนตัว',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),
            
            // ชื่อ
            TextFormField(
              key: const Key('firstName-field'),
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'ชื่อ',
                hintText: 'กรอกชื่อต้น',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              style: const TextStyle(color: Colors.white),
              validator: (val) => val == null || val.trim().isEmpty ? 'กรุณากรอกชื่อ' : null,
            ),
            const SizedBox(height: 20),

            // นามสกุล
            TextFormField(
              key: const Key('lastName-field'),
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'นามสกุล',
                hintText: 'กรอกนามสกุล',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              style: const TextStyle(color: Colors.white),
              validator: (val) => val == null || val.trim().isEmpty ? 'กรุณากรอกนามสกุล' : null,
            ),
            const SizedBox(height: 20),

            // เบอร์โทรศัพท์
            TextFormField(
              key: const Key('phone-field'),
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'เบอร์โทรศัพท์',
                hintText: 'เช่น 0812345678',
                counterText: '',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              style: const TextStyle(color: Colors.white),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'กรุณากรอกเบอร์โทรศัพท์';
                }
                if (val.length != 10) {
                  return 'เบอร์โทรศัพท์ต้องมี 10 หลัก';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // เลขบัตรประชาชน
            TextFormField(
              key: const Key('nationalId-field'),
              controller: _nationalIdController,
              keyboardType: TextInputType.number,
              maxLength: 13,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'เลขบัตรประชาชน',
                hintText: 'เลข 13 หลัก',
                counterText: '',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              style: const TextStyle(color: Colors.white),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'กรุณากรอกเลขบัตรประชาชน';
                }
                if (val.length != 13) {
                  return 'เลขบัตรประชาชนต้องมี 13 หลัก';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Date of birth and Age display row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'วันเกิด (อายุ: $_calculatedAge ปี)',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _selectBirthDate,
                    icon: const Icon(Icons.calendar_month_rounded, size: 18),
                    label: const Text('เลือกวัน'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      foregroundColor: theme.colorScheme.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Save button
            SizedBox(
              height: 50,
              child: FilledButton(
                key: const Key('save-personal-info-button'),
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'บันทึกข้อมูล',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
