import 'package:flutter/material.dart';

/// Reusable Glass Status Banner for Alert Messages
class LiquidStatusBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final bool isDark;

  const LiquidStatusBanner({
    super.key,
    required this.icon,
    required this.message,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
