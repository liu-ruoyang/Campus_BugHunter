// This cubit file manages wallet transaction history and manual transaction records.
// It watches the signed-in user's transactions and can add a transaction document to Firestore.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'wallet_state.dart';

// WalletCubit exposes transaction streams and wallet action state to the wallet page.
class WalletCubit extends Cubit<WalletState> {
  WalletCubit({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance,
      super(const WalletState());

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // This getter returns the current user's id for Firestore transaction queries.
  String get uid => _auth.currentUser!.uid;

  // This stream watches the current user's transactions ordered from newest to oldest.
  Stream<TransactionSnapshot> watchTransactions() {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // This method records a transaction and emits a simple success or failure message.
  Future<void> addTransaction(double amount, String type) async {
    emit(state.copyWith(status: WalletStatus.loading, clearMessage: true));
    try {
      await _firestore.collection('transactions').add({
        'userId': uid,
        'amount': amount,
        'type': type,
        'createdAt': Timestamp.now(),
      });
      emit(
        state.copyWith(
          status: WalletStatus.success,
          message: amount > 0 ? 'Top Up +100' : 'Withdraw -50',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: WalletStatus.failure,
          message: 'Transaction failed',
        ),
      );
    }
  }
}
