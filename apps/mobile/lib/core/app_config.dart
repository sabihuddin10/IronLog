/// App-wide storage backend switch. When `true`, every repository
/// reads/writes Firestore. When `false` (current default), the exact same
/// document shape (each model's `toJson`/`fromJson`) is instead persisted to
/// on-device local storage via [LocalCollectionStore] — useful for working
/// fully offline/without a Firebase project configured, without any
/// repository call site or UI code needing to know which backend is active.
class AppConfig {
  AppConfig._();

  static bool storeOnCloud = false;
}
