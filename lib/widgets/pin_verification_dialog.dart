import 'package:flutter/material.dart';

class PinVerificationDialog extends StatefulWidget {
  const PinVerificationDialog({super.key});

  @override
  State<PinVerificationDialog> createState() => _PinVerificationDialogState();
}

class _PinVerificationDialogState extends State<PinVerificationDialog> {
  final String _correctPin = '123456';
  String _inputPin = '';
  bool _hasError = false;
  String _errorMessage = 'กรุณากรอกรหัส PIN 6 หลักเพื่อยืนยัน';

  void _onNumberPressed(String number) {
    if (_inputPin.length >= 6) return;
    setState(() {
      _hasError = false;
      _errorMessage = 'กรุณากรอกรหัส PIN 6 หลักเพื่อยืนยัน';
      _inputPin += number;
    });

    if (_inputPin.length == 6) {
      // Small delay before verification to let the user see the 6th dot filled
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          _verifyPin();
        }
      });
    }
  }

  void _onBackspacePressed() {
    if (_inputPin.isEmpty) return;
    setState(() {
      _hasError = false;
      _inputPin = _inputPin.substring(0, _inputPin.length - 1);
    });
  }

  void _verifyPin() {
    if (_inputPin == _correctPin) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = 'รหัส PIN ไม่ถูกต้อง (ทดลองพิมพ์: 123456)';
        _inputPin = ''; // Reset input on failure
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF131C2E), // Match dark background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF243049), width: 1.5),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Security Shield Icon with custom amber glow
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _hasError 
                      ? const Color(0xFFEF4444).withOpacity(0.1) 
                      : const Color(0xFFF59E0B).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _hasError ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  _hasError ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                  color: _hasError ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              
              // Title
              const Text(
                'ยืนยันความปลอดภัย',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Subtitle/Error Message
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _hasError ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // PIN Indicator Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  bool isFilled = index < _inputPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _hasError
                          ? const Color(0xFFEF4444)
                          : isFilled
                              ? const Color(0xFF3B82F6)
                              : Colors.transparent,
                      border: Border.all(
                        color: _hasError
                            ? const Color(0xFFEF4444)
                            : isFilled
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF475569),
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),

              // Custom Keypad
              SizedBox(
                width: 250,
                child: Column(
                  children: [
                    _buildKeypadRow(['1', '2', '3']),
                    _buildKeypadRow(['4', '5', '6']),
                    _buildKeypadRow(['7', '8', '9']),
                    _buildKeypadRow(['C', '0', 'B']),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> labels) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: labels.map((label) {
          if (label == 'C') {
            return _buildKeypadButton(
              label: '',
              icon: Icons.close,
              onTap: () => Navigator.of(context).pop(false),
            );
          } else if (label == 'B') {
            return _buildKeypadButton(
              label: '',
              icon: Icons.backspace_outlined,
              onTap: _onBackspacePressed,
            );
          } else {
            return _buildKeypadButton(
              label: label,
              onTap: () => _onNumberPressed(label),
            );
          }
        }).toList(),
      ),
    );
  }

  Widget _buildKeypadButton({
    required String label,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1E2B47).withOpacity(0.2),
              border: Border.all(
                color: const Color(0xFF243049),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: icon != null
                ? Icon(icon, color: const Color(0xFF94A3B8), size: 20)
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
