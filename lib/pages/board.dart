import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/active/active_cubit.dart';
import '../bloc/active/active_state.dart';
import '../bloc/home/home_nav_cubit.dart';
import '../utils/bounty_rules.dart';

class BoardPage extends StatelessWidget {
  const BoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ActiveCubit(),
      child: const _BoardView(),
    );
  }
}

class _BoardView extends StatelessWidget {
  const _BoardView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<ActiveCubit, ActiveState>(
      listenWhen: (previous, current) => previous.message != current.message,
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!)));
        }
        if (state.status == ActiveActionStatus.success &&
            state.message == 'Bounty claimed') {
          context.read<HomeNavCubit>().selectTab(1);
        }
      },
      child: Container(
        color: const Color(0xFF050816),
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('bounties')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data();
                final status = (data['status'] ?? '').toString().toUpperCase();
                final available =
                    status.isEmpty ||
                    status == 'NOT ACCEPTED' ||
                    status == 'OPEN';
                return available && !isExpired(data, DateTime.now());
              }).toList();

              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No Available Bounties',
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
                  return _BoardCard(id: doc.id, data: doc.data());
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BoardCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;

  const _BoardCard({required this.id, required this.data});

  @override
  Widget build(BuildContext context) {
    final amount = (data['hunterReceive'] ?? data['amount'] ?? 0).toDouble();
    final stacks = (data['techStacks'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D28),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              Text(
                'RM ${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF66FFA2),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data['description']?.toString() ?? 'No description provided.',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, height: 1.45),
          ),
          if (stacks.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: stacks.map((stack) => _StackChip(stack)).toList(),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: BlocBuilder<ActiveCubit, ActiveState>(
              builder: (context, state) {
                final loading = state.status == ActiveActionStatus.loading;
                return ElevatedButton(
                  onPressed: loading
                      ? null
                      : () => context.read<ActiveCubit>().claimBounty(id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAAB5FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'CLAIM BOUNTY',
                    style: TextStyle(
                      color: Color(0xFF102C8B),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StackChip extends StatelessWidget {
  final String text;

  const _StackChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF07090D),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
