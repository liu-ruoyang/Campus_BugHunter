import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostPage extends StatefulWidget {
  final VoidCallback onPosted;

  const PostPage({super.key, required this.onPosted});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  /// TECH STACK STATE
  final List<String> selectedStacks = [];
  final List<String> customStacks = [];
  bool isAddingStack = false;
  final TextEditingController stackController = TextEditingController();

  String selectedDifficulty = "Simple";

  double walletBalance = 0;

  final TextEditingController amountController = TextEditingController();

  final TextEditingController titleController = TextEditingController();

  final TextEditingController descriptionController = TextEditingController();

  final TextEditingController locationController = TextEditingController();

  @override
  void initState() {
    super.initState();

    loadWallet();
  }

  Future<void> loadWallet() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    if (doc.exists) {
      setState(() {
        walletBalance = (doc.data()?['wallet'] ?? 0).toDouble();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              heroSection(),
              const SizedBox(height: 35),
              issueTitleSection(),
              const SizedBox(height: 30),
              techStackSection(),
              const SizedBox(height: 30),
              descriptionSection(),
              const SizedBox(height: 30),
              locationSection(),
              const SizedBox(height: 30),
              difficultySection(),
              const SizedBox(height: 40),
              bountySection(),
              const SizedBox(height: 40),
              submitSection(),
            ],
          ),
        ),
      ),
    );
  }

  /// HERO
  Widget heroSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          "Post Bounty",
          style: TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 10),

        Text(
          "Specify your technical distress signal for the hunter network.",
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
      ],
    );
  }

  ///title
  Widget issueTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        buildLabel("ISSUE TITLE"),

        buildInput(
          controller: titleController,

          hint: "Enter issue title",

          height: 70,
        ),
      ],
    );
  }

  /// TECH STACK
  Widget techStackSection() {
    final stacks = ["C/C++", "Java", "Python", "Flutter", "Firebase"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        buildLabel("TECH STACK"),

        Wrap(
          spacing: 10,
          runSpacing: 10,

          children: [
            /// DEFAULT STACKS
            ...stacks.map((stack) {
              final active = selectedStacks.contains(stack);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (active) {
                      selectedStacks.remove(stack);
                    } else {
                      selectedStacks.add(stack);
                    }
                  });
                },

                child: buildChip(stack, active: active),
              );
            }),

            /// CUSTOM STACKS
            ...customStacks.map((stack) {
              return Stack(
                clipBehavior: Clip.none,

                children: [
                  buildChip(stack, active: true),

                  Positioned(
                    top: -6,
                    right: -6,

                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          customStacks.remove(stack);
                          selectedStacks.remove(stack);
                        });
                      },

                      child: Container(
                        width: 18,
                        height: 18,

                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),

                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),

            /// ADD STACK
            isAddingStack
                ? SizedBox(
                    width: 140,

                    child: TextField(
                      controller: stackController,

                      autofocus: true,

                      style: const TextStyle(color: Colors.white),

                      decoration: InputDecoration(
                        hintText: "Other",

                        hintStyle: const TextStyle(color: Colors.white38),

                        filled: true,

                        fillColor: const Color(0xFF2A2D38),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),

                          borderSide: BorderSide.none,
                        ),
                      ),

                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          setState(() {
                            customStacks.add(value.trim());

                            selectedStacks.add(value.trim());

                            isAddingStack = false;

                            stackController.clear();
                          });
                        }
                      },
                    ),
                  )
                : GestureDetector(
                    onTap: () {
                      setState(() {
                        isAddingStack = true;
                      });
                    },

                    child: buildChip("+ Add Stack"),
                  ),
          ],
        ),
      ],
    );
  }

  /// DESCRIPTION
  Widget descriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel("PROBLEM DESCRIPTION"),
        buildInput(
          controller: descriptionController,
          hint: "Describe the bug in technical detail...",
          height: 80,
        ),
      ],
    );
  }

  /// LOCATION
  Widget locationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        buildLabel("LOCATION"),

        buildInput(
          controller: locationController,
          hint: "e.g. Engineering Hall Room 302",
          height: 70,
        ),
      ],
    );
  }

  /// DIFFICULTY
  Widget difficultySection() {
    final difficulties = ["Simple", "Difficult", "Very Difficult", "Epic"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        buildLabel("ESTIMATED DIFFICULTY"),

        Wrap(
          spacing: 12,
          runSpacing: 12,

          children: difficulties.map((difficulty) {
            final active = selectedDifficulty == difficulty;

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedDifficulty = difficulty;
                });
              },

              child: buildDifficulty(difficulty, active: active),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// BOUNTY
  Widget bountySection() {
    return Container(
      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: const Color(0xFF1A1D28),

        borderRadius: BorderRadius.circular(24),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            "Bounty Amount",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 22),

          /// BALANCE CARD
          Container(
            padding: const EdgeInsets.all(20),

            decoration: BoxDecoration(
              color: const Color(0xFF262A36),

              borderRadius: BorderRadius.circular(18),
            ),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      "AVAILABLE BALANCE",
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "RM ${walletBalance.toStringAsFixed(2)}",

                      style: const TextStyle(
                        color: Color(0xFF00FF85),

                        fontSize: 34,

                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFF00FF85),
                  size: 42,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          /// AMOUNT INPUT
          buildLabel("BOUNTY AMOUNT"),

          SizedBox(
            height: 70,

            child: TextField(
              controller: amountController,

              keyboardType: TextInputType.number,

              style: const TextStyle(color: Colors.white),

              decoration: InputDecoration(
                hintText: "Enter amount",

                hintStyle: const TextStyle(color: Colors.white38),

                filled: true,

                fillColor: const Color(0xFF0B0E1A),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),

                  borderSide: BorderSide.none,
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),

                  borderSide: BorderSide.none,
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),

                  borderSide: const BorderSide(
                    color: Color(0xFF8B93FF),
                    width: 2,
                  ),
                ),

                contentPadding: const EdgeInsets.all(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// SUBMIT
  Widget submitSection() {
    return SizedBox(
      width: double.infinity,
      height: 70,

      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFA5B4FF),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),

        onPressed: createBounty,

        icon: const Icon(Icons.rocket_launch, color: Color(0xFF18206F)),

        label: const Text(
          "POST BOUNTY",
          style: TextStyle(
            color: Color(0xFF18206F),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  /// LABEL
  Widget buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),

      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF8B93FF),
          fontSize: 12,
          letterSpacing: 3,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// INPUT
  Widget buildInput({
    required String hint,
    required double height,
    TextEditingController? controller,
  }) {
    return SizedBox(
      height: height,

      child: TextField(
        controller: controller,

        maxLines: height > 100 ? null : 1,

        style: const TextStyle(color: Colors.white),

        decoration: InputDecoration(
          hintText: hint,

          hintStyle: const TextStyle(color: Colors.white38),

          filled: true,

          fillColor: const Color(0xFF0B0E1A),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),

            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),

            borderSide: BorderSide.none,
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),

            borderSide: const BorderSide(color: Color(0xFF8B93FF), width: 2),
          ),

          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  /// CHIP
  Widget buildChip(String text, {bool active = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),

      decoration: BoxDecoration(
        color: active ? const Color(0xFFC7CCFF) : const Color(0xFF2A2D38),

        borderRadius: BorderRadius.circular(12),
      ),

      child: Text(
        text,
        style: TextStyle(
          color: active ? const Color(0xFF18206F) : Colors.white70,

          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// DIFFICULTY
  Widget buildDifficulty(String text, {bool active = false}) {
    return Container(
      width: 170,
      height: 55,

      decoration: BoxDecoration(
        color: active ? const Color(0xFF373D68) : const Color(0xFF2A2D38),

        borderRadius: BorderRadius.circular(14),
      ),

      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  ///payment amount input
  Widget buildAmountInput() {
    return SizedBox(
      height: 70,

      child: TextField(
        controller: amountController,

        keyboardType: TextInputType.number,

        style: const TextStyle(color: Colors.white),

        decoration: InputDecoration(
          hintText: "Enter amount",

          hintStyle: const TextStyle(color: Colors.white38),

          filled: true,
          fillColor: const Color(0xFF0B0E1A),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),

            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),

            borderSide: BorderSide.none,
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),

            borderSide: const BorderSide(color: Color(0xFF8B93FF), width: 2),
          ),

          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  ///pay bounty function
  Future<void> createBounty() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final amount = double.tryParse(amountController.text) ?? 0;

    /// INVALID AMOUNT
    if (amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid amount")));

      return;
    }

    /// INSUFFICIENT BALANCE
    if (walletBalance < amount) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Insufficient balance")));

      return;
    }

    /// DEDUCT WALLET
    await FirebaseFirestore.instance.collection("users").doc(uid).update({
      "wallet": walletBalance - amount,
    });

    /// CREATE BOUNTY
    await FirebaseFirestore.instance.collection("bounties").add({
      "ownerId": uid,
      "hunterId": null,
      "title": titleController.text,
      "description": descriptionController.text,
      "location": locationController.text,
      "amount": amount,
      "platformFee": amount * 0.05,
      "hunterReceive": amount - (amount * 0.05),
      "techStacks": selectedStacks,
      "difficulty": selectedDifficulty,

      /// OPEN = nobody accepted yet
      "status": "NOT ACCEPTED",
      "escrow": true,
      "createdAt": FieldValue.serverTimestamp(),
    });

    /// UPDATE UI
    setState(() {
      walletBalance -= amount;
    });

    /// SUCCESS
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Bounty posted")));

    /// WAIT
    await Future.delayed(const Duration(milliseconds: 1500));

    /// BACK HOME
    widget.onPosted();
  }
}
