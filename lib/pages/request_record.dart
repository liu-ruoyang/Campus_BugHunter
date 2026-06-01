// This page file renders the requester's request history.
// It watches owned bounty records, sorts newest first, shows status actions, and opens editable or read-only details.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/request_record/request_record_cubit.dart';
import '../bloc/request_record/request_record_state.dart';
import '../theme/app_theme.dart';
import '../utils/bounty_rules.dart';
import 'edit_post.dart';

// RequestRecordPage provides RequestRecordCubit for the request history route.
class RequestRecordPage extends StatelessWidget {
  const RequestRecordPage({super.key});

  @override
  // The build method creates the cubit scope and delegates UI rendering to _RequestRecordView.
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RequestRecordCubit(),
      child: const _RequestRecordView(),
    );
  }
}

// _RequestRecordView listens for request action messages and renders the Firestore request list.
class _RequestRecordView extends StatelessWidget {
  const _RequestRecordView();

  @override
  // The build method watches request snapshots, sorts them by creation time, and renders request cards.
  Widget build(BuildContext context) {
    final cubit = context.read<RequestRecordCubit>();

    return BlocListener<RequestRecordCubit, RequestRecordState>(
      listenWhen: (previous, current) => previous.message != current.message,
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.of(context).background,
        appBar: appBarSection(),
        body: StreamBuilder<BountySnapshot>(
          stream: cubit.watchRequests(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs.toList()
              ..sort((a, b) {
                final aCreatedAt = timestampDate(a.data()['createdAt']);
                final bCreatedAt = timestampDate(b.data()['createdAt']);
                if (aCreatedAt == null && bCreatedAt == null) return 0;
                if (aCreatedAt == null) return 1;
                if (bCreatedAt == null) return -1;
                return bCreatedAt.compareTo(aCreatedAt);
              });
            if (docs.isEmpty) {
              return Center(
                child: Text(
                  'No Requests Yet',
                  style: TextStyle(color: AppColors.of(context).textPrimary),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: docs.map((doc) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: requestCard(context, doc.data(), doc.id),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  // This helper builds the app bar for the request record screen.
  PreferredSizeWidget appBarSection() {
    return AppBar(elevation: 2, title: const Text('Request Record'));
  }

  // This helper renders one request card with amount, urgency, expiration, status, details, and cancel controls.
  Widget requestCard(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
  ) {
    final status = (data['status'] ?? '').toString().toUpperCase();
    final canComplete = status == 'NOT ACCEPTED' || status == 'IN PROGRESS';
    final canCancel = status != 'COMPLETED' && status != 'CANCELLED';
    final expiresAt = timestampDate(data['expiresAt']);
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] ?? 'No Title',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ).copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: 14),
                Text(
                  "RM ${(data['amount'] ?? 0).toString()}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ).copyWith(color: colors.success),
                ),
                const SizedBox(height: 10),
                Text(
                  'Urgency: ${data['urgencyLevel'] ?? '7 Days'}',
                  style: TextStyle(color: colors.textSecondary),
                ),
                if (expiresAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Expires: ${expiresAt.toLocal().toString().split('.').first}',
                    style: TextStyle(color: colors.textMuted),
                  ),
                ],
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: canComplete
                      ? () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) {
                              return AlertDialog(
                                backgroundColor: colors.surfaceAlt,
                                title: const Text('Complete Request?'),
                                content: const Text(
                                  'Are you sure this request has been completed?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Confirm'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirm == true) {
                            if (!context.mounted) return;
                            await context
                                .read<RequestRecordCubit>()
                                .completeRequest(docId);
                          }
                        }
                      : null,
                  child: statusTag(status),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B93FF),
                      minimumSize: const Size(110, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditPostPage(docId: docId, data: data),
                        ),
                      );
                    },
                    child: const Text(
                      'Details',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  if (canCancel) ...[
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size(110, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => context
                          .read<RequestRecordCubit>()
                          .cancelRequest(docId, data),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // This helper renders a colored status label for each request state.
  Widget statusTag(String text) {
    Color color;
    switch (text) {
      case 'NOT ACCEPTED':
        color = Colors.red;
        break;
      case 'IN PROGRESS':
        color = Colors.orange;
        break;
      case 'COMPLETED':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
