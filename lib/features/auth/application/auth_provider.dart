import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:subscription_track/features/auth/data/in_memory_auth_repository.dart';
import 'package:subscription_track/features/auth/domain/auth_repository.dart';
import 'package:subscription_track/features/auth/domain/user.dart';

part 'auth_provider.g.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => InMemoryAuthRepository(),
);

@riverpod
class AuthNotifier extends _$AuthNotifier {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AsyncValue<User?> build() {
    return const AsyncValue.data(null);
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncValue.loading();
    final result = await _repository.loginWithGoogle();
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (user) => AsyncValue.data(user),
    );
  }

  Future<void> loginWithApple() async {
    state = const AsyncValue.loading();
    final result = await _repository.loginWithApple();
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (user) => AsyncValue.data(user),
    );
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    final result = await _repository.logout();
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }
}
