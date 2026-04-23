import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  /// 登录
  Future<void> login() async {
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      await showMessage("Please fill all fields");
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await showMessage("Login Success");

    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = "User not found";
          break;
        case 'wrong-password':
          errorMessage = "Wrong password";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email";
          break;
        case 'invalid-credential':
          errorMessage = "Email or password incorrect";
          break;
        default:
          errorMessage = e.message ?? "Login Failed";
      }

      await showMessage(errorMessage);

    } catch (e) {
      await showMessage("Something went wrong");
    }

    setState(() => isLoading = false);
  }

  /// 忘记密码
  Future<void> resetPassword(String email) async {
    if (email.isEmpty) {
      await showMessage("Please enter your email");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.trim(),
      );

      await showMessage("Password reset email sent");

    } on FirebaseAuthException catch (e) {
      await showMessage(e.message ?? "Error");
    }
  }

  /// 输入邮箱弹窗
  void showResetDialog() {
    TextEditingController resetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Reset Password"),
        content: TextField(
          controller: resetController,
          decoration: InputDecoration(
            hintText: "Enter your email",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await resetPassword(resetController.text);
            },
            child: Text("Send"),
          ),
        ],
      ),
    );
  }

  /// 提示弹窗
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

                    /// 标题
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    SizedBox(height: 25),

                    /// Email
                    TextField(
                      controller: emailController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.email, color: Colors.grey),
                        hintText: "Email",
                        hintStyle: TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    SizedBox(height: 15),

                    /// Password
                    Column(
                      children: [
                        TextField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.lock, color: Colors.grey),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                            ),
                            hintText: "Password",
                            hintStyle: TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[900],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        /// 🔥 Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: showResetDialog,
                            child: Text(
                              "Forgot password?",
                              style: TextStyle(color: Colors.blueAccent),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 10),

                    /// 注册
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => Register()),
                          );
                        },
                        child: Text(
                          "Register an account ?",
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    /// 登录按钮
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : login,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue,
                        ),
                        child: isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                          "LOGIN",
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