// This cubit file handles wallet reload submissions.
// It validates the amount, updates the user's wallet balance, and records a transaction in Firestore.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'reload_state.dart';

// ReloadCubit keeps wallet top-up validation and Firestore writes out of the reload page UI.
class ReloadCubit extends Cubit<ReloadState> {
  ReloadCubit({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance,
      super(const ReloadState());

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // This method parses the entered amount, increments the user's wallet, and saves the top-up transaction.
  Future<void> reloadWallet(String amountText) async {
    final input = amountText.trim();
    if (input.isEmpty) {
      emit(
        state.copyWith(
          status: ReloadStatus.failure,
          message: 'Please enter an amount to reload.',
        ),
      );
      return;
    }

    final amount = double.tryParse(input);
    if (amount == null || amount <= 0) {
      emit(
        state.copyWith(
          status: ReloadStatus.failure,
          message: 'Please enter a valid positive number.',
        ),
      );
      return;
    }

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      emit(
        state.copyWith(
          status: ReloadStatus.failure,
          message: 'User not signed in',
        ),
      );
      return;
    }

    emit(state.copyWith(status: ReloadStatus.loading, clearMessage: true));
    try {
      await _firestore.collection('users').doc(uid).update({
        'wallet': FieldValue.increment(amount),
      });
      await _firestore.collection('transactions').add({
        'userId': uid,
        'amount': amount,
        'type': 'topup',
        'createdAt': Timestamp.now(),
      });

      emit(
        state.copyWith(
          status: ReloadStatus.success,
          message: 'Reload successful! RM ${amount.toStringAsFixed(2)} added.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ReloadStatus.failure,
          message: 'Something went wrong. Please try again.',
        ),
      );
    }
  }
}
