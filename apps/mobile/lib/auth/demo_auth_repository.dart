import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_repository.dart';

/// Used only when no Firebase project is configured yet (see main.dart).
/// Lets the UI be built and navigated end-to-end before real credentials
/// exist. Swap back to [FirebaseAuthRepository] once `flutterfire configure`
/// has been run for the WeightMaster Firebase project.
///
/// Persists the signed-in user to [SharedPreferences] (Flutter's equivalent
/// of localStorage) so the session survives app restarts instead of
/// resetting every time Android kills the process. FirebaseAuthRepository
/// gets this for free from the native SDK once real credentials exist.
class _DemoAuthUser implements AppAuthUser {
  @override
  final String uid;
  @override
  final String email;

  _DemoAuthUser(this.uid, this.email);

  @override
  Future<String?> getIdToken() async => null;
}

class DemoAuthRepository implements AuthRepository {
  static const _prefsKeyUid = 'demo_auth_uid';
  static const _prefsKeyEmail = 'demo_auth_email';

  AppAuthUser? _current;
  final _controller = StreamController<AppAuthUser?>.broadcast();

  DemoAuthRepository() {
    _loadPersisted();
  }

  Future<void> _loadPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_prefsKeyUid);
    final email = prefs.getString(_prefsKeyEmail);
    if (uid != null && email != null) {
      _current = _DemoAuthUser(uid, email);
      _controller.add(_current);
    }
  }

  @override
  AppAuthUser? get currentUser => _current;

  @override
  Stream<AppAuthUser?> authStateChanges() => _controller.stream;

  @override
  Future<void> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _current = _DemoAuthUser('demo-uid', email);
    _controller.add(_current);
    await _persist(_current!);
  }

  @override
  Future<void> signUp(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _current = _DemoAuthUser('demo-uid', email);
    _controller.add(_current);
    await _persist(_current!);
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyUid);
    await prefs.remove(_prefsKeyEmail);
  }

  Future<void> _persist(AppAuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyUid, user.uid);
    await prefs.setString(_prefsKeyEmail, user.email);
  }
}
