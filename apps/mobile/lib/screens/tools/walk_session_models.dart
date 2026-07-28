import 'dart:collection';
import 'dart:math' show sqrt;

/// Live in-progress walk/run session. Detects steps in real time from raw
/// accelerometer samples via adaptive threshold/peak detection plus cadence
/// gating, rather than relying on the OS's cumulative step-counter sensor —
/// that sensor is hardware-batched and can lag many seconds behind an actual
/// step, which reads as "not counting" to the user.
///
/// Uses the raw TYPE_ACCELEROMETER sensor (present on every phone — it's
/// what drives screen auto-rotate) rather than the synthesized
/// TYPE_LINEAR_ACCELERATION virtual sensor, which some devices don't
/// implement. Because raw readings include gravity (~9.8 m/s^2 along
/// whichever axis is "down"), gravity is tracked and subtracted with a slow
/// moving average rather than assumed to already be removed.
///
/// Step detection is a two-stage pipeline:
///
///  1. **Signal stage** ([addAccelerometerSample]): a peak detector over an
///     *adaptive* threshold derived from the min/max deviation seen in the
///     last ~2s ([_dynamicThreshold]), instead of one fixed constant. This
///     keeps it sensitive during a gentle/slow walk (small swings) while
///     staying insensitive to ambient noise during a vigorous one (large
///     swings) — a single fixed threshold can't be right for both.
///
///     Re-arming after a peak is **time-based** (a fixed
///     [_refractoryPeriod]), not magnitude-based. An earlier version
///     re-armed once the deviation decayed back under a fraction of the
///     threshold — but shrinking the threshold floor to make slow steps
///     detectable also shrinks that decay target, and the signal's natural
///     decay curve (shaped by the low-pass/gravity filters) didn't reliably
///     fall below the new, much smaller absolute bar within one gait cycle.
///     That combination left the detector stuck disarmed after the first
///     step of every walk, regardless of `_gravityAlpha` (confirmed by
///     sweeping it from 0.02-0.08 — the failure was structural, not a
///     tuning issue). Switching to a fixed lockout avoids depending on decay
///     rate at all, but the lockout still has to be long enough to outlast
///     one impact's own decay tail under these filter constants — measured
///     empirically at ~380-400ms here — or the tail itself gets
///     misdetected as a second, phantom peak once the lockout lifts. That
///     puts a rough ceiling on the fastest cadence this can detect
///     (~150 steps/min); a genuinely faster sprint could under-count.
///  2. **Cadence stage** ([_registerCandidatePeak]): a raw peak alone can't
///     tell a footstep from a hand-shake — both are just "a jerk away from
///     gravity, then back". This stage requires a short run of peaks spaced
///     like an actual gait (300ms-1200ms apart) before it trusts them as
///     real steps, which is what actually rejects shake bursts (too fast or
///     too irregular to sustain that spacing) and isolated bumps (no
///     sustained cadence at all) — the signal stage alone can't do that
///     because it only ever looks at one sample at a time.
///
/// Tradeoff worth knowing: because stage 2 buffers the first
/// [_confirmCount] steps of a sequence before trusting them, the live step
/// count won't move for the first few steps of every walk (or every
/// resumption after standing still for over [_idleGap]) — it jumps by
/// [_confirmCount] once cadence is confirmed, rather than counting one at a
/// time as they happen.
class ActiveWalkSession {
  // ---- Stage 1: adaptive peak detection ----

  /// Size of the rolling window (in samples) used to derive the adaptive
  /// threshold. At ~50Hz (`SensorInterval.gameInterval`), 100 samples is
  /// ~2 seconds — long enough to span at least one full gait cycle.
  static const int _windowSize = 100;

  /// Floor for the adaptive threshold. Below this, ambient sensor noise
  /// (phone sitting on a table, a hand tremor) would start registering as
  /// steps — but it's still low enough that a slow/gentle step's smaller
  /// deviation clears it, unlike the old fixed 1.2 threshold that missed
  /// those.
  static const double _minDynamicThreshold = 0.30;

  /// Ceiling for the adaptive threshold. Without this, a burst of large
  /// motion (running, or the phone being picked up) would push the window's
  /// max deviation way up, and the threshold would stay unrealistically
  /// high for the next ~2 seconds — until that sample ages out of the
  /// window — silently dropping genuine steps right after.
  static const double _maxDynamicThreshold = 1.50;

  /// How far into the window's [min, max] deviation range the threshold
  /// sits. Kept low (30%) so it stays close to the window's noise floor
  /// rather than its peak, since real steps *are* the window's peaks, not
  /// its median.
  static const double _thresholdWindowFraction = 0.3;

  static const double _lowPassAlpha = 0.18;
  static const double _gravityAlpha = 0.02;

  /// Fixed re-arm lockout after a peak fires — long enough to fully outlast
  /// one impact's own decay tail under these filter constants (measured
  /// empirically; see the class doc), so the tail itself can't be
  /// misdetected as a second peak once the lockout lifts. No separate
  /// magnitude-based debounce is needed on top of it.
  static const Duration _refractoryPeriod = Duration(milliseconds: 400);

