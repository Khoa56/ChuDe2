enum CountdownStatus { ready, running, paused, completed }

/// Trạng thái bất biến được gửi qua Stream.
final class CountdownState {
  const CountdownState({
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.status,
  });
  final int totalSeconds;
  final int remainingSeconds;
  final CountdownStatus status;
}

String formatTime(int seconds) {
  final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
  final remainder = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$remainder';
}
