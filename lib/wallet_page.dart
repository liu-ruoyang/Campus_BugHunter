import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalletPage extends StatefulWidget {
  final double wallet;

  const WalletPage({super.key, required this.wallet});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {

  final uid = FirebaseAuth.instance.currentUser!.uid;

  /// 🔥 写入交易记录
  Future<void> addTransaction(double amount, String type) async {
    await FirebaseFirestore.instance.collection('transactions').add({
      'userId': uid,
      'amount': amount,
      'type': type,
      'createdAt': Timestamp.now(),
    });
  }

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
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: Text("Wallet"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),

      body: Column(
        children: [

          SizedBox(height: 30),

          /// 💰 金额
          Text(
            "\$${widget.wallet.toStringAsFixed(2)}",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 20),

          /// 🔥 按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [

              ElevatedButton(
                onPressed: () async {
                  await addTransaction(100, "topup");
                  showMessage("Top Up +100");
                },
                child: Text("Top Up"),
              ),

              ElevatedButton(
                onPressed: () async {
                  await addTransaction(-50, "withdraw");
                  showMessage("Withdraw -50");
                },
                child: Text("Withdraw"),
              ),
            ],
          ),

          SizedBox(height: 30),

          /// 🔥 交易记录标题
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

          /// 🔥 交易列表（实时）
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('userId', isEqualTo: uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return Center(child: Text("No transactions"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index];

                    double amount = data['amount'];

                    return ListTile(
                      leading: Icon(
                        amount > 0 ? Icons.arrow_downward : Icons.arrow_upward,
                        color: amount > 0 ? Colors.green : Colors.red,
                      ),
                      title: Text(
                        amount > 0
                            ? "+\$${amount.toStringAsFixed(2)}"
                            : "-\$${amount.abs().toStringAsFixed(2)}",
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