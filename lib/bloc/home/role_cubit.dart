import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum UserRole { requester, hunter }

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

  static UserRole fromStorage(dynamic value) {
    return value == 'hunter' ? UserRole.hunter : UserRole.requester;
  }
}

class RoleCubit extends Cubit<UserRole> {
  RoleCubit({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance,
      super(UserRole.requester);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> loadRole() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    emit(UserRoleLabel.fromStorage(doc.data()?['role']));
  }

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
