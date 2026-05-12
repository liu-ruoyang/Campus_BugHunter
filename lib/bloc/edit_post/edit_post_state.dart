enum EditPostStatus { initial, submitting, success, failure }

class EditPostState {
  final EditPostStatus status;
  final List<String> selectedStacks;
  final List<String> customStacks;
  final bool isAddingStack;
  final String selectedDifficulty;
  final String? message;

  const EditPostState({
    this.status = EditPostStatus.initial,
    this.selectedStacks = const [],
    this.customStacks = const [],
    this.isAddingStack = false,
    this.selectedDifficulty = '',
    this.message,
  });

  EditPostState copyWith({
    EditPostStatus? status,
    List<String>? selectedStacks,
    List<String>? customStacks,
    bool? isAddingStack,
    String? selectedDifficulty,
    String? message,
    bool clearMessage = false,
  }) {
    return EditPostState(
      status: status ?? this.status,
      selectedStacks: selectedStacks ?? this.selectedStacks,
      customStacks: customStacks ?? this.customStacks,
      isAddingStack: isAddingStack ?? this.isAddingStack,
      selectedDifficulty: selectedDifficulty ?? this.selectedDifficulty,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}
