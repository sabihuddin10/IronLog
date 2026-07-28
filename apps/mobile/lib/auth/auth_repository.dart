abstract class AppAuthUser {
  String get uid;
  String get email;
  Future<String?> getIdToken();
}

abstract class AuthRepository {
  Stream<AppAuthUser?> authStateChanges();
  AppAuthUser? get currentUser;
  Future<void> signIn(String email, String password);
  Future<void> signUp(String email, String password);
  Future<void> signOut();
}
