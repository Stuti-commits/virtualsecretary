import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Supported user roles in the app.
enum UserRole { resident, secretary, security }

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.resident:
        return 'resident';
      case UserRole.secretary:
        return 'secretary';
      case UserRole.security:
        return 'security';
    }
  }

  static UserRole? fromString(String role) {
    switch (role) {
      case 'resident': return UserRole.resident;
      case 'secretary': return UserRole.secretary;
      case 'security': return UserRole.security;
      default: return null; // empty string hits here → triggers RoleSelectionScreen
    }
  }
}

/// Lightweight model returned after auth operations.
class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final UserRole? role;
  final bool isApproved;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.isApproved,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String? ?? '',
      role: UserRoleExtension.fromString(map['role'] as String? ?? ''),
      isApproved: map['isApproved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'role': role?.value,
        'isApproved': isApproved,
      };
}

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AppUser? _currentAppUser;
  AppUser? get currentAppUser => _currentAppUser;

  // ── Auth state stream ──────────────────────────────────────────────────────

  /// Emits the Firebase [User] on every auth change.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Fetch Firestore profile ────────────────────────────────────────────────

  /// Loads the /users/{uid} doc and caches it in [_currentAppUser].
  Future<AppUser?> fetchUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      _currentAppUser = AppUser.fromMap(doc.data()!);
      notifyListeners();
      return _currentAppUser;
    } catch (e) {
      debugPrint('AuthService.fetchUserProfile error: $e');
      return null;
    }
  }

  // ── Sign Up ────────────────────────────────────────────────────────────────

  /// Creates a Firebase Auth account and writes the initial Firestore profile.
  /// Role defaults to [UserRole.resident]; call [saveUserRole] after
  /// role-selection to update it.
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
    String phoneNumber = '',
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user!;
    await user.updateDisplayName(displayName);

    final now = FieldValue.serverTimestamp();
    final data = {
      'uid': user.uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoUrl': null,
      'role': '', // default; updated after role selection
      'apartmentId': null,
      'flatNumber': null,
      'isApproved': false,
      'fcmToken': null,
      'createdAt': now,
      'updatedAt': now,
    };

    await _db.collection('users').doc(user.uid).set(data);

    _currentAppUser = AppUser(
      uid: user.uid,
      email: email,
      displayName: displayName,
      role: null,
      isApproved: false,
    );
    notifyListeners();
    return _currentAppUser!;
  }

  // ── Sign In ────────────────────────────────────────────────────────────────

  Future<AppUser?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return fetchUserProfile(credential.user!.uid);
  }

  // ── Save / Update Role ─────────────────────────────────────────────────────

  /// Persists the chosen role to Firestore and refreshes [_currentAppUser].
  Future<void> saveUserRole(String uid, UserRole role) async {
    await _db.collection('users').doc(uid).update({
      'role': role.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (_currentAppUser != null) {
      _currentAppUser = AppUser(
        uid: _currentAppUser!.uid,
        email: _currentAppUser!.email,
        displayName: _currentAppUser!.displayName,
        role: role,
        isApproved: _currentAppUser!.isApproved,
      );
      notifyListeners();
    }
  }

  // ── Update FCM Token ───────────────────────────────────────────────────────

  Future<void> updateFcmToken(String uid, String token) async {
    await _db.collection('users').doc(uid).update({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _auth.signOut();
    _currentAppUser = null;
    notifyListeners();
  }

  // ── Password Reset ─────────────────────────────────────────────────────────

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
