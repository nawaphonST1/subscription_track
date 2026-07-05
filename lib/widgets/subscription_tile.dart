// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../models/subscription.dart';

class SubscriptionTile extends StatefulWidget {
  final SubscriptionModel subscription;
  final ValueChanged<bool?> onChecked;

  const SubscriptionTile({
    super.key,
    required this.subscription,
    required this.onChecked,
  });

  @override
  State<SubscriptionTile> createState() => _SubscriptionTileState();
}

class _SubscriptionTileState extends State<SubscriptionTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        transform: Matrix4.identity()
          ..scale(_isHovered ? 1.015 : 1.0), // Scale up slightly on hover
        decoration: BoxDecoration(
          color: const Color(0xFF131C2E), // Dark card background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered 
                ? const Color(0xFF3B82F6).withOpacity(0.5) 
                : const Color(0xFF243049), // Blue border glow on hover
            width: 1,
          ),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            // Left Icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF0F1B35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isHovered 
                      ? const Color(0xFF3B82F6).withOpacity(0.5) 
                      : const Color(0xFF1E3A8A).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                widget.subscription.iconData,
                color: widget.subscription.iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            // Name and Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.subscription.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Monthly Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F2537),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF1E3A8A).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          widget.subscription.billingPeriod,
                          style: const TextStyle(
                            color: Color(0xFF60A5FA), // Light blue text
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Confidence
                      Text(
                        'ความเชื่อมั่น: ${widget.subscription.confidence}%',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Price and Action Row (Badge + Checkbox)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Price
                Text(
                  '฿${widget.subscription.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Usage Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.subscription.usageStatusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: widget.subscription.usageStatusColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.subscription.usageStatusText,
                        style: TextStyle(
                          color: widget.subscription.usageStatusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Animated Custom Checkbox
                    InkWell(
                      onTap: () {
                        widget.onChecked(!widget.subscription.isSelected);
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: widget.subscription.isSelected
                              ? const Color(0xFF3B82F6) // Custom selected blue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: widget.subscription.isSelected
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF475569),
                            width: 1.5,
                          ),
                        ),
                        child: AnimatedScale(
                          scale: widget.subscription.isSelected ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutBack, // Bouncy spring pop-in
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
