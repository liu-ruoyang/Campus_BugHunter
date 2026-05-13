// This page file is the authentication gate for the app.
// It uses AuthCubit state to decide whether the user should see the login page or the authenticated home page.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth/auth_cubit.dart';
import '../bloc/auth/auth_state.dart';
import 'login.dart';
import 'home.dart';

// This file acts as the main authentication gatekeeper for the entire application.
// It decides whether to show the login screen or the main homepage based on the user's current login status.
class Auth extends StatelessWidget {
  const Auth({super.key});

  @override
  // The build method listens to authentication state and switches between loading, login, and home UI.
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.initial ||
            state.status == AuthStatus.loading && state.user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return state.user != null ? const Homepage() : Login();
      },
    );
  }
}
