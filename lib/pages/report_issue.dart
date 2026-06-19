import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/active/active_cubit.dart';
import '../bloc/active/active_state.dart';
import '../bloc/home/role_cubit.dart';
import '../theme/app_theme.dart';

class ReportIssuePage extends StatefulWidget {
  final String bountyId;
  final Map<String, dynamic> data;
  final UserRole role;

  const ReportIssuePage({
    super.key,
    required this.bountyId,
    required this.data,
    required this.role,
  });

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  late String _selectedType;
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedType = _issueTypes.first;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  List<String> get _issueTypes {
    if (widget.role == UserRole.hunter) {
      return const [
        'Requester does not confirm solved work',
        'Requester changed requirements',
        'Requester is unreachable',
        'Dispute with requester',
        'Other',
      ];
    }
    return const [
      'Hunter is delaying the task',
      'Hunter submitted an incorrect solution',
      'Hunter is unreachable',
      'Dispute with hunter',
      'Other',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return BlocConsumer<ActiveCubit, ActiveState>(
      listenWhen: (previous, current) => previous.message != current.message,
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!)));
        }
        if (state.status == ActiveActionStatus.success) {
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        final isLoading = state.status == ActiveActionStatus.loading;

        return Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(elevation: 0, title: const Text('Report Issue')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.data['title']?.toString() ?? 'No Title',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose a problem type and describe what happened. This report will be stored for admin review.',
                          style: TextStyle(
                            color: colors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'ISSUE TYPE',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._issueTypes.map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: isLoading
                            ? null
                            : () => setState(() => _selectedType = type),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceAlt,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedType == type
                                  ? colors.primary
                                  : colors.border,
                              width: _selectedType == type ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _selectedType == type
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: _selectedType == type
                                    ? colors.primary
                                    : colors.textMuted,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  type,
                                  style: TextStyle(color: colors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _descriptionController,
                    minLines: 5,
                    maxLines: 8,
                    enabled: !isLoading,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Description',
                      alignLabelWithHint: true,
                      labelStyle: TextStyle(color: colors.textMuted),
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
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 58,
                    child: ElevatedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () => context.read<ActiveCubit>().reportIssue(
                              bountyId: widget.bountyId,
                              data: widget.data,
                              role: widget.role,
                              issueType: _selectedType,
                              description: _descriptionController.text,
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.danger,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.report_outlined),
                      label: const Text(
                        'REPORT',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
