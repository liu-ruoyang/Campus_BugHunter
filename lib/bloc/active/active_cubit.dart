// This cubit file manages active bounty streams and actions for both requester and hunter roles.
// It claims bounties, moves work through review/completion, refunds expired items, and reports issues.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../home/role_cubit.dart';
import 'active_state.dart';
import '../../services/notification_service.dart';
import '../../utils/bounty_rules.dart';

// ActiveCubit coordinates Firestore bounty documents with the UI state shown on the Active page.
class ActiveCubit extends Cubit<ActiveState> {
  ActiveCubit({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _notificationService = notificationService ?? NotificationService(),
       super(const ActiveState());

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;

  // This stream watches the newest active bounty for the selected role and filters only active statuses.
  Stream<ActiveBounty?> watchActive(UserRole role) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);

    final field = role == UserRole.hunter ? 'hunterId' : 'ownerId';
    return _firestore
        .collection('bounties')
        .where(field, isEqualTo: uid)
        .snapshots()
        .asyncMap((snapshot) async {
          final activeBounties = <ActiveBounty>[];
          for (final doc in snapshot.docs) {
            final data = Map<String, dynamic>.from(doc.data());
            final status = await _syncLifecycle(doc.id, data);
            if (status == null || !_activeStatuses.contains(status)) continue;
            data['status'] = status;

            if (status == 'OVERDUE') {
              final exited = role == UserRole.hunter
                  ? data['hunterExitedOverdue'] == true
                  : data['requesterExitedOverdue'] == true;
              if (exited) continue;
            }

            activeBounties.add(ActiveBounty(id: doc.id, data: data));
          }

          if (activeBounties.isEmpty) return null;
          activeBounties.sort((a, b) {
            final aCreatedAt = a.data['claimedAt'];
            final bCreatedAt = b.data['claimedAt'];
            if (aCreatedAt is Timestamp && bCreatedAt is Timestamp) {
              return bCreatedAt.compareTo(aCreatedAt);
            }
            return 0;
          });
          return activeBounties.first;
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
      final data = doc.data();
      final status = (data['status'] ?? '').toString().toUpperCase();
      if (!_activeStatuses.contains(status)) return false;
      if (status == 'OVERDUE') {
        return role == UserRole.hunter
            ? data['hunterExitedOverdue'] != true
            : data['requesterExitedOverdue'] != true;
      }
      return true;
    });
  }

