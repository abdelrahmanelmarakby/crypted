// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:crypted_app/app/data/models/notification_model.dart';

// Privacy Settings Model
class PrivacySettings {
  final bool? oneToOneNotificationSoundEnabled;
  final bool? showLastSeenInOneToOne;
  final bool? showLastSeenInGroups;
  final bool? allowMessagesFromNonContacts;
  final bool? showProfilePhotoToNonContacts;
  final bool? showStatusToContactsOnly;
  final bool? readReceiptsEnabled;
  final bool? allowGroupInvitesFromAnyone;
  final bool? allowAddToGroupsWithoutApproval;
  final bool? allowForwardingMessages;
  final bool? allowScreenshotInChats;
  final bool? allowOnlineStatus;
  final bool? allowTypingIndicator;
  final bool? allowSeenIndicator;
  final bool? allowCamera;

  const PrivacySettings({
    this.oneToOneNotificationSoundEnabled,
    this.showLastSeenInOneToOne,
    this.showLastSeenInGroups,
    this.allowMessagesFromNonContacts,
    this.showProfilePhotoToNonContacts,
    this.showStatusToContactsOnly,
    this.readReceiptsEnabled,
    this.allowGroupInvitesFromAnyone,
    this.allowAddToGroupsWithoutApproval,
    this.allowForwardingMessages,
    this.allowScreenshotInChats,
    this.allowOnlineStatus,
    this.allowTypingIndicator,
    this.allowSeenIndicator,
    this.allowCamera,
  });

  // Default privacy settings factory
  factory PrivacySettings.defaultSettings() {
    return const PrivacySettings(
      oneToOneNotificationSoundEnabled: true,
      showLastSeenInOneToOne: true,
      showLastSeenInGroups: true,
      allowMessagesFromNonContacts: false,
      showProfilePhotoToNonContacts: false,
      showStatusToContactsOnly: true,
      readReceiptsEnabled: true,
      allowGroupInvitesFromAnyone: false,
      allowAddToGroupsWithoutApproval: false,
      allowForwardingMessages: true,
      allowScreenshotInChats: true,
      allowOnlineStatus: true,
      allowTypingIndicator: true,
      allowSeenIndicator: true,
      allowCamera: true,
    );
  }

  PrivacySettings copyWith({
    bool? oneToOneNotificationSoundEnabled,
    bool? showLastSeenInOneToOne,
    bool? showLastSeenInGroups,
    bool? allowMessagesFromNonContacts,
    bool? showProfilePhotoToNonContacts,
    bool? showStatusToContactsOnly,
    bool? readReceiptsEnabled,
    bool? allowGroupInvitesFromAnyone,
    bool? allowAddToGroupsWithoutApproval,
    bool? allowForwardingMessages,
    bool? allowScreenshotInChats,
    bool? allowOnlineStatus,
    bool? allowTypingIndicator,
    bool? allowSeenIndicator,
    bool? allowCamera,
  }) {
    return PrivacySettings(
      oneToOneNotificationSoundEnabled: oneToOneNotificationSoundEnabled ?? this.oneToOneNotificationSoundEnabled,
      showLastSeenInOneToOne: showLastSeenInOneToOne ?? this.showLastSeenInOneToOne,
      showLastSeenInGroups: showLastSeenInGroups ?? this.showLastSeenInGroups,
      allowMessagesFromNonContacts: allowMessagesFromNonContacts ?? this.allowMessagesFromNonContacts,
      showProfilePhotoToNonContacts: showProfilePhotoToNonContacts ?? this.showProfilePhotoToNonContacts,
      showStatusToContactsOnly: showStatusToContactsOnly ?? this.showStatusToContactsOnly,
      readReceiptsEnabled: readReceiptsEnabled ?? this.readReceiptsEnabled,
      allowGroupInvitesFromAnyone: allowGroupInvitesFromAnyone ?? this.allowGroupInvitesFromAnyone,
      allowAddToGroupsWithoutApproval: allowAddToGroupsWithoutApproval ?? this.allowAddToGroupsWithoutApproval,
      allowForwardingMessages: allowForwardingMessages ?? this.allowForwardingMessages,
      allowScreenshotInChats: allowScreenshotInChats ?? this.allowScreenshotInChats,
      allowOnlineStatus: allowOnlineStatus ?? this.allowOnlineStatus,
      allowTypingIndicator: allowTypingIndicator ?? this.allowTypingIndicator,
      allowSeenIndicator: allowSeenIndicator ?? this.allowSeenIndicator,
      allowCamera: allowCamera ?? this.allowCamera,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'oneToOneNotificationSoundEnabled': oneToOneNotificationSoundEnabled,
      'showLastSeenInOneToOne': showLastSeenInOneToOne,
      'showLastSeenInGroups': showLastSeenInGroups,
      'allowMessagesFromNonContacts': allowMessagesFromNonContacts,
      'showProfilePhotoToNonContacts': showProfilePhotoToNonContacts,
      'showStatusToContactsOnly': showStatusToContactsOnly,
      'readReceiptsEnabled': readReceiptsEnabled,
      'allowGroupInvitesFromAnyone': allowGroupInvitesFromAnyone,
      'allowAddToGroupsWithoutApproval': allowAddToGroupsWithoutApproval,
      'allowForwardingMessages': allowForwardingMessages,
      'allowScreenshotInChats': allowScreenshotInChats,
      'allowOnlineStatus': allowOnlineStatus,
      'allowTypingIndicator': allowTypingIndicator,
      'allowSeenIndicator': allowSeenIndicator,
      'allowCamera': allowCamera,
    };
  }

