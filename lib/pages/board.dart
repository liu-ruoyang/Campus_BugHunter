// This page file renders the hunter bounty board.
// It streams available bounty records, hides expired entries, and lets hunters claim open requests.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/active/active_cubit.dart';
import '../bloc/active/active_state.dart';
import '../bloc/home/home_nav_cubit.dart';
import '../theme/app_theme.dart';
import '../utils/bounty_rules.dart';
import 'bounty_detail.dart';

// BoardPage provides ActiveCubit so board cards can claim bounties.
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

// _BoardView listens for claim results and renders searchable available bounty cards.
class _BoardView extends StatefulWidget {
  const _BoardView();

  @override
  State<_BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<_BoardView> {
  final TextEditingController _searchController = TextEditingController();
  String _locationFilter = 'All';
  String _difficultyFilter = 'All';
  String _stackFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final activeCubit = context.read<ActiveCubit>();

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
        color: colors.background,
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('bounties')
                .snapshots()
                .asyncMap((snapshot) async {
                  await activeCubit.cancelExpiredOpenBounties(snapshot.docs);
                  return snapshot;
                }),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final availableDocs = snapshot.data!.docs.where((doc) {
                final data = doc.data();
                final status = (data['status'] ?? '').toString().toUpperCase();
                final available =
                    status.isEmpty ||
                    status == 'NOT ACCEPTED' ||
                    status == 'OPEN';
                return available && !isExpired(data, DateTime.now());
              }).toList();

              final stackOptions = _stackOptions(availableDocs);
              final docs = availableDocs.where(_matchesFilters).toList();

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _BoardHeader(
                    availableCount: availableDocs.length,
                    colors: colors,
                  ),
                  const SizedBox(height: 18),
                  _SearchBox(
                    controller: _searchController,
                    colors: colors,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  _BoardFilters(
                    locationValue: _locationFilter,
                    difficultyValue: _difficultyFilter,
                    stackValue: _stackFilter,
                    stackOptions: stackOptions,
                    colors: colors,
                    onLocationChanged: (value) {
                      setState(() => _locationFilter = value);
                    },
                    onDifficultyChanged: (value) {
                      setState(() => _difficultyFilter = value);
                    },
                    onStackChanged: (value) {
                      setState(() => _stackFilter = value);
                    },
                  ),
                  const SizedBox(height: 22),
                  if (docs.isEmpty)
                    _EmptyBoard(colors: colors)
                  else
                    ...docs.map(
                      (doc) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _BoardCard(
                          id: doc.id,
                          data: doc.data(),
                          colors: colors,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  bool _matchesFilters(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final search = _searchController.text.trim().toLowerCase();
    final title = data['title']?.toString().toLowerCase() ?? '';
    final description = data['description']?.toString().toLowerCase() ?? '';
    final locationType = data['locationType']?.toString() ?? 'Offline';
    final difficulty = data['difficulty']?.toString() ?? 'Simple';
    final stacks = (data['techStacks'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .toList();

    final matchesSearch =
        search.isEmpty ||
        title.contains(search) ||
        description.contains(search);
    final matchesLocation =
        _locationFilter == 'All' || locationType == _locationFilter;
    final matchesDifficulty =
        _difficultyFilter == 'All' || difficulty == _difficultyFilter;
    final matchesStack = _stackFilter == 'All' || stacks.contains(_stackFilter);

    return matchesSearch &&
        matchesLocation &&
        matchesDifficulty &&
        matchesStack;
  }

  List<String> _stackOptions(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final stacks = <String>{};
    for (final doc in docs) {
      final values = doc.data()['techStacks'] as List<dynamic>? ?? [];
      stacks.addAll(values.map((item) => item.toString()));
    }
    return stacks.toList()..sort();
  }
}

// _BoardCard displays one available bounty with reward, description, stacks, and claim action.
class _BoardCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final AppColors colors;

  const _BoardCard({
    required this.id,
    required this.data,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final amount = (data['hunterReceive'] ?? data['amount'] ?? 0).toDouble();
    final locationType = data['locationType']?.toString() ?? 'Offline';
    final difficulty = data['difficulty']?.toString() ?? 'Simple';
    final urgency = data['urgencyLevel']?.toString() ?? '7 Days';
    final stacks = (data['techStacks'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .toList();

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BountyDetailPage(bountyId: id, data: data),
        ),
      ),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title']?.toString() ?? 'No Title',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoPill(
                            icon: locationType == 'Online'
                                ? Icons.videocam_outlined
                                : Icons.place_outlined,
                            text: locationType,
                            colors: colors,
                          ),
                          _InfoPill(
                            icon: Icons.speed_outlined,
                            text: difficulty,
                            colors: colors,
                          ),
                          _InfoPill(
                            icon: Icons.schedule_outlined,
                            text: urgency,
                            colors: colors,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: colors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.success.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    'RM ${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: colors.success,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data['description']?.toString() ?? 'No description provided.',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.textSecondary, height: 1.45),
            ),
            if (stacks.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: stacks
                    .map((stack) => _StackChip(stack, colors))
                    .toList(),
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
                      backgroundColor: colors.primary,
                      disabledBackgroundColor: colors.surfaceAlt,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'CLAIM BOUNTY',
                      style: TextStyle(
                        color: Colors.white,
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
      ),
    );
  }
}

// _BoardHeader renders the board title and available bounty count.
class _BoardHeader extends StatelessWidget {
  final int availableCount;
  final AppColors colors;

  const _BoardHeader({required this.availableCount, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.travel_explore, color: colors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bounty Board',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$availableCount available request${availableCount == 1 ? '' : 's'}',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// _SearchBox renders the board search input.
class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final AppColors colors;

  const _SearchBox({
    required this.controller,
    required this.onChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(color: colors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Search title or description',
        hintStyle: TextStyle(color: colors.textMuted),
        prefixIcon: Icon(Icons.search, color: colors.primary),
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
      ),
    );
  }
}

// _BoardFilters renders location, difficulty, and tech stack filter controls.
class _BoardFilters extends StatelessWidget {
  final String locationValue;
  final String difficultyValue;
  final String stackValue;
  final List<String> stackOptions;
  final ValueChanged<String> onLocationChanged;
  final ValueChanged<String> onDifficultyChanged;
  final ValueChanged<String> onStackChanged;
  final AppColors colors;

  const _BoardFilters({
    required this.locationValue,
    required this.difficultyValue,
    required this.stackValue,
    required this.stackOptions,
    required this.onLocationChanged,
    required this.onDifficultyChanged,
    required this.onStackChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _FilterDropdown(
          label: 'Location',
          value: locationValue,
          values: const ['All', 'Online', 'Offline'],
          onChanged: onLocationChanged,
          colors: colors,
        ),
        _FilterDropdown(
          label: 'Difficulty',
          value: difficultyValue,
          values: const [
            'All',
            'Simple',
            'Difficult',
            'Super Difficult',
            'Epic',
          ],
          onChanged: onDifficultyChanged,
          colors: colors,
        ),
        _FilterDropdown(
          label: 'Tech Stack',
          value: stackValue,
          values: [
            'All',
            if (stackValue != 'All' && !stackOptions.contains(stackValue))
              stackValue,
            ...stackOptions,
          ],
          onChanged: onStackChanged,
          colors: colors,
        ),
      ],
    );
  }
}

// _FilterDropdown displays one compact dropdown filter.
class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;
  final AppColors colors;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: colors.surfaceAlt,
          iconEnabledColor: colors.primary,
          isExpanded: true,
          items: values.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item == 'All' ? '$label: All' : item,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.textPrimary),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}

// _InfoPill renders compact bounty metadata on the board card.
class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final AppColors colors;

  const _InfoPill({
    required this.icon,
    required this.text,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.chip,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colors.primary, size: 15),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// _EmptyBoard renders the empty state for search and filter results.
class _EmptyBoard extends StatelessWidget {
  final AppColors colors;

  const _EmptyBoard({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off, color: colors.primary, size: 42),
          const SizedBox(height: 14),
          Text(
            'No Available Bounties',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing your search or filters.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// _StackChip renders one compact technology label on a board card.
class _StackChip extends StatelessWidget {
  final String text;
  final AppColors colors;

  const _StackChip(this.text, this.colors);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
