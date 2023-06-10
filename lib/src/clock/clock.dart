abstract class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  @override
  DateTime now() {
    return DateTime.now();
  }
}