  factory PrivacySettings.fromMap(Map<String, dynamic> map) {
    return PrivacySettings(
      oneToOneNotificationSoundEnabled: map['oneToOneNotificationSoundEnabled'] as bool?,
      showLastSeenInOneToOne: map['showLastSeenInOneToOne'] as bool?,
      showLastSeenInGroups: map['showLastSeenInGroups'] as bool?,
      allowMessagesFromNonContacts: map['allowMessagesFromNonContacts'] as bool?,
      showProfilePhotoToNonContacts: map['showProfilePhotoToNonContacts'] as bool?,
      showStatusToContactsOnly: map['showStatusToContactsOnly'] as bool?,
      readReceiptsEnabled: map['readReceiptsEnabled'] as bool?,
      allowGroupInvitesFromAnyone: map['allowGroupInvitesFromAnyone'] as bool?,
      allowAddToGroupsWithoutApproval: map['allowAddToGroupsWithoutApproval'] as bool?,
      allowForwardingMessages: map['allowForwardingMessages'] as bool?,
      allowScreenshotInChats: map['allowScreenshotInChats'] as bool?,
      allowOnlineStatus: map['allowOnlineStatus'] as bool?,
      allowTypingIndicator: map['allowTypingIndicator'] as bool?,
      allowSeenIndicator: map['allowSeenIndicator'] as bool?,
      allowCamera: map['allowCamera'] as bool?,
    );
  }

  String toJson() => json.encode(toMap());

