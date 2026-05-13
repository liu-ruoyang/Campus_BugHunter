// This page file renders the wallet reload flow.
// It lets users enter or quick-select a top-up amount and submits the value through ReloadCubit.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/reload/reload_cubit.dart';
import '../bloc/reload/reload_state.dart';

// ReloadPage owns the top-up route and its amount text controller.
class ReloadPage extends StatefulWidget {
  const ReloadPage({super.key});

  @override
  State<ReloadPage> createState() => _ReloadPageState();
}

// _ReloadPageState manages the amount field, quick amount buttons, and reload action feedback.
class _ReloadPageState extends State<ReloadPage> {
  final amountController = TextEditingController();

  // This helper fills the amount text field with a quick-select value and moves the cursor to the end.
  void setAmount(double amount) {
    amountController.text = amount.toStringAsFixed(2);
    amountController.selection = TextSelection.fromPosition(
      TextPosition(offset: amountController.text.length),
    );
  }

  @override
  // The build method lays out the reload form, listens for reload results, and closes on success.
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReloadCubit(),
      child: BlocConsumer<ReloadCubit, ReloadState>(
        listenWhen: (previous, current) => previous.message != current.message,
        listener: (context, state) async {
          if (state.message != null) {
            await showMessage(context, state.message!);
          }
          if (state.status == ReloadStatus.success) {
            if (!context.mounted) return;
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          final isLoading = state.status == ReloadStatus.loading;

          return Scaffold(
            backgroundColor: const Color(0xFF020617),
            appBar: AppBar(
              title: const Text('Reload Wallet'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: Colors.white,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter amount to reload',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        prefixText: 'RM ',
                        prefixStyle: const TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        border: InputBorder.none,
                        hintText: '0.00',
                        hintStyle: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Quick Select',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      buildQuickOption(50),
                      buildQuickOption(100),
                      buildQuickOption(200),
                      buildQuickOption(500),
                      buildQuickOption(1000),
                    ],
                  ),
                  const SizedBox(height: 50),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () => context.read<ReloadCubit>().reloadWallet(
                              amountController.text,
                            ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Confirm Reload',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // This helper builds one quick-select button for a fixed reload amount.
  Widget buildQuickOption(double amount) {
    return ElevatedButton(
      onPressed: () => setAmount(amount),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        'RM ${amount.toStringAsFixed(0)}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  // This helper shows reload success or validation messages in an AlertDialog.
  Future<void> showMessage(BuildContext context, String msg) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Message'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
