import 'package:travel_hackathon/core/services/api_service.dart';
import 'package:travel_hackathon/features/auth/domain/auth_repository.dart';
import 'package:travel_hackathon/features/auth/domain/user_model.dart';
import 'package:uuid/uuid.dart';

class ApiAuthRepository implements AuthRepository {
  final ApiService _apiService;
  final Uuid _uuid = const Uuid();

  ApiAuthRepository(this._apiService);



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
     // Mock Google Sign In
     await Future.delayed(const Duration(seconds: 1));
     return UserModel(
        uid: 'demo_google_user', 
        email: 'demo@google.com', 
        displayName: 'Demo Google User',
        explorerPoints: 500
     );
  }
  @override
  Future<OtpResponse> sendOtp(String email, {bool isLogin = false}) async {
    // Adapter: Call local backend endpoint (simple)
    try {
      final response = await _apiService.post('/auth/otp/request', {
        'email': email,
        'isLogin': isLogin,
      });
      return OtpResponse(
        success: true, 
        message: response['message'] ?? 'OTP Sent',
      );
    } catch (e) {
      // Extract error message from API exception if possible
      final msg = e.toString().replaceAll('Exception:', '').trim();
      return OtpResponse(success: false, message: msg);
    }
  }

  @override
  Future<SessionResponse> login(String email, String password) async {
    try {
      final response = await _apiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      return SessionResponse(
        sessionId: response['session']['sessionId'],
        expiresAt: response['session']['expiresAt'],
        user: UserModel(
          uid: response['user']['uid'],
          email: response['user']['email'],
          displayName: response['user']['displayName'],
          explorerPoints: response['user']['explorerPoints'] ?? 0,
        ),
      );
    } catch (e) {
      // Reassign or rethrow with cleaner message
       throw Exception(e.toString().replaceAll('Exception:', '').trim());
    }
  }

  @override
  Future<SessionResponse> verifyOtp(String email, String code, {String? displayName, String? password}) async {
    // Adapter: Call local backend endpoint
    final response = await _apiService.post('/auth/otp/verify', {
      'email': email,
      'code': code,
      'displayName': displayName,
      'password': password, // Pass password if from signup
    });

    return SessionResponse(
      sessionId: response['token'], // Map token to sessionId
      expiresAt: DateTime.now().add(const Duration(days: 7)).toIso8601String(), 
      user: UserModel(
        uid: response['uid'],
        email: response['email'],
        displayName: response['displayName'],
        explorerPoints: response['explorerPoints'] ?? 0,
      ),
    );
  }

  @override
  Future<bool> validateSession(String sessionId) async {
    return true; 
  }

  @override
  Future<void> logout(String sessionId) async {
    // No-op for local simple auth
  }
}
