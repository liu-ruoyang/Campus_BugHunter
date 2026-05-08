import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_post.dart';

class RequestRecordPage extends StatelessWidget {
  const RequestRecordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),

      appBar: appBarSection(),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("bounties")
            .where("ownerId", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .snapshots(),

        builder: (context, snapshot) {
          /// LOADING
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          /// EMPTY
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No Requests Yet",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Column(
              children: docs.map((doc) {
                final data = doc.data();
                final docId = doc.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),

                  child: requestCard(context, data, docId),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  /// APP BAR
  PreferredSizeWidget appBarSection() {
    return AppBar(
      backgroundColor: const Color(0xFF12172A),

      foregroundColor: Colors.white,

      elevation: 2,

      title: const Text(
        "Request Record",

        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// REQUEST CARD
  Widget requestCard(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
  ) {
    final status = (data['status'] ?? "").toString().toUpperCase();

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: const Color(0xFF1A1D28),

        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          /// LEFT CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                /// TITLE
                Text(
                  data['title'] ?? "No Title",

                  style: const TextStyle(
                    color: Colors.white,

                    fontSize: 22,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 14),

                /// AMOUNT
                Text(
                  "RM ${(data['amount'] ?? 0).toString()}",

                  style: const TextStyle(
                    color: Color(0xFF00FF85),

                    fontSize: 18,

                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 18),

                /// STATUS
                GestureDetector(
                  onTap: status == "NOT ACCEPTED"
                      ? () async {
                          final confirm = await showDialog(
                            context: context,

                            builder: (_) {
                              return AlertDialog(
                                backgroundColor: const Color(0xFF1A1D28),

                                title: const Text(
                                  "Complete Request?",

                                  style: TextStyle(color: Colors.white),
                                ),

                                content: const Text(
                                  "Are you sure this request has been completed?",

                                  style: TextStyle(color: Colors.white70),
                                ),

                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context, false);
                                    },

                                    child: const Text("Cancel"),
                                  ),

                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),

                                    onPressed: () {
                                      Navigator.pop(context, true);
                                    },

                                    child: const Text("Confirm"),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirm == true) {
                            final bountyRef = FirebaseFirestore.instance
                                .collection("bounties")
                                .doc(docId);

                            final bountySnap = await bountyRef.get();

                            final bountyData = bountySnap.data()!;

                            final hunterId = bountyData['hunterId'];

                            final ownerId = bountyData['ownerId'];

                            final amount = (bountyData['amount'] ?? 0)
                                .toDouble();

                            final platformFee = (bountyData['platformFee'] ?? 0)
                                .toDouble();

                            final hunterReceive = amount - platformFee;

                            /// NO HUNTER
                            if (hunterId == null) {
                              final ownerRef = FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(ownerId);

                              final ownerSnap = await ownerRef.get();

                              final wallet = (ownerSnap.data()?['wallet'] ?? 0)
                                  .toDouble();

                              /// REFUND
                              await ownerRef.update({
                                "wallet": wallet + amount,
                              });
                            }
                            /// PAY HUNTER
                            else {
                              final hunterRef = FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(hunterId);

                              final hunterSnap = await hunterRef.get();

                              final wallet = (hunterSnap.data()?['wallet'] ?? 0)
                                  .toDouble();

                              await hunterRef.update({
                                "wallet": wallet + hunterReceive,
                              });
                            }

                            /// UPDATE STATUS
                            await bountyRef.update({"status": "COMPLETED"});
                          }
                        }
                      : null,

                  child: statusTag(status),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          /// RIGHT BUTTONS
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 20),

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  /// DETAILS
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B93FF),
                      minimumSize: const Size(110, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (_) =>
                              EditPostPage(docId: docId, data: data),
                        ),
                      );
                    },

                    child: const Text(
                      "Details",

                      style: TextStyle(color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// CANCEL
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: status == "COMPLETED"
                          ? Colors.grey
                          : Colors.red,

                      minimumSize: const Size(110, 45),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    onPressed: status == "COMPLETED"
                        ? null
                        : () async {
                            await cancelBounty(context, docId, data);
                          },

                    child: const Text(
                      "Cancel",

                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// cancel bounty
  Future<void> cancelBounty(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final amount = (data['amount'] ?? 0).toDouble();

    final userRef = FirebaseFirestore.instance.collection("users").doc(uid);

    final userSnap = await userRef.get();

    final wallet = (userSnap.data()?['wallet'] ?? 0).toDouble();

    /// REFUND FULL AMOUNT
    await userRef.update({"wallet": wallet + amount});

    /// DELETE BOUNTY
    await FirebaseFirestore.instance.collection("bounties").doc(docId).delete();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Request cancelled")));
  }

  /// STATUS TAG
  Widget statusTag(String text) {
    Color color;
    switch (text) {
      case "NOT ACCEPTED":
        color = Colors.red;
        break;
      case "IN PROGRESS":
        color = Colors.orange;
        break;
      case "COMPLETED":
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

      decoration: BoxDecoration(
        color: color,

        borderRadius: BorderRadius.circular(30),
      ),

      child: Text(
        text,

        style: const TextStyle(
          color: Colors.white,

          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
