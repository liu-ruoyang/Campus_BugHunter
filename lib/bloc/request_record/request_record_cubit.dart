// This cubit file manages the requester's request history actions.
// It watches owned bounties, auto-cancels expired open requests, completes requests, and refunds cancelled ones.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/email_notification_service.dart';
import '../../utils/bounty_rules.dart';
import 'request_record_state.dart';

// RequestRecordCubit connects the request record UI to Firestore bounty records.
class RequestRecordCubit extends Cubit<RequestRecordState> {
  RequestRecordCubit({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    EmailNotificationService? emailService,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _emailService = emailService ?? EmailNotificationService(),
       super(const RequestRecordState());

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final EmailNotificationService _emailService;

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
        await _cancelAndRefund(
          doc.id,
          data,
          reason: 'Expired before being claimed',
        );
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
      await _deleteChat(docId);
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
      await _cancelAndRefund(docId, data, reason: 'Cancelled by requester');
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

  // This method creates a fresh bounty from the final saved data of a cancelled or overdue request.
  Future<bool> repostRequest(String docId, Map<String, dynamic> data) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      emit(
        state.copyWith(
          status: RequestActionStatus.failure,
          message: 'User not signed in',
        ),
      );
      return false;
    }

    emit(
      state.copyWith(status: RequestActionStatus.loading, clearMessage: true),
    );
    try {
      final amount = (data['amount'] ?? 0).toDouble();
      final urgencyLevel = data['urgencyLevel']?.toString() ?? '7 Days';
      final difficulty = data['difficulty']?.toString() ?? 'Simple';
      final minimumAmount =
          (data['minimumBounty'] ?? minimumBounty(urgencyLevel, difficulty))
              .toDouble();
      final newRef = _firestore.collection('bounties').doc();
      final userRef = _firestore.collection('users').doc(uid);

      await _firestore.runTransaction((transaction) async {
        final userSnap = await transaction.get(userRef);
        final wallet = (userSnap.data()?['wallet'] ?? 0).toDouble();
        if (wallet < amount) {
          throw StateError('Insufficient balance to repost this bounty');
        }

        transaction.update(userRef, {'wallet': wallet - amount});
        transaction.set(newRef, {
          'ownerId': uid,
          'hunterId': null,
          'title': data['title']?.toString() ?? '',
          'description': data['description']?.toString() ?? '',
          'locationType': data['locationType']?.toString() ?? 'Offline',
          'location': data['location']?.toString() ?? '',
          'meetingLink': data['meetingLink']?.toString() ?? '',
          'amount': amount,
          'platformFee': (data['platformFee'] ?? amount * 0.05).toDouble(),
          'hunterReceive': (data['hunterReceive'] ?? amount - (amount * 0.05))
              .toDouble(),
          'techStacks': List<dynamic>.from(data['techStacks'] ?? const []),
          'difficulty': difficulty,
          'urgencyLevel': urgencyLevel,
          'urgencyDays': urgencyDays(urgencyLevel),
          'minimumBounty': minimumAmount,
          'imageUrls': List<dynamic>.from(data['imageUrls'] ?? const []),
          'status': 'NOT ACCEPTED',
          'escrow': true,
          'createdAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(
            DateTime.now().add(Duration(days: urgencyDays(urgencyLevel))),
          ),
          'repostedFrom': docId,
          'repostedAt': FieldValue.serverTimestamp(),
        });
      });

      emit(
        state.copyWith(
          status: RequestActionStatus.success,
          message: 'Bounty reposted',
        ),
      );
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          status: RequestActionStatus.failure,
          message: error is StateError
              ? error.message.toString()
              : 'Failed to repost bounty',
        ),
      );
      return false;
    }
  }

  // This helper performs the Firestore transaction that refunds the requester and marks the bounty as cancelled.
  Future<void> _cancelAndRefund(
    String docId,
    Map<String, dynamic> data, {
    required String reason,
  }) async {
    final uid = _auth.currentUser!.uid;
    final bountyRef = _firestore.collection('bounties').doc(docId);
    final userRef = _firestore.collection('users').doc(uid);

    var cancelled = false;
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
        'cancellationReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      cancelled = true;
    });
    if (cancelled && reason == 'Expired before being claimed') {
      await _emailService.notifyOpenBountyExpired(data);
    }
    await _deleteChat(docId);
  }

  // This helper permanently removes the temporary chat and messages for an ended request.
  Future<void> _deleteChat(String docId) async {
    final chatRef = _firestore.collection('chats').doc(docId);
    while (true) {
      final messages = await chatRef.collection('messages').limit(400).get();
      if (messages.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in messages.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    await chatRef.delete();
  }
}
