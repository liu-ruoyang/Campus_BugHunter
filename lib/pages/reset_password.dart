import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/textfield.dart';
import '../components/button.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  bool isLoading = false;

  Future<void> resetPassword() async {
    setState(() => isLoading = true);

    try {
      await _auth.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reset link sent! Check your email")),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = "Error";

      if (e.code == 'user-not-found') {
        message = "No user found";
      } else if (e.code == 'invalid-email') {
        message = "Invalid email";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617), // ✅ 和 login 一样
      body: Center(
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A), // ✅ 深色卡片
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              /// Title
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Reset Password",
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.white, // ✅ 必须白色
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              /// Subtitle
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Enter your email to receive reset link",
                  style: TextStyle(color: Colors.grey),
                ),
              ),

              const SizedBox(height: 25),

              /// Label
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "EMAIL",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),

              const SizedBox(height: 8),

              /// Email Input（组件化）
              CustomTextField(
                controller: emailController,
                hint: "name@email.com",
                icon: Icons.email,
              ),

              const SizedBox(height: 25),

              /// Button（组件化）
              CustomButton(
                text: "SEND RESET LINK",
                isLoading: isLoading,
                onPressed: resetPassword,
              ),

              const SizedBox(height: 15),

              /// Back to Login
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Back to Login",
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}