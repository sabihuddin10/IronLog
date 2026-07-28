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

void _feed(ActiveWalkSession session, List<double> deltas, {int stepMs = 20}) {
  for (var i = 0; i < deltas.length; i++) {
    session.addAccelerometerSample(0, 0, _restZ + deltas[i], at: Duration(milliseconds: i * stepMs));
  }
}

void main() {
  group('ActiveWalkSession', () {
    test('a single footstep pattern counts one step', () {
      final session = ActiveWalkSession();
      _feed(session, _step);
      expect(session.steps, 1);
    });

    test('two footsteps spaced a normal gait apart count as two steps', () {
      final session = ActiveWalkSession();
      _feed(session, [..._step, ..._quietGap, ..._step]);
      expect(session.steps, 2);
    });

    test('a sustained spike does not double-count while still above threshold', () {
      final session = ActiveWalkSession();
      _feed(session, [0.0, 3.0, 3.0, 3.0, 3.0, 3.0, 3.0]);
      expect(session.steps, 1);
    });

    test('distanceMeters multiplies steps by stride length', () {
      final session = ActiveWalkSession();
      _feed(session, [..._step, ..._quietGap, ..._step]);
      expect(session.steps, 2);
      expect(session.distanceMeters(0.75), closeTo(1.5, 0.0001));
    });

    test('speedMps is zero when the stopwatch has not been started', () {
      final session = ActiveWalkSession();
      _feed(session, _step);
      expect(session.speedMps(0.75), 0.0);
    });
  });
}