  Future<void> cancelExpiredOpenBounties(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final now = DateTime.now();
    for (final doc in docs) {
      final data = doc.data();
      final status = _statusOf(data);
      final canExpire =
          status.isEmpty || status == 'NOT ACCEPTED' || status == 'OPEN';
      if (!canExpire || !isExpired(data, now)) continue;

      final ownerId = data['ownerId']?.toString();
      if (ownerId == null) continue;
      final bountyRef = _firestore.collection('bounties').doc(doc.id);
      final ownerRef = _firestore.collection('users').doc(ownerId);

      var cancelled = false;
      await _firestore.runTransaction((transaction) async {
        final bountySnap = await transaction.get(bountyRef);
        final current = bountySnap.data();
        if (current == null) return;
        final currentStatus = _statusOf(current);
        final stillOpen =
            currentStatus.isEmpty ||
            currentStatus == 'NOT ACCEPTED' ||
            currentStatus == 'OPEN';
        if (!stillOpen || !isExpired(current, DateTime.now())) return;
        final amount = (current['amount'] ?? 0).toDouble();
        transaction.update(ownerRef, {'wallet': FieldValue.increment(amount)});
        transaction.update(bountyRef, {
          'status': 'CANCELLED',
          'cancellationReason': 'Expired before being claimed',
          'cancelledAt': FieldValue.serverTimestamp(),
        });
        cancelled = true;
      });
      if (cancelled) {
        await _notificationService.notifyOpenBountyExpired(data);
      }
    }
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
      final activeSnapshot = await _firestore
          .collection('bounties')
          .where('hunterId', isEqualTo: uid)
          .get();
      final hunterHasActive = activeSnapshot.docs.any((doc) {
        return _activeStatuses.contains(_statusOf(doc.data()));
      });
      if (hunterHasActive) {
        throw StateError('You already have an active bounty');
      }

      final initialBounty = await _firestore
          .collection('bounties')
          .doc(bountyId)
          .get();
      final initialData = initialBounty.data();
      if (initialData == null ||
          !_availableStatuses.contains(_statusOf(initialData))) {
        throw StateError('This bounty is no longer available');
      }

      final ownerId = initialData['ownerId']?.toString();
      if (ownerId == null || ownerId.isEmpty) {
        throw StateError('Bounty owner is missing');
      }
      if (ownerId == uid) {
        throw StateError('You cannot claim your own bounty');
      }

      final requesterActive = await _firestore
          .collection('bounties')
          .where('ownerId', isEqualTo: ownerId)
          .get();
      final requesterHasActive = requesterActive.docs.any((doc) {
        return _activeStatuses.contains(_statusOf(doc.data()));
      });
      if (requesterHasActive) {
        throw StateError('Requester already has an active bounty');
      }

      final claimError = await _firestore.runTransaction<String?>((
        transaction,
      ) async {
        final activeSnapshot = await _firestore
            .collection('bounties')
            .where('hunterId', isEqualTo: uid)
            .get();

        final hunterHasActive = activeSnapshot.docs.any((doc) {
          final data = doc.data();
          final status = (data['status'] ?? '').toString().toUpperCase();
          if (!_activeStatuses.contains(status)) return false;
          if (status == 'OVERDUE') return data['hunterExitedOverdue'] != true;
          return true;
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

        final transactionOwnerId = data['ownerId']?.toString();
        if (transactionOwnerId == null || transactionOwnerId.isEmpty) {
          throw StateError('Bounty owner is missing');
        }
        if (transactionOwnerId != ownerId) {
          throw StateError('Bounty owner changed. Please refresh and retry');
        }

        if (isExpired(data, DateTime.now())) {
          final ownerRef = _firestore
              .collection('users')
              .doc(transactionOwnerId);
          final amount = (data['amount'] ?? 0).toDouble();
          transaction.update(ownerRef, {
            'wallet': FieldValue.increment(amount),
          });
          transaction.update(bountyRef, {
            'status': 'CANCELLED',
            'cancellationReason': 'Expired before being claimed',
            'cancelledAt': FieldValue.serverTimestamp(),
          });
          return 'This bounty has expired';
        }

        final requesterActive = await _firestore
            .collection('bounties')
            .where('ownerId', isEqualTo: ownerId)
            .get();

        final requesterHasActive = requesterActive.docs.any((doc) {
          final data = doc.data();
          final status = (data['status'] ?? '').toString().toUpperCase();
          if (!_activeStatuses.contains(status)) return false;
          if (status == 'OVERDUE') {
            return data['requesterExitedOverdue'] != true;
          }
          return true;
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

      final bountySnap = await _firestore
          .collection('bounties')
          .doc(bountyId)
          .get();
      final bountyData = bountySnap.data();
      await _createChatRoom(
        bountyId: bountyId,
        data: bountyData,
        helperId: uid,
      );
      if (bountyData != null) {
        await _notificationService.notifyBountyClaimed(bountyData);
      }

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
      final bountySnap = await _firestore
          .collection('bounties')
          .doc(bountyId)
          .get();
      final data = bountySnap.data() ?? const <String, dynamic>{};
      final expiresAt = timestampDate(data['expiresAt']);
      final now = DateTime.now();
      final reviewBase = expiresAt != null && expiresAt.isAfter(now)
          ? expiresAt
          : now;
      await _firestore.collection('bounties').doc(bountyId).update({
        'status': 'REVIEW',
        'solvedAt': FieldValue.serverTimestamp(),
        'reviewAutoCompleteAt': Timestamp.fromDate(
          reviewBase.add(const Duration(hours: 1)),
        ),
      });
      await _notificationService.notifyMarkedSolved(data);
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
      await _completeBounty(bountyId, data);
      await _deleteChat(bountyId);
      await _notificationService.notifyBountyCompleted(data);

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

  Future<void> denySolved(String bountyId, Map<String, dynamic> data) async {
    emit(
      state.copyWith(status: ActiveActionStatus.loading, clearMessage: true),
    );
    try {
      await _cancelAndRefund(
        bountyId,
        data,
        reason: 'Requester denied the submitted solution',
      );
      emit(
        state.copyWith(
          status: ActiveActionStatus.success,
          message: 'Solution denied',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ActiveActionStatus.failure,
          message: 'Failed to deny solution',
        ),
      );
    }
  }

  Future<void> reportIssue({
    required String bountyId,
    required Map<String, dynamic> data,
    required UserRole role,
    required String issueType,
    required String description,
  }) async {
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
    if (description.trim().isEmpty) {
      emit(
        state.copyWith(
          status: ActiveActionStatus.failure,
          message: 'Please describe the issue',
        ),
      );
      return;
    }

    emit(
      state.copyWith(status: ActiveActionStatus.loading, clearMessage: true),
    );
    try {
      final reportRef = _firestore.collection('issue_reports').doc();
      final bountyRef = _firestore.collection('bounties').doc(bountyId);
      await _firestore.runTransaction((transaction) async {
        transaction.set(reportRef, {
          'bountyId': bountyId,
          'reporterId': uid,
          'reporterRole': role == UserRole.hunter ? 'hunter' : 'requester',
          'issueType': issueType,
          'description': description.trim(),
          'status': 'OPEN',
          'createdAt': FieldValue.serverTimestamp(),
          'bountySnapshot': data,
        });
        transaction.update(bountyRef, {
          'status': 'REPORTED',
          'reportedAt': FieldValue.serverTimestamp(),
          'lastReportId': reportRef.id,
        });
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

  Future<void> abandonBounty({
    required String bountyId,
    required Map<String, dynamic> data,
    required String reason,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    emit(
      state.copyWith(status: ActiveActionStatus.loading, clearMessage: true),
    );
    try {
      final bountyRef = _firestore.collection('bounties').doc(bountyId);
      final userRef = _firestore.collection('users').doc(uid);
      final recordRef = _firestore.collection('abandon_records').doc();
      await _firestore.runTransaction((transaction) async {
        final bountySnap = await transaction.get(bountyRef);
        final current = bountySnap.data();
        if (current == null || _statusOf(current) != 'IN PROGRESS') {
          throw StateError('This bounty can no longer be abandoned');
        }
        transaction.set(recordRef, {
          'bountyId': bountyId,
          'hunterId': uid,
          'requesterId': current['ownerId'],
          'reason': reason,
          'createdAt': FieldValue.serverTimestamp(),
          'bountyTitle': current['title'] ?? data['title'],
        });
        transaction.update(userRef, {
          'abandonCount': FieldValue.increment(1),
          'lastAbandonReason': reason,
          'lastAbandonedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(bountyRef, {
          'status': 'NOT ACCEPTED',
          'hunterId': null,
          'claimedAt': FieldValue.delete(),
          'lastAbandonedBy': uid,
          'lastAbandonReason': reason,
          'lastAbandonedAt': FieldValue.serverTimestamp(),
        });
      });
      await _deleteChat(bountyId);
      await _notificationService.notifyBountyAbandoned(
        data: data,
        reason: reason,
      );
      emit(
        state.copyWith(
          status: ActiveActionStatus.success,
          message: 'Bounty abandoned',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ActiveActionStatus.failure,
          message: _errorMessage(error, fallback: 'Failed to abandon bounty'),
        ),
      );
    }
  }

  Future<void> exitOverdue(String bountyId, UserRole role) async {
    emit(
      state.copyWith(status: ActiveActionStatus.loading, clearMessage: true),
    );
    try {
      await _firestore.collection('bounties').doc(bountyId).update({
        role == UserRole.hunter
                ? 'hunterExitedOverdue'
                : 'requesterExitedOverdue':
            true,
      });
      emit(
        state.copyWith(
          status: ActiveActionStatus.success,
          message: 'Exited overdue order',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ActiveActionStatus.failure,
          message: 'Failed to exit overdue order',
        ),
      );
    }
  }

  // These status sets define which bounty states are active and which can still be claimed.
  static const _activeStatuses = {'IN PROGRESS', 'REVIEW', 'OVERDUE'};
  static const _availableStatuses = {'', 'NOT ACCEPTED', 'OPEN'};

  // This helper normalizes the stored status value before comparing it with known states.
  static String _statusOf(Map<String, dynamic> data) {
    return (data['status'] ?? '').toString().toUpperCase();
  }

  Future<String?> _syncLifecycle(
    String bountyId,
    Map<String, dynamic> data,
  ) async {
    final status = _statusOf(data);
    final now = DateTime.now();

    if (status == 'IN PROGRESS' && isExpired(data, now)) {
      await _markOverdue(bountyId, data);
      return 'OVERDUE';
    }

    if (status == 'REVIEW') {
      final autoCompleteAt =
          timestampDate(data['reviewAutoCompleteAt']) ??
          _reviewAutoCompleteAt(data);
      if (autoCompleteAt != null && !autoCompleteAt.isAfter(now)) {
        await _completeBounty(bountyId, data);
        await _deleteChat(bountyId);
        await _notificationService.notifyBountyCompleted(data);
        return 'COMPLETED';
      }
      if (autoCompleteAt != null && data['reviewAutoCompleteAt'] == null) {
        await _firestore.collection('bounties').doc(bountyId).update({
          'reviewAutoCompleteAt': Timestamp.fromDate(autoCompleteAt),
        });
        data['reviewAutoCompleteAt'] = Timestamp.fromDate(autoCompleteAt);
      }
    }

    return status;
  }

  DateTime? _reviewAutoCompleteAt(Map<String, dynamic> data) {
    final solvedAt = timestampDate(data['solvedAt']);
    if (solvedAt == null) return null;
    final expiresAt = timestampDate(data['expiresAt']);
    final base = expiresAt != null && expiresAt.isAfter(solvedAt)
        ? expiresAt
        : solvedAt;
    return base.add(const Duration(hours: 1));
  }

  Future<void> _markOverdue(String bountyId, Map<String, dynamic> data) async {
    final hunterId = data['hunterId']?.toString();
    final ownerId = data['ownerId']?.toString();
    final bountyRef = _firestore.collection('bounties').doc(bountyId);
    final hunterRef = hunterId == null
        ? null
        : _firestore.collection('users').doc(hunterId);
    final recordRef = hunterId == null
        ? null
        : _firestore.collection('overdue_records').doc('${bountyId}_$hunterId');

    await _firestore.runTransaction((transaction) async {
      final bountySnap = await transaction.get(bountyRef);
      final current = bountySnap.data();
      if (current == null || _statusOf(current) != 'IN PROGRESS') return;

      transaction.update(bountyRef, {
        'status': 'OVERDUE',
        'overdueAt': FieldValue.serverTimestamp(),
      });
      if (hunterRef != null && recordRef != null) {
        transaction.update(hunterRef, {
          'overdueCount': FieldValue.increment(1),
          'lastOverdueAt': FieldValue.serverTimestamp(),
        });
        transaction.set(recordRef, {
          'bountyId': bountyId,
          'hunterId': hunterId,
          'requesterId': ownerId,
          'createdAt': FieldValue.serverTimestamp(),
          'bountyTitle': current['title'] ?? data['title'],
        });
      }
    });
  }

  Future<void> _completeBounty(
    String bountyId,
    Map<String, dynamic> data,
  ) async {
    final hunterId = data['hunterId'] as String?;
    final amount = (data['amount'] ?? 0).toDouble();
    final platformFee = (data['platformFee'] ?? amount * 0.05).toDouble();
    final hunterReceive = (data['hunterReceive'] ?? amount - platformFee)
        .toDouble();

    await _firestore.runTransaction((transaction) async {
      final bountyRef = _firestore.collection('bounties').doc(bountyId);
      final bountySnap = await transaction.get(bountyRef);
      final current = bountySnap.data();
      if (current == null || _statusOf(current) != 'REVIEW') return;

      if (hunterId != null) {
        final hunterRef = _firestore.collection('users').doc(hunterId);
        final hunterDoc = await transaction.get(hunterRef);
        final wallet = (hunterDoc.data()?['wallet'] ?? 0).toDouble();
        transaction.update(hunterRef, {
          'wallet': wallet + hunterReceive,
          'helperCount': FieldValue.increment(1),
        });
      }

      transaction.update(bountyRef, {
        'status': 'COMPLETED',
        'completedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> _cancelAndRefund(
    String bountyId,
    Map<String, dynamic> data, {
    required String reason,
  }) async {
    final ownerId = data['ownerId']?.toString();
    if (ownerId == null) throw StateError('Requester is missing');

    await _firestore.runTransaction((transaction) async {
      final bountyRef = _firestore.collection('bounties').doc(bountyId);
      final bountySnap = await transaction.get(bountyRef);
      final current = bountySnap.data();
      if (current == null) return;
      final status = _statusOf(current);
      if (status == 'COMPLETED' || status == 'CANCELLED') return;

      final amount = (current['amount'] ?? data['amount'] ?? 0).toDouble();
      final ownerRef = _firestore.collection('users').doc(ownerId);
      transaction.update(ownerRef, {'wallet': FieldValue.increment(amount)});
      transaction.update(bountyRef, {
        'status': 'CANCELLED',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancellationReason': reason,
      });
    });
    await _deleteChat(bountyId);
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
    final detail = error.toString().trim();
    return detail.isEmpty ? fallback : '$fallback: $detail';
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
