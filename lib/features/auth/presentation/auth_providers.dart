import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_hackathon/core/services/api_service_provider.dart';
import 'package:travel_hackathon/features/auth/data/api_auth_repository.dart';
import 'package:travel_hackathon/features/auth/data/firebase_auth_repository.dart';
import 'package:travel_hackathon/features/auth/domain/auth_repository.dart';

import 'package:travel_hackathon/features/auth/data/profile_repository.dart';
import 'package:travel_hackathon/features/auth/domain/user_model.dart';
import 'dart:async';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  // Reverting to Mock/Api Repo for disabled Firebase
  return ApiAuthRepository(apiService);
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ApiProfileRepository(apiService);
});

final currentUserProvider = StateProvider<String?>((ref) => null); // Store UID
final sessionIdProvider = StateProvider<String?>((ref) => null); // Store Session ID

// Fetch user profile data
final userProfileProvider = FutureProvider<UserModel?>((ref) async {
  final uid = ref.watch(currentUserProvider);
  if (uid == null) return null;
  
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getUserProfile(uid);
});

// Update Profile Logic
class ProfileController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  ProfileController(this.ref) : super(const AsyncValue.data(null));

  Future<bool> updateProfile(UserModel updatedUser, {String? password}) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(profileRepositoryProvider).updateProfile(updatedUser, password);
      // Refresh the profile provider to update UI
      ref.invalidate(userProfileProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final profileControllerProvider = StateNotifierProvider<ProfileController, AsyncValue<void>>((ref) {
  return ProfileController(ref);
});

