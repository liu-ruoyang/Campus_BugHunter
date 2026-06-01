// This component file defines a reusable text input used by form screens.
// It standardizes controller wiring, icons, password hiding, suffix actions, and dark input styling.
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// CustomTextField wraps Flutter's TextField with the project's common decoration choices.
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
  });

  @override
  // The build method connects the supplied controller and visual options to a decorated TextField.
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: colors.textPrimary),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: colors.textMuted),
        suffixIcon: suffix,
        hintText: hint,
        hintStyle: TextStyle(color: colors.textMuted),
        filled: true,
        fillColor: colors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
