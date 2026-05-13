// This page file renders a wallet balance and transaction history view.
// It provides WalletCubit, watches transaction records, and shows basic top-up or withdraw actions.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/wallet/wallet_cubit.dart';
import '../bloc/wallet/wallet_state.dart';

// WalletPage receives the current wallet amount and creates the wallet bloc scope.
class WalletPage extends StatelessWidget {
  final double wallet;

  const WalletPage({super.key, required this.wallet});

  @override
  // The build method provides WalletCubit and passes the visible balance into the wallet view.
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WalletCubit(),
      child: _WalletView(wallet: wallet),
    );
  }
}

// _WalletView renders wallet controls, transaction stream data, and feedback dialogs.
class _WalletView extends StatelessWidget {
  final double wallet;

  const _WalletView({required this.wallet});

  @override
  // The build method shows balance actions and a live Firestore transaction list.
  Widget build(BuildContext context) {
    final cubit = context.read<WalletCubit>();

    return BlocListener<WalletCubit, WalletState>(
      listenWhen: (previous, current) => previous.message != current.message,
      listener: (context, state) {
        if (state.message != null) {
          showMessage(context, state.message!);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('Wallet'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: Column(
          children: [
            const SizedBox(height: 30),
            Text(
              'RM ${wallet.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => cubit.addTransaction(100, 'topup'),
                  child: const Text('Top Up'),
                ),
                ElevatedButton(
                  onPressed: () => cubit.addTransaction(-50, 'withdraw'),
                  child: const Text('Withdraw'),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Transaction Record',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<TransactionSnapshot>(
                stream: cubit.watchTransactions(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('No transactions'));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final amount = (data['amount'] ?? 0).toDouble();

                      return ListTile(
                        leading: Icon(
                          amount > 0
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: amount > 0 ? Colors.green : Colors.red,
                        ),
                        title: Text(
                          amount > 0
                              ? '+RM ${amount.toStringAsFixed(2)}'
                              : '-RM ${amount.abs().toStringAsFixed(2)}',
                        ),
                        subtitle: Text(data['type'] ?? ''),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // This helper displays wallet action messages in a simple dialog.
  void showMessage(BuildContext context, String msg) {
    showDialog(
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
