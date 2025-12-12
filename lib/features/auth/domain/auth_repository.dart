import 'package:travel_hackathon/features/auth/domain/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login(String email, String password); // Mock password
  Future<UserModel> register(String email, String password, String displayName);
  Future<UserModel?> getUser(String uid);
}
