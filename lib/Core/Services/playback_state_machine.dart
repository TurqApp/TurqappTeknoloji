enum PlaybackSessionState {
  idle,
  primed,
  attaching,
  ready,
  active,
  suspended,
  disposed,
  failed,
}

enum PlaybackSessionEvent {
  primeRequested,
  attachRequested,
  firstFrameRendered,
  activateRequested,
  suspendRequested,
  disposeRequested,
  failure,
}

class PlaybackStateMachine {
  PlaybackStateMachine({
    this.initialState = PlaybackSessionState.idle,
  }) : _state = initialState;

  final PlaybackSessionState initialState;
  PlaybackSessionState _state;

  PlaybackSessionState get state => _state;

  PlaybackSessionState transition(PlaybackSessionEvent event) {
    switch (_state) {
      case PlaybackSessionState.idle:
        if (event == PlaybackSessionEvent.primeRequested) {
          _state = PlaybackSessionState.primed;
        } else if (event == PlaybackSessionEvent.disposeRequested) {
          _state = PlaybackSessionState.disposed;
        } else if (event == PlaybackSessionEvent.failure) {
          _state = PlaybackSessionState.failed;
        }
      case PlaybackSessionState.primed:
        if (event == PlaybackSessionEvent.attachRequested) {
          _state = PlaybackSessionState.attaching;
        } else if (event == PlaybackSessionEvent.suspendRequested) {
          _state = PlaybackSessionState.suspended;
        } else if (event == PlaybackSessionEvent.disposeRequested) {
          _state = PlaybackSessionState.disposed;
        } else if (event == PlaybackSessionEvent.failure) {
          _state = PlaybackSessionState.failed;
        }
      case PlaybackSessionState.attaching:
        if (event == PlaybackSessionEvent.firstFrameRendered) {
          _state = PlaybackSessionState.ready;
        } else if (event == PlaybackSessionEvent.suspendRequested) {
          _state = PlaybackSessionState.suspended;
        } else if (event == PlaybackSessionEvent.disposeRequested) {
          _state = PlaybackSessionState.disposed;
        } else if (event == PlaybackSessionEvent.failure) {
          _state = PlaybackSessionState.failed;
        }
      case PlaybackSessionState.ready:
        if (event == PlaybackSessionEvent.activateRequested) {
          _state = PlaybackSessionState.active;
        } else if (event == PlaybackSessionEvent.suspendRequested) {
          _state = PlaybackSessionState.suspended;
        } else if (event == PlaybackSessionEvent.disposeRequested) {
          _state = PlaybackSessionState.disposed;
        } else if (event == PlaybackSessionEvent.failure) {
          _state = PlaybackSessionState.failed;
        }
      case PlaybackSessionState.active:
        if (event == PlaybackSessionEvent.suspendRequested) {
          _state = PlaybackSessionState.suspended;
        } else if (event == PlaybackSessionEvent.disposeRequested) {
          _state = PlaybackSessionState.disposed;
        } else if (event == PlaybackSessionEvent.failure) {
          _state = PlaybackSessionState.failed;
        }
      case PlaybackSessionState.suspended:
        if (event == PlaybackSessionEvent.attachRequested) {
          _state = PlaybackSessionState.attaching;
        } else if (event == PlaybackSessionEvent.activateRequested) {
          _state = PlaybackSessionState.active;
        } else if (event == PlaybackSessionEvent.disposeRequested) {
          _state = PlaybackSessionState.disposed;
        } else if (event == PlaybackSessionEvent.failure) {
          _state = PlaybackSessionState.failed;
        }
      case PlaybackSessionState.disposed:
      case PlaybackSessionState.failed:
        if (event == PlaybackSessionEvent.primeRequested) {
          _state = PlaybackSessionState.primed;
        }
    }
    return _state;
  }

  void reset() {
    _state = initialState;
  }
}