  factory PrivacySettings.fromJson(String source) =>
      PrivacySettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PrivacySettings(oneToOneNotificationSoundEnabled: $oneToOneNotificationSoundEnabled, showLastSeenInOneToOne: $showLastSeenInOneToOne, showLastSeenInGroups: $showLastSeenInGroups, allowMessagesFromNonContacts: $allowMessagesFromNonContacts, showProfilePhotoToNonContacts: $showProfilePhotoToNonContacts, showStatusToContactsOnly: $showStatusToContactsOnly, readReceiptsEnabled: $readReceiptsEnabled, allowGroupInvitesFromAnyone: $allowGroupInvitesFromAnyone, allowAddToGroupsWithoutApproval: $allowAddToGroupsWithoutApproval, allowForwardingMessages: $allowForwardingMessages, allowScreenshotInChats: $allowScreenshotInChats, allowOnlineStatus: $allowOnlineStatus, allowTypingIndicator: $allowTypingIndicator, allowSeenIndicator: $allowSeenIndicator, allowCamera: $allowCamera)';
  }

  @override
  bool operator ==(covariant PrivacySettings other) {
    if (identical(this, other)) return true;

    return other.oneToOneNotificationSoundEnabled == oneToOneNotificationSoundEnabled &&
        other.showLastSeenInOneToOne == showLastSeenInOneToOne &&
        other.showLastSeenInGroups == showLastSeenInGroups &&
        other.allowMessagesFromNonContacts == allowMessagesFromNonContacts &&
        other.showProfilePhotoToNonContacts == showProfilePhotoToNonContacts &&
        other.showStatusToContactsOnly == showStatusToContactsOnly &&
        other.readReceiptsEnabled == readReceiptsEnabled &&
        other.allowGroupInvitesFromAnyone == allowGroupInvitesFromAnyone &&
        other.allowAddToGroupsWithoutApproval == allowAddToGroupsWithoutApproval &&
        other.allowForwardingMessages == allowForwardingMessages &&
        other.allowScreenshotInChats == allowScreenshotInChats &&
        other.allowOnlineStatus == allowOnlineStatus &&
        other.allowTypingIndicator == allowTypingIndicator &&
        other.allowSeenIndicator == allowSeenIndicator &&
        other.allowCamera == allowCamera;
  }

  @override
  int get hashCode {
    return oneToOneNotificationSoundEnabled.hashCode ^
        showLastSeenInOneToOne.hashCode ^
        showLastSeenInGroups.hashCode ^
        allowMessagesFromNonContacts.hashCode ^
        showProfilePhotoToNonContacts.hashCode ^
        showStatusToContactsOnly.hashCode ^
        readReceiptsEnabled.hashCode ^
        allowGroupInvitesFromAnyone.hashCode ^
        allowAddToGroupsWithoutApproval.hashCode ^
        allowForwardingMessages.hashCode ^
        allowScreenshotInChats.hashCode ^
        allowOnlineStatus.hashCode ^
        allowTypingIndicator.hashCode ^
        allowSeenIndicator.hashCode ^
        allowCamera.hashCode;
  }
}

// Chat Management Settings Model
class ChatSettings {
  final List<String>? favouriteChats;
  final List<String>? mutedChats;
  final List<String>? blockedChats;
  final List<String>? archivedChats;
  final bool? muteNotification;

  const ChatSettings({
    this.favouriteChats,
    this.mutedChats,
    this.blockedChats,
    this.archivedChats,
    this.muteNotification,
  });

  // Default chat settings factory
  factory ChatSettings.defaultSettings() {
    return const ChatSettings(
      favouriteChats: [],
      mutedChats: [],
      blockedChats: [],
      archivedChats: [],
      muteNotification: false,
    );
  }

  ChatSettings copyWith({
    List<String>? favouriteChats,
    List<String>? mutedChats,
    List<String>? blockedChats,
    List<String>? archivedChats,
    bool? muteNotification,
  }) {
    return ChatSettings(
      favouriteChats: favouriteChats ?? this.favouriteChats,
      mutedChats: mutedChats ?? this.mutedChats,
      blockedChats: blockedChats ?? this.blockedChats,
      archivedChats: archivedChats ?? this.archivedChats,
      muteNotification: muteNotification ?? this.muteNotification,
    );
  }

  // Helper methods for chat management
  ChatSettings addToFavourites(String chatId) {
    final newFavourites = List<String>.from(favouriteChats ?? []);
    if (!newFavourites.contains(chatId)) {
      newFavourites.add(chatId);
    }
    return copyWith(favouriteChats: newFavourites);
  }

  ChatSettings removeFromFavourites(String chatId) {
    final newFavourites = List<String>.from(favouriteChats ?? []);
    newFavourites.remove(chatId);
    return copyWith(favouriteChats: newFavourites);
  }

  ChatSettings muteChat(String chatId) {
    final newMutedChats = List<String>.from(mutedChats ?? []);
    if (!newMutedChats.contains(chatId)) {
      newMutedChats.add(chatId);
    }
    return copyWith(mutedChats: newMutedChats);
  }

  ChatSettings unmuteChat(String chatId) {
    final newMutedChats = List<String>.from(mutedChats ?? []);
    newMutedChats.remove(chatId);
    return copyWith(mutedChats: newMutedChats);
  }

  ChatSettings blockChat(String chatId) {
    final newBlockedChats = List<String>.from(blockedChats ?? []);
    if (!newBlockedChats.contains(chatId)) {
      newBlockedChats.add(chatId);
    }
    return copyWith(blockedChats: newBlockedChats);
  }

