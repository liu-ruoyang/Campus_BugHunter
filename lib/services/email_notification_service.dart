import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../utils/bounty_rules.dart';

class EmailNotificationService {
  EmailNotificationService({FirebaseFirestore? firestore, http.Client? client})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _client = client ?? http.Client();

  final FirebaseFirestore _firestore;
  final http.Client _client;

  static const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const _functionName = String.fromEnvironment(
    'SUPABASE_EMAIL_FUNCTION',
    defaultValue: 'send-email',
  );

  bool get _enabled =>
      _supabaseUrl.trim().isNotEmpty && _supabaseAnonKey.trim().isNotEmpty;

  Future<void> notifyBountyPosted(Map<String, dynamic> data) async {
    final requester = await _user(data['ownerId']);
    await _send(
      to: requester.email,
      subject: 'Bounty posted: ${_title(data)}',
      text:
          '${_title(data)} has been posted successfully. If it is not claimed before the deadline, the order will be cancelled automatically.',
    );
  }

  Future<void> notifyOpenBountyExpired(Map<String, dynamic> data) async {
    final requester = await _user(data['ownerId']);
    await _send(
      to: requester.email,
      subject: 'Bounty expired: ${_title(data)}',
      text:
          '${_title(data)} was not claimed before the deadline and has been cancelled automatically. You can repost it from the Request Record page.',
    );
  }

  Future<void> notifyBountyClaimed(Map<String, dynamic> data) async {
    final requester = await _user(data['ownerId']);
    final hunter = await _user(data['hunterId']);
    final details = _orderDetails(data);
    await Future.wait([
      _send(
        to: requester.email,
        subject: 'Bounty claimed: ${_title(data)}',
        text: '${_title(data)} has been claimed.\n\n$details',
      ),
      _send(
        to: hunter.email,
        subject: 'You claimed: ${_title(data)}',
        text:
            'You have claimed ${_title(data)}. Please try to solve it before the deadline.\n\n$details',
      ),
    ]);
  }

  Future<void> notifyBountyAbandoned({
    required Map<String, dynamic> data,
    required String reason,
  }) async {
    final requester = await _user(data['ownerId']);
    final remaining = _remaining(data);
    await _send(
      to: requester.email,
      subject: 'Bounty returned to board: ${_title(data)}',
      text:
          '${_title(data)} was abandoned by the hunter. Reason: $reason. Remaining time: $remaining. The bounty has been returned to the Bounty Board automatically.',
    );
  }

  Future<void> notifyMarkedSolved(Map<String, dynamic> data) async {
    final requester = await _user(data['ownerId']);
    await _send(
      to: requester.email,
      subject: 'Solution submitted: ${_title(data)}',
      text:
          '${_title(data)} has been marked as solved by the hunter. Please check whether the issue is resolved and confirm it in your requester Active page as soon as possible.',
    );
  }

  Future<void> notifyBountyCompleted(Map<String, dynamic> data) async {
    final requester = await _user(data['ownerId']);
    final hunter = await _user(data['hunterId']);
    final details = _orderDetails(data);
    await Future.wait([
      _send(
        to: requester.email,
        subject: 'Bounty completed: ${_title(data)}',
        text:
            'Congratulations! ${_title(data)} has been completed. You solved your problem on Campus BugHunter.\n\n$details',
      ),
      _send(
        to: hunter.email,
        subject: 'Reward received: ${_title(data)}',
        text:
            'Congratulations! ${_title(data)} has been completed. You helped another student solve a problem, and the bounty reward has been sent to your wallet.\n\n$details',
      ),
    ]);
  }

  Future<void> _send({
    required String to,
    required String subject,
    required String text,
  }) async {
    if (!_enabled || to.trim().isEmpty) return;

    final base = _supabaseUrl.endsWith('/')
        ? _supabaseUrl.substring(0, _supabaseUrl.length - 1)
        : _supabaseUrl;
    final uri = Uri.parse('$base/functions/v1/$_functionName');

    try {
      await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_supabaseAnonKey',
          'apikey': _supabaseAnonKey,
        },
        body: jsonEncode({
          'to': to,
          'subject': subject,
          'text': text,
          'html': text
              .split('\n')
              .map((line) => line.trim().isEmpty ? '<br>' : '<p>$line</p>')
              .join(),
        }),
      );
    } catch (_) {
      // Email delivery must not block the bounty workflow.
    }
  }

  Future<_EmailUser> _user(dynamic userId) async {
    final id = userId?.toString();
    if (id == null || id.isEmpty) return const _EmailUser('', '');
    final doc = await _firestore.collection('users').doc(id).get();
    final data = doc.data() ?? {};
    return _EmailUser(
      data['email']?.toString() ?? '',
      data['username']?.toString() ?? '',
    );
  }

  String _title(Map<String, dynamic> data) {
    final title = data['title']?.toString().trim();
    return title == null || title.isEmpty ? 'Your bounty' : title;
  }

  String _orderDetails(Map<String, dynamic> data) {
    final locationType = data['locationType']?.toString() ?? 'Offline';
    final location = locationType == 'Online'
        ? data['meetingLink']?.toString() ?? data['location']?.toString() ?? ''
        : data['location']?.toString() ?? '';
    final remaining = _remaining(data);
    return [
      'Remaining time: $remaining',
      '${locationType == 'Online' ? 'Meeting link' : 'Location'}: ${location.isEmpty ? 'Not provided' : location}',
      'Bounty: RM ${((data['amount'] ?? 0).toDouble()).toStringAsFixed(2)}',
    ].join('\n');
  }

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

class _EmailUser {
  final String email;
  final String username;

  const _EmailUser(this.email, this.username);
}
