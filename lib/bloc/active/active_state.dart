enum ActiveActionStatus { initial, loading, success, failure }

class ActiveState {
  final ActiveActionStatus status;
  final String? message;

  const ActiveState({this.status = ActiveActionStatus.initial, this.message});

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

class ActiveBounty {
  final String id;
  final Map<String, dynamic> data;

  const ActiveBounty({required this.id, required this.data});
}
