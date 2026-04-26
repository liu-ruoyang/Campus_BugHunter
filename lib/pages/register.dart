import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ✅ 引入组件
import '../components/textfield.dart';
import '../components/button.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final username = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();

  final auth = AuthService();

  bool obscure1 = true;
  bool obscure2 = true;
  bool loading = false;

  Future<void> handleRegister() async {
    /// double check password match
    if (password.text != confirmPassword.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    /// loading
    setState(() => loading = true);

    /// call （Firebase Auth）
    final error = await auth.register(email.text.trim(), password.text.trim());

    /// stop loading
    setState(() => loading = false);

    /// show result
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ?? "Register Success")));

    ///register success, save additional info to Firestore
    if (error == null) {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final uid = user.uid;

        ///unique username check
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          "username": username.text.trim(),
          "email": email.text.trim(),
          "gender": "prefer_not_to_say",
          "age": 0,
          "address": "",
          "wallet": 0,
          "requestCount": 0,
          "helperCount": 0,
          "createdAt": Timestamp.now(),
        });
      }

      /// 返回登录页
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                /// Back
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text("Back", style: TextStyle(color: Colors.white)),
                  ],
                ),

                const SizedBox(height: 10),

                /// Title
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                /// Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      /// Username
                      _label("USER NAME"),
                      CustomTextField(
                        controller: username,
                        hint: "Enter username",
                        icon: Icons.person,
                      ),

                      const SizedBox(height: 15),

                      /// Email
                      _label("EMAIL"),
                      CustomTextField(
                        controller: email,
                        hint: "Enter email",
                        icon: Icons.email,
                      ),

                      const SizedBox(height: 15),

                      /// Password
                      _label("PASSWORD"),
                      CustomTextField(
                        controller: password,
                        hint: "********",
                        icon: Icons.lock,
                        obscure: obscure1,
                        suffix: IconButton(
                          icon: Icon(
                            obscure1 ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () => setState(() => obscure1 = !obscure1),
                        ),
                      ),

                      const SizedBox(height: 15),

                      /// Confirm Password
                      _label("CONFIRM PASSWORD"),
                      CustomTextField(
                        controller: confirmPassword,
                        hint: "********",
                        icon: Icons.lock,
                        obscure: obscure2,
                        suffix: IconButton(
                          icon: Icon(
                            obscure2 ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () => setState(() => obscure2 = !obscure2),
                        ),
                      ),

                      const SizedBox(height: 15),

                      /// Info text
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Password must be at least 6 characters",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// Submit Button
                      CustomButton(
                        text: "SUBMIT",
                        isLoading: loading,
                        onPressed: handleRegister,
                      ),

                      const SizedBox(height: 15),

                      /// Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Already have an account? ",
                            style: TextStyle(color: Colors.grey),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              "Login",
                              style: TextStyle(color: Colors.blueAccent),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🔹 Label组件（统一风格）
  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text(
          text,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }
}
