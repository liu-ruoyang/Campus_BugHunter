import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/edit_post/edit_post_cubit.dart';
import '../bloc/edit_post/edit_post_state.dart';
import '../utils/bounty_rules.dart';

class EditPostPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const EditPostPage({super.key, required this.docId, required this.data});

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final amountController = TextEditingController();
  final stackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    titleController.text = widget.data['title'] ?? '';
    descriptionController.text = widget.data['description'] ?? '';
    locationController.text = widget.data['location'] ?? '';
    amountController.text = widget.data['amount'].toString();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EditPostCubit(initialData: widget.data),
      child: BlocConsumer<EditPostCubit, EditPostState>(
        listenWhen: (previous, current) => previous.message != current.message,
        listener: (context, state) {
          if (state.message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message!)));
          }
          if (state.status == EditPostStatus.success) {
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: const Color(0xFF050816),
            appBar: appBarSection(),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  inputSection('TITLE', titleController, 70),
                  const SizedBox(height: 20),
                  inputSection('DESCRIPTION', descriptionController, 70),
                  const SizedBox(height: 20),
                  techStackSection(context, state),
                  const SizedBox(height: 20),
                  difficultySection(context, state),
                  const SizedBox(height: 20),
                  urgencyInfoSection(state),
                  const SizedBox(height: 20),
                  extensionSection(context, state),
                  const SizedBox(height: 20),
                  inputSection('LOCATION', locationController, 70),
                  const SizedBox(height: 20),
                  minimumBountySection(state),
                  const SizedBox(height: 12),
                  inputSection('AMOUNT', amountController, 70),
                  const SizedBox(height: 30),
                  updateButton(context, state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget appBarSection() {
    return AppBar(
      backgroundColor: const Color(0xFF12172A),
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Edit Request',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget techStackSection(BuildContext context, EditPostState state) {
    final stacks = ['C/C++', 'Java', 'Python', 'Flutter', 'Firebase'];
    final cubit = context.read<EditPostCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel('TECH STACK'),
        const SizedBox(height: 14),
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

  Widget difficultySection(BuildContext context, EditPostState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel('DIFFICULTY'),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: difficultyLevels.map((difficulty) {
              final active = state.selectedDifficulty == difficulty;
              return GestureDetector(
                onTap: () =>
                    context.read<EditPostCubit>().selectDifficulty(difficulty),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: active ? Colors.orange : const Color(0xFF1A1D28),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    difficulty,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget urgencyInfoSection(EditPostState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel('URGENCY LEVEL'),
        const SizedBox(height: 10),
        buildChip(state.selectedUrgency, active: true),
      ],
    );
  }

  Widget extensionSection(BuildContext context, EditPostState state) {
    const options = [0, 1, 3, 7];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel('EXTEND TIME'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((days) {
            final active = state.extensionDays == days;
            final label = days == 0
                ? 'No Extension'
                : '+$days Day${days == 1 ? '' : 's'}';
            return GestureDetector(
              onTap: () =>
                  context.read<EditPostCubit>().selectExtensionDays(days),
              child: buildChip(label, active: active),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget minimumBountySection(EditPostState state) {
    final minimumAmount = minimumBounty(
      state.selectedUrgency,
      state.selectedDifficulty,
    );

    return Text(
      'Minimum bounty: RM ${minimumAmount.toStringAsFixed(2)}',
      style: const TextStyle(
        color: Color(0xFFFFD166),
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget updateButton(BuildContext context, EditPostState state) {
    final status = (widget.data['status'] ?? '').toString().toUpperCase();
    final submitting = state.status == EditPostStatus.submitting;
    final locked = status == 'COMPLETED' || status == 'CANCELLED';

    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: locked ? Colors.grey : const Color(0xFF8B93FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: locked || submitting
            ? null
            : () => context.read<EditPostCubit>().updateBounty(
                docId: widget.docId,
                originalData: widget.data,
                title: titleController.text,
                description: descriptionController.text,
                location: locationController.text,
                amountText: amountController.text,
              ),
        child: submitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'UPDATE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget inputSection(
    String label,
    TextEditingController controller,
    double height,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel(label),
        const SizedBox(height: 10),
        SizedBox(
          height: height,
          child: TextField(
            controller: controller,
            maxLines: height > 100 ? null : 1,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
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
                borderSide: const BorderSide(
                  color: Color(0xFF8B93FF),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(color: Color(0xFF8B93FF), letterSpacing: 2),
    );
  }

  Widget buildChip(String text, {bool active = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF8B93FF) : const Color(0xFF1A1D28),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}
