export const APP_NAME = import.meta.env.VITE_APP_NAME || 'Crypted Admin Panel';
export const SESSION_TIMEOUT = parseInt(import.meta.env.VITE_SESSION_TIMEOUT || '1800000');
export const ITEMS_PER_PAGE = parseInt(import.meta.env.VITE_ITEMS_PER_PAGE || '50');

export const COLORS = {
  primary: '#31A354',
  secondary: '#1a1a1a',
  success: '#31A354',
  warning: '#6C757D',
  danger: '#343A40',
  background: '#FAFAFA',
  text: '#1a1a1a',
  white: '#FFFFFF',
  black: '#000000',
  grey: {
    50: '#FAFAFA',
    100: '#F5F5F5',
    200: '#EEEEEE',
    300: '#E0E0E0',
    400: '#BDBDBD',
    500: '#9E9E9E',
    600: '#757575',
    700: '#616161',
    800: '#424242',
    900: '#212121',
  },
  green: {
    50: '#E8F5E9',
    100: '#C8E6C9',
    200: '#A5D6A7',
    300: '#81C784',
    400: '#66BB6A',
    500: '#31A354',
    600: '#2E9B4F',
    700: '#2A8E47',
    800: '#27813F',
    900: '#1F6A31',
  },
};

export const CHART_COLORS = [
  '#31A354',
  '#2E9B4F',
  '#66BB6A',
  '#81C784',
  '#424242',
  '#616161',
  '#757575',
  '#9E9E9E',
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
