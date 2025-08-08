import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final StatusType type;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.text,
    required this.type,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getBorderColor()),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 12,
              color: _getTextColor(),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _getTextColor(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (type) {
      case StatusType.success:
        return AppColors.success.withOpacity(0.1);
      case StatusType.warning:
        return AppColors.warning.withOpacity(0.1);
      case StatusType.error:
        return AppColors.error.withOpacity(0.1);
      case StatusType.info:
        return AppColors.info.withOpacity(0.1);
      case StatusType.primary:
        return AppColors.primary.withOpacity(0.1);
    }
  }

  Color _getBorderColor() {
    switch (type) {
      case StatusType.success:
        return AppColors.success;
      case StatusType.warning:
        return AppColors.warning;
      case StatusType.error:
        return AppColors.error;
      case StatusType.info:
        return AppColors.info;
      case StatusType.primary:
        return AppColors.primary;
    }
  }

  Color _getTextColor() {
    switch (type) {
      case StatusType.success:
        return AppColors.success;
      case StatusType.warning:
        return AppColors.warning;
      case StatusType.error:
        return AppColors.error;
      case StatusType.info:
        return AppColors.info;
      case StatusType.primary:
        return AppColors.primary;
    }
  }
}

enum StatusType {
  success,
  warning,
  error,
  info,
  primary,
}
