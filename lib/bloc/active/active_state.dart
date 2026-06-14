// This state file defines the status and data wrappers used by the active bounty flow.
// Active pages use these states to show loading, success, errors, and the current active bounty.
// ActiveActionStatus lists the lifecycle of user actions performed on an active bounty.
enum ActiveActionStatus { initial, loading, success, failure }

// ActiveState carries action progress and user-facing messages for active bounty controls.
class ActiveState {
  final ActiveActionStatus status;
  final String? message;

  const ActiveState({this.status = ActiveActionStatus.initial, this.message});

  // copyWith returns a new active state while optionally clearing stale messages.
  ActiveState copyWith({
    ActiveActionStatus? status,
    String? message,
    bool clearMessage = false,
  }) {
    return ActiveState(
      status: status ?? this.status,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

// ActiveBounty wraps a Firestore bounty document id with its map data for the active screen.
class ActiveBounty {
  final String id;
  final Map<String, dynamic> data;

  const ActiveBounty({required this.id, required this.data});
}
