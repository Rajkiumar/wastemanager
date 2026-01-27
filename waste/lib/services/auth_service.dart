import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_profile_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserProfileService _profileService = UserProfileService();

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      print("🔍 Starting Google Sign-In...");
      
      // 1. Trigger the Google sign-in UI
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("❌ Google Sign-In: User canceled");
        return null; // User canceled
      }
      
      print("✓ Google User: ${googleUser.email}");

      // 2. Get auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print("✓ Got auth tokens");

      // 3. Create a credential for Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase and return user
      print("🔄 Signing in to Firebase...");
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      print("✅ Firebase Sign-In successful: ${userCredential.user?.email}");
      
      // 5. Create user profile if this is first time
      if (userCredential.user != null && userCredential.additionalUserInfo?.isNewUser == true) {
        print("🆕 Creating profile for new Google user...");
        await _profileService.createUserProfile(
          userCredential.user!.uid,
          userCredential.user!.email ?? '',
          displayName: userCredential.user!.displayName ?? '',
        );
        print("✅ Profile created");
      }
      
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("❌ Firebase Auth Error: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      print("❌ Google Auth Error: $e");
      rethrow;
    }
  }

  // Sign out (Useful for testing)
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}