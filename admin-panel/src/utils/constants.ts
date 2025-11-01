export const APP_NAME = import.meta.env.VITE_APP_NAME || 'Crypted Admin Panel';
export const SESSION_TIMEOUT = parseInt(import.meta.env.VITE_SESSION_TIMEOUT || '1800000');
export const ITEMS_PER_PAGE = parseInt(import.meta.env.VITE_ITEMS_PER_PAGE || '50');

export const COLORS = {
  primary: '#31A354',
  secondary: '#2C3E50',
  success: '#27AE60',
  warning: '#F39C12',
  danger: '#E74C3C',
  background: '#F5F6FA',
  text: '#2C3E50',
  white: '#FFFFFF',
  grey: {
    100: '#F8F9FA',
    200: '#E9ECEF',
    300: '#DEE2E6',
    400: '#CED4DA',
    500: '#ADB5BD',
    600: '#6C757D',
    700: '#495057',
    800: '#343A40',
    900: '#212529',
  },
};

export const CHART_COLORS = [
  '#31A354',
  '#2C3E50',
  '#27AE60',
  '#F39C12',
  '#E74C3C',
  '#3498DB',
  '#9B59B6',
  '#1ABC9C',
];

export const ROUTES = {
  LOGIN: '/login',
  DASHBOARD: '/',
  USERS: '/users',
  USER_DETAIL: '/users/:id',
  CHATS: '/chats',
  CHAT_DETAIL: '/chats/:id',
  STORIES: '/stories',
  STORY_DETAIL: '/stories/:id',
  REPORTS: '/reports',
  REPORT_DETAIL: '/reports/:id',
  CALLS: '/calls',
  ANALYTICS: '/analytics',
  NOTIFICATIONS: '/notifications',
  SETTINGS: '/settings',
};

export const FIREBASE_COLLECTIONS = {
  USERS: 'users',
  STORIES: 'Stories',
  CHAT_ROOMS: 'chat_rooms',
  CALLS: 'calls',
  NOTIFICATIONS: 'notifications',
  REPORTS: 'reports',
  ADMIN_USERS: 'admin_users',
  ADMIN_LOGS: 'admin_logs',
  APP_SETTINGS: 'app_settings',
};

export const DEFAULT_PERMISSIONS = {
  super_admin: {
    canManageUsers: true,
    canDeleteContent: true,
    canBanUsers: true,
    canManageAdmins: true,
    canViewAnalytics: true,
    canSendNotifications: true,
    canManageSettings: true,
    canAccessAuditLogs: true,
  },
  moderator: {
    canManageUsers: true,
    canDeleteContent: true,
    canBanUsers: false,
    canManageAdmins: false,
    canViewAnalytics: true,
    canSendNotifications: false,
    canManageSettings: false,
    canAccessAuditLogs: false,
  },
  support: {
    canManageUsers: false,
    canDeleteContent: false,
    canBanUsers: false,
    canManageAdmins: false,
    canViewAnalytics: true,
    canSendNotifications: false,
    canManageSettings: false,
    canAccessAuditLogs: false,
  },
};

export const STORY_EXPIRATION_HOURS = 24;
export const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB
export const SUPPORTED_IMAGE_FORMATS = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
export const SUPPORTED_VIDEO_FORMATS = ['video/mp4', 'video/webm', 'video/ogg'];
