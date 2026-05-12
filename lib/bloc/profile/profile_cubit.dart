import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance,
      super(const ProfileState());

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> loadProfile() async {
    emit(state.copyWith(status: ProfileStatus.loading, clearMessage: true));

    try {
      final user = _auth.currentUser;
      if (user == null) {
        emit(
          state.copyWith(
            status: ProfileStatus.loaded,
            username: 'Guest',
            wallet: 0,
          ),
        );
        return;
      }

      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({
          'username': user.email ?? 'User',
          'email': user.email ?? '',
          'gender': 'prefer_not_to_say',
          'age': 0,
          'address': '',
          'wallet': 0,
          'createdAt': Timestamp.now(),
        });
      }

      final data = (await docRef.get()).data() ?? {};
      emit(
        state.copyWith(
          status: ProfileStatus.loaded,
          username: data['username'] ?? user.email ?? 'User',
          email: data['email'] ?? user.email ?? '',
          gender: _normalizeGender(data['gender']),
          age: (data['age'] ?? 0) is int
              ? data['age'] as int
              : int.tryParse('${data['age']}') ?? 0,
          address: data['address'] ?? '',
          wallet: (data['wallet'] ?? 0).toDouble(),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          username: 'Error',
          wallet: 0,
          message: 'Failed to load profile',
        ),
      );
    }
  }

  Future<void> saveProfile({
    required String username,
    required String gender,
    required String age,
    required String address,
    required String email,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          message: 'User not signed in',
        ),
      );
      return;
    }

    emit(state.copyWith(status: ProfileStatus.saving, clearMessage: true));
    try {
      await _firestore.collection('users').doc(uid).update({
        'username': username.trim(),
        'gender': gender,
        'age': int.tryParse(age) ?? 0,
        'address': address.trim(),
        'email': email.trim(),
      });

      emit(
        state.copyWith(
          status: ProfileStatus.success,
          username: username.trim(),
          gender: gender,
          age: int.tryParse(age) ?? 0,
          address: address.trim(),
          email: email.trim(),
          message: 'Profile updated',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          message: 'Failed to save profile',
        ),
      );
    }
  }

  String _normalizeGender(dynamic value) {
    if (value == 'male' || value == 'Male') return 'male';
    if (value == 'female' || value == 'Female') return 'female';
    return 'prefer_not_to_say';
  }
}
