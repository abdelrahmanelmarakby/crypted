// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:firebase_auth/firebase_auth.dart';

enum AuthStatus {
  successful,
  wrongPassword,
  emailAlreadyExists,
  invalidEmail,
  iNVALIDLOGINCREDENTIALS,
  invalidDevice,
  accountSuspended,
  weakPassword,
  unknown,
}
//

class RegisterModel {
  final AuthStatus? authStatus;
  final User? user;
  RegisterModel({
    this.authStatus,
    this.user,
  });

  RegisterModel copyWith({
    AuthStatus? authStatus,
    User? user,
  }) {
    return RegisterModel(
      authStatus: authStatus ?? this.authStatus,
      user: user ?? this.user,
    );
  }

  @override
  String toString() => 'RegisterModel(authStatus: $authStatus, user: $user)';

  @override
  bool operator ==(covariant RegisterModel other) {
    if (identical(this, other)) return true;

    return other.authStatus == authStatus && other.user == user;
  }

  @override
  int get hashCode => authStatus.hashCode ^ user.hashCode;
}

class AuthExceptionHandler {
  static handleAuthException(FirebaseAuthException e) {
    AuthStatus status;
    switch (e.code) {
      case "INVALID_LOGIN_CREDENTIALS":
        status = AuthStatus.iNVALIDLOGINCREDENTIALS;
        break;
      case "invalid-email":
        status = AuthStatus.invalidEmail;
        break;
      case "wrong-password":
        status = AuthStatus.wrongPassword;
        break;
      case "weak-password":
        status = AuthStatus.weakPassword;
        break;
      case "email-already-in-use":
        status = AuthStatus.emailAlreadyExists;
        break;
      default:
        status = AuthStatus.unknown;
    }
    return status;
  }

  static String generateErrorMessage(error) {
    String errorMessage;
    switch (error) {
      case AuthStatus.accountSuspended:
        errorMessage =
            " تم ايقاف الحساب بسبب عمليه تسجيل دخول غير موثوقه برجا التواصل مع الاكاديميه لحل المشكله";
      case AuthStatus.iNVALIDLOGINCREDENTIALS:
        errorMessage = "بيانات تسجيل الدخول غير صحيحة";
        break;
      case AuthStatus.invalidEmail:
        errorMessage = "يبدو أن عنوان بريدك الإلكتروني غير صحيح";
        break;
      case AuthStatus.weakPassword:
        errorMessage =
            "يجب أن تتكون كلمة المرور الخاصة بك من 6 أحرف على الأقل.";
        break;
      case AuthStatus.wrongPassword:
        errorMessage = "بريدك الإلكتروني أو كلمة المرور خاطئة.";
        break;
      case AuthStatus.emailAlreadyExists:
        errorMessage =
            "عنوان البريد الإلكتروني قيد الاستخدام بالفعل من قبل حساب آخر.";
        break;
      case AuthStatus.invalidDevice:
        errorMessage =
            "لأسباب أمنية، لا يُسمح للجهاز الذي تحاول الوصول إليه بالوصول إليه";
        break;
      default:
        errorMessage = "حدث خطأ. الرجاء معاودة المحاولة في وقت لاحق.";
    }
    return errorMessage;
  }
}
