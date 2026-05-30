// This cubit file manages active bounty streams and actions for both requester and hunter roles.
// It claims bounties, moves work through review/completion, refunds expired items, and reports issues.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../home/role_cubit.dart';
import 'active_state.dart';
import '../../utils/bounty_rules.dart';

// ActiveCubit coordinates Firestore bounty documents with the UI state shown on the Active page.
class ActiveCubit extends Cubit<ActiveState> {
  ActiveCubit({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance,
      super(const ActiveState());

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // This stream watches the newest active bounty for the selected role and filters only active statuses.
  Stream<ActiveBounty?> watchActive(UserRole role) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);

    final field = role == UserRole.hunter ? 'hunterId' : 'ownerId';
    return _firestore
        .collection('bounties')
        .where(field, isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.where((doc) {
            return _activeStatuses.contains(
              (doc.data()['status'] ?? '').toString().toUpperCase(),
            );
          }).toList();
          if (docs.isEmpty) return null;
          docs.sort((a, b) {
            final aCreatedAt = a.data()['claimedAt'];
            final bCreatedAt = b.data()['claimedAt'];
            if (aCreatedAt is Timestamp && bCreatedAt is Timestamp) {
              return bCreatedAt.compareTo(aCreatedAt);
            }
            return 0;
          });
          final doc = docs.first;
          return ActiveBounty(id: doc.id, data: doc.data());
        });
  }

  // This method checks whether a user already has an active bounty for a given role.
  Future<bool> hasActive(UserRole role, String uid) async {
    final field = role == UserRole.hunter ? 'hunterId' : 'ownerId';
    final snapshot = await _firestore
        .collection('bounties')
        .where(field, isEqualTo: uid)
        .get();
    return snapshot.docs.any((doc) {
      return _activeStatuses.contains(
        (doc.data()['status'] ?? '').toString().toUpperCase(),
      );
    });
  }

  // This method claims an available bounty, blocks duplicate active work, and cancels expired bounties with a refund.
  Future<void> claimBounty(String bountyId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      emit(
        state.copyWith(
          status: ActiveActionStatus.failure,
          message: 'User not signed in',
        ),
      );
      return;
    }

    emit(
      state.copyWith(status: ActiveActionStatus.loading, clearMessage: true),
    );
    try {
      final claimError = await _firestore.runTransaction<String?>((
        transaction,
      ) async {
        final activeSnapshot = await _firestore
            .collection('bounties')
            .where('hunterId', isEqualTo: uid)
            .get();

        final hunterHasActive = activeSnapshot.docs.any((doc) {
          return _activeStatuses.contains(
            (doc.data()['status'] ?? '').toString().toUpperCase(),
          );
        });

        if (hunterHasActive) {
          throw StateError('You already have an active bounty');
        }

        final bountyRef = _firestore.collection('bounties').doc(bountyId);
        final bountyDoc = await transaction.get(bountyRef);
        final data = bountyDoc.data();

        if (data == null || !_availableStatuses.contains(_statusOf(data))) {
          throw StateError('This bounty is no longer available');
        }

        final ownerId = data['ownerId'] as String?;
        if (ownerId == null) {
          throw StateError('Bounty owner is missing');
        }

        if (isExpired(data, DateTime.now())) {
          final ownerRef = _firestore.collection('users').doc(ownerId);
          final amount = (data['amount'] ?? 0).toDouble();
          transaction.update(ownerRef, {
            'wallet': FieldValue.increment(amount),
          });
          transaction.update(bountyRef, {
            'status': 'CANCELLED',
            'cancelledAt': FieldValue.serverTimestamp(),
          });
          return 'This bounty has expired';
        }

        final requesterActive = await _firestore
            .collection('bounties')
            .where('ownerId', isEqualTo: ownerId)
            .get();

        final requesterHasActive = requesterActive.docs.any((doc) {
          return _activeStatuses.contains(
            (doc.data()['status'] ?? '').toString().toUpperCase(),
          );
        });

        if (requesterHasActive) {
          throw StateError('Requester already has an active bounty');
        }

        transaction.update(bountyRef, {
          'hunterId': uid,
          'status': 'IN PROGRESS',
          'claimedAt': FieldValue.serverTimestamp(),
        });
        return null;
      });

      if (claimError != null) {
        throw StateError(claimError);
      }

      final bountySnap = await _firestore.collection('bounties').doc(bountyId).get();
      final bountyData = bountySnap.data();
      await _createChatRoom(bountyId: bountyId, data: bountyData, helperId: uid);

      emit(
        state.copyWith(
          status: ActiveActionStatus.success,
          message: 'Bounty claimed',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ActiveActionStatus.failure,
          message: _errorMessage(error, fallback: 'Failed to claim bounty'),
        ),
      );
    }
  }

  // This method moves a hunter's in-progress bounty into requester review.
  Future<void> markAsSolved(String bountyId) async {
    emit(
      state.copyWith(status: ActiveActionStatus.loading, clearMessage: true),
    );
    try {
      await _firestore.collection('bounties').doc(bountyId).update({
        'status': 'REVIEW',
        'solvedAt': FieldValue.serverTimestamp(),
      });
      emit(
        state.copyWith(
          status: ActiveActionStatus.success,
          message: 'Marked as solved',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ActiveActionStatus.failure,
          message: 'Failed to update bounty',
        ),
      );
    }
  }

  // This method completes a reviewed bounty and transfers the hunter payout after platform fee deduction.
  Future<void> commitSolved(String bountyId, Map<String, dynamic> data) async {
    emit(
      state.copyWith(status: ActiveActionStatus.loading, clearMessage: true),
    );
    try {
      final hunterId = data['hunterId'] as String?;
      final amount = (data['amount'] ?? 0).toDouble();
      final platformFee = (data['platformFee'] ?? amount * 0.05).toDouble();
      final hunterReceive = (data['hunterReceive'] ?? amount - platformFee)
          .toDouble();

      await _firestore.runTransaction((transaction) async {
        final bountyRef = _firestore.collection('bounties').doc(bountyId);
        if (hunterId != null) {
          final hunterRef = _firestore.collection('users').doc(hunterId);
          final hunterDoc = await transaction.get(hunterRef);
          final wallet = (hunterDoc.data()?['wallet'] ?? 0).toDouble();
          transaction.update(hunterRef, {'wallet': wallet + hunterReceive});
        }

        transaction.update(bountyRef, {
          'status': 'COMPLETED',
          'completedAt': FieldValue.serverTimestamp(),
        });
      });
      await _deleteChat(bountyId);

      emit(
        state.copyWith(
          status: ActiveActionStatus.success,
          message: 'Bounty completed',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ActiveActionStatus.failure,
          message: 'Failed to complete bounty',
        ),
      );
    }
  }

  // This method flags a bounty as reported when the requester disputes the submitted solution.
  Future<void> reportIssue(String bountyId) async {
    emit(
      state.copyWith(status: ActiveActionStatus.loading, clearMessage: true),
    );
    try {
      await _firestore.collection('bounties').doc(bountyId).update({
        'status': 'REPORTED',
        'reportedAt': FieldValue.serverTimestamp(),
      });
      await _deleteChat(bountyId);
      emit(
        state.copyWith(
          status: ActiveActionStatus.success,
          message: 'Issue reported',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ActiveActionStatus.failure,
          message: 'Failed to report issue',
        ),
      );
    }
  }

  // These status sets define which bounty states are active and which can still be claimed.
  static const _activeStatuses = {'IN PROGRESS', 'REVIEW'};
  static const _availableStatuses = {'', 'NOT ACCEPTED', 'OPEN'};

  // This helper normalizes the stored status value before comparing it with known states.
  static String _statusOf(Map<String, dynamic> data) {
    return (data['status'] ?? '').toString().toUpperCase();
  }

  // This helper creates the temporary chat after the bounty claim succeeds.
  Future<void> _createChatRoom({
    required String bountyId,
    required Map<String, dynamic>? data,
    required String helperId,
  }) async {
    try {
      final requesterId = data?['ownerId']?.toString();
      if (requesterId == null || requesterId.isEmpty) return;
      await _firestore.collection('chats').doc(bountyId).set({
        'bountyId': bountyId,
        'requesterId': requesterId,
        'helperId': helperId,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageAt': null,
      }, SetOptions(merge: true));
    } catch (_) {
      // Chat setup should not undo a successful bounty claim.
    }
  }

  // This helper preserves useful Firebase errors in snackbar messages.
  String _errorMessage(Object error, {required String fallback}) {
    if (error is StateError) return error.message;
    if (error is FirebaseException) {
      final message = error.message;
      if (message != null && message.trim().isNotEmpty) return message;
      return error.code;
    }
    return fallback;
  }

  // This helper permanently removes the temporary chat and all messages for an ended request.
  Future<void> _deleteChat(String bountyId) async {
    final chatRef = _firestore.collection('chats').doc(bountyId);
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
