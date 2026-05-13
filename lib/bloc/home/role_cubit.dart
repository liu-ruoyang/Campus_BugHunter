// This cubit file manages whether the signed-in user is acting as a requester or hunter.
// The selected role is mirrored to Firestore so the app can restore it across sessions.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// UserRole defines the two role modes supported by the app.
enum UserRole { requester, hunter }

// UserRoleLabel converts role values between UI labels, Firestore storage, and opposite role selection.
extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.requester:
        return 'Requester';
      case UserRole.hunter:
        return 'Hunter';
    }
  }

  String get storageValue {
    switch (this) {
      case UserRole.requester:
        return 'requester';
      case UserRole.hunter:
        return 'hunter';
    }
  }

  UserRole get opposite {
    switch (this) {
      case UserRole.requester:
        return UserRole.hunter;
      case UserRole.hunter:
        return UserRole.requester;
    }
  }

  // This helper reads the Firestore role string and falls back to requester when unknown.
  static UserRole fromStorage(dynamic value) {
    return value == 'hunter' ? UserRole.hunter : UserRole.requester;
  }
}

// RoleCubit loads and switches the current user role for role-specific pages and actions.
class RoleCubit extends Cubit<UserRole> {
  RoleCubit({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance,
      super(UserRole.requester);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // This method loads the saved role from the current user's Firestore document.
  Future<void> loadRole() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    emit(UserRoleLabel.fromStorage(doc.data()?['role']));
  }

  // This method toggles the role locally and persists the new role to Firestore.
  Future<void> switchRole() async {
    final nextRole = state.opposite;
    emit(nextRole);

    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'role': nextRole.storageValue,
    }, SetOptions(merge: true));
  }
}
