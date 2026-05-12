import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance,
      super(const AuthState()) {
    _authSubscription = _auth.authStateChanges().listen(_onAuthChanged);
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  late final StreamSubscription<User?> _authSubscription;

  void _onAuthChanged(User? user) {
    emit(
      AuthState(
        status: user == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated,
        user: user,
      ),
    );
  }

  Future<void> login(String email, String password) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          message: 'Please fill all fields',
        ),
      );
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading, clearMessage: true));
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      emit(
        state.copyWith(status: AuthStatus.success, message: 'Login Success'),
      );
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(status: AuthStatus.failure, message: _authError(e)));
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          message: 'Something went wrong',
        ),
      );
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (password != confirmPassword) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          message: 'Passwords do not match',
        ),
      );
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading, clearMessage: true));
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = credential.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'username': username.trim(),
          'email': email.trim(),
          'gender': 'prefer_not_to_say',
          'age': 0,
          'address': '',
          'wallet': 0,
          'requestCount': 0,
          'helperCount': 0,
          'createdAt': Timestamp.now(),
        });
      }

      emit(
        state.copyWith(status: AuthStatus.success, message: 'Register Success'),
      );
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(status: AuthStatus.failure, message: _authError(e)));
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          message: 'Something went wrong',
        ),
      );
    }
  }

  Future<void> resetPassword(String email) async {
    emit(state.copyWith(status: AuthStatus.loading, clearMessage: true));
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      emit(
        state.copyWith(
          status: AuthStatus.success,
          message: 'Reset link sent! Check your email',
        ),
      );
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(status: AuthStatus.failure, message: _authError(e)));
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      emit(
        state.copyWith(status: AuthStatus.success, message: 'Account deleted'),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          message: 'Please re-login before delete',
        ),
      );
    }
  }

  String _authError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'User not found';
      case 'wrong-password':
        return 'Wrong password';
      case 'invalid-email':
        return 'Invalid email';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'weak-password':
        return 'Password too weak';
      default:
        return e.message ?? 'Authentication failed';
    }
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
