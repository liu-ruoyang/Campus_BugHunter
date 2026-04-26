import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  // 登录
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return "User not found";
        case 'wrong-password':
          return "Wrong password";
        case 'invalid-email':
          return "Invalid email";
        default:
          return e.message ?? "Login failed";
      }
    } catch (_) {
      return "Something went wrong";
    }
  }

  // 注册
  Future<String?> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return "Email already in use";
        case 'weak-password':
          return "Password too weak";
        case 'invalid-email':
          return "Invalid email";
        default:
          return e.message ?? "Register failed";
      }
    } catch (_) {
      return "Something went wrong";
    }
  }
}