import 'package:travel_hackathon/features/auth/domain/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login(String email, String password); // Legacy
  Future<UserModel> register(String email, String password, String displayName); // Legacy
  Future<UserModel?> getUser(String uid);
  Future<UserModel> signInWithGoogle();
  
  // Real OTP Flow
  Future<void> requestOtp(String email);
  Future<UserModel> verifyOtp(String email, String code);
}
