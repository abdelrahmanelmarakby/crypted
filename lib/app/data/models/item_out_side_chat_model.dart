import 'package:crypted_app/app/data/models/user_model.dart';

class ItemOutSideChatModel {
  final bool unread;
  final bool activeNow;
  final String imageUser;
  final String nameUser;
  final String message;
  final String phoneNumber;
  final String? timeRead;
  final String? numberOfMessages;
  final String? timeUnread;
  final SocialMediaUser? user;

  ItemOutSideChatModel({
    required this.unread,
    required this.activeNow,
    required this.imageUser,
    required this.nameUser,
    required this.message,
    this.timeRead,
    this.numberOfMessages,
    this.timeUnread,
    this.phoneNumber = '',
    this.user,
  });

  SocialMediaUser toSocialMediaUser() {
    return SocialMediaUser(
      uid: phoneNumber,
      fullName: nameUser,
      imageUrl: imageUser,
      phoneNumber: phoneNumber,
    );
  }
}
