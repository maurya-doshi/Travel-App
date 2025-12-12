import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_hackathon/features/safety/data/http_safety_repository.dart';

final safetyRepositoryProvider = Provider<HttpSafetyRepository>((ref) {
  return HttpSafetyRepository();
});
