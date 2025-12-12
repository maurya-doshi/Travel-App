import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_hackathon/core/services/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});
