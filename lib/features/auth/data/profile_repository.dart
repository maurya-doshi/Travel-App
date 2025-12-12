import 'package:travel_hackathon/core/services/api_service.dart';
import 'package:travel_hackathon/features/auth/domain/user_model.dart';

abstract class ProfileRepository {
  Future<UserModel> getUserProfile(String uid);
  Future<UserModel> updateProfile(UserModel user, String? password);
}

class ApiProfileRepository implements ProfileRepository {
  final ApiService _apiService;

  ApiProfileRepository(this._apiService);

  @override
  Future<UserModel> getUserProfile(String uid) async {
    final response = await _apiService.get('/users/$uid');
    return UserModel.fromJson(response);
  }

  @override
  Future<UserModel> updateProfile(UserModel user, String? password) async {
    final body = user.toMap();
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }
    
    final response = await _apiService.put('/users/${user.uid}', body);
    return UserModel.fromJson(response);
  }
}
