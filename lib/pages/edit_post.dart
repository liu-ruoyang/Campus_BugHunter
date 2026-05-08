import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditPostPage extends StatefulWidget {
  final String docId;

  final Map<String, dynamic> data;

  const EditPostPage({super.key, required this.docId, required this.data});

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  /// CONTROLLERS
  final TextEditingController titleController = TextEditingController();

  final TextEditingController descriptionController = TextEditingController();

  final TextEditingController locationController = TextEditingController();

  final TextEditingController amountController = TextEditingController();

  final TextEditingController customStackController = TextEditingController();
  bool showCustomInput = false;

  List<String> customStacks = [];
  final TextEditingController stackController = TextEditingController();

  bool isAddingStack = false;

  /// TECH STACK
  List<String> selectedStacks = [];

  /// DIFFICULTY
  String selectedDifficulty = "";

  @override
  void initState() {
    super.initState();

    /// LOAD DATA
    titleController.text = widget.data['title'] ?? "";

    descriptionController.text = widget.data['description'] ?? "";

    locationController.text = widget.data['location'] ?? "";

    amountController.text = widget.data['amount'].toString();

    /// LOAD STACKS
    selectedStacks = List<String>.from(widget.data['techStacks'] ?? []);

    /// DEFAULT STACKS
    final defaultStacks = ["C/C++", "Java", "Python", "Flutter", "Firebase"];

    /// LOAD CUSTOM STACKS
    customStacks = selectedStacks
        .where((stack) => !defaultStacks.contains(stack))
        .toList();

    /// DIFFICULTY
    selectedDifficulty = widget.data['difficulty'] ?? "";
  }

  /// UPDATE
  Future<void> updateBounty() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final amount = double.tryParse(amountController.text) ?? 0;

    /// OLD AMOUNT
    final oldAmount = (widget.data['amount'] ?? 0).toDouble();

    /// DIFFERENCE
    final diff = amount - oldAmount;

    final userRef = FirebaseFirestore.instance.collection("users").doc(uid);

    final userSnap = await userRef.get();

    final wallet = (userSnap.data()?['wallet'] ?? 0).toDouble();

    /// NEED EXTRA MONEY
    if (diff > 0) {
      if (wallet < diff) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Insufficient balance")));

        return;
      }

      /// DEDUCT
      await userRef.update({"wallet": wallet - diff});
    }

    /// REFUND
    if (diff < 0) {
      await userRef.update({"wallet": wallet + diff.abs()});
    }

    /// UPDATE BOUNTY
    await FirebaseFirestore.instance
        .collection("bounties")
        .doc(widget.docId)
        .update({
          "title": titleController.text,

          "description": descriptionController.text,

          "location": locationController.text,

          "amount": amount,

          "platformFee": amount * 0.05,

          "hunterReceive": amount - (amount * 0.05),

          "techStacks": selectedStacks,

          "difficulty": selectedDifficulty,
        });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Updated")));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),

      appBar: appBarSection(),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            issueTitleSection(),
            const SizedBox(height: 20),

            descriptionSection(),
            const SizedBox(height: 20),

            techStackSection(),
            const SizedBox(height: 20),

            difficultySection(),
            const SizedBox(height: 20),

            locationSection(),
            const SizedBox(height: 20),

            amountSection(),
            const SizedBox(height: 30),

            updateButton(),
          ],
        ),
      ),
    );
  }

  /// APP BAR
  PreferredSizeWidget appBarSection() {
    return AppBar(
      backgroundColor: const Color(0xFF12172A),

      foregroundColor: Colors.white,

      elevation: 0,

      title: const Text(
        "Edit Request",

        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// TITLE
  Widget issueTitleSection() {
    return inputSection("TITLE", titleController, 70);
  }

  /// DESCRIPTION
  Widget descriptionSection() {
    return inputSection("DESCRIPTION", descriptionController, 70);
  }

  /// LOCATION
  Widget locationSection() {
    return inputSection("LOCATION", locationController, 70);
  }

  /// AMOUNT
  Widget amountSection() {
    return inputSection("AMOUNT", amountController, 70);
  }

  /// TECH STACK
  Widget techStackSection() {
    final stacks = ["C/C++", "Java", "Python", "Flutter", "Firebase"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        buildLabel("TECH STACK"),

        const SizedBox(height: 14),

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

  /// DIFFICULTY
  Widget difficultySection() {
    final difficulties = ["Simple", "Difficult", "Very Difficult", "Epic"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        buildLabel("DIFFICULTY"),

        const SizedBox(height: 14),

        Align(
          alignment: Alignment.centerLeft,

          child: Wrap(
            spacing: 10,
            runSpacing: 10,

            children: difficulties.map((difficulty) {
              final active = selectedDifficulty == difficulty;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDifficulty = difficulty;
                  });
                },

                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),

                  decoration: BoxDecoration(
                    color: active ? Colors.orange : const Color(0xFF1A1D28),

                    borderRadius: BorderRadius.circular(30),
                  ),

                  child: Text(
                    difficulty,

                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// UPDATE BUTTON
  Widget updateButton() {
    final status = (widget.data['status'] ?? "").toString().toUpperCase();

    return SizedBox(
      width: double.infinity,
      height: 60,

      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: status == "COMPLETED"
              ? Colors.grey
              : const Color(0xFF8B93FF),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        onPressed: status == "COMPLETED" ? null : updateBounty,

        child: const Text(
          "UPDATE",

          style: TextStyle(
            color: Colors.white,

            fontSize: 18,

            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// INPUT SECTION
  Widget inputSection(
    String label,
    TextEditingController controller,
    double height,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        buildLabel(label),

        const SizedBox(height: 10),

        SizedBox(
          height: height,

          child: TextField(
            controller: controller,

            maxLines: height > 100 ? null : 1,

            style: const TextStyle(color: Colors.white),

            decoration: InputDecoration(
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
    );
  }

  /// LABEL
  Widget buildLabel(String text) {
    return Text(
      text,

      style: const TextStyle(color: Color(0xFF8B93FF), letterSpacing: 2),
    );
  }

  /// CHIP
  Widget buildChip(String text, {bool active = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),

      decoration: BoxDecoration(
        color: active ? const Color(0xFF8B93FF) : const Color(0xFF1A1D28),

        borderRadius: BorderRadius.circular(30),
      ),

      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}
