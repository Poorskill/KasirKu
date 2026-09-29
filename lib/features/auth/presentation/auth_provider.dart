import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_profile.dart';
import '../../../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return HybridAuthRepository();
});

final authStateProvider = StreamProvider<UserProfile?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.watchAuthState();
});

final currentUserProvider = StateProvider<UserProfile?>((ref) {
  final asyncUser = ref.watch(authStateProvider);
  return asyncUser.asData?.value;
});

class AuthState {
  final bool isLoading;
  final String? errorMessage;

  const AuthState({this.isLoading = false, this.errorMessage});
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final Ref _ref;

  AuthNotifier(this._repo, this._ref) : super(const AuthState());

  Future<bool> login(String email, String password) async {
    state = const AuthState(isLoading: true);
    try {
      final user = await _repo.login(email, password);
      _ref.read(currentUserProvider.notifier).state = user;
      state = const AuthState(isLoading: false);
      return true;
    } catch (e) {
      state = AuthState(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = const AuthState(isLoading: true);
    await _repo.logout();
    _ref.read(currentUserProvider.notifier).state = null;
    state = const AuthState(isLoading: false);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo, ref);
});
