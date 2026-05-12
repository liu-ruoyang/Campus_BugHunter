import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/request_record/request_record_cubit.dart';
import '../bloc/request_record/request_record_state.dart';
import 'edit_post.dart';

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
        backgroundColor: const Color(0xFF050816),
        appBar: appBarSection(),
        body: StreamBuilder<BountySnapshot>(
          stream: cubit.watchRequests(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  'No Requests Yet',
                  style: TextStyle(color: Colors.white),
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

  PreferredSizeWidget appBarSection() {
    return AppBar(
      backgroundColor: const Color(0xFF12172A),
      foregroundColor: Colors.white,
      elevation: 2,
      title: const Text(
        'Request Record',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget requestCard(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
  ) {
    final status = (data['status'] ?? '').toString().toUpperCase();
    final canComplete = status == 'NOT ACCEPTED' || status == 'IN PROGRESS';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D28),
        borderRadius: BorderRadius.circular(20),
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
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "RM ${(data['amount'] ?? 0).toString()}",
                  style: const TextStyle(
                    color: Color(0xFF00FF85),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: canComplete
                      ? () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) {
                              return AlertDialog(
                                backgroundColor: const Color(0xFF1A1D28),
                                title: const Text(
                                  'Complete Request?',
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: const Text(
                                  'Are you sure this request has been completed?',
                                  style: TextStyle(color: Colors.white70),
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
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: status == 'COMPLETED'
                          ? Colors.grey
                          : Colors.red,
                      minimumSize: const Size(110, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: status == 'COMPLETED'
                        ? null
                        : () => context
                              .read<RequestRecordCubit>()
                              .cancelRequest(docId, data),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
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
