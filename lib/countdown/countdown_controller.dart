import 'dart:async';

import 'countdown_state.dart';

/// Quản lý Timer và Stream; không phụ thuộc giao diện Flutter.
final class CountdownController {
  CountdownController({required int seconds, Duration Function()? elapsed}) {
    _validate(seconds);
    _clock.start();
    _elapsed = elapsed ?? () => _clock.elapsed;
    _remaining = Duration(seconds: seconds);
    _state = CountdownState(
      totalSeconds: seconds,
      remainingSeconds: seconds,
      status: CountdownStatus.ready,
    );
  }

  final _events = StreamController<CountdownState>.broadcast();
  final _clock = Stopwatch();
  late final Duration Function() _elapsed;
  late CountdownState _state;
  late Duration _remaining;
  Duration? _deadline;
  Timer? _timer;
  Future<void>? _closeFuture;
  bool _disposed = false;

  Stream<CountdownState> get stream => _events.stream;
  CountdownState get state => _state;
  bool get isDisposed => _disposed;
  bool get isTimerActive => _timer?.isActive ?? false;
  bool get hasListener => _events.hasListener;

  void start() {
    if (_disposed ||
        _state.status == CountdownStatus.running ||
        _state.status == CountdownStatus.completed) {
      return;
    }
    _deadline = _elapsed() + _remaining;
    _emit(CountdownStatus.running);
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  void _tick() {
    if (_disposed) return;
    final remaining = _deadline! - _elapsed();
    _remaining = remaining.isNegative ? Duration.zero : remaining;
    if (_remaining == Duration.zero) {
      _stopTimer();
      _emit(CountdownStatus.completed);
    } else if (_secondsLeft != _state.remainingSeconds) {
      _emit(CountdownStatus.running);
    }
  }

  void pause() {
    if (_disposed || _state.status != CountdownStatus.running) return;
    _tick();
    if (_state.status == CountdownStatus.completed) return;
    _stopTimer();
    _emit(CountdownStatus.paused);
  }

  void reset({int? seconds}) {
    if (_disposed) return;
    final total = seconds ?? _state.totalSeconds;
    _validate(total);
    _stopTimer();
    _remaining = Duration(seconds: total);
    _emit(CountdownStatus.ready, total: total);
  }

  int get _secondsLeft =>
      (_remaining.inMicroseconds + Duration.microsecondsPerSecond - 1) ~/
      Duration.microsecondsPerSecond;

  void _emit(CountdownStatus status, {int? total}) {
    if (_disposed) return;
    _state = CountdownState(
      totalSeconds: total ?? _state.totalSeconds,
      remainingSeconds: _secondsLeft,
      status: status,
    );
    _events.add(_state);
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _deadline = null;
  }

  Future<void> dispose() {
    if (_closeFuture != null) return _closeFuture!;
    _disposed = true;
    _stopTimer();
    _clock.stop();
    return _closeFuture = _events.close();
  }

  static void _validate(int seconds) {
    if (seconds < 1 || seconds > 3600) {
      throw ArgumentError.value(seconds, 'seconds', 'Phải từ 1 đến 3600');
    }
  }
}
