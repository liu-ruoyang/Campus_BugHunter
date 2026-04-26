import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// This page is dedicated to showing the user's wallet details, including their current balance and a history of their transactions.
class WalletPage extends StatefulWidget {
  // We require the current wallet balance to be passed into this page when it is opened so we can display it immediately.
  final double wallet;

  const WalletPage({super.key, required this.wallet});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {

  // We grab the unique identifier of the currently logged in user from Firebase Authentication so we can filter and save their specific transactions.
  final uid = FirebaseAuth.instance.currentUser!.uid;

  // This asynchronous function creates a new record in the database whenever a user tops up or withdraws money.
  // It saves the user ID, the amount involved, the type of transaction, and the exact time it happened.
  Future<void> addTransaction(double amount, String type) async {
    await FirebaseFirestore.instance.collection('transactions').add({
      'userId': uid,
      'amount': amount,
      'type': type,
      'createdAt': Timestamp.now(),
    });
  }

  // A standard helper function to display simple pop-up alert dialogs to confirm actions like topping up or withdrawing.
  void showMessage(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Message"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // We use a Scaffold to structure this page with a light grey background for a clean financial look.
    return Scaffold(
      backgroundColor: Colors.grey[100],

      // The top app bar gives the page a clean white header with black text indicating the page title.
      appBar: AppBar(
        title: Text("Wallet"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),

      body: Column(
        children: [

          SizedBox(height: 30),

          // This section prominently displays the current wallet balance passed from the previous screen, formatted to two decimal places in RM.
          Text(
            "RM ${widget.wallet.toStringAsFixed(2)}",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 20),

          // We use a row to place the Top Up and Withdraw simulation buttons side by side evenly across the screen.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [

              ElevatedButton(
                onPressed: () async {
                  // This simulates adding funds. It logs the transaction in the database and shows a confirmation message.
                  await addTransaction(100, "topup");
                  showMessage("Top Up +100");
                },
                child: Text("Top Up"),
              ),

              ElevatedButton(
                onPressed: () async {
                  // This simulates removing funds. It logs a negative amount transaction and shows a confirmation.
                  await addTransaction(-50, "withdraw");
                  showMessage("Withdraw -50");
                },
                child: Text("Withdraw"),
              ),
            ],
          ),

          SizedBox(height: 30),

          // This is a simple section title letting the user know the list below contains their past transactions.
          Padding(
            padding: EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Transaction Record",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // We use an Expanded widget so the transaction list takes up all the remaining vertical space on the screen without overflowing.
          // Inside, we use a StreamBuilder which creates a live, real-time connection to the Firestore database.
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // We listen specifically to the transactions collection, filter it so we only see records belonging to the current user, and order them newest first.
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('userId', isEqualTo: uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {

                // While we wait for the initial data to load from the cloud, we show a spinning progress circle in the center.
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                // If the database successfully connects but finds zero records for this user, we show a friendly empty state message.
                if (docs.isEmpty) {
                  return Center(child: Text("No transactions"));
                }

                // If we have data, we build a scrollable list of items to display each transaction.
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index];
                    double amount = data['amount'];

                    // Each transaction is displayed as a list tile.
                    // It uses a green downward arrow for money coming in (positive amounts) and a red upward arrow for money going out (negative amounts).
                    // The text also dynamically formats the amount with a plus or minus sign and the RM currency label.
                    return ListTile(
                      leading: Icon(
                        amount > 0 ? Icons.arrow_downward : Icons.arrow_upward,
                        color: amount > 0 ? Colors.green : Colors.red,
                      ),
                      title: Text(
                        amount > 0
                            ? "+RM ${amount.toStringAsFixed(2)}"
                            : "-RM ${amount.abs().toStringAsFixed(2)}",
                      ),
                      subtitle: Text(data['type']),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}