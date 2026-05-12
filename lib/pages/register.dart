import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth/auth_cubit.dart';
import '../bloc/auth/auth_state.dart';
import '../components/button.dart';
import '../components/textfield.dart';

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

  bool obscure1 = true;
  bool obscure2 = true;

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
        if (state.status == AuthStatus.success) {
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        final loading = state.status == AuthStatus.loading;

        return Scaffold(
          backgroundColor: const Color(0xFF020617),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Back',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          _label('USER NAME'),
                          CustomTextField(
                            controller: username,
                            hint: 'Enter username',
                            icon: Icons.person,
                          ),
                          const SizedBox(height: 15),
                          _label('EMAIL'),
                          CustomTextField(
                            controller: email,
                            hint: 'Enter email',
                            icon: Icons.email,
                          ),
                          const SizedBox(height: 15),
                          _label('PASSWORD'),
                          CustomTextField(
                            controller: password,
                            hint: '********',
                            icon: Icons.lock,
                            obscure: obscure1,
                            suffix: IconButton(
                              icon: Icon(
                                obscure1
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () =>
                                  setState(() => obscure1 = !obscure1),
                            ),
                          ),
                          const SizedBox(height: 15),
                          _label('CONFIRM PASSWORD'),
                          CustomTextField(
                            controller: confirmPassword,
                            hint: '********',
                            icon: Icons.lock,
                            obscure: obscure2,
                            suffix: IconButton(
                              icon: Icon(
                                obscure2
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () =>
                                  setState(() => obscure2 = !obscure2),
                            ),
                          ),
                          const SizedBox(height: 15),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Password must be at least 6 characters',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          CustomButton(
                            text: 'SUBMIT',
                            isLoading: loading,
                            onPressed: () => context.read<AuthCubit>().register(
                              username: username.text,
                              email: email.text,
                              password: password.text,
                              confirmPassword: confirmPassword.text,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Already have an account? ',
                                style: TextStyle(color: Colors.grey),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text(
                                  'Login',
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
      },
    );
  }

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
