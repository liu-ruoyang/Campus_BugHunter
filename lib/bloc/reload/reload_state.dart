// This state file defines the wallet reload action status used by the reload page.
// It carries the latest loading result and snackbar message for top-up actions.
// ReloadStatus lists the phases of a wallet reload request.
enum ReloadStatus { initial, loading, success, failure }

// ReloadState stores the current reload request status and optional user-facing message.
class ReloadState {
  final ReloadStatus status;
  final String? message;

  const ReloadState({this.status = ReloadStatus.initial, this.message});

  // copyWith creates a new reload state and can clear stale messages after they are shown.
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
