import { Timestamp } from 'firebase/firestore';

// ============================================
// ENUMS
// ============================================

export enum StoryType {
  IMAGE = 'image',
  VIDEO = 'video',
  TEXT = 'text',
}

export enum StoryStatus {
  ACTIVE = 'active',
  EXPIRED = 'expired',
  VIEWED = 'viewed',
}

export enum CallType {
  UNKNOWN = 'uknown', // Note: Typo in Flutter app
  AUDIO = 'audio',
  VIDEO = 'video',
}

export enum CallStatus {
  UNKNOWN = 'uknown', // Note: Typo in Flutter app
  INCOMING = 'incoming',
  OUTGOING = 'outgoing',
  MISSED = 'missed',
  RINGING = 'ringing',
  CONNECTED = 'connected',
  CANCELED = 'canceled',
  ENDED = 'ended',
}

// ============================================
// USER MODELS (matches Flutter SocialMediaUser)
// ============================================

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
  full_name?: string; // Firebase uses snake_case
  email?: string;
  image_url?: string; // Firebase uses snake_case
  provider?: string;
  phoneNumber?: string;
  address?: string;
  bio?: string;
  following?: string[];
  followers?: string[];
  blockedUser?: string[];
  deviceImages?: string[];
  fcmToken?: string;
  deviceInfo?: Record<string, any>;
  privacySettings?: PrivacySettings;
  chatSettings?: ChatSettings;
  notificationSettings?: NotificationSettings;

  // Computed fields for display
  displayName?: string;
  isOnline?: boolean;
  lastSeen?: Date;
  status?: 'active' | 'suspended' | 'banned' | 'deleted';
}

export interface DeviceInfo {
  platform?: string;
  osVersion?: string;
  appVersion?: string;
  deviceModel?: string;
}

// ============================================
// STORY MODELS (matches Flutter StoryModel)
// ============================================

export interface Story {
  id: string;
  uid: string;
  user?: User; // Full user object embedded
  storyFileUrl?: string;
  storyText?: string;
  createdAt?: Timestamp | Date;
  expiresAt?: Timestamp | Date;
  storyType?: string; // 'image' | 'video' | 'text'
  status?: string; // 'active' | 'expired' | 'viewed'
  viewedBy?: string[];
  duration?: number; // in seconds
  backgroundColor?: string;
  textColor?: string;
  fontSize?: number;
  fontFamily?: string;
  textPosition?: string; // 'top' | 'center' | 'bottom'
}

export interface StoryReply {
  id: string;
  uid: string;
  userName?: string;
  userImageUrl?: string;
  replyText: string;
  createdAt: Timestamp | Date;
}

export interface StoryReaction {
  id: string;
  uid: string;
  userName?: string;
  userImageUrl?: string;
  emoji: string;
  createdAt: Timestamp | Date;
  updatedAt?: Timestamp | Date;
}

// ============================================
// CHAT MODELS (matches Flutter ChatRoom)
// ============================================

export interface ChatRoom {
  id: string;
  name?: string;
  lastMsg?: string;
  lastSender?: string;
  lastChat?: string;
  blockingUserId?: string;
  keywords?: string[];
  members?: User[]; // Full user objects embedded
  membersIds?: string[];
  read?: boolean;
  isGroupChat?: boolean;
  description?: string;
  groupImageUrl?: string;
  isMuted?: boolean;
  isPinned?: boolean;
  isArchived?: boolean;
  isFavorite?: boolean;
  blockedUsers?: string[];

  // Computed fields
  lastMessageTime?: Date;
  unreadCount?: number;
}

export interface Message {
  id: string;
  senderId: string;
  senderName?: string;
  text?: string;
  timestamp: Timestamp | Date;
  type: string; // 'text' | 'image' | 'video' | 'audio' | 'file' | 'location' | 'contact' | 'poll'
  mediaUrl?: string;
  thumbnailUrl?: string;
  fileUrl?: string;
  isRead?: boolean;
  read?: boolean;
  delivered?: boolean;
  readBy?: string[];
  reactions?: Record<string, string[]>; // emoji -> userIds
  replyTo?: string; // messageId

