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
        appBar: appBarSection(context),
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

  PreferredSizeWidget appBarSection(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.of(context).surface,
      title: const Text('Request Record'),
    );
  }

  Widget requestCard(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
  ) {
    final status = (data['status'] ?? '').toString().toUpperCase();
    final canComplete = status == 'NOT ACCEPTED' || status == 'IN PROGRESS';
    final canCancel =
        status != 'COMPLETED' &&
        status != 'CANCELLED' &&
        status != 'OVERDUE' &&
        status != 'REPORTED';
    final expiresAt = timestampDate(data['expiresAt']);
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
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
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.monetization_on_outlined,
                      color: colors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "RM ${(data['amount'] ?? 0).toString()}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      color: colors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Urgency: ${data['urgencyLevel'] ?? '7 Days'}',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                  ],
                ),
                if (expiresAt != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: colors.textMuted,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Expires: ${expiresAt.toLocal().toString().split('.').first}',
                          style: TextStyle(color: colors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
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
                                      backgroundColor: colors.success,
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      'Confirm',
                                      style: TextStyle(color: Colors.white),
                                    ),
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
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      minimumSize: const Size(120, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      final requestCubit = context.read<RequestRecordCubit>();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: requestCubit,
                            child: EditPostPage(docId: docId, data: data),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (canCancel) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.danger,
                        side: BorderSide(color: colors.danger),
                        minimumSize: const Size(120, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => context
                          .read<RequestRecordCubit>()
                          .cancelRequest(docId, data),
                      icon: Icon(
                        Icons.cancel_outlined,
                        color: colors.danger,
                        size: 18,
                      ),
                      label: Text(
                        'Cancel',
                        style: TextStyle(
                          color: colors.danger,
                          fontWeight: FontWeight.bold,
                        ),
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
      case 'OVERDUE':
        color = Colors.deepPurple;
        break;
      case 'REPORTED':
        color = Colors.redAccent;
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
          fontSize: 12,
        ),
      ),
    );
  }
}
