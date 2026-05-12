import 'package:firebase_auth/firebase_auth.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  success,
  failure,
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? message;

  const AuthState({this.status = AuthStatus.initial, this.user, this.message});

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
