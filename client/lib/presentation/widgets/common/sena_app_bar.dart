import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SenaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom; // Add bottom parameter

  const SenaAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.bottom, // Include in constructor
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/sena_logo.png',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      actions: actions,
      elevation: 2,
      bottom: bottom, // Pass bottom to AppBar
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      ); // Adjust preferredSize to account for bottom widget
}