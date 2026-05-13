// This component file defines a reusable full-width button for forms and actions.
// It standardizes the loading state, shape, and color treatment used across authentication-style screens.
import 'package:flutter/material.dart';

// CustomButton uses an ElevatedButton and optionally replaces its label with a spinner while work is in progress.
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  // The build method composes the button container, disabled loading behavior, and visible label or progress indicator.
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue, // ✅ 蓝色按钮
          foregroundColor: Colors.white, // ✅ 文字白色
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white) // ✅ 更统一
            : Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
