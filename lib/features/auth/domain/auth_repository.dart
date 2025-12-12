import 'package:travel_hackathon/features/auth/domain/user_model.dart';

/// OTP Response containing the generated OTP (for hackathon demo)
class OtpResponse {
  final bool success;
  final String message;
  final String? otp; // Only returned in dev mode

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
  Future<UserModel> login(String email, String password); // Mock password
  Future<UserModel> register(String email, String password, String displayName);
  Future<UserModel?> getUser(String uid);
  Future<UserModel> signInWithGoogle();
  
  // OTP Authentication
  Future<OtpResponse> sendOtp(String email);
  Future<SessionResponse> verifyOtp(String email, String otp, {String? displayName});
  Future<bool> validateSession(String sessionId);
  Future<void> logout(String sessionId);
}
