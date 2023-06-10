import 'package:stalemate/src/clock/clock.dart';

class MockClock implements Clock {
  DateTime _now;

  MockClock({DateTime? now}) : _now = now ?? DateTime.now();

  @override
  DateTime now() {
    return _now;
  }

  void setNow(DateTime now) {
    _now = now;
  }

  void advance(Duration duration) {
    _now = _now.add(duration);
  }
}