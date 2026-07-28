import 'package:flutter_test/flutter_test.dart';
import 'package:ironlog/utils/health_formulas.dart';

void main() {
  group('HealthFormulas walk/run calories', () {
    const weightKg = 70.0;
    const bmrValue = 1500.0;

    test('totalWalkKcal matches a hand-computed walking example', () {
      // ACSM walking VO2 = 0.1*80 + 3.5 = 11.5 ml/kg/min
      // active kcal/min = 11.5*70/200 = 4.025
      // resting kcal/min = 1500/1440 = 1.041666...
      // total over 30 min = (4.025+1.041666...)*30 = 152.0
      final kcal = HealthFormulas.totalWalkKcal(
        weightKg: weightKg,
        speedMetersPerMin: 80,
        durationMinutes: 30,
        bmrValue: bmrValue,
      );
      expect(kcal, closeTo(152.0, 0.01));
    });

    test('speedForKcalTarget inverts totalWalkKcal for a walking-speed result', () {
      const speed = 80.0;
      const duration = 30.0;
      final kcal = HealthFormulas.totalWalkKcal(
        weightKg: weightKg,
        speedMetersPerMin: speed,
        durationMinutes: duration,
        bmrValue: bmrValue,
      );
      final solvedSpeed = HealthFormulas.speedForKcalTarget(
        weightKg: weightKg,
        durationMinutes: duration,
        bmrValue: bmrValue,
        targetKcal: kcal,
      );
      expect(solvedSpeed, closeTo(speed, 0.001));
    });

    test('speedForKcalTarget inverts totalWalkKcal for a running-speed result', () {
      const speed = 200.0; // ~7.4 mph, above the 134 m/min walking cutoff
      const duration = 20.0;
      final kcal = HealthFormulas.totalWalkKcal(
        weightKg: weightKg,
        speedMetersPerMin: speed,
        durationMinutes: duration,
        bmrValue: bmrValue,
      );
      final solvedSpeed = HealthFormulas.speedForKcalTarget(
        weightKg: weightKg,
        durationMinutes: duration,
        bmrValue: bmrValue,
        targetKcal: kcal,
      );
      expect(solvedSpeed, closeTo(speed, 0.001));
    });

    test('durationMinutesForKcalTarget inverts totalWalkKcal', () {
      const speed = 90.0;
      const duration = 45.0;
      final kcal = HealthFormulas.totalWalkKcal(
        weightKg: weightKg,
        speedMetersPerMin: speed,
        durationMinutes: duration,
        bmrValue: bmrValue,
      );
      final solvedDuration = HealthFormulas.durationMinutesForKcalTarget(
        weightKg: weightKg,
        speedMetersPerMin: speed,
        bmrValue: bmrValue,
        targetKcal: kcal,
      );
      expect(solvedDuration, closeTo(duration, 0.001));
    });
  });

  group('HealthFormulas unit conversions', () {
    test('km/h <-> meters per minute round-trips', () {
      const kmh = 5.5;
      final metersPerMin = HealthFormulas.kmhToMetersPerMin(kmh);
      expect(HealthFormulas.metersPerMinToKmh(metersPerMin), closeTo(kmh, 0.0001));
    });

    test('mph <-> meters per minute round-trips', () {
      const mph = 3.2;
      final metersPerMin = HealthFormulas.mphToMetersPerMin(mph);
      expect(HealthFormulas.metersPerMinToMph(metersPerMin), closeTo(mph, 0.0001));
    });

    test('pace (min/km) <-> meters per minute round-trips', () {
      const paceMinPerKm = 10.0;
      final metersPerMin = HealthFormulas.paceMinPerKmToMetersPerMin(paceMinPerKm);
      expect(HealthFormulas.metersPerMinToPaceMinPerKm(metersPerMin), closeTo(paceMinPerKm, 0.0001));
    });

    test('km <-> miles round-trips', () {
      const km = 12.3;
      expect(HealthFormulas.kmToMiles(HealthFormulas.milesToKm(km)), closeTo(km, 0.0001));
    });
  });
}
