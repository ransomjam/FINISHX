import '../../core/utils/id_generator.dart';
import '../../domain/enums/app_enums.dart';
import '../../domain/models/user.dart';
import '../datasources/local_storage_datasource.dart';

abstract interface class AuthRepository {
  bool get isExternalAuthConfigured;
  User? getCurrentUser();
  DateTime? getPreviousLastActiveAt();
  Future<User> signInWithProvider({
    required AuthProviderType provider,
    required String displayName,
    required String email,
  });
  Future<User> updateProfile({required String displayName});
  Future<void> recordActivity(DateTime now);
  Future<void> signOut();
}

/// Development/Demo authentication implementation backed by local storage.
///
/// Clearly reports [isExternalAuthConfigured] as false so the UI informs users
/// that authentication is running in local demo mode until OAuth/backend keys
/// are configured.
class LocalDemoAuthRepository implements AuthRepository {
  LocalDemoAuthRepository(this._storage);

  final LocalStorageDataSource _storage;

  @override
  bool get isExternalAuthConfigured => false;

  @override
  User? getCurrentUser() {
    final json = _storage.readObject(LocalStorageDataSource.keyCurrentUser);
    if (json == null) return null;
    return User.fromJson(json);
  }

  @override
  DateTime? getPreviousLastActiveAt() {
    return _storage.readDateTime(LocalStorageDataSource.keyPreviousLastActive);
  }

  @override
  Future<User> signInWithProvider({
    required AuthProviderType provider,
    required String displayName,
    required String email,
  }) async {
    final now = DateTime.now();
    final existing = getCurrentUser();
    final trimmedName = displayName.trim().isEmpty
        ? 'Alex Mercer'
        : displayName.trim();
    final trimmedEmail = email.trim().isEmpty
        ? '${trimmedName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '.')}@demo.finishx.app'
        : email.trim();

    if (existing != null) {
      await _storage.writeDateTime(
        LocalStorageDataSource.keyPreviousLastActive,
        existing.lastActiveAt,
      );
    }

    final user = User(
      id: existing?.id ?? IdGenerator.next('usr'),
      name: trimmedName,
      email: trimmedEmail,
      authProvider: provider,
      createdAt: existing?.createdAt ?? now,
      lastActiveAt: now,
      isDemoAccount: true,
    );

    await _storage.writeObject(
      LocalStorageDataSource.keyCurrentUser,
      user.toJson(),
    );
    return user;
  }

  @override
  Future<User> updateProfile({required String displayName}) async {
    final current = getCurrentUser();
    if (current == null) {
      throw StateError('No signed-in user to update.');
    }
    final updated = current.copyWith(
      name: displayName.trim(),
      lastActiveAt: DateTime.now(),
    );
    await _storage.writeObject(
      LocalStorageDataSource.keyCurrentUser,
      updated.toJson(),
    );
    return updated;
  }

  @override
  Future<void> recordActivity(DateTime now) async {
    final current = getCurrentUser();
    if (current == null) return;
    await _storage.writeDateTime(
      LocalStorageDataSource.keyPreviousLastActive,
      current.lastActiveAt,
    );
    final updated = current.copyWith(lastActiveAt: now);
    await _storage.writeObject(
      LocalStorageDataSource.keyCurrentUser,
      updated.toJson(),
    );
  }

  @override
  Future<void> signOut() async {
    await _storage.writeObject(LocalStorageDataSource.keyCurrentUser, null);
  }
}