  ChatSettings unblockChat(String chatId) {
    final newBlockedChats = List<String>.from(blockedChats ?? []);
    newBlockedChats.remove(chatId);
    return copyWith(blockedChats: newBlockedChats);
  }

  ChatSettings archiveChat(String chatId) {
    final newArchivedChats = List<String>.from(archivedChats ?? []);
    if (!newArchivedChats.contains(chatId)) {
      newArchivedChats.add(chatId);
    }
    return copyWith(archivedChats: newArchivedChats);
  }

  ChatSettings unarchiveChat(String chatId) {
    final newArchivedChats = List<String>.from(archivedChats ?? []);
    newArchivedChats.remove(chatId);
    return copyWith(archivedChats: newArchivedChats);
  }

  // Check methods
  bool isFavourite(String chatId) => favouriteChats?.contains(chatId) ?? false;
  bool isMuted(String chatId) => mutedChats?.contains(chatId) ?? false;
  bool isBlocked(String chatId) => blockedChats?.contains(chatId) ?? false;
  bool isArchived(String chatId) => archivedChats?.contains(chatId) ?? false;

  Map<String, dynamic> toMap() {
    return {
      'favouriteChats': favouriteChats,
      'mutedChats': mutedChats,
      'blockedChats': blockedChats,
      'archivedChats': archivedChats,
      'muteNotification': muteNotification,
    };
  }

  factory ChatSettings.fromMap(Map<String, dynamic> map) {
    return ChatSettings(
      favouriteChats: map['favouriteChats'] != null ? List<String>.from(map['favouriteChats']) : null,
      mutedChats: map['mutedChats'] != null ? List<String>.from(map['mutedChats']) : null,
      blockedChats: map['blockedChats'] != null ? List<String>.from(map['blockedChats']) : null,
      archivedChats: map['archivedChats'] != null ? List<String>.from(map['archivedChats']) : null,
      muteNotification: map['muteNotification'] as bool?,
    );
  }

  String toJson() => json.encode(toMap());

  factory ChatSettings.fromJson(String source) =>
      ChatSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ChatSettings(favouriteChats: $favouriteChats, mutedChats: $mutedChats, blockedChats: $blockedChats, archivedChats: $archivedChats, muteNotification: $muteNotification)';
  }

  @override
  bool operator ==(covariant ChatSettings other) {
    if (identical(this, other)) return true;

    return listEquals(other.favouriteChats, favouriteChats) &&
        listEquals(other.mutedChats, mutedChats) &&
        listEquals(other.blockedChats, blockedChats) &&
        listEquals(other.archivedChats, archivedChats) &&
        other.muteNotification == muteNotification;
  }

  @override
  int get hashCode {
    return favouriteChats.hashCode ^
        mutedChats.hashCode ^
        blockedChats.hashCode ^
        archivedChats.hashCode ^
        muteNotification.hashCode;
  }
}

// Simplified Social Media User Model
class SocialMediaUser {
  // Core user information
  final String? fullName;
  final String? email;
  final String? imageUrl;
  final String? provider;
  final String? uid;
  final String? phoneNumber;
  final String? address;
  final String? bio;

  // Social connections
  final List<String>? following;
  final List<String>? followers;
  final List<String>? blockedUser;

  // Device and technical data
  final List<String>? deviceImages;
  final List<Contact>? contacts;
  final String? fcmToken;
  final Map<String, dynamic>? deviceInfo;

  // Settings models
  final PrivacySettings? privacySettings;
  final ChatSettings? chatSettings;
  final NotificationModel? notificationSettings;

  const SocialMediaUser({
    this.fullName,
    this.email,
    this.imageUrl,
    this.provider,
    this.uid,
    this.phoneNumber,
    this.address,
    this.bio,
    this.following,
    this.followers,
    this.blockedUser,
    this.deviceImages,
    this.contacts,
    this.fcmToken,
    this.deviceInfo,
    this.privacySettings,
    this.chatSettings,
    this.notificationSettings,
  });

