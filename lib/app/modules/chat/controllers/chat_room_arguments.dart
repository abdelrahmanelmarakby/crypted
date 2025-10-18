import 'package:crypted_app/app/data/models/user_model.dart';

class ChatRoomArguments {
  final String roomId;
  final List<SocialMediaUser> members;
  final String blockingUserId;
  final bool isGroupChat;

  ChatRoomArguments({
    required this.roomId,
    required this.members,
    required this.blockingUserId,
    required this.isGroupChat,
  });
}