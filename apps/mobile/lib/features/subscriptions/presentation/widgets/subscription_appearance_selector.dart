import 'package:flutter/material.dart';

class SubscriptionIconSelection {
  const SubscriptionIconSelection({required this.icon, required this.category});

  final IconData icon;
  final String category;
}

class SubscriptionAppearanceSelector extends StatelessWidget {
  const SubscriptionAppearanceSelector({
    required this.selectedIcon,
    required this.selectedColor,
    required this.onIconSelected,
    required this.onColorSelected,
    super.key,
  });

  static const iconSelections = <SubscriptionIconSelection>[
    SubscriptionIconSelection(
      icon: Icons.play_circle_fill,
      category: 'entertainment',
    ),
    SubscriptionIconSelection(icon: Icons.music_note, category: 'music'),
    SubscriptionIconSelection(icon: Icons.chat_bubble, category: 'ai'),
    SubscriptionIconSelection(icon: Icons.cloud, category: 'cloud'),
    SubscriptionIconSelection(icon: Icons.palette, category: 'design'),
    SubscriptionIconSelection(
      icon: Icons.movie_filter,
      category: 'entertainment',
    ),
    SubscriptionIconSelection(icon: Icons.gamepad, category: 'gaming'),
    SubscriptionIconSelection(icon: Icons.shopping_cart, category: 'shopping'),
    SubscriptionIconSelection(icon: Icons.credit_card, category: 'finance'),
    SubscriptionIconSelection(icon: Icons.laptop, category: 'productivity'),
    SubscriptionIconSelection(icon: Icons.phone_android, category: 'mobile'),
    SubscriptionIconSelection(icon: Icons.star, category: 'other'),
  ];

  static const colors = <Color>[
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
    Color(0xFF64748B),
  ];

  final IconData selectedIcon;
  final Color selectedColor;
  final ValueChanged<SubscriptionIconSelection> onIconSelected;
  final ValueChanged<Color> onColorSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AppearanceTitle('เลือกไอคอนสำหรับบริการ'),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: iconSelections.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final selection = iconSelections[index];
              final isSelected = selectedIcon == selection.icon;
              return InkWell(
                onTap: () => onIconSelected(selection),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 50,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? selectedColor.withValues(alpha: 0.2)
                        : const Color(0xFF131C2E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? selectedColor
                          : const Color(0xFF243049),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    selection.icon,
                    color: isSelected ? selectedColor : const Color(0xFF94A3B8),
                    size: 24,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        const _AppearanceTitle('เลือกสีธีม'),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: colors.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final color = colors[index];
              final isSelected = selectedColor == color;
              return InkWell(
                onTap: () => onColorSelected(color),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 42,
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
                              color: color.withValues(alpha: 0.6),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AppearanceTitle extends StatelessWidget {
  const _AppearanceTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF94A3B8),
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
  );
}
