import 'dart:async';

/// Runs [onValue] after [duration] since the last [call] with the latest value.
final class Debouncer {
  Debouncer({required this.duration, required this.onValue});

  final Duration duration;
  final void Function(String value) onValue;
  Timer? _timer;

  void call(String value) {
    _timer?.cancel();
    _timer = Timer(duration, () => onValue(value));
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
