import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_config.dart';

enum Gender { male, female }

enum ActivityLevel {
  sedentary('Sedentary - little or no exercise', 1.2),
  light('Light Active - 1-3 times/week', 1.375),
  moderate('Moderate Active - 3-5 times/week', 1.55),
  veryActive('Very Active - 6-7 times/week', 1.725),
  extraActive('Extra Active - very active & physical job', 1.9);

  final String label;
  final double multiplier;
  const ActivityLevel(this.label, this.multiplier);
}

/// Inputs shared across every health calculator so switching between BMI,
/// BMR, ideal weight, etc. keeps the same age/weight/height/gender filled
/// in, matching how the reference calculator app behaves.
class BodyProfileStore extends ChangeNotifier {
  int age = 23;
  Gender gender = Gender.male;

  double _weightKg = 85.8;
  bool weightInLbs = false;

  double _heightCm = 177.8;
  bool heightInFt = true;

  ActivityLevel activityLevel = ActivityLevel.sedentary;

  String? _uid;

  double get weightKg => _weightKg;
  double get weightLbs => _weightKg * 2.2046226218;

  void setWeightKg(double kg) {
    _weightKg = kg;
    notifyListeners();
    _persist();
  }

  void setWeightLbs(double lbs) {
    _weightKg = lbs / 2.2046226218;
    notifyListeners();
    _persist();
  }

  double get heightCm => _heightCm;
  int get heightFeet => (_heightCm / 30.48).floor();
  double get heightRemainderInches => (_heightCm / 2.54) - (heightFeet * 12);

  void setHeightCm(double cm) {
    _heightCm = cm;
    notifyListeners();
    _persist();
  }

  void setHeightFtIn(int feet, double inches) {
    _heightCm = (feet * 12 + inches) * 2.54;
    notifyListeners();
    _persist();
  }

  void setAge(int value) {
    age = value;
    notifyListeners();
    _persist();
  }

  void setGender(Gender value) {
    gender = value;
    notifyListeners();
    _persist();
  }

  void setActivityLevel(ActivityLevel value) {
    activityLevel = value;
    notifyListeners();
    _persist();
  }

  void toggleWeightUnit(bool lbs) {
    weightInLbs = lbs;
    notifyListeners();
    _persist();
  }

  void toggleHeightUnit(bool ft) {
    heightInFt = ft;
    notifyListeners();
    _persist();
  }

  /// Loads the saved profile for [uid] from Firestore, if one exists, and
  /// arms persistence for subsequent edits. Called from `main.dart` when
  /// auth signs a user in. Fields not present in the doc (e.g. a brand-new
  /// account) keep their current defaults.
  Future<void> loadForUser(String uid) async {
    _uid = uid;
    final data = AppConfig.storeOnCloud
        ? (await FirebaseFirestore.instance.collection('users').doc(uid).get()).data()
        : await _loadLocal(uid);
    if (data == null) return;

    age = data['age'] as int? ?? age;
    gender = Gender.values.firstWhere(
      (g) => g.name == data['gender'],
      orElse: () => gender,
    );
    _weightKg = (data['weightKg'] as num?)?.toDouble() ?? _weightKg;
    weightInLbs = data['weightInLbs'] as bool? ?? weightInLbs;
    _heightCm = (data['heightCm'] as num?)?.toDouble() ?? _heightCm;
    heightInFt = data['heightInFt'] as bool? ?? heightInFt;
    activityLevel = ActivityLevel.values.firstWhere(
      (a) => a.name == data['activityLevel'],
      orElse: () => activityLevel,
    );
    notifyListeners();
  }

  /// Clears the signed-in user and stops persisting further edits. Called
  /// on sign-out; the in-memory values are left as-is (harmless, since the
  /// next `loadForUser` overwrites them) rather than reset to defaults.
  void signOut() {
    _uid = null;
  }

  static String _localKey(String uid) => 'local_profile_$uid';

  Future<Map<String, dynamic>?> _loadLocal(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localKey(uid));
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  void _persist() {
    final uid = _uid;
    if (uid == null) return;
    final data = {
      'age': age,
      'gender': gender.name,
      'weightKg': _weightKg,
      'weightInLbs': weightInLbs,
      'heightCm': _heightCm,
      'heightInFt': heightInFt,
      'activityLevel': activityLevel.name,
    };
    if (AppConfig.storeOnCloud) {
      FirebaseFirestore.instance.collection('users').doc(uid).set(data, SetOptions(merge: true));
    } else {
      SharedPreferences.getInstance().then((prefs) => prefs.setString(_localKey(uid), jsonEncode(data)));
    }
  }
}
