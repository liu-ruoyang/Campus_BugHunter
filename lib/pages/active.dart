// This page file renders the currently active bounty for requester or hunter roles.
// It watches active bounty data, shows task progress, remaining time, issue details, and role-specific controls.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../bloc/active/active_cubit.dart';
import '../bloc/active/active_state.dart';
import '../bloc/home/role_cubit.dart';
import '../theme/app_theme.dart';
import '../utils/bounty_rules.dart';
import 'bounty_detail.dart';
import 'chat.dart';

// ActivePage provides ActiveCubit for watching and acting on active bounties.
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

// _ActiveView combines role state and active bounty stream data to decide what active UI to show.
class _ActiveView extends StatelessWidget {
  const _ActiveView();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

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
                return Container(
                  color: colors.background,
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              final bounty = snapshot.data;
              if (bounty == null) {
                return _EmptyActive(role: role, colors: colors);
              }

              return _ActiveBountyContent(
                bounty: bounty,
                role: role,
                colors: colors,
              );
            },
          );
        },
      ),
    );
  }
}

// _ActiveBountyContent lays out all sections for a single active bounty document.
class _ActiveBountyContent extends StatelessWidget {
  final ActiveBounty bounty;
  final UserRole role;
  final AppColors colors;

  const _ActiveBountyContent({
    required this.bounty,
    required this.role,
    required this.colors,
  });

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
      color: colors.background,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(role: role, colors: colors),
              const SizedBox(height: 28),
              _StatusCard(status: status, bountyId: bounty.id, colors: colors),
              const SizedBox(height: 16),
              _TimerCard(status: status, data: data, colors: colors),
              const SizedBox(height: 22),
              _PersonCard(
                bountyId: bounty.id,
                role: role,
                data: data,
                colors: colors,
              ),
              const SizedBox(height: 22),
              _BountyCard(
                amount: role == UserRole.hunter ? hunterReceive : amount,
                difficulty: data['difficulty']?.toString() ?? 'Simple',
                colors: colors,
              ),
              const SizedBox(height: 22),
              _IssueCard(
                bountyId: bounty.id,
                data: data,
                stacks: stacks,
                colors: colors,
              ),
              const SizedBox(height: 28),
              _Controls(
                bountyId: bounty.id,
                data: data,
                role: role,
                colors: colors,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final UserRole role;
  final AppColors colors;

  const _Header({required this.role, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: colors.primarySoft,
          child: Icon(Icons.person, color: colors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            role == UserRole.hunter ? 'BugHunter' : 'Requester',
            style: TextStyle(
              color: colors.primary,
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
            foregroundColor: colors.primary,
            side: BorderSide(color: colors.border),
            backgroundColor: colors.surfaceAlt,
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
  final AppColors colors;

  const _StatusCard({
    required this.status,
    required this.bountyId,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final activeStep = status == 'REVIEW' ? 2 : 1;

    return _Panel(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT STATE',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _readableStatus(status),
                      style: TextStyle(
                        color: colors.primary,
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
                  color: colors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${bountyId.substring(0, bountyId.length > 6 ? 6 : bountyId.length).toUpperCase()}',
                  style: TextStyle(
                    color: colors.success,
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
              _StepDot(
                label: 'CLAIMED',
                active: activeStep >= 0,
                colors: colors,
              ),
              _StepLine(active: activeStep >= 1, colors: colors),
              _StepDot(
                label: 'SOLVING',
                active: activeStep >= 1,
                colors: colors,
              ),
              _StepLine(active: activeStep >= 2, colors: colors),
              _StepDot(
                label: 'REVIEW',
                active: activeStep >= 2,
                colors: colors,
              ),
              _StepLine(active: false, colors: colors),
              _StepDot(label: 'PAID', active: false, colors: colors),
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
  final Map<String, dynamic> data;
  final AppColors colors;

  const _TimerCard({
    required this.status,
    required this.data,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final remainingText = _remainingText(data);

    return _Panel(
      colors: colors,
      colorOverride: colors.primary.withValues(alpha: 0.05),
      child: Column(
        children: [
          Icon(Icons.timer_outlined, color: colors.primary, size: 32),
          const SizedBox(height: 8),
          Text(
            status == 'REVIEW' ? 'Waiting Review' : 'In Progress',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (status == 'IN PROGRESS' && remainingText != null) ...[
            const SizedBox(height: 8),
            Text(
              remainingText,
              style: TextStyle(
                color: colors.success,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'ACTIVE TASK',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  String? _remainingText(Map<String, dynamic> data) {
    final expiresAt = timestampDate(data['expiresAt']);
    if (expiresAt == null) return null;

    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative || remaining.inSeconds == 0) {
      return 'Expired';
    }

    if (remaining.inDays < 1) {
      final hours = remaining.inHours;
      if (hours < 1) return 'Less than 1 hour remaining';
      return '$hours hour${hours == 1 ? '' : 's'} remaining';
    }

    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    return '$days day${days == 1 ? '' : 's'} $hours hour${hours == 1 ? '' : 's'} remaining';
  }
}

class _PersonCard extends StatelessWidget {
  final String bountyId;
  final UserRole role;
  final Map<String, dynamic> data;
  final AppColors colors;

  const _PersonCard({
    required this.bountyId,
    required this.role,
    required this.data,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final userId = role == UserRole.hunter
        ? data['ownerId']?.toString()
        : data['hunterId']?.toString();

    return _Panel(
      colors: colors,
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: colors.background,
            child: Icon(Icons.person_pin, color: colors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role == UserRole.hunter ? 'Requester' : 'Hunter',
                  style: TextStyle(
                    color: colors.textPrimary,
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
                      style: TextStyle(color: colors.textSecondary),
                    );
                  },
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: userId == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          bountyId: bountyId,
                          peerName: role == UserRole.hunter
                              ? 'Requester'
                              : 'Hunter',
                        ),
                      ),
                    );
                  },
            icon: const Icon(Icons.chat_bubble_outline),
            color: colors.primary,
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.phone_outlined),
            color: colors.primary,
          ),
        ],
      ),
    );
  }
}

class _BountyCard extends StatelessWidget {
  final double amount;
  final String difficulty;
  final AppColors colors;

  const _BountyCard({
    required this.amount,
    required this.difficulty,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      colors: colors,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BOUNTY LOCKED',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'RM ${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: colors.success,
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
              color: colors.primary,
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
  final String bountyId;
  final Map<String, dynamic> data;
  final List<String> stacks;
  final AppColors colors;

  const _IssueCard({
    required this.bountyId,
    required this.data,
    required this.stacks,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    void openDetails() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BountyDetailPage(bountyId: bountyId, data: data),
        ),
      );
    }

    return InkWell(
      onTap: openDetails,
      borderRadius: BorderRadius.circular(16),
      child: _Panel(
        colors: colors,
        colorOverride: colors.surfaceAlt,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    data['title']?.toString() ?? 'No Title',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Open details',
                  onPressed: openDetails,
                  icon: Icon(Icons.open_in_full, color: colors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              data['description']?.toString() ?? 'No description provided.',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textSecondary,
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
                          color: colors.chip,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          stack.toUpperCase(),
                          style: TextStyle(
                            color: colors.textSecondary,
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
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final String bountyId;
  final Map<String, dynamic> data;
  final UserRole role;
  final AppColors colors;

  const _Controls({
    required this.bountyId,
    required this.data,
    required this.role,
    required this.colors,
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
              _SectionTitle('HUNTER CONTROL', colors: colors),
              _PrimaryButton(
                label: 'MARK AS SOLVED',
                enabled: !isLoading && status == 'IN PROGRESS',
                colors: colors,
                onPressed: () => cubit.markAsSolved(bountyId),
              ),
            ],
            if (role == UserRole.requester) ...[
              _SectionTitle('REQUESTER CONTROL', colors: colors),
              _PrimaryButton(
                label: 'COMMIT SOLVED',
                enabled: !isLoading && status == 'REVIEW',
                colors: colors,
                onPressed: () => cubit.commitSolved(bountyId, data),
              ),
              const SizedBox(height: 14),
              _DangerButton(
                label: 'REPORT ISSUE',
                enabled: !isLoading,
                colors: colors,
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
  final AppColors colors;

  const _EmptyActive({required this.role, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(role: role, colors: colors),
              const Spacer(),
              Icon(
                Icons.assignment_turned_in_outlined,
                color: colors.primarySoft,
                size: 56,
              ),
              const SizedBox(height: 18),
              Text(
                'No Active Bounty',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
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
                style: TextStyle(color: colors.textSecondary, height: 1.4),
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
  final AppColors colors;
  final Color? colorOverride;

  const _Panel({required this.child, required this.colors, this.colorOverride});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorOverride ?? colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StepDot extends StatelessWidget {
  final String label;
  final bool active;
  final AppColors colors;

  const _StepDot({
    required this.label,
    required this.active,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? colors.success : colors.border;

    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: colors.surfaceAlt, width: 4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: active ? colors.success : colors.textMuted,
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
  final AppColors colors;

  const _StepLine({required this.active, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 22),
        color: active ? colors.success : colors.border,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final AppColors colors;

  const _SectionTitle(this.text, {required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: colors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              text,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: Divider(color: colors.border)),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  final AppColors colors;

  const _PrimaryButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          disabledBackgroundColor: colors.surfaceAlt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
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
  final AppColors colors;

  const _DangerButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.danger,
          side: BorderSide(color: enabled ? colors.danger : colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: enabled ? colors.danger : colors.textMuted,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
