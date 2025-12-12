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
    // Backend doesn't have login, only /users/:uid or create /users.
    // For hackathon, we simulate login by fetching user by email? 
    // Backend: GET /users/:uid
    // We don't have endpoints to search by email!
    // We can fetch user if we know UID. 
    // Real auth is hard.
    // Proposal: "Login" just creates a new session or we reuse a hardcoded user or try to find logic.
    // Let's implement a "fake" login that registers if not exists or just uses a consistent ID for email?
    // Or just use the 'register' flow which is upsert in backend.
    
    // Simplification: Login = Register (Upsert)
    // We generate a deterministic UID from email? No, UUID.
    // Let's assume the user enters UID or we just create a new one.
    // Hackathon shortcut: Login creates/gets user.
    
    // Proper way: We need endpoint to find user by email.
    // I'll skip implementing 'find by email' in backend for now unless really needed.
    // I will treat login as "register/login" with upsert.
    
    final uid = _uuid.v5(Uuid.NAMESPACE_URL, email); // Deterministic UID based on email!
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
}
