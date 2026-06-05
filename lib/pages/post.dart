// This page file renders the requester form for posting a new bounty.
// It collects issue details, tech stacks, location, urgency, difficulty, bounty amount, and submits through PostFormCubit.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/home/home_nav_cubit.dart';
import '../bloc/post/post_form_cubit.dart';
import '../bloc/post/post_form_state.dart';
import '../theme/app_theme.dart';
import '../utils/bounty_rules.dart';

// PostPage owns the request creation route and its form controllers.
class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

// _PostPageState manages local text inputs and delegates business rules to PostFormCubit.
class _PostPageState extends State<PostPage> {
  final stackController = TextEditingController();
  final amountController = TextEditingController();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final meetingLinkController = TextEditingController();
  String locationType = 'Offline';

  @override
  void dispose() {
    stackController.dispose();
    amountController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    meetingLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    
    return BlocProvider(
      create: (_) => PostFormCubit()..loadWallet(),
      child: BlocConsumer<PostFormCubit, PostFormState>(
        listenWhen: (previous, current) => previous.message != current.message,
        listener: (context, state) async {
          if (state.message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message!)));
          }
          if (state.status == PostFormStatus.success) {
            await Future.delayed(const Duration(milliseconds: 800));
            if (!context.mounted) return;
            context.read<HomeNavCubit>().selectTab(0);
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: colors.background,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heroSection(colors),
                    const SizedBox(height: 35),
                    _SectionCard(
                      colors: colors,
                      child: issueTitleSection(colors),
                    ),
                    const SizedBox(height: 20),
                    _SectionCard(
                      colors: colors,
                      child: techStackSection(context, state, colors),
                    ),
                    const SizedBox(height: 20),
                    _SectionCard(
                      colors: colors,
                      child: descriptionSection(colors),
                    ),
                    const SizedBox(height: 20),
                    _SectionCard(
                      colors: colors,
                      child: locationSection(context, colors),
                    ),
                    const SizedBox(height: 20),
                    _SectionCard(
                      colors: colors,
                      child: urgencySection(context, state, colors),
                    ),
                    const SizedBox(height: 20),
                    _SectionCard(
                      colors: colors,
                      child: difficultySection(context, state, colors),
                    ),
                    const SizedBox(height: 30),
                    bountySection(state, colors),
                    const SizedBox(height: 40),
                    submitSection(context, state, colors),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget heroSection(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Post Bounty',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Specify your technical distress signal for the hunter network.',
          style: TextStyle(color: colors.textSecondary, fontSize: 15),
        ),
      ],
    );
  }

  Widget issueTitleSection(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel('ISSUE TITLE', Icons.title, colors),
        buildInput(
          controller: titleController,
          hint: 'Enter issue title',
          height: 70,
          colors: colors,
        ),
      ],
    );
  }

  Widget techStackSection(BuildContext context, PostFormState state, AppColors colors) {
    final stacks = ['C/C++', 'Java', 'Python', 'Flutter', 'Firebase'];
    final cubit = context.read<PostFormCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel('TECH STACK', Icons.code, colors),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ...stacks.map((stack) {
              final active = state.selectedStacks.contains(stack);
              return GestureDetector(
                onTap: () => cubit.toggleStack(stack),
                child: buildChip(stack, colors, active: active),
              );
            }),
            ...state.customStacks.map((stack) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  buildChip(stack, colors, active: true),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: GestureDetector(
                      onTap: () => cubit.removeCustomStack(stack),
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: colors.danger,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
            state.isAddingStack
                ? SizedBox(
                    width: 140,
                    child: TextField(
                      controller: stackController,
                      autofocus: true,
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Other',
                        hintStyle: TextStyle(color: colors.textMuted),
                        filled: true,
                        fillColor: colors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onSubmitted: (value) {
                        cubit.addCustomStack(value);
                        stackController.clear();
                      },
                    ),
                  )
                : GestureDetector(
                    onTap: cubit.startAddingStack,
                    child: buildChip('+ Add Stack', colors),
                  ),
          ],
        ),
      ],
    );
  }

  Widget descriptionSection(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel('PROBLEM DESCRIPTION', Icons.description_outlined, colors),
        buildInput(
          controller: descriptionController,
          hint: 'Describe the bug in technical detail...',
          height: 100,
          colors: colors,
        ),
      ],
    );
  }

  Widget locationSection(BuildContext context, AppColors colors) {
    final isOffline = locationType == 'Offline';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel('LOCATION TYPE', Icons.map_outlined, colors),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ['Offline', 'Online'].map((type) {
            final active = locationType == type;
            return GestureDetector(
              onTap: () => setState(() => locationType = type),
              child: buildChip(type, colors, active: active),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        buildLabel(isOffline ? 'LOCATION' : 'MEETING LINK', isOffline ? Icons.place_outlined : Icons.link, colors),
        buildInput(
          controller: isOffline ? locationController : meetingLinkController,
          hint: isOffline
              ? 'e.g. Engineering Hall Room 302'
              : 'e.g. https://meet.google.com/...',
          height: 70,
          keyboardType: isOffline ? null : TextInputType.url,
          colors: colors,
        ),
      ],
    );
  }

  Widget difficultySection(BuildContext context, PostFormState state, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel('ESTIMATED DIFFICULTY', Icons.speed_outlined, colors),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: difficultyLevels.map((difficulty) {
            final active = state.selectedDifficulty == difficulty;
            return GestureDetector(
              onTap: () =>
                  context.read<PostFormCubit>().selectDifficulty(difficulty),
              child: buildDifficulty(difficulty, colors, active: active),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget urgencySection(BuildContext context, PostFormState state, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel('URGENCY LEVEL', Icons.schedule_outlined, colors),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: urgencyLevels.map((urgency) {
            final active = state.selectedUrgency == urgency;
            return GestureDetector(
              onTap: () => context.read<PostFormCubit>().selectUrgency(urgency),
              child: buildDifficulty(urgency, colors, active: active),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget bountySection(PostFormState state, AppColors colors) {
    final minimumAmount = minimumBounty(
      state.selectedUrgency,
      state.selectedDifficulty,
    );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monetization_on_outlined, color: colors.success, size: 28),
              const SizedBox(width: 12),
              Text(
                'Bounty Amount',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AVAILABLE BALANCE',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'RM ${state.walletBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: colors.success,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.account_balance_wallet,
                  color: colors.success,
                  size: 42,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.info_outline, color: colors.warning, size: 16),
              const SizedBox(width: 8),
              Text(
                'Minimum bounty: RM ${minimumAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: colors.warning,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          buildLabel('BOUNTY AMOUNT', Icons.attach_money, colors),
          buildInput(
            controller: amountController,
            hint: 'Enter amount',
            height: 70,
            keyboardType: TextInputType.number,
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget submitSection(BuildContext context, PostFormState state, AppColors colors) {
    final submitting = state.status == PostFormStatus.submitting;

    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: submitting
            ? null
            : () => context.read<PostFormCubit>().createBounty(
                title: titleController.text,
                description: descriptionController.text,
                locationType: locationType,
                location: locationType == 'Offline'
                    ? locationController.text
                    : meetingLinkController.text,
                amountText: amountController.text,
              ),
        icon: submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.rocket_launch, color: Colors.white),
        label: const Text(
          'POST BOUNTY',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget buildLabel(String text, IconData icon, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: colors.primary, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: colors.primary,
              fontSize: 12,
              letterSpacing: 3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInput({
    required String hint,
    required double height,
    required AppColors colors,
    TextEditingController? controller,
    TextInputType? keyboardType,
  }) {
    return SizedBox(
      height: height,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: height > 100 ? null : 1,
        style: TextStyle(color: colors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: colors.textMuted),
          filled: true,
          fillColor: colors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget buildChip(String text, AppColors colors, {bool active = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: active ? colors.primarySoft : colors.chip,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? colors.primary : colors.border),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? colors.primary : colors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget buildDifficulty(String text, AppColors colors, {bool active = false}) {
    return Container(
      width: 170,
      height: 55,
      decoration: BoxDecoration(
        color: active ? colors.primarySoft : colors.chip,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: active ? colors.primary : colors.border),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: active ? colors.primary : colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// _SectionCard adds a subtle background and padding around form sections.
class _SectionCard extends StatelessWidget {
  final Widget child;
  final AppColors colors;

  const _SectionCard({required this.child, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
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
