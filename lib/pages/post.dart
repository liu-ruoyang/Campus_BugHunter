// This page file renders the requester form for posting a new bounty.
// It collects issue details, tech stacks, location, urgency, difficulty, bounty amount, and submits through PostFormCubit.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/home/home_nav_cubit.dart';
import '../bloc/post/post_form_cubit.dart';
import '../bloc/post/post_form_state.dart';
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
  // dispose releases all text controllers used by the post form.
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
  // The build method wires PostFormCubit to the form and lays out each request creation section.
  Widget build(BuildContext context) {
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
            backgroundColor: const Color(0xFF050816),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heroSection(),
                    const SizedBox(height: 35),
                    issueTitleSection(),
                    const SizedBox(height: 30),
                    techStackSection(context, state),
                    const SizedBox(height: 30),
                    descriptionSection(),
                    const SizedBox(height: 30),
                    locationSection(context),
                    const SizedBox(height: 30),
                    urgencySection(context, state),
                    const SizedBox(height: 30),
                    difficultySection(context, state),
                    const SizedBox(height: 40),
                    bountySection(state),
                    const SizedBox(height: 40),
                    submitSection(context, state),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // This section displays the page title and short description at the top of the form.
  Widget heroSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Post Bounty',
          style: TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Specify your technical distress signal for the hunter network.',
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
      ],
    );
  }

  // This section captures the short title of the technical issue.
  Widget issueTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel('ISSUE TITLE'),
        buildInput(
          controller: titleController,
          hint: 'Enter issue title',
          height: 70,
        ),
      ],
    );
  }

  // This section renders built-in and custom tech stack chips and updates cubit selections.
  Widget techStackSection(BuildContext context, PostFormState state) {
    final stacks = ['C/C++', 'Java', 'Python', 'Flutter', 'Firebase'];
    final cubit = context.read<PostFormCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel('TECH STACK'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ...stacks.map((stack) {
              final active = state.selectedStacks.contains(stack);
              return GestureDetector(
                onTap: () => cubit.toggleStack(stack),
                child: buildChip(stack, active: active),
              );
            }),
            ...state.customStacks.map((stack) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  buildChip(stack, active: true),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: GestureDetector(
                      onTap: () => cubit.removeCustomStack(stack),
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Colors.red,
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
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Other',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF2A2D38),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (value) {
                        cubit.addCustomStack(value);
                        stackController.clear();
                      },
                    ),
                  )
                : GestureDetector(
                    onTap: cubit.startAddingStack,
                    child: buildChip('+ Add Stack'),
                  ),
          ],
        ),
      ],
    );
  }

  // This section captures the detailed problem description.
  Widget descriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel('PROBLEM DESCRIPTION'),
        buildInput(
          controller: descriptionController,
          hint: 'Describe the bug in technical detail...',
          height: 80,
        ),
      ],
    );
  }

  // This section switches between online and offline location inputs.
  Widget locationSection(BuildContext context) {
    final isOffline = locationType == 'Offline';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel('LOCATION TYPE'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ['Offline', 'Online'].map((type) {
            final active = locationType == type;
            return GestureDetector(
              onTap: () => setState(() => locationType = type),
              child: buildChip(type, active: active),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        buildLabel(isOffline ? 'LOCATION' : 'MEETING LINK'),
        buildInput(
          controller: isOffline ? locationController : meetingLinkController,
          hint: isOffline
              ? 'e.g. Engineering Hall Room 302'
              : 'e.g. https://meet.google.com/...',
          height: 70,
          keyboardType: isOffline ? null : TextInputType.url,
        ),
      ],
    );
  }

  // This section renders difficulty choices used by minimum bounty scoring.
  Widget difficultySection(BuildContext context, PostFormState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel('ESTIMATED DIFFICULTY'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: difficultyLevels.map((difficulty) {
            final active = state.selectedDifficulty == difficulty;
            return GestureDetector(
              onTap: () =>
                  context.read<PostFormCubit>().selectDifficulty(difficulty),
              child: buildDifficulty(difficulty, active: active),
            );
          }).toList(),
        ),
      ],
    );
  }

  // This section renders urgency choices used by expiration and minimum bounty scoring.
  Widget urgencySection(BuildContext context, PostFormState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel('URGENCY LEVEL'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: urgencyLevels.map((urgency) {
            final active = state.selectedUrgency == urgency;
            return GestureDetector(
              onTap: () => context.read<PostFormCubit>().selectUrgency(urgency),
              child: buildDifficulty(urgency, active: active),
            );
          }).toList(),
        ),
      ],
    );
  }

  // This section shows wallet balance, calculated minimum bounty, and the reward amount input.
  Widget bountySection(PostFormState state) {
    final minimumAmount = minimumBounty(
      state.selectedUrgency,
      state.selectedDifficulty,
    );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D28),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bounty Amount',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF262A36),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AVAILABLE BALANCE',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'RM ${state.walletBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF00FF85),
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFF00FF85),
                  size: 42,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Minimum bounty: RM ${minimumAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFFFFD166),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          buildLabel('BOUNTY AMOUNT'),
          buildInput(
            controller: amountController,
            hint: 'Enter amount',
            height: 70,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  // This section renders the submit button and sends the collected form values to the cubit.
  Widget submitSection(BuildContext context, PostFormState state) {
    final submitting = state.status == PostFormStatus.submitting;

    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFA5B4FF),
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
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.rocket_launch, color: Color(0xFF18206F)),
        label: const Text(
          'POST BOUNTY',
          style: TextStyle(
            color: Color(0xFF18206F),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  // This helper renders the uppercase labels used above form controls.
  Widget buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF8B93FF),
          fontSize: 12,
          letterSpacing: 3,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // This helper builds a dark styled text input with optional controller and keyboard type.
  Widget buildInput({
    required String hint,
    required double height,
    TextEditingController? controller,
    TextInputType? keyboardType,
  }) {
    return SizedBox(
      height: height,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: height > 100 ? null : 1,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: const Color(0xFF0B0E1A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF8B93FF), width: 2),
          ),
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  // This helper builds the small rounded chips used by stack and location selections.
  Widget buildChip(String text, {bool active = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFC7CCFF) : const Color(0xFF2A2D38),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? const Color(0xFF18206F) : Colors.white70,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // This helper builds fixed-size option buttons used by difficulty and urgency selections.
  Widget buildDifficulty(String text, {bool active = false}) {
    return Container(
      width: 170,
      height: 55,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF373D68) : const Color(0xFF2A2D38),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
