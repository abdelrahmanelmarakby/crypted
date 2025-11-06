import { format, formatDistanceToNow } from 'date-fns';
import { Timestamp } from 'firebase/firestore';

/**
 * Format Firebase Timestamp to readable date string
 */
export const formatDate = (timestamp: Timestamp | Date | undefined, formatStr = 'MMM dd, yyyy'): string => {
  if (!timestamp) return 'N/A';

  try {
    const date = timestamp instanceof Timestamp ? timestamp.toDate() : timestamp;
    return format(date, formatStr);
  } catch (error) {
    return 'Invalid date';
  }
};

/**
 * Format Firebase Timestamp to relative time (e.g., "2 hours ago")
 */
export const formatRelativeTime = (timestamp: Timestamp | Date | undefined): string => {
  if (!timestamp) return 'N/A';

  try {
    const date = timestamp instanceof Timestamp ? timestamp.toDate() : timestamp;
    return formatDistanceToNow(date, { addSuffix: true });
  } catch (error) {
    return 'Invalid date';
  }
};

/**
 * Format number with commas (e.g., 1000 -> 1,000)
 */
export const formatNumber = (num: number): string => {
  return num.toLocaleString();
};

/**
 * Format bytes to readable size (e.g., 1024 -> 1 KB)
 */
export const formatBytes = (bytes: number, decimals = 2): string => {
  if (bytes === 0) return '0 Bytes';

  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];

  const i = Math.floor(Math.log(bytes) / Math.log(k));

  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
};

/**
 * Truncate text with ellipsis
 */
export const truncateText = (text: string, maxLength: number): string => {
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength) + '...';
};

/**
 * Get initials from name
 */
export const getInitials = (name: string): string => {
  if (!name) return '?';

  const parts = name.trim().split(' ');
  if (parts.length === 1) return parts[0][0].toUpperCase();

  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
};

/**
 * Get color based on status
 */
export const getStatusColor = (status: string): string => {
  const colors: Record<string, string> = {
    active: 'green',
    pending: 'yellow',
    suspended: 'orange',
    deleted: 'red',
    completed: 'green',
    missed: 'red',
    rejected: 'orange',
    cancelled: 'gray',
    reviewed: 'blue',
    action_taken: 'green',
    dismissed: 'gray',
  };

  return colors[status] || 'gray';
};

/**
 * Calculate percentage growth
 */
export const calculateGrowth = (current: number, previous: number): number => {
  if (previous === 0) return current > 0 ? 100 : 0;
  return ((current - previous) / previous) * 100;
};

/**
 * Validate email
 */
export const isValidEmail = (email: string): boolean => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

/**
 * Generate random color for avatar
 */
export const getRandomColor = (): string => {
  const colors = ['red', 'orange', 'yellow', 'green', 'teal', 'blue', 'cyan', 'purple', 'pink'];
  return colors[Math.floor(Math.random() * colors.length)];
};

/**
 * Debounce function
 */
export const debounce = <T extends (...args: any[]) => any>(
  func: T,
  wait: number
): ((...args: Parameters<T>) => void) => {
  let timeout: NodeJS.Timeout;

  return (...args: Parameters<T>) => {
    clearTimeout(timeout);
    timeout = setTimeout(() => func(...args), wait);
  };
};

/**
 * Get greeting based on time of day
 */
export const getGreeting = (): string => {
  const hour = new Date().getHours();

  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
};
