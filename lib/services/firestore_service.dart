import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class FirestoreService {
  final CollectionReference users =
      FirebaseFirestore.instance.collection("users");

  /// Create User
  Future<void> createUser(UserModel user) async {
    await users.doc(user.uid).set(user.toMap());
  }

  /// Get User
  Future<UserModel?> getUser(String uid) async {
    final doc = await users.doc(uid).get();

    if (!doc.exists) return null;

    return UserModel.fromMap(
      doc.data() as Map<String, dynamic>,
    );
  }

  /// Update User
  Future<void> updateUser(UserModel user) async {
    await users.doc(user.uid).update(user.toMap());
  }

  /// Update User Name
  Future<void> updateName(
      String uid,
      String name,
      ) async {
    await users.doc(uid).update({
      "fullName": name,
    });
  }

  /// Update Profile Image
  Future<void> updateProfileImage(
      String uid,
      String image,
      ) async {
    await users.doc(uid).update({
      "profileImage": image,
    });
  }

  /// Update Trust Score
  Future<void> updateTrustScore(
      String uid,
      double score,
      ) async {
    await users.doc(uid).update({
      "trustScore": score,
    });
  }

  /// Update Verification
  Future<void> verifyUser(
      String uid,
      bool verified,
      ) async {
    await users.doc(uid).update({
      "verified": verified,
    });
  }

  /// Update Role
  Future<void> updateRole(
      String uid,
      String role,
      ) async {
    await users.doc(uid).update({
      "role": role,
    });
  }

  /// Update Last Login
  Future<void> updateLastLogin(
      String uid,
      ) async {
    await users.doc(uid).update({
      "lastLogin": Timestamp.now(),
    });
  }

  /// Delete User
  Future<void> deleteUser(
      String uid,
      ) async {
    await users.doc(uid).delete();
  }
}