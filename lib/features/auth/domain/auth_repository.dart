import 'package:travel_hackathon/features/auth/domain/user_model.dart';

/// OTP Response containing the generated OTP (for hackathon demo)
class OtpResponse {
  final bool success;
  final String message;
  final String? otp; // Only returned in dev/ethereal mode

  OtpResponse({required this.success, required this.message, this.otp});
}

/// Session response after successful OTP verification
class SessionResponse {
  final String sessionId;
  final String expiresAt;
  final UserModel user;

  SessionResponse({required this.sessionId, required this.expiresAt, required this.user});
}

abstract class AuthRepository {
  Future<SessionResponse> login(String email, String password);
  Future<UserModel> register(String email, String password, String displayName);
  Future<UserModel?> getUser(String uid);
  Future<UserModel> signInWithGoogle();
  
  // Real OTP Flow
  Future<OtpResponse> sendOtp(String email, {bool isLogin = false});
  Future<SessionResponse> verifyOtp(String email, String code, {String? displayName, String? password});
  Future<void> logout(String sessionId);
}
