// This service centralizes simple Firebase Authentication calls for login and registration.
// It wraps Firebase errors into user-facing English messages for the authentication screens.
import 'package:firebase_auth/firebase_auth.dart';

// AuthService uses FirebaseAuth directly to keep basic authentication calls reusable.
class AuthService {
  final _auth = FirebaseAuth.instance;

  // This method signs in with trimmed email and password values, then maps Firebase login errors to readable messages.
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

  // This method creates a Firebase account and returns validation or registration errors as strings.
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
