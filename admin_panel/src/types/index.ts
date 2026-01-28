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
  createdAt?: Timestamp | Date;
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
  lastTime?: Date | Timestamp;
  unreadCount?: number;
  messageCount?: number;
  lastMsgType?: string;
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

// ============================================
// ADVANCED ANALYTICS TYPES (Meta/Google-level)
// ============================================

// Event Tracking
export interface AnalyticsEvent {
  id?: string;
  event_name: string;
  user_id: string;
  session_id?: string;
  timestamp: Timestamp | Date;
  local_timestamp?: string;
  properties?: Record<string, any>;
  platform?: 'android' | 'ios' | 'web';
  app_version?: string;
}

// User Session Analytics
export interface UserSession {
  id: string;
  session_id: string;
  user_id: string;
  start_time: Timestamp | Date;
  end_time?: Timestamp | Date;
  duration_seconds?: number;
  events_count?: number;
  platform?: string;
  device_info?: Record<string, any>;
}

// Daily Metrics (Pre-aggregated)
export interface DailyMetrics {
  date: string;
  user_id: string;
  timestamp: Timestamp | Date;

  // Activity metrics
  sessions_count?: number;
  total_session_duration?: number;
  messages_sent?: number;
  messages_received?: number;
  stories_created?: number;
  stories_viewed?: number;
  calls_made?: number;
  calls_received?: number;
}

// User Cohort
export interface UserCohort {
  cohort_name: string;
  cohort_date: string; // YYYY-MM-DD or YYYY-WW format
  user_ids: string[];
  size: number;
  created_at: Timestamp | Date;
}

// Retention Data
export interface RetentionData {
  cohort_date: string;
  cohort_size: number;
  day_0: number; // Always 100%
  day_1?: number;
  day_7?: number;
  day_14?: number;
  day_30?: number;
  day_60?: number;
  day_90?: number;
}

// Funnel Analytics
export interface FunnelStep {
  step_name: string;
  step_order: number;
  users_count: number;
  conversion_rate?: number; // Percentage from previous step
  drop_off_rate?: number;
  avg_time_to_next_step?: number; // seconds
}

export interface Funnel {
  id: string;
  funnel_name: string;
  description?: string;
  steps: FunnelStep[];
  total_entries: number;
  total_completions: number;
  overall_conversion_rate: number;
  created_at: Timestamp | Date;
  updated_at?: Timestamp | Date;
}

// Feature Usage
export interface FeatureUsage {
  feature_name: string;
  date: string;
  total_users: number;
  total_usages: number;
  unique_users: number;
  avg_usage_per_user: number;
}

// Advanced Dashboard Stats
export interface AdvancedDashboardStats extends DashboardStats {
  // Engagement metrics
  dau?: number; // Daily Active Users
  wau?: number; // Weekly Active Users
  mau?: number; // Monthly Active Users
  stickiness?: number; // DAU/MAU ratio

  // Retention metrics
  day1_retention?: number;
  day7_retention?: number;
  day30_retention?: number;

  // Revenue/Conversion metrics (for future)
  avg_session_duration?: number;
  avg_sessions_per_user?: number;

  // Content metrics
  avg_messages_per_user?: number;
  avg_stories_per_user?: number;
  avg_calls_per_user?: number;

  // Growth metrics
  user_growth_rate?: number; // Percentage
  message_growth_rate?: number;
  story_growth_rate?: number;
}

// User Behavior Analytics
export interface UserBehaviorMetrics {
  user_id: string;

  // Activity metrics
  total_sessions: number;
  avg_session_duration: number;
  last_active: Timestamp | Date;
  first_seen: Timestamp | Date;
  days_since_signup: number;

  // Engagement metrics
  messages_sent: number;
  messages_received: number;
  stories_created: number;
  stories_viewed: number;
  calls_made: number;
  calls_received: number;

  // Social metrics
  followers_count: number;
  following_count: number;
  chat_rooms_count: number;

  // Computed scores
  engagement_score?: number; // 0-100
  activity_score?: number; // 0-100
  social_score?: number; // 0-100
  overall_score?: number; // 0-100

  // Segmentation
  user_segment?: 'power_user' | 'active' | 'casual' | 'at_risk' | 'dormant';

  // Cohort
  signup_cohort?: string;
}

// Geographic Analytics
export interface GeoAnalytics {
  country?: string;
  city?: string;
  latitude?: number;
  longitude?: number;
  users_count: number;
  stories_count?: number;
  messages_count?: number;
  calls_count?: number;
}

// Real-time Metrics
export interface RealTimeMetrics {
  timestamp: Timestamp | Date;
  active_users_now: number;
  active_sessions: number;
  messages_per_minute: number;
  stories_per_hour: number;
  calls_in_progress: number;

  // Peak metrics
  peak_concurrent_users?: number;
  peak_messages_per_minute?: number;
}

// User Segment
export interface UserSegment {
  segment_id: string;
  segment_name: string;
  description?: string;
  criteria: Record<string, any>; // Filtering criteria
  user_count: number;
  created_at: Timestamp | Date;
  updated_at?: Timestamp | Date;
}

// Time Series Data (for charts)
export interface TimeSeriesDataPoint {
  date: string;
  value: number;
  label?: string;
}

export interface MultiSeriesDataPoint {
  date: string;
  [key: string]: string | number; // Multiple series
}

// Event Analytics (aggregated)
export interface EventAnalytics {
  event_name: string;
  total_count: number;
  unique_users: number;
  avg_per_user: number;
  trend?: 'up' | 'down' | 'stable';
  growth_rate?: number; // Percentage change
}

// Conversion Metrics
export interface ConversionMetrics {
  metric_name: string;
  numerator: number; // e.g., users who completed action
  denominator: number; // e.g., total users who could complete action
  conversion_rate: number; // Percentage
  date_range: {
    start: string;
    end: string;
  };
}

// A/B Test Results (for future)
export interface ABTestResult {
  test_id: string;
  test_name: string;
  variant_a: {
    name: string;
    users_count: number;
    conversion_rate: number;
  };
  variant_b: {
    name: string;
    users_count: number;
    conversion_rate: number;
  };
  statistical_significance?: number;
  winner?: 'a' | 'b' | 'inconclusive';
}

// User Journey
export interface UserJourneyStep {
  step_number: number;
  event_name: string;
  timestamp: Timestamp | Date;
  properties?: Record<string, any>;
}

export interface UserJourney {
  user_id: string;
  session_id: string;
  journey_start: Timestamp | Date;
  journey_end?: Timestamp | Date;
  steps: UserJourneyStep[];
  completed?: boolean;
}

// Analytics Report Configuration
export interface AnalyticsReport {
  id: string;
  report_name: string;
  report_type: 'user_behavior' | 'engagement' | 'retention' | 'funnel' | 'cohort' | 'custom';
  date_range: {
    start: string;
    end: string;
  };
  filters?: Record<string, any>;
  metrics: string[]; // List of metric names
  created_at: Timestamp | Date;
  created_by: string; // Admin ID
  schedule?: 'daily' | 'weekly' | 'monthly'; // For automated reports
}

// Chart Data Types
export interface ChartData {
  labels: string[];
  datasets: ChartDataset[];
}

export interface ChartDataset {
  label: string;
  data: number[];
  color?: string;
  backgroundColor?: string;
  borderColor?: string;
}

// Analytics Filters
export interface AnalyticsFilters {
  date_range?: {
    start: string;
    end: string;
  };
  user_segments?: string[];
  platforms?: ('android' | 'ios' | 'web')[];
  countries?: string[];
  user_ids?: string[];
  event_names?: string[];
}
