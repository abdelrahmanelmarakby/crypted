import { Timestamp } from 'firebase/firestore';

// User Types
export interface User {
  uid: string;
  full_name: string;
  email: string;
  image_url?: string;
  phoneNumber?: string;
  bio?: string;
  following?: string[];
  followers?: string[];
  blockedUser?: string[];
  fcmToken?: string;
  deviceInfo?: DeviceInfo;
  privacySettings?: PrivacySettings;
  chatSettings?: ChatSettings;
  notificationSettings?: NotificationSettings;
  createdAt?: Timestamp;
  lastSeen?: Timestamp;
  isOnline?: boolean;
  status?: 'active' | 'suspended' | 'deleted';
}

export interface DeviceInfo {
  platform?: string;
  osVersion?: string;
  appVersion?: string;
  deviceModel?: string;
}

export interface PrivacySettings {
  lastSeen?: 'everyone' | 'contacts' | 'nobody';
  profilePhoto?: 'everyone' | 'contacts' | 'nobody';
  about?: 'everyone' | 'contacts' | 'nobody';
}

export interface ChatSettings {
  wallpaper?: string;
  fontSize?: 'small' | 'medium' | 'large';
}

export interface NotificationSettings {
  messageNotifications?: boolean;
  groupNotifications?: boolean;
  callNotifications?: boolean;
}

// Story Types
export interface Story {
  id: string;
  uid: string;
  user: {
    full_name: string;
    image_url?: string;
  };
  storyFileUrl?: string;
  storyText?: string;
  createdAt: Timestamp;
  expiresAt: Timestamp;
  storyType: 'image' | 'video' | 'text';
  status: 'active' | 'expired' | 'deleted';
  viewedBy?: string[];
  duration?: number;
}

// Chat Types
export interface ChatRoom {
  id: string;
  participants: string[];
  participantDetails?: User[];
  type: 'private' | 'group';
  name?: string;
  image?: string;
  createdAt: Timestamp;
  lastMessage?: Message;
  lastMessageTime?: Timestamp;
  isActive?: boolean;
}

export interface Message {
  id: string;
  senderId: string;
  senderName?: string;
  text?: string;
  type: 'text' | 'image' | 'video' | 'audio' | 'file' | 'location' | 'contact';
  fileUrl?: string;
  timestamp: Timestamp;
  isRead?: boolean;
  readBy?: string[];
}

// Report Types
export interface Report {
  id: string;
  reporterId: string;
  reporterDetails?: User;
  reportedUserId?: string;
  reportedUserDetails?: User;
  reportedMessageId?: string;
  reportedStoryId?: string;
  contentType: 'user' | 'message' | 'story';
  reason: string;
  description?: string;
  status: 'pending' | 'reviewed' | 'action_taken' | 'dismissed';
  priority: 'low' | 'medium' | 'high';
  createdAt: Timestamp;
  reviewedAt?: Timestamp;
  reviewedBy?: string;
  action?: string;
  notes?: string;
}

// Admin Types
export interface AdminUser {
  uid: string;
  email: string;
  displayName: string;
  role: 'super_admin' | 'admin' | 'moderator' | 'analyst';
  permissions: string[];
  createdAt: Timestamp;
  lastLogin?: Timestamp;
}

export interface AdminLog {
  id: string;
  adminId: string;
  adminName: string;
  action: string;
  resource: 'user' | 'chat' | 'story' | 'report' | 'settings';
  resourceId?: string;
  timestamp: Timestamp;
  ipAddress?: string;
  details?: Record<string, any>;
}

// Analytics Types
export interface DashboardStats {
  totalUsers: number;
  activeUsers24h: number;
  activeUsers7d: number;
  activeUsers30d: number;
  totalMessages: number;
  messagesToday: number;
  activeChatRooms: number;
  activeStories: number;
  totalCalls: number;
  callsToday: number;
  pendingReports: number;
  storageUsage: number;
}

export interface UserGrowthData {
  date: string;
  users: number;
}

export interface MessageActivityData {
  date: string;
  messages: number;
}

// Call Types
export interface Call {
  id: string;
  callerId: string;
  receiverId: string;
  participants: string[];
  type: 'audio' | 'video';
  duration?: number;
  status: 'completed' | 'missed' | 'rejected' | 'cancelled';
  startTime: Timestamp;
  endTime?: Timestamp;
}
