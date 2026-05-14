import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum SnackbarType { success, error, info }

void showAppSnackbar(
  BuildContext context, {
  required String message,
  SnackbarType type = SnackbarType.info,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final (icon, bg) = switch (type) {
    SnackbarType.success => (Icons.check_circle, AppColors.credit),
    SnackbarType.error => (Icons.error, AppColors.debit),
    SnackbarType.info => (Icons.info, AppColors.textPrimary),
  };

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: bg,
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}
