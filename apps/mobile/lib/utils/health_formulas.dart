import '../data/body_profile_store.dart';

class BmiResult {
  final double bmi;
  final double bodyFatPercent;
  BmiResult(this.bmi, this.bodyFatPercent);
}

class HealthFormulas {
  HealthFormulas._();

  static double heightM(double heightCm) => heightCm / 100;

  /// Traditional BMI: weight(kg) / height(m)^2
  static double bmiStandard(double weightKg, double heightCm) {
    final h = heightM(heightCm);
    return weightKg / (h * h);
  }

  /// Trefethen's corrected BMI: 1.3 * weight / height^2.5 (kg, m).
  /// Reduces the height-bias of the standard formula.
  static double bmiNew(double weightKg, double heightCm) {
    final h = heightM(heightCm);
    return 1.3 * weightKg / _pow(h, 2.5);
  }

  /// Inverse of [bmiStandard]: weight(kg) needed to hit a target BMI at this height.
  static double weightForBmiStandard(double targetBmi, double heightCm) {
    final h = heightM(heightCm);
    return targetBmi * h * h;
  }

  /// Inverse of [bmiNew]: weight(kg) needed to hit a target BMI at this height.
  static double weightForBmiNew(double targetBmi, double heightCm) {
    final h = heightM(heightCm);
    return targetBmi * _pow(h, 2.5) / 1.3;
  }

  static double _pow(double base, double exponent) {
    var result = 1.0;
    // exponent is always 2.5 here; compute via sqrt for the .5 part.
    final intPart = exponent.floor();
    for (var i = 0; i < intPart; i++) {
      result *= base;
    }
    return result * _sqrt(base);
  }

  static double _sqrt(double v) {
    if (v <= 0) return 0;
    var x = v;
    for (var i = 0; i < 20; i++) {
      x = 0.5 * (x + v / x);
    }
    return x;
  }

  static BmiResult bmi(double weightKg, double heightCm, Gender gender, int age, bool useNewFormula) {
    final value = useNewFormula ? bmiNew(weightKg, heightCm) : bmiStandard(weightKg, heightCm);
    final sex = gender == Gender.male ? 1 : 0;
    final fat = (1.2 * value) + (0.23 * age) - (10.8 * sex) - 5.4;
    return BmiResult(value, fat.clamp(0, 100));
  }

  static const bmiCategories = <(String, double, double)>[
    ('Severe Underweight', double.negativeInfinity, 16),
    ('Moderate Underweight', 16, 16.9),
    ('Underweight', 17, 18.4),
    ('Normal', 18.5, 24.9),
    ('Overweight', 25, 29.9),
    ('Obese Class I', 30, 34.9),
    ('Obese Class II', 35, 39.9),
    ('Obese Class III', 40, double.infinity),
  ];

  static String bmiCategoryLabel(double bmi) {
    for (final c in bmiCategories) {
      if (bmi < c.$3 || (c.$3 == double.infinity)) {
        if (bmi >= c.$2 || c.$2 == double.negativeInfinity) return c.$1;
      }
    }
    return 'Normal';
  }

  static String bmiAdvice(double bmi) {
    final category = bmiCategoryLabel(bmi);
    switch (category) {
      case 'Severe Underweight':
      case 'Moderate Underweight':
      case 'Underweight':
        return 'Your BMI indicates that you are underweight. Consider increasing '
            'your calorie intake with nutrient-dense foods. Talk to your doctor for advice.';
      case 'Normal':
        return 'Your BMI indicates that you are at a healthy weight. Keep up the '
            'balanced diet and regular activity.';
      default:
        return 'Your BMI indicates that you are overweight. Its Time to lose some '
            'weight, your health may be at risk. Talk to your doctor for advice.';
    }
  }

