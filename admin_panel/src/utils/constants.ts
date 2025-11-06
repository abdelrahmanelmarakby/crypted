// App Constants
export const APP_NAME = import.meta.env.VITE_APP_NAME || 'Crypted Admin Panel';
export const SESSION_TIMEOUT = parseInt(import.meta.env.VITE_SESSION_TIMEOUT || '1800000', 10);

// Theme Colors (matching Crypted app)
export const COLORS = {
  primary: '#31A354',
  secondary: '#2C3E50',
  success: '#27AE60',
  warning: '#F39C12',
  danger: '#E74C3C',
  info: '#3498DB',
  dark: '#1A202C',
  light: '#F7FAFC',
};

// Pagination
export const PAGE_SIZE = 50;
export const PAGE_SIZE_OPTIONS = [25, 50, 100, 200];

// Date Formats
export const DATE_FORMAT = 'MMM dd, yyyy';
export const DATE_TIME_FORMAT = 'MMM dd, yyyy HH:mm';
export const TIME_FORMAT = 'HH:mm';

// User Roles
export const USER_ROLES = {
  SUPER_ADMIN: 'super_admin',
  ADMIN: 'admin',
  MODERATOR: 'moderator',
  ANALYST: 'analyst',
} as const;

// User Status
export const USER_STATUS = {
  ACTIVE: 'active',
  SUSPENDED: 'suspended',
  DELETED: 'deleted',
} as const;

// Report Status
export const REPORT_STATUS = {
  PENDING: 'pending',
  REVIEWED: 'reviewed',
  ACTION_TAKEN: 'action_taken',
  DISMISSED: 'dismissed',
} as const;

// Report Priority
export const REPORT_PRIORITY = {
  LOW: 'low',
  MEDIUM: 'medium',
  HIGH: 'high',
} as const;

// Content Types
export const CONTENT_TYPES = {
  USER: 'user',
  MESSAGE: 'message',
  STORY: 'story',
} as const;

// Story Types
export const STORY_TYPES = {
  IMAGE: 'image',
  VIDEO: 'video',
  TEXT: 'text',
} as const;

// Message Types
export const MESSAGE_TYPES = {
  TEXT: 'text',
  IMAGE: 'image',
  VIDEO: 'video',
  AUDIO: 'audio',
  FILE: 'file',
  LOCATION: 'location',
  CONTACT: 'contact',
} as const;

// Call Types
export const CALL_TYPES = {
  AUDIO: 'audio',
  VIDEO: 'video',
} as const;

// Call Status
export const CALL_STATUS = {
  COMPLETED: 'completed',
  MISSED: 'missed',
  REJECTED: 'rejected',
  CANCELLED: 'cancelled',
} as const;

// Firebase Collections
export const COLLECTIONS = {
  USERS: 'users',
  STORIES: 'Stories',
  CHAT_ROOMS: 'chat_rooms',
  CALLS: 'calls',
  REPORTS: 'reports',
  ADMIN_USERS: 'admin_users',
  ADMIN_LOGS: 'admin_logs',
  NOTIFICATIONS: 'notifications',
  APP_SETTINGS: 'app_settings',
} as const;

// Chart Colors
export const CHART_COLORS = [
  '#31A354',
  '#3498DB',
  '#F39C12',
  '#E74C3C',
  '#9B59B6',
  '#1ABC9C',
  '#34495E',
  '#95A5A6',
];

// Suspension Durations
export const SUSPENSION_DURATIONS = [
  { label: '1 Day', value: 1 },
  { label: '7 Days', value: 7 },
  { label: '30 Days', value: 30 },
  { label: 'Permanent', value: -1 },
];

// Error Messages
export const ERROR_MESSAGES = {
  AUTH_FAILED: 'Authentication failed. Please check your credentials.',
  UNAUTHORIZED: 'You do not have permission to perform this action.',
  NETWORK_ERROR: 'Network error. Please check your connection.',
  UNKNOWN_ERROR: 'An unexpected error occurred. Please try again.',
  SESSION_EXPIRED: 'Your session has expired. Please log in again.',
} as const;
