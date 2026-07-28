import 'package:flutter_test/flutter_test.dart';
import 'package:ironlog/screens/tools/walk_session_models.dart';

// Raw accelerometer readings include gravity (~9.8 m/s^2), unlike the
// gravity-removed virtual sensor this used to read from. A realistic single
// footstep: quiet baseline at rest, an impact spike sustained across a few
// 20ms samples (matching the 50Hz sampling rate the screen requests), then
// decay back to baseline before the next step.
const _restZ = 9.8;
const _step = [0.0, 0.0, 3.0, 3.0, 3.0, 0.5, 0.2, 0.0, 0.0, 0.0];
const _quietGap = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

// A gentle/slow step: a much smaller impact than a normal stride, and a
// longer quiet gap after it — this is exactly the kind of step the old fixed
// 1.2 threshold missed, and the adaptive threshold should catch instead.
const _gentleStep = [0.0, 0.0, 1.1, 1.1, 0.9, 0.2, 0.0, 0.0, 0.0, 0.0];
final _slowGap = List<double>.filled(45, 0.0); // ~900ms at 20ms/sample

// A hand-shake burst: rapid, large-amplitude jerks much faster than any real
// gait cadence (well under the 300ms cadence floor) — this is what the
// cadence gate exists to reject.
const _shakeJerk = [0.0, 6.0, -6.0, 6.0, -6.0, 0.0];

void _feed(ActiveWalkSession session, List<double> deltas, {int startMs = 0, int stepMs = 20}) {
  for (var i = 0; i < deltas.length; i++) {
    session.addAccelerometerSample(0, 0, _restZ + deltas[i], at: Duration(milliseconds: startMs + i * stepMs));
  }
}

/// Feeds [count] footsteps spaced a normal gait apart (each [_step] followed
/// by a [_quietGap]), continuing the elapsed-time sequence from wherever
/// [session] currently is.
void _feedGait(ActiveWalkSession session, int count, {int startMs = 0}) {
  var t = startMs;
  for (var i = 0; i < count; i++) {
    _feed(session, _step, startMs: t);
    t += _step.length * 20;
    _feed(session, _quietGap, startMs: t);
    t += _quietGap.length * 20;
  }
}

void main() {
  group('ActiveWalkSession', () {
    test('a single footstep is buffered, not counted immediately', () {
      final session = ActiveWalkSession();
      _feed(session, _step);
      expect(session.steps, 0);
    });

    test('fewer than 4 gait-spaced footsteps stay buffered', () {
      final session = ActiveWalkSession();
      _feedGait(session, 3);
      expect(session.steps, 0);
    });

    test('4 consecutive gait-spaced footsteps flush together and confirm walking', () {
      final session = ActiveWalkSession();
      _feedGait(session, 4);
      expect(session.steps, 4);
    });

    test('once walking is confirmed, each further gait-spaced step counts immediately', () {
      final session = ActiveWalkSession();
      _feedGait(session, 4);
      expect(session.steps, 4);
      _feedGait(session, 1, startMs: 4 * (_step.length + _quietGap.length) * 20);
      expect(session.steps, 5);
    });

    test('a sustained spike does not double-count while still above threshold', () {
      final session = ActiveWalkSession();
      _feed(session, [0.0, 3.0, 3.0, 3.0, 3.0, 3.0, 3.0]);
      _feed(session, _quietGap, startMs: 7 * 20);
      _feedGait(session, 3, startMs: (7 + _quietGap.length) * 20);
      // The sustained spike only ever produces one raw peak, so it's step 1
      // of the buffered sequence; the following 3 gait-spaced steps
      // complete the confirmation to 4 total.
      expect(session.steps, 4);
    });

    test('a hand-shake burst while otherwise stationary counts no steps', () {
      final session = ActiveWalkSession();
      _feed(session, _shakeJerk);
      _feed(session, _shakeJerk, startMs: _shakeJerk.length * 20);
      _feed(session, _shakeJerk, startMs: 2 * _shakeJerk.length * 20);
      expect(session.steps, 0);
    });

    test('gentle/slow steps are still detected via the adaptive threshold', () {
      final session = ActiveWalkSession();
      var t = 0;
      for (var i = 0; i < 4; i++) {
        _feed(session, _gentleStep, startMs: t);
        t += _gentleStep.length * 20;
        _feed(session, _slowGap, startMs: t);
        t += _slowGap.length * 20;
      }
      expect(session.steps, 4);
    });

    test('distanceMeters multiplies steps by stride length', () {
      final session = ActiveWalkSession();
      _feedGait(session, 4);
      expect(session.steps, 4);
      expect(session.distanceMeters(0.75), closeTo(3.0, 0.0001));
    });

    test('speedMps is zero when the stopwatch has not been started', () {
      final session = ActiveWalkSession();
      _feedGait(session, 4);
      expect(session.speedMps(0.75), 0.0);
    });
  });
}
