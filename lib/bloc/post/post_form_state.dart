enum PostFormStatus {
  initial,
  loadingWallet,
  ready,
  submitting,
  success,
  failure,
}

class PostFormState {
  final PostFormStatus status;
  final List<String> selectedStacks;
  final List<String> customStacks;
  final bool isAddingStack;
  final String selectedDifficulty;
  final String selectedUrgency;
  final double walletBalance;
  final String? message;

  const PostFormState({
    this.status = PostFormStatus.initial,
    this.selectedStacks = const [],
    this.customStacks = const [],
    this.isAddingStack = false,
    this.selectedDifficulty = 'Simple',
    this.selectedUrgency = '7 Days',
    this.walletBalance = 0,
    this.message,
  });

  PostFormState copyWith({
    PostFormStatus? status,
    List<String>? selectedStacks,
    List<String>? customStacks,
    bool? isAddingStack,
    String? selectedDifficulty,
    String? selectedUrgency,
    double? walletBalance,
    String? message,
    bool clearMessage = false,
  }) {
    return PostFormState(
      status: status ?? this.status,
      selectedStacks: selectedStacks ?? this.selectedStacks,
      customStacks: customStacks ?? this.customStacks,
      isAddingStack: isAddingStack ?? this.isAddingStack,
      selectedDifficulty: selectedDifficulty ?? this.selectedDifficulty,
      selectedUrgency: selectedUrgency ?? this.selectedUrgency,
      walletBalance: walletBalance ?? this.walletBalance,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}
