import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../bloc/active/active_cubit.dart';
import '../bloc/active/active_state.dart';
import '../bloc/home/role_cubit.dart';

class ActivePage extends StatelessWidget {
  const ActivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ActiveCubit(),
      child: const _ActiveView(),
    );
  }
}

class _ActiveView extends StatelessWidget {
  const _ActiveView();

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
      },
      child: BlocBuilder<RoleCubit, UserRole>(
        builder: (context, role) {
          return StreamBuilder<ActiveBounty?>(
            stream: context.read<ActiveCubit>().watchActive(role),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final bounty = snapshot.data;
              if (bounty == null) {
                return _EmptyActive(role: role);
              }

              return _ActiveBountyContent(bounty: bounty, role: role);
            },
          );
        },
      ),
    );
  }
}

class _ActiveBountyContent extends StatelessWidget {
  final ActiveBounty bounty;
  final UserRole role;

  const _ActiveBountyContent({required this.bounty, required this.role});

  @override
  Widget build(BuildContext context) {
    final data = bounty.data;
    final status = (data['status'] ?? 'IN PROGRESS').toString().toUpperCase();
    final amount = (data['amount'] ?? 0).toDouble();
    final hunterReceive = (data['hunterReceive'] ?? amount).toDouble();
    final stacks = (data['techStacks'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .toList();

    return Container(
      color: const Color(0xFF111315),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(role: role),
              const SizedBox(height: 28),
              _StatusCard(status: status, bountyId: bounty.id),
              const SizedBox(height: 16),
              _TimerCard(status: status),
              const SizedBox(height: 22),
              _PersonCard(role: role, data: data),
              const SizedBox(height: 22),
              _BountyCard(
                amount: role == UserRole.hunter ? hunterReceive : amount,
                difficulty: data['difficulty']?.toString() ?? 'Simple',
              ),
              const SizedBox(height: 22),
              _IssueCard(data: data, stacks: stacks),
              const SizedBox(height: 28),
              _Controls(bountyId: bounty.id, data: data, role: role),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final UserRole role;

  const _Header({required this.role});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 22,
          backgroundColor: Color(0xFF274B57),
          child: Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            role == UserRole.hunter ? 'BugHunter' : 'Requester',
            style: const TextStyle(
              color: Color(0xFFC7CCFF),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => context.read<RoleCubit>().switchRole(),
          icon: const Icon(Icons.swap_horiz, size: 18),
          label: const Text('Switch Role'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFC7CCFF),
            side: BorderSide.none,
            backgroundColor: const Color(0xFF2B2E34),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String status;
  final String bountyId;

  const _StatusCard({required this.status, required this.bountyId});

  @override
  Widget build(BuildContext context) {
    final activeStep = status == 'REVIEW' ? 2 : 1;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CURRENT STATE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _readableStatus(status),
                      style: const TextStyle(
                        color: Color(0xFFC7CCFF),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E3B24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${bountyId.substring(0, bountyId.length > 6 ? 6 : bountyId.length).toUpperCase()}',
                  style: const TextStyle(
                    color: Color(0xFF66FFA2),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              _StepDot(label: 'CLAIMED', active: activeStep >= 0),
              _StepLine(active: activeStep >= 1),
              _StepDot(label: 'SOLVING', active: activeStep >= 1),
              _StepLine(active: activeStep >= 2),
              _StepDot(label: 'REVIEW', active: activeStep >= 2),
              _StepLine(active: false),
              const _StepDot(label: 'PAID', active: false),
            ],
          ),
        ],
      ),
    );
  }

  String _readableStatus(String status) {
    switch (status) {
      case 'REVIEW':
        return 'Review';
      case 'IN PROGRESS':
        return 'In Progress';
      default:
        return status;
    }
  }
}

class _TimerCard extends StatelessWidget {
  final String status;

  const _TimerCard({required this.status});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      color: const Color(0xFF292B2F),
      child: Column(
        children: [
          const Icon(Icons.timer_outlined, color: Color(0xFFC7CCFF), size: 32),
          const SizedBox(height: 8),
          Text(
            status == 'REVIEW' ? 'Waiting Review' : 'In Progress',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ACTIVE TASK',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final UserRole role;
  final Map<String, dynamic> data;

  const _PersonCard({required this.role, required this.data});

  @override
  Widget build(BuildContext context) {
    final userId = role == UserRole.hunter
        ? data['ownerId']?.toString()
        : data['hunterId']?.toString();

    return _Panel(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFF050816),
            child: Icon(Icons.person_pin, color: Color(0xFFC7CCFF)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role == UserRole.hunter ? 'Requester' : 'Hunter',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: userId == null
                      ? null
                      : FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .get(),
                  builder: (context, snapshot) {
                    final userData = snapshot.data?.data();
                    final displayName =
                        userData?['username']?.toString().trim().isNotEmpty ==
                            true
                        ? userData!['username'].toString()
                        : userData?['email']?.toString() ??
                              (userId == null ? 'Not assigned' : 'Unknown');

                    return Text(
                      displayName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white60),
                    );
                  },
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.chat_bubble_outline),
            color: const Color(0xFFC7CCFF),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.phone_outlined),
            color: const Color(0xFFC7CCFF),
          ),
        ],
      ),
    );
  }
}

