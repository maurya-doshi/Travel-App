import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:travel_hackathon/core/services/api_service.dart';
import 'package:travel_hackathon/features/auth/domain/user_model.dart';
import 'package:travel_hackathon/features/auth/domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  final ApiService _apiService;

  FirebaseAuthRepository(this._apiService);

  @override
  Future<UserModel> register(String email, String password, String displayName) async {
    try {
      // 1. Create User in Firebase
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      // 2. Sync to Backend
      return await _syncUserToBackend(credential.user!, displayName);
    } catch (e) {
      throw Exception('Firebase Registration Failed: $e');
    }
  }

  @override
  Future<UserModel> login(String email, String password) async {
    try {
       final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      return await _syncUserToBackend(credential.user!, credential.user!.displayName ?? 'User');
    } catch (e) {
      throw Exception('Login Failed: $e');
    }
  }

  @override
  Future<UserModel?> getUser(String uid) async {
    // Basic check, usually we'd fetch from backend or firebase
    final user = _firebaseAuth.currentUser;
    if (user != null && user.uid == uid) {
       return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'User',
        explorerPoints: 0 // TODO: Fetch from backend
       );
    }
    return null;
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google Sign In Aborted');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final  userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      return await _syncUserToBackend(userCredential.user!, userCredential.user!.displayName ?? 'Google User');

    } catch (e) {
       throw Exception('Google Sign In Failed: $e');
    }
  }

  Future<UserModel> _syncUserToBackend(User firebaseUser, String displayName) async {
    try {
      // Send Firebase UID to our Node Backend to create/sync the user record
      final response = await _apiService.post('/users', {
        'uid': firebaseUser.uid,
        'email': firebaseUser.email,
        'displayName': displayName,
        'explorerPoints': 0
      });

      return UserModel(
        uid: response['uid'],
        email: response['email'],
        displayName: response['displayName'],
        explorerPoints: response['explorerPoints'] ?? 0,
      );
    } catch (e) {
      // Passively fail sync if backend is down, but user is authed? 
      // Better to throw so UI knows.
      throw Exception('Backend Sync Failed: $e');
    }
  }
}
