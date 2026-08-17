import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  authenticating,
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _currentUser;
  AuthStatus _status = AuthStatus.uninitialized;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<UserModel?>? _userSub;

  UserModel? get currentUser => _currentUser;
  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _currentUser != null;
  bool get isInitialLoading => _status == AuthStatus.uninitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void initAuthListener() {
    _authSub?.cancel();
    _authSub = _authService.authStateChanges.listen((User? firebaseUser) {
      _userSub?.cancel();
      if (firebaseUser == null) {
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      } else {
        _userSub = _firestoreService.streamUser(firebaseUser.uid).listen((user) {
          if (user != null) {
            _currentUser = user;
            _status = AuthStatus.authenticated;
          } else {
            // Profile document might be momentarily syncing
            _status = AuthStatus.authenticated;
          }
          notifyListeners();
        }, onError: (err) {
          _status = AuthStatus.authenticated;
          notifyListeners();
        });
      }
    });
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
    required String username,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      _currentUser = await _authService.registerWithEmailPassword(
        email: email,
        password: password,
        displayName: displayName,
        username: username,
      );
      _status = AuthStatus.authenticated;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(AuthService.getReadableErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      _currentUser = await _authService.loginWithEmailPassword(
        email: email,
        password: password,
      );
      _status = AuthStatus.authenticated;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(AuthService.getReadableErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(AuthService.getReadableErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _setError(AuthService.getReadableErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }
}
