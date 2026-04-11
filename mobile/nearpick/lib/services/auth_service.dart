import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirebaseAuth get auth => _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    required String role, // 'consumer' vagy 'merchant'
    required String companyName,
  }) async {
    final trimmedDisplayName = displayName.trim();
    final trimmedCompanyName = companyName.trim();
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final data = <String, dynamic>{
      'email': email,
      'displayName': trimmedDisplayName,
      'role': role,
      'accountStatus': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (trimmedCompanyName.isNotEmpty) {
      data['companyName'] = trimmedCompanyName;
    }

    await credential.user!.updateDisplayName(trimmedDisplayName);
    await _db.collection('users').doc(credential.user!.uid).set(data);
  }

  Future<void> updateCurrentUserProfile({
    String? displayName,
    String? companyName,
    GeoPoint? companyLocation,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Nincs bejelentkezett felhasznalo.');
    }

    final updates = <String, dynamic>{};
    String? trimmedDisplayName;

    if (displayName != null) {
      trimmedDisplayName = displayName.trim();
      if (trimmedDisplayName.isEmpty) {
        throw Exception('A felhasznalonev nem lehet ures.');
      }
      updates['displayName'] = trimmedDisplayName;
    }

    if (companyName != null) {
      final trimmedCompanyName = companyName.trim();
      if (trimmedCompanyName.isEmpty) {
        throw Exception('A ceg neve nem lehet ures.');
      }
      updates['companyName'] = trimmedCompanyName;
    }

    if (companyLocation != null) {
      updates['companyLocation'] = companyLocation;
    }

    if (updates.isEmpty) {
      return;
    }

    await _db
        .collection('users')
        .doc(user.uid)
        .set(updates, SetOptions(merge: true));

    if (trimmedDisplayName != null) {
      await user.updateDisplayName(trimmedDisplayName);
    }
  }

  Future<void> login({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