class _BountyCard extends StatelessWidget {
  final double amount;
  final String difficulty;

  const _BountyCard({required this.amount, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BOUNTY LOCKED',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'RM ${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF66FFA2),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF5867D8),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              'DIFFICULTY: ${difficulty.toUpperCase()}',
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<String> stacks;

  const _IssueCard({required this.data, required this.stacks});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      color: const Color(0xFF2A2C30),
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
              const Icon(Icons.open_in_full, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            data['description']?.toString() ?? 'No description provided.',
            style: const TextStyle(
              color: Colors.white70,
              height: 1.55,
              fontSize: 16,
            ),
          ),
          if (stacks.isNotEmpty) ...[
            const SizedBox(height: 22),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: stacks
                  .map(
                    (stack) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF07090D),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        stack.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final String bountyId;
  final Map<String, dynamic> data;
  final UserRole role;

  const _Controls({
    required this.bountyId,
    required this.data,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? '').toString().toUpperCase();
    final cubit = context.read<ActiveCubit>();

    return BlocBuilder<ActiveCubit, ActiveState>(
      builder: (context, state) {
        final isLoading = state.status == ActiveActionStatus.loading;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (role == UserRole.hunter) ...[
              _SectionTitle('HUNTER CONTROL'),
              _PrimaryButton(
                label: 'MARK AS SOLVED',
                enabled: !isLoading && status == 'IN PROGRESS',
                onPressed: () => cubit.markAsSolved(bountyId),
              ),
            ],
            if (role == UserRole.requester) ...[
              _SectionTitle('REQUESTER CONTROL'),
              _PrimaryButton(
                label: 'COMMIT SOLVED',
                enabled: !isLoading && status == 'REVIEW',
                onPressed: () => cubit.commitSolved(bountyId, data),
              ),
              const SizedBox(height: 14),
              _DangerButton(
                label: 'REPORT ISSUE',
                enabled: !isLoading,
                onPressed: () => cubit.reportIssue(bountyId),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _EmptyActive extends StatelessWidget {
  final UserRole role;

  const _EmptyActive({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111315),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(role: role),
              const Spacer(),
              const Icon(
                Icons.assignment_turned_in_outlined,
                color: Color(0xFFC7CCFF),
                size: 56,
              ),
              const SizedBox(height: 18),
              const Text(
                'No Active Bounty',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                role == UserRole.hunter
                    ? 'Claim a board bounty to start working.'
                    : 'Your active bounty will appear here once a hunter claims it.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, height: 1.4),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  final Color color;

  const _Panel({required this.child, this.color = const Color(0xFF1B1D20)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

class _StepDot extends StatelessWidget {
  final String label;
  final bool active;

  const _StepDot({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF66FFA2) : const Color(0xFF3A3D42);

    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF26292E), width: 4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFF66FFA2) : Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool active;

  const _StepLine({required this.active});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 22),
        color: active ? const Color(0xFF66FFA2) : const Color(0xFF3A3D42),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFF25282D))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Expanded(child: Divider(color: Color(0xFF25282D))),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFAAB5FF),
          disabledBackgroundColor: const Color(0xFF33363C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF102C8B),
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _DangerButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFFB1A7),
          side: const BorderSide(color: Color(0xFF2A2D33)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
      ),
    );
  }
}
