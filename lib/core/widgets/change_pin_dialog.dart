import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/core/security/pin_provider.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/core/theme/app_typography.dart';

class ChangePinDialog extends ConsumerStatefulWidget {
  const ChangePinDialog({super.key});

  @override
  ConsumerState<ChangePinDialog> createState() => _ChangePinDialogState();

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ChangePinDialog(),
    );
  }
}

enum ChangePinStep { verifyOld, enterNew, confirmNew }

class _ChangePinDialogState extends ConsumerState<ChangePinDialog> {
  ChangePinStep _step = ChangePinStep.verifyOld;
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _errorMessage;
  
  String _newPin = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handlePinSubmit(String value) {
    if (value.length != 6) return;

    setState(() {
      _errorMessage = null;
    });

    switch (_step) {
      case ChangePinStep.verifyOld:
        final correct = ref.read(securityPinProvider) == value;
        if (correct) {
          setState(() {
            _step = ChangePinStep.enterNew;
            _pinController.clear();
          });
          _focusNode.requestFocus();
        } else {
          setState(() {
            _errorMessage = 'รหัส PIN เดิมไม่ถูกต้อง';
            _pinController.clear();
          });
          _focusNode.requestFocus();
        }
      case ChangePinStep.enterNew:
        setState(() {
          _newPin = value;
          _step = ChangePinStep.confirmNew;
          _pinController.clear();
        });
        _focusNode.requestFocus();
      case ChangePinStep.confirmNew:
        if (value == _newPin) {
          ref.read(securityPinProvider.notifier).updatePin(value);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('เปลี่ยนรหัส PIN สำเร็จแล้ว')),
          );
          Navigator.of(context).pop();
        } else {
          setState(() {
            _errorMessage = 'รหัส PIN ยืนยันไม่ตรงกัน กรุณาตั้งค่าใหม่';
            _step = ChangePinStep.enterNew;
            _newPin = '';
            _pinController.clear();
          });
          _focusNode.requestFocus();
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = _pinController.text;

    final title = switch (_step) {
      ChangePinStep.verifyOld => 'ยืนยัน PIN เดิม',
      ChangePinStep.enterNew => 'ตั้งค่า PIN ใหม่',
      ChangePinStep.confirmNew => 'ยืนยัน PIN ใหม่',
    };

    final message = switch (_step) {
      ChangePinStep.verifyOld => 'กรุณากรอกรหัส PIN เดิมของคุณเพื่อทำรายการ',
      ChangePinStep.enterNew => 'กรุณากรอกรหัส PIN ใหม่ 6 หลัก',
      ChangePinStep.confirmNew => 'กรุณากรอกรหัส PIN ใหม่อีกครั้งเพื่อยืนยัน',
    };

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            _step == ChangePinStep.verifyOld ? Icons.security_rounded : Icons.lock_reset_rounded,
            color: theme.colorScheme.primary,
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.headingSmall.copyWith(
              color: theme.textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 0,
                child: SizedBox(
                  width: 0,
                  height: 0,
                  child: TextField(
                    controller: _pinController,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (val) {
                      setState(() {
                        if (_errorMessage != null) {
                          _errorMessage = null;
                        }
                      });
                      if (val.length == 6) {
                        _handlePinSubmit(val);
                      }
                    },
                    decoration: const InputDecoration(
                      counterText: '',
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _focusNode.requestFocus(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    final hasValue = index < text.length;
                    final isFocused = _focusNode.hasFocus && index == text.length;

                    return Container(
                      width: 40,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _errorMessage != null
                              ? AppColors.danger
                              : isFocused
                                  ? theme.colorScheme.primary
                                  : theme.dividerColor,
                          width: isFocused || _errorMessage != null ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        hasValue ? '•' : '',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
      ],
    );
  }
}
