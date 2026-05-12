import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestActionStatus { initial, loading, success, failure }

class RequestRecordState {
  final RequestActionStatus status;
  final String? message;

  const RequestRecordState({
    this.status = RequestActionStatus.initial,
    this.message,
  });

  RequestRecordState copyWith({
    RequestActionStatus? status,
    String? message,
    bool clearMessage = false,
  }) {
    return RequestRecordState(
      status: status ?? this.status,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

typedef BountySnapshot = QuerySnapshot<Map<String, dynamic>>;
