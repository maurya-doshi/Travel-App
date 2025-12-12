import 'package:travel_hackathon/core/services/api_service.dart';
import 'package:travel_hackathon/features/auth/domain/auth_repository.dart';
import 'package:travel_hackathon/features/auth/domain/user_model.dart';
import 'package:uuid/uuid.dart';

class ApiAuthRepository implements AuthRepository {
  final ApiService _apiService;
  final Uuid _uuid = const Uuid();

  ApiAuthRepository(this._apiService);

  @override
  Future<UserModel> login(String email, String password) async {
    final uid = _uuid.v5(Uuid.NAMESPACE_URL, email);
    return register(email, password, email.split('@')[0]);
  }

  @override
  Future<UserModel> register(String email, String password, String displayName) async {
    final uid = _uuid.v5(Uuid.NAMESPACE_URL, email);
    final response = await _apiService.post('/users', {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'explorerPoints': 0
    });
    
    return UserModel(
      uid: response['uid'],
      email: response['email'],
      displayName: response['displayName'],
      explorerPoints: response['explorerPoints'] ?? 0,
    );
  }

  @override
  Future<UserModel?> getUser(String uid) async {
    try {
      final response = await _apiService.get('/users/$uid');
      return UserModel(
        uid: response['uid'],
        email: response['email'],
        displayName: response['displayName'],
        explorerPoints: response['explorerPoints'] ?? 0,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
     await Future.delayed(const Duration(seconds: 1));
     return UserModel(
        uid: 'demo_google_user', 
        email: 'demo@google.com', 
        displayName: 'Demo Google User',
        explorerPoints: 500
     );
  }

  // --- OTP AUTHENTICATION ---

  @override
  Future<OtpResponse> sendOtp(String email) async {
    final response = await _apiService.post('/auth/send-otp', {'email': email});
    return OtpResponse(
      success: response['success'] ?? false,
      message: response['message'] ?? 'OTP sent',
      otp: response['otp'], // For hackathon demo
    );
  }

  @override
  Future<SessionResponse> verifyOtp(String email, String otp, {String? displayName}) async {
    final response = await _apiService.post('/auth/verify-otp', {
      'email': email,
      'otp': otp,
      'displayName': displayName,
    });

    final userMap = response['user'];
    final sessionMap = response['session'];

    return SessionResponse(
      sessionId: sessionMap['sessionId'],
      expiresAt: sessionMap['expiresAt'],
      user: UserModel(
        uid: userMap['uid'],
        email: userMap['email'],
        displayName: userMap['displayName'],
        explorerPoints: userMap['explorerPoints'] ?? 0,
      ),
    );
  }

  @override
  Future<bool> validateSession(String sessionId) async {
    try {
      final response = await _apiService.get('/auth/session/$sessionId');
      return response['valid'] == true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> logout(String sessionId) async {
    await _apiService.post('/auth/logout', {'sessionId': sessionId});
  }
}