  // Factory constructor with default settings
  factory SocialMediaUser.create({
    required String fullName,
    required String email,
    required String uid,
    String? imageUrl,
    String? provider,
    String? phoneNumber,
    String? address,
    String? bio,
    List<String>? following,
    List<String>? followers,
    List<String>? blockedUser,
    List<String>? deviceImages,
    List<Contact>? contacts,
    String? fcmToken,
    Map<String, dynamic>? deviceInfo,
  }) {
    return SocialMediaUser(
      fullName: fullName,
      email: email,
      uid: uid,
      imageUrl: imageUrl,
      provider: provider,
      phoneNumber: phoneNumber,
      address: address,
      bio: bio,
      following: following ?? [],
      followers: followers ?? [],
      blockedUser: blockedUser ?? [],
      deviceImages: deviceImages ?? [],
      contacts: contacts ?? [],
      fcmToken: fcmToken,
      deviceInfo: deviceInfo ?? {},
      privacySettings: PrivacySettings.defaultSettings(),
      chatSettings: ChatSettings.defaultSettings(),
      notificationSettings: NotificationModel(
        showMessageNotification: true,
        soundMessage: 'Note',
        reactionMessageNotification: true,
        showGroupNotification: true,
        soundGroup: 'Note',
        reactionGroupNotification: true,
        soundStatus: 'Note',
        reactionStatusNotification: true,
        reminderNotification: true,
        showPreviewNotification: true,
      ),
    );
  }

  SocialMediaUser copyWith({
    String? fullName,
    String? email,
    String? imageUrl,
    String? provider,
    String? uid,
    String? phoneNumber,
    String? address,
    String? bio,
    List<String>? following,
    List<String>? followers,
    List<String>? blockedUser,
    List<String>? deviceImages,
    List<Contact>? contacts,
    String? fcmToken,
    Map<String, dynamic>? deviceInfo,
    PrivacySettings? privacySettings,
    ChatSettings? chatSettings,
    NotificationModel? notificationSettings,
  }) {
    return SocialMediaUser(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      imageUrl: imageUrl ?? this.imageUrl,
      provider: provider ?? this.provider,
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      bio: bio ?? this.bio,
      following: following ?? this.following,
      followers: followers ?? this.followers,
      blockedUser: blockedUser ?? this.blockedUser,
      deviceImages: deviceImages ?? this.deviceImages,
      contacts: contacts ?? this.contacts,
      fcmToken: fcmToken ?? this.fcmToken,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      privacySettings: privacySettings ?? this.privacySettings,
      chatSettings: chatSettings ?? this.chatSettings,
      notificationSettings: notificationSettings ?? this.notificationSettings,
    );
  }

  // Helper methods for easy access
  bool isChatFavourite(String chatId) => chatSettings?.isFavourite(chatId) ?? false;
  bool isChatMuted(String chatId) => chatSettings?.isMuted(chatId) ?? false;
  bool isChatBlocked(String chatId) => chatSettings?.isBlocked(chatId) ?? false;
  bool isChatArchived(String chatId) => chatSettings?.isArchived(chatId) ?? false;

  // Update chat settings methods
  SocialMediaUser addChatToFavourites(String chatId) {
    return copyWith(chatSettings: chatSettings?.addToFavourites(chatId));
  }

  SocialMediaUser removeChatFromFavourites(String chatId) {
    return copyWith(chatSettings: chatSettings?.removeFromFavourites(chatId));
  }

  SocialMediaUser muteChat(String chatId) {
    return copyWith(chatSettings: chatSettings?.muteChat(chatId));
  }

  SocialMediaUser unmuteChat(String chatId) {
    return copyWith(chatSettings: chatSettings?.unmuteChat(chatId));
  }

  SocialMediaUser blockChat(String chatId) {
    return copyWith(chatSettings: chatSettings?.blockChat(chatId));
  }

  SocialMediaUser unblockChat(String chatId) {
    return copyWith(chatSettings: chatSettings?.unblockChat(chatId));
  }

  SocialMediaUser archiveChat(String chatId) {
    return copyWith(chatSettings: chatSettings?.archiveChat(chatId));
  }

  SocialMediaUser unarchiveChat(String chatId) {
    return copyWith(chatSettings: chatSettings?.unarchiveChat(chatId));
  }

