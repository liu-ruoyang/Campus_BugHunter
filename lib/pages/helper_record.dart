// This page file renders the current helper's claimed bounty history.
// It watches assigned bounty records, sorts newest first, and opens read-only details.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/helper_record/helper_record_cubit.dart';
import '../bloc/helper_record/helper_record_state.dart';
import '../utils/bounty_rules.dart';

// HelperRecordPage provides HelperRecordCubit for the helper history route.
class HelperRecordPage extends StatelessWidget {
  const HelperRecordPage({super.key});

  @override
  // The build method creates the cubit scope and delegates UI rendering.
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HelperRecordCubit(),
      child: const _HelperRecordView(),
    );
  }
}

// _HelperRecordView renders the Firestore helper record list.
class _HelperRecordView extends StatelessWidget {
  const _HelperRecordView();

  @override
  // The build method watches helper snapshots and sorts them by latest activity.
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12172A),
        foregroundColor: Colors.white,
        elevation: 2,
        title: const Text(
          'Helper Record',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<HelperBountySnapshot>(
        stream: context.read<HelperRecordCubit>().watchHelperRecords(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data();
            return _acceptedStatuses.contains(
                  (data['status'] ?? '').toString().toUpperCase(),
                ) &&
                timestampDate(data['claimedAt']) != null;
          }).toList()
            ..sort((a, b) {
              final aDate = _latestActivityDate(a.data());
              final bDate = _latestActivityDate(b.data());
              if (aDate == null && bDate == null) return 0;
              if (aDate == null) return 1;
              if (bDate == null) return -1;
              return bDate.compareTo(aDate);
            });

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No Helper Records Yet',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final doc = docs[index];
              return _HelperRecordCard(id: doc.id, data: doc.data());
            },
          );
        },
      ),
    );
  }
}

// _HelperRecordCard displays one claimed bounty in the helper history list.
class _HelperRecordCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;

  const _HelperRecordCard({required this.id, required this.data});

  @override
  // The build method formats reward, status, dates, and navigation.
  Widget build(BuildContext context) {
    final status = (data['status'] ?? '').toString().toUpperCase();
    final amount = (data['hunterReceive'] ?? data['amount'] ?? 0).toDouble();
    final claimedAt = timestampDate(data['claimedAt']);
    final completedAt = timestampDate(data['completedAt']);
    final solvedAt = timestampDate(data['solvedAt']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D28),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  data['title']?.toString() ?? 'No Title',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'RM ${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF66FFA2),
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data['description']?.toString() ?? 'No description provided.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, height: 1.45),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StatusTag(status),
              if (claimedAt != null) _MetaChip('Claimed ${_formatDate(claimedAt)}'),
              if (solvedAt != null) _MetaChip('Solved ${_formatDate(solvedAt)}'),
              if (completedAt != null)
                _MetaChip('Completed ${_formatDate(completedAt)}'),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B93FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HelperRecordDetailPage(id: id, data: data),
                  ),
                );
              },
              child: const Text(
                'DETAILS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// HelperRecordDetailPage shows a focused task summary without payment details.
class HelperRecordDetailPage extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;

  const HelperRecordDetailPage({
    super.key,
    required this.id,
    required this.data,
  });

  @override
  // The build method formats the task fields relevant to a helper.
  Widget build(BuildContext context) {
    final status = (data['status'] ?? '').toString().toUpperCase();
    final stacks = (data['techStacks'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Helper Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF12172A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF27304A)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF293462),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.task_alt,
                          color: Color(0xFFC7CCFF),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'HELP RECORD',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            _StatusText(status),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    data['title']?.toString() ?? 'No Title',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _DetailBlock(
                    label: 'Description',
                    child: Text(
                      data['description']?.toString() ??
                          'No description provided.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _DetailBlock(
                    label: 'Tech Stack',
                    child: stacks.isEmpty
                        ? const Text(
                            'Not provided',
                            style: TextStyle(color: Colors.white70),
                          )
                        : Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: stacks
                                .map((stack) => _StackPill(stack))
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 20),
                  _DetailBlock(
                    label: 'Difficulty',
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5867D8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          data['difficulty']?.toString() ?? 'Simple',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (status == 'COMPLETED')
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC7CCFF),
                    side: const BorderSide(color: Color(0xFF27304A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.receipt_long),
                  label: const Text(
                    'Transaction Record',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            HelperTransactionPage(id: id, data: data),
                      ),
                    );
                  },
                ),
              )
            else
              _CurrentStatusPanel(status: status),
          ],
        ),
      ),
    );
  }
}

