export enum ReportType {
  USER = 'user',
  MESSAGE = 'message',
  STORY = 'story',
  PROFILE = 'profile',
}

export enum ReportReason {
  SPAM = 'spam',
  HARASSMENT = 'harassment',
  HATE_SPEECH = 'hate_speech',
  VIOLENCE = 'violence',
  NUDITY = 'nudity',
  FALSE_INFORMATION = 'false_information',
  SCAM = 'scam',
  OTHER = 'other',
}

export enum ReportStatus {
  PENDING = 'pending',
  REVIEWED = 'reviewed',
  RESOLVED = 'resolved',
  DISMISSED = 'dismissed',
}

export enum ReportPriority {
  LOW = 'low',
  MEDIUM = 'medium',
  HIGH = 'high',
  CRITICAL = 'critical',
}

export interface Report {
  id: string;
  reportedBy: string;
  reportedByDetails?: any;
  reportedUser?: string;
  reportedUserDetails?: any;
  reportedContentId?: string;
  reportedContentType?: string;
  reportType: ReportType;
  reason: ReportReason;
  description?: string;
  status: ReportStatus;
  priority: ReportPriority;
  createdAt: any;
  reviewedAt?: any;
  reviewedBy?: string;
  resolvedAt?: any;
  resolvedBy?: string;
  notes?: string;
  actionTaken?: string;
  evidence?: string[];
}
