// This utility file provides a shared dialog helper for simple user-facing messages.
// Pages can call it to show an AlertDialog without repeating the same dialog layout.
import 'package:flutter/material.dart';

// This function uses Flutter's dialog API to show a message and a single OK action.
Future<void> showMessage(BuildContext context, String msg) {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      content: Text(msg),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        ),
      ],
    ),
  );
}
