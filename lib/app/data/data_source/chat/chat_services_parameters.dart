// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:crypted_app/app/data/models/user_model.dart';

class ChatServicesParameters {
  int? myId;
  int? hisId;
  SocialMediaUser? myUser;
  SocialMediaUser? hisUser;
  ChatServicesParameters({this.myId, this.hisId, this.myUser, this.hisUser});
}