  Map<String, dynamic> toMap() {
    return {
      'full_name': fullName,
      'email': email,
      'image_url': imageUrl ?? 'https://ui-avatars.com/api/?background=random&name=${fullName ?? "NA"}',
      'provider': provider,
      'uid': uid,
      'phoneNumber': phoneNumber,
      'address': address,
      'bio': bio,
      'following': following,
      'followers': followers,
      'blockedUser': blockedUser,
      'deviceImages': deviceImages ?? [],
      'contacts': contacts?.map((x) => x.toJson()).toList(),
      'fcmToken': fcmToken,
      'deviceInfo': deviceInfo ?? {},
      'privacySettings': privacySettings?.toMap(),
      'chatSettings': chatSettings?.toMap(),
      'notificationSettings': notificationSettings?.toMap(),
    };
  }

  factory SocialMediaUser.fromMap(Map<String, dynamic> map) {
    return SocialMediaUser(
      fullName: map['full_name'] as String?,
      email: map['email'] as String?,
      imageUrl: map['image_url'] != null && (map['image_url'] as String).isNotEmpty
          ? map['image_url']
          : 'https://ui-avatars.com/api/?background=random&name=${map['full_name'] ?? "NA"}',
      provider: map['provider'] as String?,
      uid: map['uid'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      address: map['address'] as String?,
      bio: map['bio'] as String?,
      following: map['following'] != null ? List<String>.from(map['following']) : null,
      followers: map['followers'] != null ? List<String>.from(map['followers']) : null,
      blockedUser: map['blockedUser'] != null ? List<String>.from(map['blockedUser']) : null,
      deviceImages: map['deviceImages'] != null ? List<String>.from(map['deviceImages']) : null,
      contacts: map['contacts'] != null
          ? List<Contact>.from(
              (map['contacts'] as List).map<Contact>(
                (x) => Contact.fromJson(x as Map<String, dynamic>),
              ),
            )
          : null,
      fcmToken: map['fcmToken'] as String?,
      deviceInfo: map['deviceInfo'] != null ? Map<String, dynamic>.from(map['deviceInfo']) : null,
      privacySettings: map['privacySettings'] != null
          ? PrivacySettings.fromMap(Map<String, dynamic>.from(map['privacySettings']))
          : null,
      chatSettings: map['chatSettings'] != null
          ? ChatSettings.fromMap(Map<String, dynamic>.from(map['chatSettings']))
          : null,
      notificationSettings: map['notificationSettings'] != null
          ? NotificationModel.fromMap(Map<String, dynamic>.from(map['notificationSettings']))
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory SocialMediaUser.fromJson(String source) =>
      SocialMediaUser.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'SocialMediaUser(fullName: $fullName, email: $email, imageUrl: $imageUrl, provider: $provider, uid: $uid, phoneNumber: $phoneNumber, address: $address, bio: $bio, following: $following, followers: $followers, blockedUser: $blockedUser, fcmToken: $fcmToken, privacySettings: $privacySettings, chatSettings: $chatSettings, notificationSettings: $notificationSettings)';
  }

  @override
  bool operator ==(covariant SocialMediaUser other) {
    if (identical(this, other)) return true;

    return other.fullName == fullName &&
        other.email == email &&
        other.imageUrl == imageUrl &&
        other.provider == provider &&
        other.uid == uid &&
        other.phoneNumber == phoneNumber &&
        other.address == address &&
        other.bio == bio &&
        listEquals(other.following, following) &&
        listEquals(other.followers, followers) &&
        listEquals(other.blockedUser, blockedUser) &&
        listEquals(other.deviceImages, deviceImages) &&
        listEquals(other.contacts, contacts) &&
        other.fcmToken == fcmToken &&
        mapEquals(other.deviceInfo, deviceInfo) &&
        other.privacySettings == privacySettings &&
        other.chatSettings == chatSettings &&
        other.notificationSettings == notificationSettings;
  }

  @override
  int get hashCode {
    return fullName.hashCode ^
        email.hashCode ^
        imageUrl.hashCode ^
        provider.hashCode ^
        uid.hashCode ^
        phoneNumber.hashCode ^
        address.hashCode ^
        bio.hashCode ^
        following.hashCode ^
        followers.hashCode ^
        blockedUser.hashCode ^
        deviceImages.hashCode ^
        contacts.hashCode ^
        fcmToken.hashCode ^
        deviceInfo.hashCode ^
        privacySettings.hashCode ^
        chatSettings.hashCode ^
        notificationSettings.hashCode;
  }
}