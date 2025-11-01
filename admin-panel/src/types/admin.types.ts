export enum AdminRole {
  SUPER_ADMIN = 'super_admin',
  MODERATOR = 'moderator',
  SUPPORT = 'support',
}

export interface AdminPermissions {
  canManageUsers: boolean;
  canDeleteContent: boolean;
  canBanUsers: boolean;
  canManageAdmins: boolean;
  canViewAnalytics: boolean;
  canSendNotifications: boolean;
  canManageSettings: boolean;
  canAccessAuditLogs: boolean;
}

export interface AdminUser {
  uid: string;
  email: string;
  displayName: string;
  role: AdminRole;
  permissions: AdminPermissions;
  createdAt: any;
  lastLogin?: any;
  isActive: boolean;
  photoURL?: string;
}

export enum AdminActionType {
  USER_SUSPENDED = 'user_suspended',
  USER_BANNED = 'user_banned',
  USER_DELETED = 'user_deleted',
  CONTENT_DELETED = 'content_deleted',
  REPORT_RESOLVED = 'report_resolved',
  SETTINGS_UPDATED = 'settings_updated',
  NOTIFICATION_SENT = 'notification_sent',
  ADMIN_CREATED = 'admin_created',
  ADMIN_DELETED = 'admin_deleted',
}

export interface AuditLog {
  id: string;
  adminId: string;
  adminDetails?: AdminUser;
  action: AdminActionType;
  targetId?: string;
  targetType?: string;
  details: string;
  timestamp: any;
  ipAddress?: string;
  userAgent?: string;
}

export interface DashboardStats {
  totalUsers: number;
  activeUsers24h: number;
  activeUsers7d: number;
  activeUsers30d: number;
  totalMessages: number;
  messagesToday: number;
  totalStories: number;
  activeStories: number;
  totalCalls: number;
  callsToday: number;
  activeChatRooms: number;
  pendingReports: number;
  storageUsed: number;
  userGrowth: number;
}
