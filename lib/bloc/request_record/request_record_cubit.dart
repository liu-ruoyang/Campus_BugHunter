import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'request_record_state.dart';

class RequestRecordCubit extends Cubit<RequestRecordState> {
  RequestRecordCubit({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance,
      super(const RequestRecordState());

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<BountySnapshot> watchRequests() {
    return _firestore
        .collection('bounties')
        .where('ownerId', isEqualTo: _auth.currentUser!.uid)
        .snapshots();
  }

  Future<void> completeRequest(String docId) async {
    emit(
      state.copyWith(status: RequestActionStatus.loading, clearMessage: true),
    );
    try {
      final bountyRef = _firestore.collection('bounties').doc(docId);
      final bountySnap = await bountyRef.get();
      final bountyData = bountySnap.data()!;
      final hunterId = bountyData['hunterId'];
      final ownerId = bountyData['ownerId'];
      final amount = (bountyData['amount'] ?? 0).toDouble();
      final platformFee = (bountyData['platformFee'] ?? 0).toDouble();
      final hunterReceive = amount - platformFee;

      if (hunterId == null) {
        final ownerRef = _firestore.collection('users').doc(ownerId);
        final ownerSnap = await ownerRef.get();
        final wallet = (ownerSnap.data()?['wallet'] ?? 0).toDouble();
        await ownerRef.update({'wallet': wallet + amount});
      } else {
        final hunterRef = _firestore.collection('users').doc(hunterId);
        final hunterSnap = await hunterRef.get();
        final wallet = (hunterSnap.data()?['wallet'] ?? 0).toDouble();
        await hunterRef.update({'wallet': wallet + hunterReceive});
      }

      await bountyRef.update({'status': 'COMPLETED'});
      emit(
        state.copyWith(
          status: RequestActionStatus.success,
          message: 'Request completed',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: RequestActionStatus.failure,
          message: 'Failed to complete request',
        ),
      );
    }
  }

  Future<void> cancelRequest(String docId, Map<String, dynamic> data) async {
    emit(
      state.copyWith(status: RequestActionStatus.loading, clearMessage: true),
    );
    try {
      final uid = _auth.currentUser!.uid;
      final amount = (data['amount'] ?? 0).toDouble();
      final userRef = _firestore.collection('users').doc(uid);
      final userSnap = await userRef.get();
      final wallet = (userSnap.data()?['wallet'] ?? 0).toDouble();

      await userRef.update({'wallet': wallet + amount});
      await _firestore.collection('bounties').doc(docId).delete();
      emit(
        state.copyWith(
          status: RequestActionStatus.success,
          message: 'Request cancelled',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: RequestActionStatus.failure,
          message: 'Failed to cancel request',
        ),
      );
    }
  }
}