  final Queue<double> _deviationWindow = Queue<double>();

  double? _gravityEstimate;
  double _filteredDeviation = 0;
  bool _armed = true;
  Duration? _lastPeakElapsed;

  // ---- Stage 2: cadence gating / anti-shake debounce ----

  /// Cadence bounds a real gait must fall inside: 300ms (a fast run, ~200
  /// steps/min) to 1200ms (a very slow walk, ~50 steps/min). A peak whose
  /// interval from the previous one falls outside this range can't be part
  /// of the same walking cadence — a shake burst is much faster and far
  /// less regular than this window allows.
  static const Duration _minCadenceInterval = Duration(milliseconds: 300);
  static const Duration _maxCadenceInterval = Duration(milliseconds: 1200);

  /// If nothing has been detected for longer than this, treat the session
  /// as having gone fully idle — the next peak starts a cold sequence
  /// rather than being compared against a stale timestamp.
  static const Duration _idleGap = Duration(milliseconds: 1500);

  /// Consecutive same-cadence peaks required before they're trusted as real
  /// steps and flushed to [_steps] together, rather than counting the first
  /// jerk of a hand-shake burst immediately.
  static const int _confirmCount = 4;

  _WalkGaitState _state = _WalkGaitState.idle;
  int _candidateSteps = 0;

  final Stopwatch stopwatch = Stopwatch();
  int _steps = 0;

  int get steps => _steps;

  /// Feed each raw sample from accelerometerEventStream() here. [at]
  /// overrides the elapsed-time reference used for step debouncing — only
  /// meant for tests; production calls always use the running stopwatch.
  void addAccelerometerSample(double x, double y, double z, {Duration? at}) {
    final magnitude = sqrt(x * x + y * y + z * z);
    _gravityEstimate = _gravityEstimate == null
        ? magnitude
        : _gravityAlpha * magnitude + (1 - _gravityAlpha) * _gravityEstimate!;
    final deviation = (magnitude - _gravityEstimate!).abs();
    _filteredDeviation = _lowPassAlpha * deviation + (1 - _lowPassAlpha) * _filteredDeviation;

    _deviationWindow.addLast(_filteredDeviation);
    if (_deviationWindow.length > _windowSize) _deviationWindow.removeFirst();

    final threshold = _dynamicThreshold();
    final elapsed = at ?? stopwatch.elapsed;
    final previousPeak = _lastPeakElapsed;

    if (!_armed && previousPeak != null && elapsed - previousPeak >= _refractoryPeriod) {
      _armed = true;
    }

    if (_armed && _filteredDeviation > threshold) {
      _armed = false;
      _lastPeakElapsed = elapsed;
      _registerCandidatePeak(elapsed, previousPeak);
    }
  }

  /// O(window size) full scan is trivial here (100 elements, once per
  /// sample) — not worth a sliding-window-min/max structure for a buffer
  /// this small.
  double _dynamicThreshold() {
    if (_deviationWindow.isEmpty) return _minDynamicThreshold;
    var min = _deviationWindow.first;
    var max = _deviationWindow.first;
    for (final v in _deviationWindow) {
      if (v < min) min = v;
      if (v > max) max = v;
    }
    final raw = min + _thresholdWindowFraction * (max - min);
    return raw.clamp(_minDynamicThreshold, _maxDynamicThreshold);
  }

  void _registerCandidatePeak(Duration elapsed, Duration? previousPeak) {
    if (previousPeak == null) {
      _startNewSequence();
      return;
    }

    final interval = elapsed - previousPeak;
    if (interval > _idleGap) {
      // Long enough since the last peak that this isn't a continuation of
      // anything — treat it as a fresh baseline, not even the first
      // candidate of a new sequence (the *next* peak will be).
      _state = _WalkGaitState.idle;
      _candidateSteps = 0;
      return;
    }
    if (interval < _minCadenceInterval || interval > _maxCadenceInterval) {
      // Outside plausible gait cadence, but recent enough that it could
      // still be the start of a new sequence — let it seed one rather than
      // discarding it outright.
      _startNewSequence();
      return;
    }

    // Interval matches a plausible walking/running cadence.
    if (_state == _WalkGaitState.walking) {
      _steps++;
    } else {
      _candidateSteps++;
      if (_candidateSteps >= _confirmCount) {
        _steps += _candidateSteps;
        _candidateSteps = 0;
        _state = _WalkGaitState.walking;
      }
    }
  }

  void _startNewSequence() {
    _state = _WalkGaitState.idle;
    _candidateSteps = 1;
  }

  double distanceMeters(double strideLengthMeters) => _steps * strideLengthMeters;

  double speedMps(double strideLengthMeters) {
    final elapsedSeconds = stopwatch.elapsed.inMilliseconds / 1000;
    if (elapsedSeconds <= 0) return 0.0;
    return distanceMeters(strideLengthMeters) / elapsedSeconds;
  }
}

enum _WalkGaitState { idle, walking }
