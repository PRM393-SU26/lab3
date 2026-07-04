import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/analytics_service.dart';

enum AuthState { initial, authenticated, unauthenticated, error }

class AuthViewModel extends ChangeNotifier {
  AuthState _state = AuthState.initial;
  AuthState get state => _state;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  AuthViewModel() {
    checkAuthState();
  }

  void checkAuthState() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _isLoading = false;
      if (user != null) {
        _state = AuthState.authenticated;
      } else {
        _state = AuthState.unauthenticated;
      }
      notifyListeners();
    });
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.setCustomParameters({
          'prompt': 'select_account'
        });
        final userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
        if (userCredential.user != null) {
          await AnalyticsService.logLogin();
          _isLoading = false;
          notifyListeners();
          return true;
        }
      } else {
        final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
        if (googleUser == null) {
          _isLoading = false;
          notifyListeners();
          return false; // User canceled
        }
        
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        if (userCredential.user != null) {
          await AnalyticsService.logLogin();
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Sign-In failed: $e\n(You can use Mock Login if on an emulator)';
      _isLoading = false;
      notifyListeners();
      return false;
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signInMock() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName("Developer Account");
        await userCredential.user!.updatePhotoURL("https://images.unsplash.com/photo-1535713875002-d1d0cf377fde");
        await AnalyticsService.logLogin();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Firebase Anonymous Sign-In failed, falling back to local Developer mode: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }
}
