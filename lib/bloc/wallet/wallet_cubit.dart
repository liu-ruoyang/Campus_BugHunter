import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'wallet_state.dart';

class WalletCubit extends Cubit<WalletState> {
  WalletCubit({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance,
      super(const WalletState());

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String get uid => _auth.currentUser!.uid;

  Stream<TransactionSnapshot> watchTransactions() {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

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
