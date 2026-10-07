import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:subscription_track/app/routing/route_constants.dart';
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/core/security/pin_provider.dart';
import 'package:subscription_track/core/widgets/pin/pin.dart';
import 'package:subscription_track/features/auth/application/auth_provider.dart';

class SetupPinScreen extends ConsumerStatefulWidget {
  const SetupPinScreen({
    super.key,
    this.initialCurrentPin,
  });

  final String? initialCurrentPin;

  @override
  ConsumerState<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends ConsumerState<SetupPinScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _currentPinController;
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  final FocusNode _currentPinFocusNode = FocusNode();
  final FocusNode _newPinFocusNode = FocusNode();
  final FocusNode _confirmPinFocusNode = FocusNode();

  bool _obscureCurrentPin = true;
  bool _obscureNewPin = true;
  bool _obscureConfirmPin = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentPinController =
        TextEditingController(text: widget.initialCurrentPin ?? '');
  }

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    _currentPinFocusNode.dispose();
    _newPinFocusNode.dispose();
    _confirmPinFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final currentPin = _currentPinController.text.trim().isNotEmpty
        ? _currentPinController.text.trim()
        : '111111';
    final newPin = _newPinController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = ref.read(pinRepositoryProvider);
    final result = await repo.changePin(
      currentPin: currentPin,
      newPin: newPin,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.displayMessage;
        });
      },
      (_) {
        setState(() {
          _isLoading = false;
        });
        ref.read(authProvider.notifier).markPinConfigured();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ตั้งค่ารหัส PIN สำเร็จแล้ว'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go(RouteConstants.dashboard);
      },
    );
  }

  Widget _buildPinField({
    required Key key,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    required String? Function(String?) validator,
  }) {
    return FormField<String>(
      validator: (_) => validator(controller.text),
      builder: (fieldState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF94A3B8), size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF94A3B8),
                    size: 20,
                  ),
                  onPressed: onToggleObscure,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Center(
              child: PinCodeInput(
                textFieldKey: key,
                controller: controller,
                focusNode: focusNode,
                obscureText: obscureText,
                hasError: fieldState.hasError,
                autoFocus: false,
                onChanged: (_) {
                  if (fieldState.hasError) {
                    fieldState.validate();
                  }
                },
              ),
            ),
            if (fieldState.hasError) ...[
              const SizedBox(height: 6),
              Text(
                fieldState.errorText!,
                style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Header Icon ---
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131C2E),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF3B82F6).withValues(alpha: 0.15),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.security_rounded,
                        size: 48,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Title & Subtitle ---
                  const Text(
                    'ตั้งค่ารหัสความปลอดภัย (PIN)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'เพื่อความปลอดภัยของบัญชี กรุณาตั้งรหัส PIN 6 หลัก\nสำหรับยืนยันการทำธุรกรรมและจัดการบริการสำคัญ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final defaultPinText = List.filled(6, '1').join();
                      return Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                const Color(0xFF3B82F6).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFF60A5FA),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'หากเพิ่งสมัครผ่าน Google หรือ Apple ระบบได้ตั้งรหัส PIN เริ่มต้นไว้เป็น $defaultPinText '
                                'กรุณากรอก $defaultPinText เป็นรหัสเดิม แล้วตั้งรหัส PIN ใหม่ของคุณด้านล่าง',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF93C5FD),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // --- Current / Temporary PIN Field ---
                  _buildPinField(
                    key: const Key('setup_current_pin_field'),
                    controller: _currentPinController,
                    focusNode: _currentPinFocusNode,
                    label: 'รหัส PIN เดิม / รหัสเริ่มต้น (6 หลัก)',
                    icon: Icons.vpn_key_outlined,
                    obscureText: _obscureCurrentPin,
                    onToggleObscure: () => setState(
                      () => _obscureCurrentPin = !_obscureCurrentPin,
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'กรุณากรอกรหัส PIN เดิมหรือรหัสเริ่มต้น';
                      }
                      if (val.length != 6) {
                        return 'รหัส PIN ต้องมี 6 หลัก';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- New PIN Field ---
                  _buildPinField(
                    key: const Key('setup_new_pin_field'),
                    controller: _newPinController,
                    focusNode: _newPinFocusNode,
                    label: 'รหัส PIN ใหม่ (6 หลัก)',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscureNewPin,
                    onToggleObscure: () => setState(
                      () => _obscureNewPin = !_obscureNewPin,
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'กรุณากรอกรหัส PIN ใหม่';
                      }
                      if (val.length != 6) {
                        return 'รหัส PIN ต้องเป็นตัวเลข 6 หลัก';
                      }
                      if (val == _currentPinController.text) {
                        return 'รหัส PIN ใหม่ต้องไม่ซ้ำกับรหัสเดิม';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- Confirm New PIN Field ---
                  _buildPinField(
                    key: const Key('setup_confirm_pin_field'),
                    controller: _confirmPinController,
                    focusNode: _confirmPinFocusNode,
                    label: 'ยืนยันรหัส PIN ใหม่',
                    icon: Icons.lock_reset_rounded,
                    obscureText: _obscureConfirmPin,
                    onToggleObscure: () => setState(
                      () => _obscureConfirmPin = !_obscureConfirmPin,
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'กรุณายืนยันรหัส PIN';
                      }
                      if (val != _newPinController.text) {
                        return 'รหัส PIN ยืนยันไม่ตรงกัน';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // --- Error Message Display ---
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFEF4444),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // --- Submit Button ---
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                    )
                  else
                    ElevatedButton(
                      key: const Key('setup_pin_submit_button'),
                      onPressed: _onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'บันทึกและเริ่มใช้งาน',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      key: const Key('setup_pin_logout_button'),
                      onPressed: () async =>
                          ref.read(authProvider.notifier).logout(),
                      child: const Text(
                        'ออกจากระบบ',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
