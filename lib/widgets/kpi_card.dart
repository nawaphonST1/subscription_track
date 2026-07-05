// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class KpiCard extends StatefulWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color subtitleColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.subtitleColor,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
  });

  @override
  State<KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<KpiCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? -6.0 : 0.0, 0.0), // Lift effect
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF131C2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? widget.iconColor.withOpacity(0.5) : const Color(0xFF243049), // Glow border
            width: 1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _isHovered ? const Color(0xFF1E2B47) : const Color(0xFF131C2E),
              const Color(0xFF0F172A),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered 
                  ? widget.iconColor.withOpacity(0.2) // Glow shadow matching theme
                  : Colors.black.withOpacity(0.3),
              blurRadius: _isHovered ? 16 : 10,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      color: widget.subtitleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Right Icon Container (Scales up slightly on hover)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 48,
              height: 48,
              transform: Matrix4.identity()
                ..scale(_isHovered ? 1.12 : 1.0),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                color: _isHovered 
                    ? widget.iconColor.withOpacity(0.25)
                    : widget.iconBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.icon,
                color: widget.iconColor,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
