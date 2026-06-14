// This state file defines action state for the request record screen.
// It also aliases the Firestore bounty snapshot type used by the request list stream.
import 'package:cloud_firestore/cloud_firestore.dart';

// RequestActionStatus lists the loading and result states for completing or cancelling requests.
enum RequestActionStatus { initial, loading, success, failure }

// RequestRecordState carries the latest request action status and any snackbar message.
class RequestRecordState {
  final RequestActionStatus status;
  final String? message;

  const RequestRecordState({
    this.status = RequestActionStatus.initial,
    this.message,
  });

  // copyWith creates updated action state and can clear old messages after the UI consumes them.
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

// BountySnapshot names the Firestore query snapshot shape used by request record streams.
typedef BountySnapshot = QuerySnapshot<Map<String, dynamic>>;
