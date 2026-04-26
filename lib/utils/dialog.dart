import 'package:flutter/material.dart';

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