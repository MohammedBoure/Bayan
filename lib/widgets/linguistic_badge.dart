import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A colorful, rounded tag indicating grammatical function (فعل، فاعل، مفعول به، حرف).
class LinguisticBadge extends StatelessWidget {
  final String label;
  final String type; // 'verb', 'subject', 'object', 'particle', or custom
  final VoidCallback? onTap;
  final bool isSelected;

  const LinguisticBadge({
    super.key,
    required this.label,
    required this.type,
    this.onTap,
    this.isSelected = false,
  });

  Color _getColor() {
    switch (type.toLowerCase()) {
      case 'verb':
      case 'فعل':
        return AppTheme.verbColor;
      case 'subject':
      case 'فاعل':
        return AppTheme.subjectColor;
      case 'object':
      case 'مفعول به':
        return AppTheme.objectColor;
      case 'particle':
      case 'حرف':
        return AppTheme.particleColor;
      default:
        return AppTheme.primaryTeal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
