import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app/constants.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

abstract class IAuthService {
  Stream<User?> get authStateChanges;
  User? get currentUser;
  String? get currentUserId;

  Future<UserModel> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
    required String username,
  });

  Future<UserModel> loginWithEmailPassword({
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
}

class AuthService implements IAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Future<UserModel> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
    required String username,
  }) async {
    final cleanUsername = username.trim().toLowerCase();
    final cleanEmail = email.trim().toLowerCase();
    final cleanDisplayName = displayName.trim();

    // 1. Check unique username at Firestore /users collection
    final usernameQuery = await _firestore
        .collection(AppConstants.usersCollection)
        .where('username', '==', cleanUsername)
        .limit(1)
        .get();

    if (usernameQuery.docs.isNotEmpty) {
      throw FirebaseAuthException(
        code: 'username-already-in-use',
        message: 'The username @$cleanUsername is already taken by another fan.',
      );
    }

    // 2. Create User with Firebase Auth
    final UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final User? firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'Failed to create user account with Firebase Authentication.',
      );
    }

    // 3. Update Firebase Auth Profile Display Name
    await firebaseUser.updateDisplayName(cleanDisplayName);

    // 4. Retrieve FCM Token for instant push notifications
    final fcmToken = await NotificationService().getDeviceToken();

    final now = DateTime.now();
    final userModel = UserModel(
      uid: firebaseUser.uid,
      email: cleanEmail,
      displayName: cleanDisplayName,
      username: cleanUsername,
      photoUrl: null,
      bio: '',
      followersCount: 0,
      followingCount: 0,
      friendsCount: 0,
      isOnline: true,
      lastSeen: now,
      fcmToken: fcmToken,
      createdAt: now,
      updatedAt: now,
    );

    // 5. Save user profile document to /users/{uid}
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(firebaseUser.uid)
        .set(userModel.toMap());

    return userModel;
  }

  @override
  Future<UserModel> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    final UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final User? firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'User authentication failed.',
      );
    }

    // Update presence & FCM token on login
    final fcmToken = await NotificationService().getDeviceToken();
    final userDocRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(firebaseUser.uid);

    await userDocRef.update({
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
      if (fcmToken != null) 'fcmToken': fcmToken,
    });

    final snapshot = await userDocRef.get();
    if (!snapshot.exists || snapshot.data() == null) {
      throw FirebaseAuthException(
        code: 'profile-not-found',
        message: 'User profile document was not found in Firestore.',
      );
    }

    return UserModel.fromMap(snapshot.data()!, firebaseUser.uid);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    await _auth.sendPasswordResetEmail(email: cleanEmail);
  }

  @override
  Future<void> signOut() async {
    final uid = currentUserId;
    if (uid != null) {
      try {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .update({
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
          'fcmToken': FieldValue.delete(),
        });
      } catch (_) {
        // Suppress network errors during logout presence update
      }
    }
    await _auth.signOut();
  }

  /// Converts technical Firebase Auth exception codes to clean user-friendly messages
  static String getReadableErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found with this email address.';
        case 'wrong-password':
          return 'Incorrect password. Please verify and try again.';
        case 'invalid-credential':
          return 'Invalid email or password. Please check your credentials.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'email-already-in-use':
          return 'An account already exists with this email address.';
        case 'username-already-in-use':
          return error.message ?? 'This username is already taken.';
        case 'weak-password':
          return 'Password must be at least 6 characters with good complexity.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'too-many-requests':
          return 'Too many unsuccessful attempts. Please wait a few moments and try again.';
        case 'network-request-failed':
          return 'Network connection error. Please check your internet connection.';
        default:
          return error.message ?? 'An authentication error occurred. Please try again.';
      }
    }
    return error?.toString() ?? 'An unexpected error occurred. Please try again.';
  }
}
