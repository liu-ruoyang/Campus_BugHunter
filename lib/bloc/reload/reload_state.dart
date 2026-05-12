enum ReloadStatus { initial, loading, success, failure }

class ReloadState {
  final ReloadStatus status;
  final String? message;

  const ReloadState({this.status = ReloadStatus.initial, this.message});

  ReloadState copyWith({
    ReloadStatus? status,
    String? message,
    bool clearMessage = false,
  }) {
    return ReloadState(
      status: status ?? this.status,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}
