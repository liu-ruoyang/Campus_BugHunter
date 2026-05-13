// This state file defines wallet transaction loading state and Firestore snapshot typing.
// The wallet page uses it to display transaction history and action messages.
import 'package:cloud_firestore/cloud_firestore.dart';

// WalletStatus lists the action states for transaction-related wallet work.
enum WalletStatus { initial, loading, success, failure }

// WalletState carries transaction action status and optional snackbar messages.
class WalletState {
  final WalletStatus status;
  final String? message;

  const WalletState({this.status = WalletStatus.initial, this.message});

  // copyWith creates updated wallet state while optionally clearing old messages.
  WalletState copyWith({
    WalletStatus? status,
    String? message,
    bool clearMessage = false,
  }) {
    return WalletState(
      status: status ?? this.status,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

// TransactionSnapshot names the Firestore query snapshot shape used by the wallet history stream.
typedef TransactionSnapshot = QuerySnapshot<Map<String, dynamic>>;
