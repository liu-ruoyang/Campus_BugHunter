// This cubit file controls the requester post bounty form.
// It loads wallet balance, manages selected form chips, validates bounty rules, and creates Firestore bounty records.
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/bounty_image_service.dart';
import '../../utils/bounty_rules.dart';
import 'post_form_state.dart';

// PostFormCubit keeps form behavior out of the UI and writes new bounty data to Firebase.
class PostFormCubit extends Cubit<PostFormState> {
  static const _uploadTimeout = Duration(seconds: 30);
  static const _transactionTimeout = Duration(seconds: 30);

  PostFormCubit({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    BountyImageService? imageService,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _imageService = imageService ?? BountyImageService(),
       super(const PostFormState());

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final BountyImageService _imageService;

  // This method reads the current user's wallet balance before the requester submits a bounty.
  Future<void> loadWallet() async {
    emit(
      state.copyWith(status: PostFormStatus.loadingWallet, clearMessage: true),
    );
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      emit(
        state.copyWith(
          status: PostFormStatus.failure,
          message: 'User not signed in',
        ),
      );
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      emit(
        state.copyWith(
          status: PostFormStatus.ready,
          walletBalance: (doc.data()?['wallet'] ?? 0).toDouble(),
        ),
      );
    } on FirebaseException catch (error) {
      emit(
        state.copyWith(
          status: PostFormStatus.failure,
          message: _firebaseErrorMessage(error, action: 'load wallet'),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: PostFormStatus.failure,
          message: 'Failed to load wallet',
        ),
      );
    }
  }

  // This method toggles a predefined tech stack in the selected stack list.
  void toggleStack(String stack) {
    final selected = List<String>.from(state.selectedStacks);
    selected.contains(stack) ? selected.remove(stack) : selected.add(stack);
    emit(state.copyWith(selectedStacks: selected));
  }

  // This method switches the form into the custom stack input state.
  void startAddingStack() => emit(state.copyWith(isAddingStack: true));

  // This method trims and adds a custom stack to both selected and custom stack collections.
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

  // This method removes a custom stack from the form selections.
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

  // This method stores the selected estimated difficulty for bounty scoring.
  void selectDifficulty(String difficulty) {
    emit(state.copyWith(selectedDifficulty: difficulty));
  }

  // This method stores the selected urgency level used for expiration and minimum bounty calculation.
  void selectUrgency(String urgency) {
    emit(state.copyWith(selectedUrgency: urgency));
  }

  Future<void> pickImages() async {
    final result = await _imageService.pickImages(
      remainingSlots: maxBountyImages - state.pendingImages.length,
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

  void removeImage(int index) {
    if (index < 0 || index >= state.pendingImages.length) return;
    final images = [...state.pendingImages]..removeAt(index);
    emit(state.copyWith(pendingImages: images, clearMessage: true));
  }

  // This method validates the form, deducts requester balance, and creates the Firestore bounty document.
  Future<void> createBounty({
    required String title,
    required String description,
    required String locationType,
    required String location,
    required String amountText,
  }) async {
    final uid = _auth.currentUser?.uid;
    final amount = double.tryParse(amountText) ?? 0;
    final trimmedLocation = location.trim();
    final isOnline = locationType == 'Online';
    final minimumAmount = minimumBounty(
      state.selectedUrgency,
      state.selectedDifficulty,
    );

    if (uid == null) {
      emit(
        state.copyWith(
          status: PostFormStatus.failure,
          message: 'User not signed in',
        ),
      );
      return;
    }
    if (amount <= 0) {
      emit(
        state.copyWith(
          status: PostFormStatus.failure,
          message: 'Invalid amount',
        ),
      );
      return;
    }
    if (state.walletBalance < amount) {
      emit(
        state.copyWith(
          status: PostFormStatus.failure,
          message: 'Insufficient balance',
        ),
      );
      return;
    }
    if (amount < minimumAmount) {
      emit(
        state.copyWith(
          status: PostFormStatus.failure,
          message:
              'Bounty amount must be at least RM ${minimumAmount.toStringAsFixed(2)}',
        ),
      );
      return;
    }
    if (trimmedLocation.isEmpty) {
      emit(
        state.copyWith(
          status: PostFormStatus.failure,
          message: isOnline
              ? 'Meeting link is required'
              : 'Location is required',
        ),
      );
      return;
    }

    emit(state.copyWith(status: PostFormStatus.submitting, clearMessage: true));
    final bountyRef = _firestore.collection('bounties').doc();
    var uploadedUrls = <String>[];
    try {
      uploadedUrls = await _imageService
          .uploadImages(
            bountyId: bountyRef.id,
            userId: uid,
            images: state.pendingImages,
          )
          .timeout(_uploadTimeout);

      await _firestore
          .runTransaction((transaction) async {
            final userRef = _firestore.collection('users').doc(uid);
            final userSnapshot = await transaction.get(userRef);
            final currentWallet = (userSnapshot.data()?['wallet'] ?? 0)
                .toDouble();
            if (currentWallet < amount) {
              throw StateError('Insufficient balance');
            }
            transaction.update(userRef, {'wallet': currentWallet - amount});
            transaction.set(bountyRef, {
              'ownerId': uid,
              'hunterId': null,
              'title': title.trim(),
              'description': description.trim(),
              'locationType': locationType,
              'location': trimmedLocation,
              'meetingLink': isOnline ? trimmedLocation : '',
              'amount': amount,
              'platformFee': amount * 0.05,
              'hunterReceive': amount - (amount * 0.05),
              'techStacks': state.selectedStacks,
              'difficulty': state.selectedDifficulty,
              'urgencyLevel': state.selectedUrgency,
              'urgencyDays': urgencyDays(state.selectedUrgency),
              'minimumBounty': minimumAmount,
              'imageUrls': uploadedUrls,
              'status': 'NOT ACCEPTED',
              'escrow': true,
              'createdAt': FieldValue.serverTimestamp(),
              'expiresAt': Timestamp.fromDate(
                DateTime.now().add(
                  Duration(days: urgencyDays(state.selectedUrgency)),
                ),
              ),
            });
          })
          .timeout(_transactionTimeout);

      emit(
        state.copyWith(
          status: PostFormStatus.success,
          walletBalance: state.walletBalance - amount,
          message: 'Bounty posted',
        ),
      );
    } catch (error) {
      try {
        await _imageService
            .deleteUrls(uploadedUrls)
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        // Cleanup must not leave the form stuck in the submitting state.
      }
      emit(
        state.copyWith(
          status: PostFormStatus.failure,
          message: switch (error) {
            TimeoutException() =>
              'Posting timed out. Check your internet connection and Firebase configuration.',
            StateError() => error.message.toString(),
            FirebaseException() => _firebaseErrorMessage(
              error,
              action: 'post bounty',
            ),
            _ => 'Failed to post bounty: $error',
          },
        ),
      );
    }
  }

  static String _firebaseErrorMessage(
    FirebaseException error, {
    required String action,
  }) {
    if (error.code == 'permission-denied' || error.code == 'unauthorized') {
      return 'Firebase permission denied while trying to $action. Check Firestore and Storage rules.';
    }
    if (error.code == 'unavailable') {
      return 'Firebase is unavailable. Check your network and try again.';
    }

    final detail = error.message?.trim();
    return detail == null || detail.isEmpty
        ? 'Failed to $action (${error.code})'
        : 'Failed to $action (${error.code}): $detail';
  }
}
