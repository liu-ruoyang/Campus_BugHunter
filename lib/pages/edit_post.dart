// This page file renders editable request details and read-only completed or cancelled request reports.
// It updates existing bounties through EditPostCubit when the request is still editable.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/edit_post/edit_post_cubit.dart';
import '../bloc/edit_post/edit_post_state.dart';
import '../utils/bounty_rules.dart';

// EditPostPage receives a bounty document id and data map from the request record list.
class EditPostPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const EditPostPage({super.key, required this.docId, required this.data});

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

// _EditPostPageState initializes controllers from the bounty data and builds the editable form.
class _EditPostPageState extends State<EditPostPage> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final amountController = TextEditingController();
  final stackController = TextEditingController();

  @override
  // initState fills the edit controllers with the selected bounty's current stored values.
  void initState() {
    super.initState();
    titleController.text = widget.data['title'] ?? '';
    descriptionController.text = widget.data['description'] ?? '';
    locationController.text = widget.data['location'] ?? '';
    amountController.text = widget.data['amount'].toString();
  }

  @override
  // The build method chooses a read-only report for locked requests or an editable bloc-backed form for open requests.
  Widget build(BuildContext context) {
    final status = (widget.data['status'] ?? '').toString().toUpperCase();
    final locked = status == 'COMPLETED' || status == 'CANCELLED';

    if (locked) {
      return _RequestReportPage(
        docId: widget.docId,
        data: widget.data,
        status: status,
      );
    }

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

  // This helper builds the edit request app bar.
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

  // This section renders built-in and custom tech stack chips for the edit form.
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

  // This section renders difficulty chips with the shared chip style.
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
                child: buildChip(difficulty, active: active),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // This section displays the stored urgency level for the request.
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

  // This section lets the requester choose how much time to add to the existing deadline.
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

  // This section displays the recalculated minimum bounty for the selected urgency and difficulty.
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

  // This helper builds the update button and disables it while submitting or when the request is locked.
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

  // This helper renders one labeled text input used by the edit form.
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

  // This helper renders uppercase section labels for the edit form.
  Widget buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(color: Color(0xFF8B93FF), letterSpacing: 2),
    );
  }

  // This helper renders rounded chips for stacks, difficulty, urgency, and extension choices.
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

// _RequestReportPage shows completed or cancelled request details without editable controls.
class _RequestReportPage extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String status;

  const _RequestReportPage({
    required this.docId,
    required this.data,
    required this.status,
  });

  @override
  // The build method formats bounty metadata and payment values into a report-style detail page.
  Widget build(BuildContext context) {
    final stacks = (data['techStacks'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .toList();
    final amount = (data['amount'] ?? 0).toDouble();
    final platformFee = (data['platformFee'] ?? amount * 0.05).toDouble();
    final hunterReceive = (data['hunterReceive'] ?? amount - platformFee)
        .toDouble();
    final locationType = data['locationType']?.toString() ?? 'Offline';
    final location = data['location']?.toString().trim().isNotEmpty == true
        ? data['location'].toString()
        : data['meetingLink']?.toString() ?? 'Not provided';

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Request Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D28),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['title']?.toString() ?? 'No Title',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _ReportStatus(status),
              const SizedBox(height: 24),
              _ReportRow(label: 'Order ID', value: docId),
              _ReportRow(
                label: 'Description',
                value:
                    data['description']?.toString() ??
                    'No description provided.',
              ),
              _ReportRow(
                label: 'Tech Stack',
                value: stacks.isEmpty ? 'Not provided' : stacks.join(', '),
              ),
              _ReportRow(
                label: 'Estimated Difficulty',
                value: data['difficulty']?.toString() ?? 'Simple',
              ),
              _ReportRow(
                label: 'Urgency Level',
                value: data['urgencyLevel']?.toString() ?? '7 Days',
              ),
              _ReportRow(label: 'Location Type', value: locationType),
              _ReportRow(
                label: locationType == 'Online' ? 'Meeting Link' : 'Location',
                value: location,
              ),
              if (status == 'COMPLETED') ...[
                const SizedBox(height: 10),
                const Divider(color: Color(0xFF2A2D38)),
                const SizedBox(height: 10),
                _ReportRow(
                  label: 'Paid Bounty',
                  value: 'RM ${amount.toStringAsFixed(2)}',
                ),
                _ReportRow(
                  label: 'Platform Fee',
                  value: 'RM ${platformFee.toStringAsFixed(2)}',
                ),
                _ReportRow(
                  label: 'Hunter Receives',
                  value: 'RM ${hunterReceive.toStringAsFixed(2)}',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// _ReportStatus displays the locked request status with completed requests highlighted.
class _ReportStatus extends StatelessWidget {
  final String status;

  const _ReportStatus(this.status);

  @override
  // The build method renders the status text with color based on the final request state.
  Widget build(BuildContext context) {
    final color = status == 'COMPLETED'
        ? const Color(0xFF00FF85)
        : Colors.white54;

    return Text(
      status,
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
  }
}

// _ReportRow renders one label-value pair in the read-only request report.
class _ReportRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReportRow({required this.label, required this.value});

  @override
  // The build method stacks a small uppercase label above the report value.
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF8B93FF),
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
