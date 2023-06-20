import 'package:logger/logger.dart';
import 'package:synchronized/synchronized.dart';

import 'stalemate_loader_state.dart';

typedef StateListener = void Function(
  StaleMateLoaderState state,
  StaleMateLoaderState prevState,
);

/// Manages the state of the data loader
///
/// This class is used internally by the data loader
/// to manage the state of the data loader
///
/// It is simply to abstract away the state management and
/// decouple it from the data loader
///
/// See also:
/// - [StaleMateLoaderState]
class StaleMateStateManager {
  /// A lock that is used to synchronize state changes
  final Lock _stateLock = Lock();

  /// A logger that is used to log state changes
  final Logger _logger;

  /// Creates a new state manager
  ///
  /// Arguments:
  /// - **logger:** A logger that is used to log state changes
  StaleMateStateManager({required Logger logger}) : _logger = logger;

  /// Indicates what the current state of the data loader is
  StaleMateLoaderState _state = StaleMateLoaderState.initial();

  StaleMateLoaderState get state => _state;

  /// Holds state listeners that will be called when the state changes
  final List<StateListener> _stateListeners = [];

  /// Changes the state of the data loader
  ///
  /// This method should only be used internally by the data loader
  ///
  /// Arguments:
  /// - [state] : The new state of the data loader
  Future<void> _setState(StaleMateLoaderState newState) async {
    await _stateLock.synchronized(() {
      final prevState = _state;
      _state = newState;

      // Call the state listeners
      for (var listener in _stateListeners) {
        try {
          listener(newState, prevState);
        } catch (e, stackTrace) {
          _logger.e('Error while calling state listener', e, stackTrace);
        }
      }

      _logger.d('State changed to $newState');
    });
  }

  /// Changes the local state of the data loader
  Future<void> setLocalState(
    StaleMateStatus status, {
    Object? error,
  }) async {
    await _setState(state.copyWithLocalStatus(
      status,
      error: error,
    ));
  }

  /// Changes the remote state of the data loader
  Future<void> setRemoteState(
    StaleMateStatus status, {
    StaleMateFetchReason? fetchReason,
    Object? error,
  }) async {
    await _setState(state.copyWithRemoteStatus(
      status,
      fetchReason: fetchReason,
      error: error,
    ));
  }

  Future<void> reset() async {
    await _setState(StaleMateLoaderState.initial());
  }

  /// Adds a state listener to the data loader
  ///
  /// The state listener will be called whenever the state of the data loader changes
  ///
  /// Arguments:
  /// - [listener] : The listener that will be called when the state changes
  void addListener(StateListener listener) {
    _stateListeners.add(listener);
  }

  /// Removes a state listener from the data loader
  ///
  /// The state listener will no longer be called when the state of the data loader changes
  ///
  /// Arguments:
  /// - [listener] : The listener that will be removed
  void removeListener(StateListener listener) {
    _stateListeners.remove(listener);
  }
}
