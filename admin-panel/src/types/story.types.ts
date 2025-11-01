import { User } from './user.types';

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

export interface Story {
  id: string;
  uid: string;
  user?: User;
  storyFileUrl?: string;
  storyText?: string;
  createdAt: any;
  expiresAt: any;
  storyType: StoryType;
  status: StoryStatus;
  viewedBy: string[];
  duration?: number;
  backgroundColor?: string;
  textColor?: string;
  fontSize?: number;
  fontFamily?: string;
  textPosition?: 'top' | 'center' | 'bottom';
}
