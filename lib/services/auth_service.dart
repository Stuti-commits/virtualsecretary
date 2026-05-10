import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// ─── Role ─────────────────────────────────────────────────────────────────────

enum UserRole { resident, secretary, security }

extension UserRoleX on UserRole {
  String get value => name; // 'resident' | 'secretary' | 'security'

  static UserRole? fromString(String? s) {
    if (s == null || s.isEmpty) return null;
    return UserRole.values.cast<UserRole?>().firstWhere(
      (e) => e?.name == s,
      orElse: () => null,
    );
  }
}

// ─── AppUser ──────────────────────────────────────────────────────────────────

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final UserRole? role;       // null = not yet chosen
  final bool isApproved;
  final String? flatNumber;
  final String? apartmentId;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.isApproved,
    this.flatNumber,
    this.apartmentId,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) => AppUser(
    uid:         uid,
    email:       m['email']       ?? '',
    displayName: m['displayName'] ?? '',
    role:        UserRoleX.fromString(m['role'] as String?),
    isApproved:  m['isApproved']  ?? false,
    flatNumber:  m['flatNumber'],
    apartmentId: m['apartmentId'],
  );
}

// ─── AuthService ──────────────────────────────────────────────────────────────

class AuthService extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  AppUser? _user;
  AppUser? get currentAppUser => _user;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Fetch profile ──────────────────────────────────────────────────────────

  Future<AppUser?> fetchUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      _user = AppUser.fromMap(uid, doc.data()!);
      notifyListeners();
      return _user;
    } catch (e) {
      debugPrint('fetchUserProfile: $e');
      return null;
    }
  }

  // ── Sign up — role saved as '' so RoleSelectionScreen is shown ────────────

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    final uid = cred.user!.uid;
    await cred.user!.updateDisplayName(displayName);

    final data = {
      'email':       email,
      'displayName': displayName,
      'role':        '',          // ← empty: forces role selection
      'isApproved':  false,
      'flatNumber':  null,
      'apartmentId': null,
      'fcmToken':    null,
      'createdAt':   FieldValue.serverTimestamp(),
      'updatedAt':   FieldValue.serverTimestamp(),
    };
    await _db.collection('users').doc(uid).set(data);

    _user = AppUser(
      uid: uid, email: email, displayName: displayName,
      role: null, isApproved: false,
    );
    notifyListeners();
    return _user!;
  }

  // ── Sign in ────────────────────────────────────────────────────────────────

  Future<AppUser?> signIn({required String email, required String password}) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    return fetchUserProfile(cred.user!.uid);
  }

  // ── Save role (called from RoleSelectionScreen) ────────────────────────────

  Future<void> saveUserRole(String uid, UserRole role) async {
    await _db.collection('users').doc(uid).update({
      'role':      role.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (_user != null) {
      _user = AppUser(
        uid:         _user!.uid,
        email:       _user!.email,
        displayName: _user!.displayName,
        role:        role,
        isApproved:  _user!.isApproved,
        flatNumber:  _user!.flatNumber,
        apartmentId: _user!.apartmentId,
      );
      notifyListeners();
    }
  }

  // ── Update FCM token ───────────────────────────────────────────────────────

  Future<void> updateFcmToken(String uid, String token) async {
    await _db.collection('users').doc(uid).update({'fcmToken': token});
  }

  // ── Sign out ───────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email);
}
