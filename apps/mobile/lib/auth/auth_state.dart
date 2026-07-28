import 'package:flutter/foundation.dart';
import 'auth_repository.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthState extends ChangeNotifier {
  final AuthRepository repository;

  AuthStatus status = AuthStatus.unknown;
  AppAuthUser? user;
  String? errorMessage;
  bool isBusy = false;

  AuthState(this.repository) {
    repository.authStateChanges().listen((u) {
      user = u;
      status = u != null ? AuthStatus.signedIn : AuthStatus.signedOut;
      notifyListeners();
    });
    user = repository.currentUser;
    status = user != null ? AuthStatus.signedIn : AuthStatus.signedOut;
  }

  Future<void> signIn(String email, String password) => _run(
        () => repository.signIn(email, password),
      );

  Future<void> signUp(String email, String password) => _run(
        () => repository.signUp(email, password),
      );

  Future<void> signOut() => repository.signOut();

  Future<void> _run(Future<void> Function() action) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }
}
