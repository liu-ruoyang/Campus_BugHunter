// This state file defines editable request state for the Edit Request page.
// It keeps editable fields, screenshots, extension choice, submission status, and messages together.
import '../../models/pending_bounty_image.dart';

// EditPostStatus lists the phases of updating an existing bounty.
enum EditPostStatus { initial, submitting, success, failure }

// EditPostState stores the current edit form selections and action state for EditPostCubit.
class EditPostState {
  final EditPostStatus status;
  final List<String> selectedStacks;
  final List<String> customStacks;
  final bool isAddingStack;
  final String selectedDifficulty;
  final String selectedUrgency;
  final int extensionDays;
  final List<String> existingImageUrls;
  final List<String> removedImageUrls;
  final List<PendingBountyImage> pendingImages;
  final String? message;

  const EditPostState({
    this.status = EditPostStatus.initial,
    this.selectedStacks = const [],
    this.customStacks = const [],
    this.isAddingStack = false,
    this.selectedDifficulty = '',
    this.selectedUrgency = '7 Days',
    this.extensionDays = 0,
    this.existingImageUrls = const [],
    this.removedImageUrls = const [],
    this.pendingImages = const [],
    this.message,
  });

  // copyWith creates a new edit state while retaining values that were not changed.
  EditPostState copyWith({
    EditPostStatus? status,
    List<String>? selectedStacks,
    List<String>? customStacks,
    bool? isAddingStack,
    String? selectedDifficulty,
    String? selectedUrgency,
    int? extensionDays,
    List<String>? existingImageUrls,
    List<String>? removedImageUrls,
    List<PendingBountyImage>? pendingImages,
    String? message,
    bool clearMessage = false,
  }) {
    return EditPostState(
      status: status ?? this.status,
      selectedStacks: selectedStacks ?? this.selectedStacks,
      customStacks: customStacks ?? this.customStacks,
      isAddingStack: isAddingStack ?? this.isAddingStack,
      selectedDifficulty: selectedDifficulty ?? this.selectedDifficulty,
      selectedUrgency: selectedUrgency ?? this.selectedUrgency,
      extensionDays: extensionDays ?? this.extensionDays,
      existingImageUrls: existingImageUrls ?? this.existingImageUrls,
      removedImageUrls: removedImageUrls ?? this.removedImageUrls,
      pendingImages: pendingImages ?? this.pendingImages,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}
