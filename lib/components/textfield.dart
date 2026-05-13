// This component file defines a reusable text input used by form screens.
// It standardizes controller wiring, icons, password hiding, suffix actions, and dark input styling.
import 'package:flutter/material.dart';

// CustomTextField wraps Flutter's TextField with the project's common decoration choices.
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix; // ✅ 加这个

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix, // ✅ 加这个
  });

  @override
  // The build method connects the supplied controller and visual options to a decorated TextField.
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixIcon: suffix, // ✅ 加这个
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
