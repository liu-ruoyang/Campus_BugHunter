// This cubit file controls editing an existing requester bounty.
// It initializes form selections from Firestore data, validates reward changes, updates wallet differences, and extends deadlines.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/bounty_image_service.dart';
import '../../utils/bounty_rules.dart';
import 'edit_post_state.dart';

// EditPostCubit keeps update logic separate from the Edit Request UI.
class EditPostCubit extends Cubit<EditPostState> {
  EditPostCubit({
    required Map<String, dynamic> initialData,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    BountyImageService? imageService,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _imageService = imageService ?? BountyImageService(),
       super(_initialState(initialData));

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final BountyImageService _imageService;

  // This helper builds the initial edit state from the bounty document being edited.
  static EditPostState _initialState(Map<String, dynamic> data) {
    final selectedStacks = List<String>.from(data['techStacks'] ?? []);
    const defaultStacks = ['C/C++', 'Java', 'Python', 'Flutter', 'Firebase'];
    return EditPostState(
      selectedStacks: selectedStacks,
      customStacks: selectedStacks
          .where((stack) => !defaultStacks.contains(stack))
          .toList(),
      selectedDifficulty: data['difficulty'] ?? '',
      selectedUrgency: data['urgencyLevel'] ?? '7 Days',
      existingImageUrls: BountyImageService.urlsFromData(data),
    );
  }

  // This method toggles a predefined tech stack selection.
  void toggleStack(String stack) {
    final selected = List<String>.from(state.selectedStacks);
    selected.contains(stack) ? selected.remove(stack) : selected.add(stack);
    emit(state.copyWith(selectedStacks: selected));
  }

  // This method shows the custom stack input in the edit form.
  void startAddingStack() => emit(state.copyWith(isAddingStack: true));

  // This method adds a custom stack to the selected stack collections.
  void addCustomStack(String stack) {
    final value = stack.trim();
    if (value.isEmpty) return;
    emit(
      state.copyWith(
        selectedStacks: {...state.selectedStacks, value}.toList(),
        customStacks: {...state.customStacks, value}.toList(),
        isAddingStack: false,
      ),
    );
  }

  // This method removes a custom stack from both selected and custom stack lists.
  void removeCustomStack(String stack) {
    emit(
      state.copyWith(
        selectedStacks: state.selectedStacks
            .where((item) => item != stack)
            .toList(),
        customStacks: state.customStacks
            .where((item) => item != stack)
            .toList(),
      ),
    );
  }

  // This method stores the selected urgency value from the existing bounty data.
  void selectUrgency(String urgency) {
    emit(state.copyWith(selectedUrgency: urgency));
  }

  // This method stores how many days the requester wants to add to the bounty deadline.
  void selectExtensionDays(int days) {
    emit(state.copyWith(extensionDays: days));
  }

  Future<void> pickImages() async {
    final currentCount =
        state.existingImageUrls.length + state.pendingImages.length;
    final result = await _imageService.pickImages(
      remainingSlots: maxBountyImages - currentCount,
    );
    if (result.images.isNotEmpty) {
      emit(
        state.copyWith(
          pendingImages: [...state.pendingImages, ...result.images],
          message: result.message,
          clearMessage: result.message == null,
        ),
      );
    } else if (result.message != null) {
      emit(state.copyWith(message: result.message));
    }
  }

  void removeExistingImage(String url) {
    emit(
      state.copyWith(
        existingImageUrls: state.existingImageUrls
            .where((item) => item != url)
            .toList(),
        removedImageUrls: {...state.removedImageUrls, url}.toList(),
        clearMessage: true,
      ),
    );
  }

  void removePendingImage(int index) {
    if (index < 0 || index >= state.pendingImages.length) return;
    final images = [...state.pendingImages]..removeAt(index);
    emit(state.copyWith(pendingImages: images, clearMessage: true));
  }

  // This method validates updates, adjusts wallet balance by reward difference, and writes changes to Firestore.
  Future<void> updateBounty({
    required String docId,
    required Map<String, dynamic> originalData,
    required String title,
    required String description,
    required String location,
    required String amountText,
  }) async {
    final uid = _auth.currentUser?.uid;
    final amount = double.tryParse(amountText) ?? 0;
    final minimumAmount = minimumBounty(
      state.selectedUrgency,
      state.selectedDifficulty,
    );
    if (uid == null) {
      emit(
        state.copyWith(
          status: EditPostStatus.failure,
          message: 'User not signed in',
        ),
      );
      return;
    }

    emit(state.copyWith(status: EditPostStatus.submitting, clearMessage: true));
    var uploadedUrls = <String>[];
    try {
      final oldAmount = (originalData['amount'] ?? 0).toDouble();
      final diff = amount - oldAmount;
      final userRef = _firestore.collection('users').doc(uid);

      if (amount < minimumAmount) {
        emit(
          state.copyWith(
            status: EditPostStatus.failure,
            message:
                'Bounty amount must be at least RM ${minimumAmount.toStringAsFixed(2)}',
          ),
        );
        return;
      }

      final updateData = <String, dynamic>{
        'title': title.trim(),
        'description': description.trim(),
        'location': location.trim(),
        'amount': amount,
        'platformFee': amount * 0.05,
        'hunterReceive': amount - (amount * 0.05),
        'techStacks': state.selectedStacks,
        'urgencyLevel': state.selectedUrgency,
        'urgencyDays': urgencyDays(state.selectedUrgency),
        'minimumBounty': minimumAmount,
      };

      uploadedUrls = await _imageService.uploadImages(
        bountyId: docId,
        userId: uid,
        images: state.pendingImages,
      );
      updateData['imageUrls'] = [...state.existingImageUrls, ...uploadedUrls];

      final currentExpiresAt =
          timestampDate(originalData['expiresAt']) ??
          DateTime.now().add(
            Duration(days: urgencyDays(state.selectedUrgency)),
          );
      if (state.extensionDays > 0) {
        updateData['expiresAt'] = Timestamp.fromDate(
          currentExpiresAt.add(Duration(days: state.extensionDays)),
        );
        updateData['extendedDays'] =
            (originalData['extendedDays'] ?? 0) + state.extensionDays;
      }

      final bountyRef = _firestore.collection('bounties').doc(docId);
      await _firestore.runTransaction((transaction) async {
        final userSnap = await transaction.get(userRef);
        final wallet = (userSnap.data()?['wallet'] ?? 0).toDouble();
        if (diff > 0 && wallet < diff) {
          throw StateError('Insufficient balance');
        }
        if (diff != 0) {
          transaction.update(userRef, {'wallet': wallet - diff});
        }
        transaction.update(bountyRef, updateData);
      });
      await _imageService.deleteUrls(state.removedImageUrls);

      emit(state.copyWith(status: EditPostStatus.success, message: 'Updated'));
    } catch (error) {
      await _imageService.deleteUrls(uploadedUrls);
      emit(
        state.copyWith(
          status: EditPostStatus.failure,
          message: error is StateError
              ? error.message.toString()
              : 'Failed to update',
        ),
      );
    }
  }
}
