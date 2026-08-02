import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:subscription_track/models/user.dart';
import 'package:subscription_track/services/auth_service.dart';
import 'package:subscription_track/services/service_providers.dart';

part 'auth_provider.g.dart';

@riverpod
class AuthNotifier extends _$AuthNotifier {
  late final AuthService _authService;

  @override
  AsyncValue<User?> build() {
    _authService = ref.read(authServiceProvider);
    return const AsyncValue.data(null);
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncValue.loading();
    final result = await _authService.loginWithGoogle();
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (user) => AsyncValue.data(user),
    );
  }

  Future<void> loginWithApple() async {
    state = const AsyncValue.loading();
    final result = await _authService.loginWithApple();
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (user) => AsyncValue.data(user),
    );
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await _authService.logout();
    state = const AsyncValue.data(null);
  }
}
