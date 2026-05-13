// This cubit file manages the requester's request history actions.
// It watches owned bounties, auto-cancels expired open requests, completes requests, and refunds cancelled ones.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../utils/bounty_rules.dart';
import 'request_record_state.dart';

// RequestRecordCubit connects the request record UI to Firestore bounty records.
class RequestRecordCubit extends Cubit<RequestRecordState> {
  RequestRecordCubit({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance,
      super(const RequestRecordState());

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // This stream watches the current requester's bounty documents and checks each snapshot for expired requests.
  Stream<BountySnapshot> watchRequests() {
    return _firestore
        .collection('bounties')
        .where('ownerId', isEqualTo: _auth.currentUser!.uid)
        .snapshots()
        .asyncMap((snapshot) async {
          await _cancelExpiredRequests(snapshot.docs);
          return snapshot;
        });
  }

  // This helper scans visible request documents and cancels open ones whose expiration time has passed.
  Future<void> _cancelExpiredRequests(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final now = DateTime.now();
    for (final doc in docs) {
      final data = doc.data();
      final status = (data['status'] ?? '').toString().toUpperCase();
      final canExpire =
          status.isEmpty || status == 'NOT ACCEPTED' || status == 'OPEN';
      if (canExpire && isExpired(data, now)) {
        await _cancelAndRefund(doc.id, data);
      }
    }
  }

  // This method marks a request as completed and pays either the hunter or refunds the requester when no hunter exists.
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

  // This method cancels a request by delegating to the shared refund transaction.
  Future<void> cancelRequest(String docId, Map<String, dynamic> data) async {
    emit(
      state.copyWith(status: RequestActionStatus.loading, clearMessage: true),
    );
    try {
      await _cancelAndRefund(docId, data);
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

  // This helper performs the Firestore transaction that refunds the requester and marks the bounty as cancelled.
  Future<void> _cancelAndRefund(String docId, Map<String, dynamic> data) async {
    final uid = _auth.currentUser!.uid;
    final bountyRef = _firestore.collection('bounties').doc(docId);
    final userRef = _firestore.collection('users').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final bountySnap = await transaction.get(bountyRef);
      final bountyData = bountySnap.data();
      if (bountyData == null) return;

      final status = (bountyData['status'] ?? '').toString().toUpperCase();
      if (status == 'CANCELLED' || status == 'COMPLETED') return;

      final amount = (bountyData['amount'] ?? data['amount'] ?? 0).toDouble();
      transaction.update(userRef, {'wallet': FieldValue.increment(amount)});
      transaction.update(bountyRef, {
        'status': 'CANCELLED',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