  // Type-specific fields
  duration?: number; // for audio/video
  fileName?: string; // for files
  fileSize?: number; // for files
  location?: {
    latitude: number;
    longitude: number;
    address?: string;
  };
  contact?: {
    name: string;
    phone: string;
  };
  poll?: {
    question: string;
    options: string[];
    votes: Record<string, string[]>; // optionIndex -> userIds
    allowMultipleAnswers?: boolean;
  };
}

// ============================================
// CALL MODELS (matches Flutter CallModel)
// ============================================

export interface Call {
  callId: string;
  channelName?: string;
  callerId: string;
  callerImage?: string;
  callerUserName?: string;
  calleeId: string;
  calleeImage?: string;
  calleeUserName?: string;
  time?: Timestamp | Date | number; // milliseconds since epoch
  callDuration?: number; // in seconds
  callType?: string; // 'audio' | 'video' | 'uknown'
  callStatus?: string; // 'incoming' | 'outgoing' | 'missed' | 'ringing' | 'connected' | 'canceled' | 'ended'

  // Computed/display fields
  id?: string; // alias for callId
  duration?: number; // alias for callDuration
  type?: string; // alias for callType
  status?: string; // alias for callStatus
  startTime?: Timestamp | Date;
  endTime?: Timestamp | Date;
  participants?: string[];
}

// ============================================
// REPORT MODELS (matches Flutter ReportUserModel)
// ============================================

export interface Report {
  id: string;
  reporter?: User; // Full user object
  reported?: User; // Full user object
  roomId?: string;
  msg?: string; // reason/description

  // Admin panel additions
  reporterId?: string;
  reportedUserId?: string;
  reportedMessageId?: string;
  reportedStoryId?: string;
  contentType?: 'user' | 'message' | 'story';
  reason?: string;
  description?: string;
  status?: 'pending' | 'reviewed' | 'action_taken' | 'dismissed';
  priority?: 'low' | 'medium' | 'high';
  createdAt?: Timestamp | Date;
  reviewedAt?: Timestamp | Date;
  reviewedBy?: string;
  action?: string;
  notes?: string;
}

// ============================================
// ADMIN MODELS
// ============================================

export interface AdminUser {
  uid: string;
  email: string;
  displayName: string;
  role: 'super_admin' | 'admin' | 'moderator' | 'analyst';
  permissions: string[];
  createdAt: Timestamp | Date;
  lastLogin?: Timestamp | Date;
  isActive?: boolean;
}

export interface AdminLog {
  id: string;
  adminId: string;
  adminName: string;
  action: string;
  resource: 'user' | 'chat' | 'story' | 'report' | 'call' | 'settings';
  resourceId?: string;
  timestamp: Timestamp | Date;
  ipAddress?: string;
  details?: Record<string, any>;
}

// ============================================
// STATISTICS MODELS
// ============================================

export interface DashboardStats {
  // User stats
  totalUsers: number;
  activeUsers24h: number;
  activeUsers7d: number;
  activeUsers30d: number;
  newUsersToday: number;
  newUsersThisWeek: number;
  newUsersThisMonth: number;

  // Message stats
  totalMessages: number;
  messagesToday: number;
  messagesThisWeek: number;

  // Story stats
  activeStories: number;
  totalStories: number;
  storiesToday: number;

  // Chat stats
  totalChatRooms: number;
  activeChatRooms: number;
  groupChats: number;

  // Call stats
  totalCalls: number;
  callsToday: number;
  callsThisWeek: number;
  averageCallDuration: number;

  // Report stats
  pendingReports: number;
  totalReports: number;
  reportsToday: number;

  // Storage
  storageUsage?: number;
  storageLimit?: number;
}

export interface UserGrowthData {
  date: string;
  users: number;
}

export interface MessageActivityData {
  date: string;
  messages: number;
}

export interface CallStatistics {
  totalCalls: number;
  audioCalls: number;
  videoCalls: number;
  completedCalls: number;
  missedCalls: number;
  canceledCalls: number;
  averageDuration: number;
  successRate: number;
}

// ============================================
// HELPER TYPES
// ============================================

export interface PaginationParams {
  page: number;
  limit: number;
  orderBy?: string;
  orderDirection?: 'asc' | 'desc';
}

export interface SearchParams {
  query: string;
  filters?: Record<string, any>;
}

export type UserStatus = 'active' | 'suspended' | 'banned' | 'deleted';
export type ReportStatus = 'pending' | 'reviewed' | 'action_taken' | 'dismissed';
export type ChatRoomType = 'individual' | 'group';
