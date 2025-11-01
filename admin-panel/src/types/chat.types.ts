export interface Reaction {
  emoji: string;
  userId: string;
}

export interface ReplyToMessage {
  id: string;
  senderId: string;
  previewText: string;
}

export enum MessageType {
  TEXT = 'text',
  PHOTO = 'photo',
  VIDEO = 'video',
  AUDIO = 'audio',
  FILE = 'file',
  LOCATION = 'location',
  CONTACT = 'contact',
  POLL = 'poll',
  CALL = 'call',
  EVENT = 'event',
}

export interface BaseMessage {
  id: string;
  roomId: string;
  senderId: string;
  timestamp: any;
  reactions?: Reaction[];
  replyTo?: ReplyToMessage;
  isPinned?: boolean;
  isFavorite?: boolean;
  isDeleted?: boolean;
  isForwarded?: boolean;
  forwardedFrom?: string;
  type: MessageType;
}

export interface TextMessage extends BaseMessage {
  type: MessageType.TEXT;
  content: string;
}

export interface PhotoMessage extends BaseMessage {
  type: MessageType.PHOTO;
  imageUrl: string;
  caption?: string;
  thumbnailUrl?: string;
}

export interface VideoMessage extends BaseMessage {
  type: MessageType.VIDEO;
  videoUrl: string;
  caption?: string;
  thumbnailUrl?: string;
  duration?: number;
}

export interface AudioMessage extends BaseMessage {
  type: MessageType.AUDIO;
  audioUrl: string;
  duration?: number;
  waveform?: number[];
}

export interface FileMessage extends BaseMessage {
  type: MessageType.FILE;
  fileUrl: string;
  fileName: string;
  fileSize: number;
  mimeType: string;
}

export interface LocationMessage extends BaseMessage {
  type: MessageType.LOCATION;
  latitude: number;
  longitude: number;
  address?: string;
}

export interface ContactMessage extends BaseMessage {
  type: MessageType.CONTACT;
  contactName: string;
  contactPhone: string;
}

export interface PollMessage extends BaseMessage {
  type: MessageType.POLL;
  question: string;
  options: string[];
  votes: Record<number, string[]>;
  allowMultipleVotes?: boolean;
}

export type Message = TextMessage | PhotoMessage | VideoMessage | AudioMessage |
                     FileMessage | LocationMessage | ContactMessage | PollMessage;

export interface ChatRoom {
  id: string;
  participants: string[];
  participantDetails?: any[];
  lastMessage?: string;
  lastMessageTime?: any;
  unreadCount?: number;
  isGroup?: boolean;
  groupName?: string;
  groupImage?: string;
  createdAt?: any;
  createdBy?: string;
  isArchived?: boolean;
  isPinned?: boolean;
}
