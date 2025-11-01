export interface PrivacySettings {
  oneToOneNotificationSoundEnabled?: boolean;
  showLastSeenInOneToOne?: boolean;
  showLastSeenInGroups?: boolean;
  allowMessagesFromNonContacts?: boolean;
  showProfilePhotoToNonContacts?: boolean;
  showStatusToContactsOnly?: boolean;
  readReceiptsEnabled?: boolean;
  allowGroupInvitesFromAnyone?: boolean;
  allowAddToGroupsWithoutApproval?: boolean;
  allowForwardingMessages?: boolean;
  allowScreenshotInChats?: boolean;
  allowOnlineStatus?: boolean;
  allowTypingIndicator?: boolean;
  allowSeenIndicator?: boolean;
  allowCamera?: boolean;
}

export interface ChatSettings {
  favouriteChats?: string[];
  mutedChats?: string[];
  blockedChats?: string[];
  archivedChats?: string[];
  muteNotification?: boolean;
}

export interface NotificationSettings {
  showMessageNotification?: boolean;
  soundMessage?: string;
  reactionMessageNotification?: boolean;
  showGroupNotification?: boolean;
  soundGroup?: string;
  reactionGroupNotification?: boolean;
  soundStatus?: string;
  reactionStatusNotification?: boolean;
  reminderNotification?: boolean;
  showPreviewNotification?: boolean;
}

export interface User {
  uid: string;
  full_name: string;
  email: string;
  image_url?: string;
  phoneNumber?: string;
  address?: string;
  bio?: string;
  provider?: string;
  following?: string[];
  followers?: string[];
  blockedUser?: string[];
  deviceImages?: string[];
  fcmToken?: string;
  deviceInfo?: Record<string, any>;
  privacySettings?: PrivacySettings;
  chatSettings?: ChatSettings;
  notificationSettings?: NotificationSettings;
  createdAt?: any;
  lastActive?: any;
  isOnline?: boolean;
  status?: 'active' | 'suspended' | 'banned' | 'deleted';
}

export interface UserStats {
  messagesSent: number;
  messagesReceived: number;
  storiesPosted: number;
  callsMade: number;
  followersCount: number;
  followingCount: number;
  lastActive: Date;
}
