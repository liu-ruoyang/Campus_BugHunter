import 'package:cloud_firestore/cloud_firestore.dart';

enum WalletStatus { initial, loading, success, failure }

class WalletState {
  final WalletStatus status;
  final String? message;

  const WalletState({this.status = WalletStatus.initial, this.message});

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

typedef TransactionSnapshot = QuerySnapshot<Map<String, dynamic>>;
