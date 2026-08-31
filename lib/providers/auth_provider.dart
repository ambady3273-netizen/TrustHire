import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/firebase_error_handler.dart';

// ============================================================
// SERVICE PROVIDERS
// ============================================================

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService.instance;
});

// ============================================================
// USER MODEL PROVIDER
// Watches the Firebase auth state; when a user is signed in it
// fetches (and re-fetches on change) their Firestore document.
// Yields AsyncValue<UserModel?> — null means "not signed in".
// ============================================================

final userProvider = StreamProvider<UserModel?>((ref) async* {
  final authService = ref.watch(authServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  // Re-emit every time the Firebase auth state changes.
  await for (final firebaseUser in authService.authStateChanges) {
    if (firebaseUser == null) {
      yield null;
    } else {
      // Attempt to load the Firestore document.
      try {
        final userModel = await firestoreService.getUser(firebaseUser.uid);
        yield userModel; // may be null if doc doesn't exist yet
      } catch (_) {
        yield null;
      }
    }
  }
});

// ============================================================
// AUTH NOTIFIER
// Manages login / register / logout / forgot-password actions.
// ============================================================

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier(this.ref) : super(const AsyncValue.loading()) {
    _listenToAuthState();
  }

  final Ref ref;

  late final AuthService _authService = ref.read(authServiceProvider);
  late final FirestoreService _firestoreService =
      ref.read(firestoreServiceProvider);

  late final StreamSubscription<User?> _authSubscription;

  void _listenToAuthState() {
    _authSubscription = _authService.authStateChanges.listen((user) {
      state = AsyncValue.data(user);
    });
  }

  /// Login — returns an error string on failure, null on success.
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _authService.login(
        email: email,
        password: password,
      );

      final uid = _authService.currentUser!.uid;
      await _firestoreService.updateLastLogin(uid);

      return null;
    } on FirebaseAuthException catch (e) {
      return FirebaseErrorHandler.getMessage(e.code);
    } catch (e) {
      return e.toString();
    }
  }

  /// Register — creates Firebase Auth account + Firestore document.
  /// Returns an error string on failure, null on success.
  Future<String?> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final credential = await _authService.register(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      final user = UserModel(
        uid: uid,
        fullName: fullName,
        email: email,
        role: role,
        verified: false,
        trustScore: 0,
        profileImage: '',
        createdAt: Timestamp.now(),
        lastLogin: Timestamp.now(),
      );

      await _firestoreService.createUser(user);

      await _authService.sendVerificationEmail();

      return null;
    } on FirebaseAuthException catch (e) {
      return FirebaseErrorHandler.getMessage(e.code);
    } catch (e) {
      return e.toString();
    }
  }

  /// Logout.
  Future<void> logout() async {
    await _authService.logout();
  }

  /// Forgot Password — sends a reset email.
  /// Returns an error string on failure, null on success.
  Future<String?> forgotPassword(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
      return null;
    } on FirebaseAuthException catch (e) {
      return FirebaseErrorHandler.getMessage(e.code);
    } catch (e) {
      return e.toString();
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}

// ============================================================
// GLOBAL AUTH PROVIDER
// ============================================================

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref);
});
