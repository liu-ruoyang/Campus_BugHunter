import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_cubit.dart';
import '../bloc/auth/auth_state.dart';
import 'register.dart';
import 'reset_password.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final email = TextEditingController();
  final password = TextEditingController();

  bool obscure = true;

  /// 登录
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, current) => previous.message != current.message,
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        final loading = state.status == AuthStatus.loading;
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF020617)],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      /// LOGO
                      Image.asset(
                        'assets/images/CampusBugHunter_icon.png',
                        width: 90,
                        height: 90,
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        "Welcome back, Hunter/Requester!",
                        style: TextStyle(fontSize: 15, color: Colors.white70),
                      ),

                      const SizedBox(height: 35),

                      /// CARD
                      Container(
                        width: 350,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            /// TITLE
                            const Align(
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

                            const SizedBox(height: 25),

                            /// EMAIL
                            TextField(
                              controller: email,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.email,
                                  color: Colors.grey,
                                ),
                                hintText: "Email",
                                hintStyle: const TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: Colors.grey[900],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),

                            const SizedBox(height: 15),

                            /// PASSWORD + FORGOT
                            Column(
                              children: [
                                /// PASSWORD INPUT
                                TextField(
                                  controller: password,
                                  obscureText: obscure,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(
                                      Icons.lock,
                                      color: Colors.grey,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        obscure
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          obscure = !obscure;
                                        });
                                      },
                                    ),
                                    hintText: "Password",
                                    hintStyle: const TextStyle(
                                      color: Colors.grey,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[900],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),

                                ///FORGOT PASSWORD
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ResetPasswordPage(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "Forgot password?",
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            /// REGISTER
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Text(
                                  "Don't have an account? ",
                                  style: TextStyle(color: Colors.white),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => Register(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Register",
                                    style: TextStyle(color: Colors.blueAccent),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            /// LOGIN BUTTON
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: loading
                                    ? null
                                    : () => context.read<AuthCubit>().login(
                                        email.text,
                                        password.text,
                                      ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  backgroundColor: Colors.blue,
                                ),
                                child: loading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text(
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