// HelperTransactionPage displays payment and timing information for one helper record.
class HelperTransactionPage extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;

  const HelperTransactionPage({
    super.key,
    required this.id,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? '').toString().toUpperCase();
    final amount = (data['amount'] ?? 0).toDouble();
    final platformFee = (data['platformFee'] ?? amount * 0.05).toDouble();
    final hunterReceive = (data['hunterReceive'] ?? amount - platformFee)
        .toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Transaction Record',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF10251B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF1E6F48)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'HELPER RECEIVES',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'RM ${hunterReceive.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF66FFA2),
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _StatusText(status),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D28),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(label: 'Order ID', value: id),
                  _DetailRow(
                    label: 'Posted Bounty',
                    value: 'RM ${amount.toStringAsFixed(2)}',
                  ),
                  _DetailRow(
                    label: 'Platform Fee',
                    value: 'RM ${platformFee.toStringAsFixed(2)}',
                  ),
                  _DetailRow(
                    label: 'Helper Receives',
                    value: 'RM ${hunterReceive.toStringAsFixed(2)}',
                  ),
                  _DetailRow(
                    label: 'Claimed At',
                    value: _formatOptionalDate(data['claimedAt']),
                  ),
                  _DetailRow(
                    label: 'Solved At',
                    value: _formatOptionalDate(data['solvedAt']),
                  ),
                  _DetailRow(
                    label: 'Completed At',
                    value: _formatOptionalDate(data['completedAt']),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// _StatusTag renders a compact colored status label for list cards.
class _StatusTag extends StatelessWidget {
  final String status;

  const _StatusTag(this.status);

  @override
  // The build method maps workflow states to badge colors.
  Widget build(BuildContext context) {
    final color = switch (status) {
      'COMPLETED' => const Color(0xFF0E8F52),
      'REVIEW' => const Color(0xFF5867D8),
      'IN PROGRESS' => Colors.orange,
      'REPORTED' => Colors.red,
      _ => Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.isEmpty ? 'UNKNOWN' : status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// _MetaChip renders a small secondary date label on helper cards.
class _MetaChip extends StatelessWidget {
  final String text;

  const _MetaChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF07090D),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white60, fontSize: 11),
      ),
    );
  }
}

// _StatusText displays the detail page status with completed records highlighted.
class _StatusText extends StatelessWidget {
  final String status;

  const _StatusText(this.status);

  @override
  Widget build(BuildContext context) {
    final color = status == 'COMPLETED'
        ? const Color(0xFF00FF85)
        : const Color(0xFF8B93FF);

    return Text(
      status.isEmpty ? 'UNKNOWN' : status,
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
  }
}

// _DetailBlock groups a polished label with custom detail content.
class _DetailBlock extends StatelessWidget {
  final String label;
  final Widget child;

  const _DetailBlock({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1020),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF202845)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF8B93FF),
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// _StackPill renders one technology chip in the helper detail view.
class _StackPill extends StatelessWidget {
  final String text;

  const _StackPill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF202845),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// _CurrentStatusPanel replaces transaction access until a helper record is completed.
class _CurrentStatusPanel extends StatelessWidget {
  final String status;

  const _CurrentStatusPanel({required this.status});

  @override
  Widget build(BuildContext context) {
    final message = switch (status) {
      'IN PROGRESS' => 'This request is currently in progress.',
      'REVIEW' => 'This request is waiting for requester review.',
      'REPORTED' => 'This request has been reported.',
      _ => 'Current request status is ${status.isEmpty ? 'UNKNOWN' : status}.',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF101827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF27304A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFC7CCFF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CURRENT STATUS',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// _DetailRow renders one label-value pair in the helper detail report.
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF8B93FF),
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// This helper chooses the most relevant activity date for sorting helper records.
DateTime? _latestActivityDate(Map<String, dynamic> data) {
  return timestampDate(data['completedAt']) ??
      timestampDate(data['solvedAt']) ??
      timestampDate(data['claimedAt']) ??
      timestampDate(data['createdAt']);
}

// These states represent bounties a helper has already accepted.
const _acceptedStatuses = {'IN PROGRESS', 'REVIEW', 'COMPLETED', 'REPORTED'};

// This helper formats a non-null date for compact list metadata.
String _formatDate(DateTime date) {
  return date.toLocal().toString().split('.').first;
}

// This helper formats optional Firestore date values for the detail report.
String _formatOptionalDate(dynamic value) {
  final date = timestampDate(value);
  if (date == null) return 'Not recorded';
  return _formatDate(date);
}
