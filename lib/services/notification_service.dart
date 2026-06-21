// This service creates in-app notifications for bounty lifecycle events.
// It replaces external email delivery with Firestore-backed user notifications.
import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/bounty_rules.dart';

class NotificationService {
  NotificationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // Uses FirebaseFirestore to create a notification document.
  // Implements the notification for a successfully posted bounty.
  // The purpose is to confirm the bounty creation to the owner.
  Future<void> notifyBountyPosted(Map<String, dynamic> data) async {
    await _create(
      userId: data['ownerId'],
      title: 'Bounty posted: ${_title(data)}',
      description:
          '${_title(data)} has been posted successfully. If it is not claimed before the deadline, it will be cancelled automatically.',
      bountyId: data['id']?.toString(),
    );
  }

  // Uses FirebaseFirestore to create a notification document.
  // Implements the notification for an expired open bounty.
  // The purpose is to alert the owner that the bounty was cancelled automatically.
  Future<void> notifyOpenBountyExpired(Map<String, dynamic> data) async {
    await _create(
      userId: data['ownerId'],
      title: 'Bounty expired: ${_title(data)}',
      description:
          '${_title(data)} was not claimed before the deadline and has been cancelled automatically. You can repost it from the Request Record page.',
      bountyId: data['id']?.toString(),
    );
  }

  // Uses Future.wait to run multiple notification creations concurrently.
  // Implements the notification for a claimed bounty for both the owner and the hunter.
  // The purpose is to inform both parties about the start of the bounty resolution.
  Future<void> notifyBountyClaimed(Map<String, dynamic> data) async {
    final details = _orderDetails(data);
    await Future.wait([
      _create(
        userId: data['ownerId'],
        title: 'Bounty claimed: ${_title(data)}',
        description: '${_title(data)} has been claimed.\n\n$details',
        bountyId: data['id']?.toString(),
      ),
      _create(
        userId: data['hunterId'],
        title: 'You claimed: ${_title(data)}',
        description:
            'You have claimed ${_title(data)}. Please try to solve it before the deadline.\n\n$details',
        bountyId: data['id']?.toString(),
      ),
    ]);
  }

  // Uses FirebaseFirestore to create a notification document.
  // Implements the notification for a bounty abandoned by the hunter.
  // The purpose is to inform the owner and indicate the return of the bounty to the board.
  Future<void> notifyBountyAbandoned({
    required Map<String, dynamic> data,
    required String reason,
  }) async {
    await _create(
      userId: data['ownerId'],
      title: 'Bounty returned to board: ${_title(data)}',
      description:
          '${_title(data)} was abandoned by the hunter. Reason: $reason. Remaining time: ${_remaining(data)}. The bounty has been returned to the Bounty Board automatically.',
      bountyId: data['id']?.toString(),
    );
  }

  // Uses FirebaseFirestore to create a notification document.
  // Implements the notification when a hunter marks a bounty as solved.
  // The purpose is to prompt the owner to check and confirm the resolution.
  Future<void> notifyMarkedSolved(Map<String, dynamic> data) async {
    await _create(
      userId: data['ownerId'],
      title: 'Solution submitted: ${_title(data)}',
      description:
          '${_title(data)} has been marked as solved by the hunter. Please check whether the issue is resolved and confirm it in your requester Active page as soon as possible.',
      bountyId: data['id']?.toString(),
    );
  }

  // Uses Future.wait to notify multiple users concurrently.
  // Implements the notification for a completed bounty for both the owner and the hunter.
  // The purpose is to congratulate both parties and confirm the reward transfer.
  Future<void> notifyBountyCompleted(Map<String, dynamic> data) async {
    final details = _orderDetails(data);
    await Future.wait([
      _create(
        userId: data['ownerId'],
        title: 'Bounty completed: ${_title(data)}',
        description:
            'Congratulations! ${_title(data)} has been completed. You solved your problem on Campus BugHunter.\n\n$details',
        bountyId: data['id']?.toString(),
      ),
      _create(
        userId: data['hunterId'],
        title: 'Reward received: ${_title(data)}',
        description:
            'Congratulations! ${_title(data)} has been completed. You helped another student solve a problem, and the bounty reward has been sent to your wallet.\n\n$details',
        bountyId: data['id']?.toString(),
      ),
    ]);
  }

  // Uses FirebaseFirestore collection to add a new document.
  // Implements the actual database write operation for notifications.
  // The purpose is to encapsulate the common notification creation logic safely without blocking.
  Future<void> _create({
    required dynamic userId,
    required String title,
    required String description,
    String? bountyId,
  }) async {
    final id = userId?.toString().trim();
    if (id == null || id.isEmpty) return;

    try {
      await _firestore.collection('notifications').add({
        'userId': id,
        'title': title,
        'description': description,
        'bountyId': bountyId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Notification delivery must not block the bounty workflow.
    }
  }

  // Uses basic string manipulation.
  // Implements the extraction of the bounty title.
  // The purpose is to provide a fallback title if the original is empty or missing.
  String _title(Map<String, dynamic> data) {
    final title = data['title']?.toString().trim();
    return title == null || title.isEmpty ? 'Your bounty' : title;
  }

  // Uses data mapping and conditional logic.
  // Implements the formatting of bounty details like location and amount.
  // The purpose is to create a readable summary string for notifications.
  String _orderDetails(Map<String, dynamic> data) {
    final locationType = data['locationType']?.toString() ?? 'Offline';
    final location = locationType == 'Online'
        ? data['meetingLink']?.toString() ?? data['location']?.toString() ?? ''
        : data['location']?.toString() ?? '';
    return [
      'Remaining time: ${_remaining(data)}',
      '${locationType == 'Online' ? 'Meeting link' : 'Location'}: ${location.isEmpty ? 'Not provided' : location}',
      'Bounty: RM ${((data['amount'] ?? 0).toDouble()).toStringAsFixed(2)}',
    ].join('\n');
  }

  // Uses DateTime difference calculations.
  // Implements the calculation of the remaining time until the bounty expires.
  // The purpose is to display a human-readable remaining time string.
  String _remaining(Map<String, dynamic> data) {
    final expiresAt = timestampDate(data['expiresAt']);
    if (expiresAt == null) return 'Not available';
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return 'Expired';
    if (remaining.inDays > 0) {
      return '${remaining.inDays} day(s) ${remaining.inHours.remainder(24)} hour(s)';
    }
    if (remaining.inHours > 0) return '${remaining.inHours} hour(s)';
    return '${remaining.inMinutes.clamp(0, 59)} minute(s)';
  }
}
