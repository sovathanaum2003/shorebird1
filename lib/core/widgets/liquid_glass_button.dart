import 'package:flutter/material.dart';

/// Reusable Secondary Glass Button
class LiquidGlassButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isHighlight;
  final IconData icon;
  final String label;
  final bool isDark;

  const LiquidGlassButton({
    super.key,
    required this.onPressed,
    required this.isHighlight,
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isHighlight
            ? const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
              )
            : null,
        color: isHighlight
            ? null
            : (isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.6)),
        border: Border.all(
          color: isHighlight
              ? Colors.white.withValues(alpha: 0.4)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : const Color(0xFF6366F1).withValues(alpha: 0.3)),
          width: 1.2,
        ),
        boxShadow: isHighlight
            ? [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isHighlight
                      ? Colors.white
                      : (isDark ? Colors.white : const Color(0xFF4F46E5)),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isHighlight
                        ? Colors.white
                        : (isDark ? Colors.white : const Color(0xFF4F46E5)),
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