  /// Mifflin-St Jeor BMR (kcal/day).
  static double bmr(double weightKg, double heightCm, int age, Gender gender) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return gender == Gender.male ? base + 5 : base - 161;
  }

  static double tdee(double bmr, ActivityLevel level) => bmr * level.multiplier;

  /// Robinson / Miller / Devine / Hamwi ideal-weight formulas (kg), for
  /// heights >= 5ft. All defined per inch over 5 feet.
  static Map<String, double> idealWeightFormulas(double heightCm, Gender gender) {
    final totalInches = heightCm / 2.54;
    final overInches = (totalInches - 60).clamp(0, double.infinity);

    double robinson, miller, devine, hamwi;
    if (gender == Gender.male) {
      robinson = 52 + 1.9 * overInches;
      miller = 56.2 + 1.41 * overInches;
      devine = 50 + 2.3 * overInches;
      hamwi = 48.0 + 2.7 * overInches;
    } else {
      robinson = 49 + 1.7 * overInches;
      miller = 53.1 + 1.36 * overInches;
      devine = 45.5 + 2.3 * overInches;
      hamwi = 45.5 + 2.2 * overInches;
    }

    final h = heightM(heightCm);
    final whoLow = 18.5 * h * h;
    final whoHigh = 25 * h * h;

    return {
      'WHO': (whoLow + whoHigh) / 2,
      'Robinson Formula': robinson,
      'Miller Formula': miller,
      'Devine Formula': devine,
      'Hamwi Formula': hamwi,
    };
  }

  static (double, double) whoRange(double heightCm) {
    final h = heightM(heightCm);
    return (18.5 * h * h, 25 * h * h);
  }

  /// Daily water intake suggestion: ~0.5oz per lb of bodyweight.
  static (double ounces, double liters) waterIntake(double weightKg) {
    final lbs = weightKg * 2.2046226218;
    final oz = lbs * 0.5;
    final liters = oz * 0.0295735;
    return (oz, liters);
  }

  static double calorieTarget(double bmrValue, ActivityLevel level, double kcalDeltaPerDay) {
    return tdee(bmrValue, level) + kcalDeltaPerDay;
  }

  /// ADA range: ~1.0-1.8 g protein per kg bodyweight.
  static (double, double) adaProteinRangeGrams(double weightKg) => (weightKg * 1.0, weightKg * 1.8);

  /// CDC range: 10-35% of daily calories, at 4 kcal/g.
  static (double, double) cdcProteinRangeGrams(double dailyCalories) =>
      (dailyCalories * 0.10 / 4, dailyCalories * 0.35 / 4);

  static (double, double) carbRangeGrams(double dailyCalories) =>
      (dailyCalories * 0.45 / 4, dailyCalories * 0.65 / 4);

  static (double, double) fatRangeGrams(double dailyCalories) =>
      (dailyCalories * 0.20 / 9, dailyCalories * 0.35 / 9);

  // --- Walk/run calorie estimation (ACSM metabolic equations) ---

  /// ACSM net (activity-only) VO2 estimate (ml/kg/min), auto-selecting the
  /// walking vs running equation by speed (walking below ~134 m/min / 5mph,
  /// running above, per ACSM's own domain guidance for each equation). The
  /// gross ACSM equations end in "+ 3.5", a 1-MET resting-metabolism
  /// baseline; that's dropped here since resting energy is already accounted
  /// for separately via [restingKcalPerMinute] — including it here as well
  /// would double-count rest.
  static double _walkRunVo2Net(double speedMetersPerMin) {
    if (speedMetersPerMin <= 134) return 0.1 * speedMetersPerMin;
    return 0.2 * speedMetersPerMin;
  }

  /// Active (mechanical) calorie burn rate, kcal/min, from the ACSM VO2
  /// estimate. Excludes resting metabolism — see [restingKcalPerMinute].
  static double activeKcalPerMinute(double weightKg, double speedMetersPerMin) =>
      _walkRunVo2Net(speedMetersPerMin) * weightKg / 200;

  /// Resting calorie burn rate, kcal/min, from a daily BMR value. Folded
  /// into [totalWalkKcal] so age/height/gender (already baked into [bmr])
  /// affect the total, not just weight and speed.
  static double restingKcalPerMinute(double bmrValue) => bmrValue / 1440;

  /// Total calories burned over a walk/run: active + resting, over the
  /// given duration.
  static double totalWalkKcal({
    required double weightKg,
    required double speedMetersPerMin,
    required double durationMinutes,
    required double bmrValue,
  }) {
    final perMinute = activeKcalPerMinute(weightKg, speedMetersPerMin) + restingKcalPerMinute(bmrValue);
    return perMinute * durationMinutes;
  }

  /// Inverse of [totalWalkKcal]: the speed (m/min) needed to burn
  /// [targetKcal] over [durationMinutes] at [weightKg]/[bmrValue]. Solves
  /// with the walking equation first; if that lands outside the walking
  /// speed range, re-solves with the running equation.
  static double speedForKcalTarget({
    required double weightKg,
    required double durationMinutes,
    required double bmrValue,
    required double targetKcal,
  }) {
    double solve(double vo2Coeff) {
      final perMinuteTarget = targetKcal / durationMinutes;
      final resting = restingKcalPerMinute(bmrValue);
      return (perMinuteTarget - resting) * 200 / (weightKg * vo2Coeff);
    }

    final walkingSpeed = solve(0.1);
    if (walkingSpeed <= 134) return walkingSpeed < 0 ? 0 : walkingSpeed;
    final runningSpeed = solve(0.2);
    return runningSpeed < 0 ? 0 : runningSpeed;
  }

  /// Inverse of [totalWalkKcal]: the duration (minutes) needed to burn
  /// [targetKcal] at [speedMetersPerMin]/[weightKg]/[bmrValue].
  static double durationMinutesForKcalTarget({
    required double weightKg,
    required double speedMetersPerMin,
    required double bmrValue,
    required double targetKcal,
  }) {
    final perMinute = activeKcalPerMinute(weightKg, speedMetersPerMin) + restingKcalPerMinute(bmrValue);
    if (perMinute <= 0) return 0;
    return targetKcal / perMinute;
  }

  // --- Resistance training calorie estimation (Compendium of Physical
  // Activities METs) ---

  /// MET tier for a resistance-training set, from the Compendium of
  /// Physical Activities. Individual sets aren't timed, so intensity is
  /// inferred from rep range / warm-up status rather than measured effort:
  /// - warm-up: 3.5 MET (light/general effort, code 02054)
  /// - <=6 reps: 6.0 MET (vigorous effort, heavy/low-rep, code 02050)
  /// - 7-15 reps: 5.0 MET (moderate effort, working sets, code 02052)
  /// - >15 reps: 3.5 MET (light-moderate, high-rep/endurance, code 02054)
  static double _resistanceMet({required bool isWarmup, required int reps}) {
    if (isWarmup) return 3.5;
    if (reps <= 6) return 6.0;
    if (reps <= 15) return 5.0;
    return 3.5;
  }

  /// Assumed time under tension per rep, seconds (~1.5s concentric + ~2s
  /// eccentric) — sets aren't individually timed, so this stands in for
  /// actual rep duration, the same way most lifting-calorie estimators do.
  static const double secondsPerRep = 3.5;

  /// Personalized resting oxygen-consumption baseline (mL O2/kg/min),
  /// derived from the lifter's own Mifflin-St Jeor RMR rather than assumed.
  /// Standard MET tables define "1 MET" as the population-average 3.5
  /// mL/kg/min; substituting this personal baseline for that constant in
  /// [setKcal] scales energy cost to the individual's actual metabolic rate
  /// (linearly, once) instead of layering a second correction factor on top
  /// of the MET value, which would double-apply the correction.
  static double oxygenBaseline(double bmrValue, double bodyWeightKg) {
    if (bodyWeightKg <= 0) return 3.5;
    return (bmrValue / 1440 / 5) / bodyWeightKg * 1000;
  }

  /// Relative-load adjustment on top of the rep-range MET tier: the
  /// Compendium's MET values don't vary with how much weight is on the bar,
  /// so two sets at the same rep count score identically regardless of
  /// load (30kg x10 == 50kg x10). This scales the MET up by 12% per 1x
  /// bodyweight lifted — a consumer-app heuristic (not itself a Compendium
  /// value) layered on top of the Compendium baseline so heavier relative
  /// loads cost more, same rep count or not.
  static double _loadBonus({required double loadKg, required double bodyWeightKg}) =>
      bodyWeightKg <= 0 ? 1 : 1 + (loadKg / bodyWeightKg) * 0.12;

  /// Net (activity-only) calorie cost of a single set, kcal. Uses the
  /// lifter's body weight for the kcal/min conversion (MET-based formulas
  /// scale with the exerciser's own mass) while [loadKg] — the weight
  /// actually lifted — biases the MET tier via [_loadBonus]. Nets out the
  /// 1-MET resting baseline the Compendium's gross MET values include, so
  /// this can be added to [restingKcalPerMinute] without double-counting
  /// rest — same convention as [activeKcalPerMinute] for walk/run. Uses
  /// [oxygenBaseline] (personalized, from [bmrValue]) in place of the
  /// standard 3.5 mL/kg/min MET constant.
  /// Floor on gross MET before netting out the 1-MET resting baseline, so
  /// `netMet` can never reach zero/negative even if a future exercise-tier
  /// or load input pushes the raw value below this.
  static const double _minGrossMet = 2.0;

  static double setKcal({
    required double bodyWeightKg,
    required double bmrValue,
    required int reps,
    required bool isWarmup,
    double loadKg = 0,
  }) {
    if (reps <= 0) return 0;
    final rawGrossMet =
        _resistanceMet(isWarmup: isWarmup, reps: reps) * _loadBonus(loadKg: loadKg, bodyWeightKg: bodyWeightKg);
    final grossMet = rawGrossMet < _minGrossMet ? _minGrossMet : rawGrossMet;
    final netMet = grossMet - 1;
    final ob = oxygenBaseline(bmrValue, bodyWeightKg);
    final activeMinutes = (reps * secondsPerRep) / 60;
    return netMet * ob * bodyWeightKg / 200 * activeMinutes;
  }

  /// Net (activity-only) calorie cost of a cardio (duration + distance) set
  /// — treadmill, bike, rower, jump rope etc. When distance is known, reuses
  /// the ACSM walk/run speed-based VO2 model ([activeKcalPerMinute]) rather
  /// than inventing a separate formula. When there's no meaningful distance
  /// to derive a speed from, falls back to a flat moderate-vigorous cardio
  /// MET (7.0, mid-range for machine cardio per the Compendium of Physical
  /// Activities) net of the resting baseline.
  static double cardioSetKcal({
    required double bodyWeightKg,
    required double durationMinutes,
    double? distanceMeters,
  }) {
    if (durationMinutes <= 0) return 0;
    if (distanceMeters != null && distanceMeters > 0) {
      final speedMetersPerMin = distanceMeters / durationMinutes;
      return activeKcalPerMinute(bodyWeightKg, speedMetersPerMin) * durationMinutes;
    }
    const flatCardioMet = 7.0;
    final netMet = flatCardioMet - 1;
    return netMet * 3.5 * bodyWeightKg / 200 * durationMinutes;
  }

  /// Total workout calories: the net active cost of every set (sum of
  /// [setKcal]/[cardioSetKcal] across the workout, passed in as
  /// [activeSetKcalSum]) plus resting metabolism applied across the whole
  /// workout's elapsed time — active seconds included. That's not double
  /// counting: [setKcal] already nets out 1 MET (the baseline this term
  /// covers) before charging the incremental active cost, so this baseline
  /// sweep has to span the *entire* duration, not just the gaps between sets.
  ///
  /// Two ways to source that duration, chosen by [isLiveSession]:
  /// - live (true): [liveDuration] — the real stopwatch-tracked elapsed
  ///   time, ground truth for a session actually being tracked as it
  ///   happens.
  /// - not live (false): [syntheticDuration] — a caller-computed estimate
  ///   (active time-under-tension per completed set, plus each exercise's
  ///   configured rest-between-sets duration across its set gaps), used
  ///   when there's no real elapsed time to trust: backfilling a past
  ///   workout entered after the fact, or previewing a template.
  static double workoutKcal({
    required double activeSetKcalSum,
    required double bmrValue,
    required bool isLiveSession,
    Duration liveDuration = Duration.zero,
    Duration syntheticDuration = Duration.zero,
  }) {
    final baselineDuration = isLiveSession ? liveDuration : syntheticDuration;
    return activeSetKcalSum + restingKcalPerMinute(bmrValue) * (baselineDuration.inMilliseconds / 60000);
  }

  // --- Distance/speed/pace unit conversions ---

  static double kmhToMetersPerMin(double kmh) => kmh * 1000 / 60;
  static double metersPerMinToKmh(double metersPerMin) => metersPerMin * 60 / 1000;

  static double mphToMetersPerMin(double mph) => mph * 1609.344 / 60;
  static double metersPerMinToMph(double metersPerMin) => metersPerMin * 60 / 1609.344;

  /// Pace expressed as minutes per kilometer <-> speed in meters/minute.
  static double paceMinPerKmToMetersPerMin(double paceMinPerKm) =>
      paceMinPerKm <= 0 ? 0 : 1000 / paceMinPerKm;
  static double metersPerMinToPaceMinPerKm(double metersPerMin) =>
      metersPerMin <= 0 ? 0 : 1000 / metersPerMin;

  static double kmToMiles(double km) => km / 1.609344;
  static double milesToKm(double miles) => miles * 1.609344;
}
