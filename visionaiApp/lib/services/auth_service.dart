import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Web client ID from your google-services.json
    clientId: '335489594965-hn51vjgtial9u3d3sf1c1q4o1ii9ub6i.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Simulate a logged-in user
  static Map<String, dynamic>? _currentUser;

  // Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  // Get current user - fixed to avoid naming conflicts
  Map<String, dynamic>? get dummyUser => _currentUser;

  // Email/Password Sign In
  Future<UserCredential?> signInWithEmailPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    print('Starting Google Sign In process...');
    
    try {
      // Create a new instance of GoogleSignIn each time to avoid caching
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: '335489594965-hn51vjgtial9u3d3sf1c1q4o1ii9ub6i.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );
      
      // Force sign out from Google
      await googleSignIn.disconnect();
      await googleSignIn.signOut();
      
      // Force sign out from Firebase Auth as well
      try {
        await _auth.signOut();
      } catch (e) {
        print('Firebase sign out error (ignored): $e');
      }
      
      // Sign in with explicit selection (should force the account picker)
      print('Showing account picker dialog...');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        print('Sign in cancelled by user');
        return null;
      }

      print('Getting authentication tokens for: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      print('Creating Firebase credential');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      try {
        print('Signing in to Firebase with credential');
        final userCredential = await _auth.signInWithCredential(credential);
        
        // Save user data if first sign in
        try {
          if (userCredential.additionalUserInfo?.isNewUser == true) {
            print('New user, saving additional data');
            await FirebaseDatabase.instance
                .ref()
                .child('users/${userCredential.user!.uid}')
                .set({
              'fullName': userCredential.user!.displayName ?? 'User',
              'email': userCredential.user!.email,
              'type': 'User',
              'createdAt': DateTime.now().toIso8601String(),
              'verified': userCredential.user!.emailVerified,
              'online': true,
              'last_seen': ServerValue.timestamp,
              'photo_url': userCredential.user!.photoURL,
            });
            print('User data saved successfully');
          }
        } catch (dbError) {
          // Handle database error but don't fail the sign-in
          print('Error saving user data: $dbError');
        }
        
        return userCredential;
      } catch (credentialError) {
        print('Error in Firebase sign-in phase: $credentialError');
        
        // If there was an error with the credential but we have a currentUser,
        // the sign-in actually succeeded but there was an error constructing the UserCredential
        if (_auth.currentUser != null) {
          print('User is actually signed in! Handling successful sign-in');
          
          // Instead, just save the user data to database if needed
          final currentUser = _auth.currentUser!;
          try {
            // Check if user data exists
            final snapshot = await FirebaseDatabase.instance
                .ref()
                .child('users/${currentUser.uid}')
                .get();
                
            if (!snapshot.exists) {
              // Save user data
              await FirebaseDatabase.instance
                  .ref()
                  .child('users/${currentUser.uid}')
                  .set({
                'fullName': currentUser.displayName ?? 'User',
                'email': currentUser.email,
                'type': 'User',
                'createdAt': DateTime.now().toIso8601String(),
                'verified': currentUser.emailVerified,
                'online': true,
                'last_seen': ServerValue.timestamp,
                'photo_url': currentUser.photoURL,
              });
            }
          } catch (e) {
            print('Error saving user data: $e');
          }
          
          // Return null but the sign-in is successful
          print('Returning with successful sign-in');
          return null;
        }
        rethrow;
      }
    } catch (e) {
      print('Unexpected error during Google Sign In: $e');
      
      // Handle the specific PigeonUserDetails error
      if (e.toString().contains('PigeonUserDetails')) {
        // Check if the user is actually signed in
        if (_auth.currentUser != null) {
          print('User is signed in despite Pigeon error: ${_auth.currentUser!.uid}');
          
          // The user is already signed in, save data if needed
          final currentUser = _auth.currentUser!;
          try {
            // Check if user data exists
            final snapshot = await FirebaseDatabase.instance
                .ref()
                .child('users/${currentUser.uid}')
                .get();
                
            if (!snapshot.exists) {
              // Save user data
              await FirebaseDatabase.instance
                  .ref()
                  .child('users/${currentUser.uid}')
                  .set({
                'fullName': currentUser.displayName ?? 'User',
                'email': currentUser.email,
                'type': 'User',
                'createdAt': DateTime.now().toIso8601String(),
                'verified': currentUser.emailVerified,
                'online': true,
                'last_seen': ServerValue.timestamp,
                'photo_url': currentUser.photoURL,
              });
            }
          } catch (e) {
            print('Error saving user data: $e');
          }
          
          // Return null but the sign-in is successful
          return null;
        }
      }
      
      throw 'An error occurred during Google sign in: $e';
    }
  }

  // Helper method to get credentials for an already signed-in user
  Future<UserCredential?> _getExistingUserCredential() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;
    
    // Create minimal user data in database if not already there
    try {
      final userRef = FirebaseDatabase.instance.ref().child('users/${currentUser.uid}');
      final snapshot = await userRef.get();
      
      if (!snapshot.exists) {
        await userRef.set({
          'fullName': currentUser.displayName ?? 'User',
          'email': currentUser.email,
          'type': 'User',
          'createdAt': DateTime.now().toIso8601String(),
          'verified': currentUser.emailVerified,
          'online': true,
          'last_seen': ServerValue.timestamp,
          'photo_url': currentUser.photoURL,
        });
      }
    } catch (e) {
      print('Error checking/creating user data: $e');
    }
    
    print('Returning already signed in user: ${currentUser.uid}');
    
    // Simply return null since we've confirmed the user is signed in
    return null;
  }

  // Email/Password Sign Up
  Future<UserCredential?> signUpWithEmailPassword(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
  }

  // Error Handler
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'The email address is already in use by another account.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'user-disabled':
        return 'This user has been disabled.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }

  // Add this method above the Google Sign In method
  Future<void> checkGoogleSignInSetup() async {
    print('Checking Google Sign In setup...');
    try {
      // Test if we can get the available Google sign-in accounts without actually signing in
      final isAvailable = await GoogleSignIn().isSignedIn();
      print('GoogleSignIn.isSignedIn() check: $isAvailable');
      
      // Get installed app package name for debugging
      print('Checking for Web Client ID configuration...');
      final GoogleSignIn testSignIn = GoogleSignIn();
      print('GoogleSignIn instance created successfully');
      
      print('Google Sign In setup check completed');
    } catch (e) {
      print('Error during GoogleSignIn setup check: $e');
    }
  }

  // Sign in with email and password (always succeeds)
  Future<Map<String, dynamic>> signInWithEmailAndPassword(
      String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Create a dummy user
    _currentUser = {
      'uid': 'dummy-user-id',
      'email': email,
      'displayName': email.split('@')[0],
      'photoURL': null,
    };
    
    return _currentUser!;
  }

  // Sign in with Google (always succeeds)
  Future<Map<String, dynamic>> dummySignInWithGoogle() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Create a dummy Google user
    _currentUser = {
      'uid': 'google-dummy-id',
      'email': 'demo@gmail.com',
      'displayName': 'Google User',
      'photoURL': null,
    };
    
    return _currentUser!;
  }
} 