import 'dart:async';

/// Throttle function calls
class Throttler {
  final Duration delay;
  Timer? _timer;
  bool _isReady = true;

  Throttler({required this.delay});

  void call(void Function() action) {
    if (_isReady) {
      _isReady = false;
      action();
      _timer = Timer(delay, () {
        _isReady = true;
      });
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}
