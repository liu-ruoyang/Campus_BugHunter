import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool isLoading = false;
  bool obscure1 = true;
  bool obscure2 = true;

  /// 🔥 注册逻辑
  Future<void> register() async {
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmController.text.isEmpty ||
        usernameController.text.isEmpty) {
      await showMessage("Please fill all fields");
      return;
    }

    if (passwordController.text != confirmController.text) {
      await showMessage("Passwords do not match");
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1️⃣ 创建账号（Auth）
      UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;

      // 2️⃣ 写入 Firestore（users 表）
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({
        'username': usernameController.text,
        'email': user.email, // 🔥 自动带上 email
        'helperCount': 0,
        'requestCount': 0,
        'wallet': 0,
        'createdAt': Timestamp.now(),
      });

      // 3️⃣ 成功提示（必须点击）
      await showMessage("Register Success");

      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = "Email already in use";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email";
          break;
        case 'weak-password':
          errorMessage = "Password must be at least 6 characters";
          break;
        default:
          errorMessage = e.message ?? "Register Failed";
      }

      await showMessage(errorMessage);

    } catch (e) {
      await showMessage("Something went wrong");
    }

    setState(() => isLoading = false);
  }

  /// 🔥 弹窗提示（稳定）
  Future<void> showMessage(String message) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Message"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  InputDecoration inputStyle(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.grey),
      suffixIcon: suffix,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.grey[900],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF020617)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: 350,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [

                    /// 返回
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),

                    /// 标题
                    Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 25),

                    /// 用户名
                    TextField(
                      controller: usernameController,
                      style: TextStyle(color: Colors.white),
                      decoration: inputStyle("Username", Icons.person),
                    ),

                    SizedBox(height: 15),

                    /// 邮箱
                    TextField(
                      controller: emailController,
                      style: TextStyle(color: Colors.white),
                      decoration: inputStyle("Email", Icons.email),
                    ),

                    SizedBox(height: 15),

                    /// 密码
                    TextField(
                      controller: passwordController,
                      obscureText: obscure1,
                      style: TextStyle(color: Colors.white),
                      decoration: inputStyle(
                        "Password",
                        Icons.lock,
                        suffix: IconButton(
                          icon: Icon(
                            obscure1
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() => obscure1 = !obscure1);
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: 15),

                    /// 确认密码
                    TextField(
                      controller: confirmController,
                      obscureText: obscure2,
                      style: TextStyle(color: Colors.white),
                      decoration: inputStyle(
                        "Confirm Password",
                        Icons.security,
                        suffix: IconButton(
                          icon: Icon(
                            obscure2
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() => obscure2 = !obscure2);
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: 25),

                    /// 注册按钮
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : register,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue,
                        ),
                        child: isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                          "SUBMIT",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}