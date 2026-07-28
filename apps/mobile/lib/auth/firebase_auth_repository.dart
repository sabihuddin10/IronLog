import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'auth_repository.dart';

class _FirebaseAuthUser implements AppAuthUser {
  final fb.User _user;
  _FirebaseAuthUser(this._user);

  @override
  String get uid => _user.uid;

  @override
  String get email => _user.email ?? '';

  @override
  Future<String?> getIdToken() => _user.getIdToken();
}

class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  @override
  AppAuthUser? get currentUser {
    final user = _auth.currentUser;
    return user != null ? _FirebaseAuthUser(user) : null;
  }

  @override
  Stream<AppAuthUser?> authStateChanges() =>
      _auth.authStateChanges().map((u) => u != null ? _FirebaseAuthUser(u) : null);

  @override
  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> signUp(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
