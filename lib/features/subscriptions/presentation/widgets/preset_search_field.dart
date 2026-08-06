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
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'ค้นหาแพ็กเกจ เช่น Netflix, Spotify...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(icon: const Icon(Icons.clear), onPressed: onClear),
      ),
    );
  }
}
