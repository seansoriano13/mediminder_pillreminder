import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }

  User? get currentUser {
    return _auth.currentUser;
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    final UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential;
  }

  Future<UserCredential> signUpWithEmail(String email, String password) async {
    final UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential;
  }

  /// On web: uses Firebase's signInWithPopup which handles OAuth natively.
  /// On native: would use google_sign_in, but since we're targeting web only
  /// for now we fall back to popup as well.
  Future<UserCredential?> signInWithGoogle() async {
    final GoogleAuthProvider googleProvider = GoogleAuthProvider();
    final UserCredential credential = await _auth.signInWithPopup(googleProvider);
    return credential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
