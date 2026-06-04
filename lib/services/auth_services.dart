import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static User? get user => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<User?> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return cred.user;
  }

  static Future<User?> register(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return cred.user;
  }

  static Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await _auth.signInWithCredential(
      credential,
    );
    return userCredential.user;
  }

  static Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  static bool get isSignedIn => _auth.currentUser != null;

  static Future<void> reauthenticate(String email, String password) async {
    final user = _auth.currentUser;
    if (user != null) {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    }
  }

  static Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }
}
