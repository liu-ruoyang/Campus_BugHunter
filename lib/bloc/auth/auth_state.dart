// This state file defines the authentication status model used by AuthCubit and authentication screens.
// It carries the current Firebase user, loading result, and one-time messages for UI feedback.
import 'package:firebase_auth/firebase_auth.dart';

// AuthStatus lists each phase the authentication flow can report to the UI.
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  success,
  failure,
}

// AuthState is an immutable snapshot of the current authentication flow and signed-in user.
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? message;

  const AuthState({this.status = AuthStatus.initial, this.user, this.message});

  // copyWith creates a new state while preserving fields that were not changed.
  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? message,
    bool clearMessage = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}
