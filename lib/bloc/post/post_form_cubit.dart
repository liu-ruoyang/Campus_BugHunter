import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'post_form_state.dart';

class PostFormCubit extends Cubit<PostFormState> {
  PostFormCubit({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance,
      super(const PostFormState());

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> loadWallet() async {
    emit(
      state.copyWith(status: PostFormStatus.loadingWallet, clearMessage: true),
    );
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _firestore.collection('users').doc(uid).get();
    emit(
      state.copyWith(
        status: PostFormStatus.ready,
        walletBalance: (doc.data()?['wallet'] ?? 0).toDouble(),
      ),
    );
  }

  void toggleStack(String stack) {
    final selected = List<String>.from(state.selectedStacks);
    selected.contains(stack) ? selected.remove(stack) : selected.add(stack);
    emit(state.copyWith(selectedStacks: selected));
  }

  void startAddingStack() => emit(state.copyWith(isAddingStack: true));

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

  void selectDifficulty(String difficulty) {
    emit(state.copyWith(selectedDifficulty: difficulty));
  }

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
    if (trimmedLocation.isEmpty) {
      emit(
        state.copyWith(
          status: PostFormStatus.failure,
          message: isOnline ? 'Meeting link is required' : 'Location is required',
        ),
      );
      return;
    }

    emit(state.copyWith(status: PostFormStatus.submitting, clearMessage: true));
    try {
      await _firestore.collection('users').doc(uid).update({
        'wallet': state.walletBalance - amount,
      });

      await _firestore.collection('bounties').add({
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
        'status': 'NOT ACCEPTED',
        'escrow': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      emit(
        state.copyWith(
          status: PostFormStatus.success,
          walletBalance: state.walletBalance - amount,
          message: 'Bounty posted',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: PostFormStatus.failure,
          message: 'Failed to post bounty',
        ),
      );
    }
  }
}
