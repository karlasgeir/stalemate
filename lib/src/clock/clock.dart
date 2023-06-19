/// A clock that can be used to get the current time.
///
/// **Why do we need this?**
/// - It is very beneficial to be able to override the clock for testing
/// - We want to be able to make tests fast and deterministic
///
/// Implementations:
/// - [SystemClock] : Uses the system time
abstract class Clock {
  DateTime now();
}

/// A clock that uses the system time
///
/// This is the clock that will always be used in production
/// Any other clock should only be used for testing
class SystemClock implements Clock {
  @override
  DateTime now() {
    return DateTime.now();
  }
}
