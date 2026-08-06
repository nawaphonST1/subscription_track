import 'package:flutter/material.dart';

class PresetSearchField extends StatelessWidget {
  const PresetSearchField({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
    super.key,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFF243049);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'ค้นหาแพ็กเกจ เช่น Netflix, Spotify...',
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear, color: Color(0xFF64748B)),
                onPressed: onClear,
              ),
        filled: true,
        fillColor: const Color(0xFF131C2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6)),
        ),
      ),
    );
  }
}
