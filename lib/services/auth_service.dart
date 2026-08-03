import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Current Logged In User
  User? get currentUser => _auth.currentUser;

  /// Authentication State
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register New User
  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  /// Login
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  /// Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Forgot Password
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  /// Email Verification
  Future<void> sendVerificationEmail() async {
    if (_auth.currentUser != null &&
        !_auth.currentUser!.emailVerified) {
      await _auth.currentUser!.sendEmailVerification();
    }
  }

  /// Reload Current User
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  /// Check Email Verification
  bool get isEmailVerified {
    return _auth.currentUser?.emailVerified ?? false;
  }

  /// Delete Account
  Future<void> deleteAccount() async {
    await _auth.currentUser?.delete();
  }
}