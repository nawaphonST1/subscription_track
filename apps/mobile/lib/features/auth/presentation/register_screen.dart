import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:subscription_track/app/routing/route_constants.dart';
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/core/network/network_status.dart';
import 'package:subscription_track/core/widgets/connectivity_status_banner.dart';
import 'package:subscription_track/features/auth/application/auth_provider.dart';
import 'package:subscription_track/features/auth/domain/user.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authProvider.notifier).registerWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // ดักจับเมื่อสมัครสำเร็จหรือเกิดข้อผิดพลาด
    ref.listen<AsyncValue<User?>>(authProvider, (previous, next) {
      if (next is AsyncError) {
        final error = next.error;
        if (error is Failure) {
          ref.read(networkStatusProvider.notifier).reportFailure(error);
        }
        final errorText = error is Failure
            ? error.displayMessage
            : (error?.toString() ?? 'การสมัครสมาชิกล้มเหลว');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorText),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (next is AsyncData && next.value != null) {
        context.go(RouteConstants.dashboard);
      }
    });

    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      body: SafeArea(
        child: Column(
          children: [
            const ConnectivityStatusBanner(),
            Expanded(
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
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 48,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Title & Subtitle ---
                  const Text(
                    'สร้างบัญชีใหม่',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'เริ่มต้นจัดการค่าใช้จ่ายและการติดตาม Subscription',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 32),

                  // --- Name Field ---
                  _buildInputField(
                    controller: _nameController,
                    label: 'ชื่อ-นามสกุล',
                    hint: 'กรอกชื่อของคุณ',
                    icon: Icons.person_outline_rounded,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'กรุณากรอกชื่อของคุณ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- Email Field ---
                  _buildInputField(
                    controller: _emailController,
                    label: 'อีเมล',
                    hint: 'example@email.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'กรุณากรอกอีเมล';
                      }
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(val.trim())) {
                        return 'รูปแบบอีเมลไม่ถูกต้อง';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- Password Field ---
                  _buildInputField(
                    controller: _passwordController,
                    label: 'รหัสผ่าน',
                    hint: 'อย่างน้อย 6 ตัวอักษร',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: const Color(0xFF94A3B8),
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'กรุณากรอกรหัสผ่าน';
                      }
                      if (val.length < 6) {
                        return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- Confirm Password Field ---
                  _buildInputField(
                    controller: _confirmPasswordController,
                    label: 'ยืนยันรหัสผ่าน',
                    hint: 'กรอกรหัสผ่านอีกครั้ง',
                    icon: Icons.lock_reset_rounded,
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: const Color(0xFF94A3B8),
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    validator: (val) {
                      if (val != _passwordController.text) {
                        return 'รหัสผ่านไม่ตรงกัน';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // --- Register Button ---
                  if (isLoading)
                    const Center(
                      child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                    )
                  else
                    ElevatedButton(
                      onPressed: _onRegister,
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
                        'สมัครสมาชิก',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // --- Divider ---
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Color(0xFF243049))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'หรือสมัครด้วย',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: Color(0xFF243049))),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- Social Sign Up (Google & Apple - FE-002) ---
                  Row(
                    children: [
                      // Google Button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => ref.read(authProvider.notifier).loginWithGoogle(),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.g_mobiledata_rounded, size: 28, color: Colors.blue),
                              SizedBox(width: 4),
                              Text('Google', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Apple Button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => ref.read(authProvider.notifier).loginWithApple(),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFF131C2E),
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF243049)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.apple_rounded, size: 22),
                              SizedBox(width: 6),
                              Text('Apple', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // --- Switch to Login Link ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'มีบัญชีอยู่แล้วใช่ไหม? ',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                      GestureDetector(
                        onTap: () => context.go(RouteConstants.login),
                        child: const Text(
                          'เข้าสู่ระบบ',
                          style: TextStyle(
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFF131C2E),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF243049)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
