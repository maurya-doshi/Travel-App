import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_hackathon/core/services/api_service_provider.dart';
import 'package:travel_hackathon/features/auth/data/api_auth_repository.dart';
import 'package:travel_hackathon/features/auth/domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ApiAuthRepository(apiService);
});

final currentUserProvider = StateProvider<String?>((ref) => null); // Store UID
