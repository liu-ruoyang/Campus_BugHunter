import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../utils/bounty_rules.dart';
import 'edit_post_state.dart';

class EditPostCubit extends Cubit<EditPostState> {
  EditPostCubit({
    required Map<String, dynamic> initialData,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       super(_initialState(initialData));

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

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

  void selectUrgency(String urgency) {
    emit(state.copyWith(selectedUrgency: urgency));
  }

  void selectExtensionDays(int days) {
    emit(state.copyWith(extensionDays: days));
  }

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
    try {
      final oldAmount = (originalData['amount'] ?? 0).toDouble();
      final diff = amount - oldAmount;
      final userRef = _firestore.collection('users').doc(uid);
      final userSnap = await userRef.get();
      final wallet = (userSnap.data()?['wallet'] ?? 0).toDouble();

      if (diff > 0) {
        if (wallet < diff) {
          emit(
            state.copyWith(
              status: EditPostStatus.failure,
              message: 'Insufficient balance',
            ),
          );
          return;
        }
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
        await userRef.update({'wallet': wallet - diff});
      }

      if (diff <= 0 && amount < minimumAmount) {
        emit(
          state.copyWith(
            status: EditPostStatus.failure,
            message:
                'Bounty amount must be at least RM ${minimumAmount.toStringAsFixed(2)}',
          ),
        );
        return;
      }

      if (diff < 0) {
        await userRef.update({'wallet': wallet + diff.abs()});
      }

      final updateData = <String, dynamic>{
        'title': title.trim(),
        'description': description.trim(),
        'location': location.trim(),
        'amount': amount,
        'platformFee': amount * 0.05,
        'hunterReceive': amount - (amount * 0.05),
        'techStacks': state.selectedStacks,
        'difficulty': state.selectedDifficulty,
        'urgencyLevel': state.selectedUrgency,
        'urgencyDays': urgencyDays(state.selectedUrgency),
        'minimumBounty': minimumAmount,
      };

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

      await _firestore.collection('bounties').doc(docId).update(updateData);

      emit(state.copyWith(status: EditPostStatus.success, message: 'Updated'));
    } catch (_) {
      emit(
        state.copyWith(
          status: EditPostStatus.failure,
          message: 'Failed to update',
        ),
      );
    }
  }
}
