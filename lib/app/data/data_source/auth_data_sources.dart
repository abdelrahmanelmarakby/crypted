import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_exceptions.dart';

class AuthenticationService {
  static final auth = FirebaseAuth.instance;
  static late AuthStatus _status;
  static late RegisterModel _registerModel;
  Future<bool> isEmailInUse(String email) async {
    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection(FirebaseCollections.users)
        .where('email', isEqualTo: email)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  Future<bool> isPhoneInUse(String phoneNumber) async {
    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection(FirebaseCollections.users)
        .where('phoneNumber', isEqualTo: phoneNumber)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  Future<RegisterModel> login({
    required String email,
    required String password,
  }) async {
    try {
      var res = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _status = AuthStatus.successful;
      _registerModel = RegisterModel(
        authStatus: AuthStatus.successful,
        user: res.user,
      );
    } on FirebaseAuthException catch (e) {
      log(e.code);
      _status = AuthExceptionHandler.handleAuthException(e);
      _registerModel = RegisterModel(
        authStatus: AuthExceptionHandler.handleAuthException(e),
      );
    }
    return _registerModel;
  }

  Future<RegisterModel> createAccount({
    required String email,
    required String password,
    String? name,
  }) async {
    bool isEmailUsed = await isEmailInUse(email);
    if (!isEmailUsed) {
      try {
        UserCredential newUser = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        auth.currentUser!.updateDisplayName(name);
        newUser.user!.sendEmailVerification();
        _status = AuthStatus.successful;
        _registerModel = RegisterModel(
          authStatus: AuthStatus.successful,
          user: newUser.user,
        );
      } on FirebaseAuthException catch (e) {
        _status = AuthExceptionHandler.handleAuthException(e);
        _registerModel = RegisterModel(
          authStatus: AuthExceptionHandler.handleAuthException(e),
        );
      }
    } else {
      _status = AuthExceptionHandler.handleAuthException(
        FirebaseAuthException(code: "email-already-in-use"),
      );
      _registerModel = RegisterModel(
        authStatus: AuthExceptionHandler.handleAuthException(
          FirebaseAuthException(code: "email-already-in-use"),
        ),
      );
    }
    return _registerModel;
  }

  Future<AuthStatus> resetPassword({required String email}) async {
    await auth
        .sendPasswordResetEmail(email: email)
        .then((value) => _status = AuthStatus.successful)
        .catchError(
          (e) => _status = AuthExceptionHandler.handleAuthException(e),
        );
    return _status;
  }

  Future<AuthStatus> sendEmailVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.sendEmailVerification().then(
            (value) => _status = AuthStatus.successful,
          );
    } else {
      _status = AuthStatus.unknown;
    }
    return _status;
  }

  Future<void> logout() async {
    await auth.signOut();
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;
      OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      var user = await FirebaseAuth.instance.signInWithCredential(credential);
      return user.user;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('exception->$e');
      }
      return null;
    }
  }

  static Future<List<SocialMediaUser>> getAllUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection(FirebaseCollections.users).get();
    return snapshot.docs
        .map((doc) => SocialMediaUser.fromMap(doc.data()))
        .toList();
  }
}
