# Crypted App - Admin Panel Documentation

## Table of Contents
1. [Overview](#overview)
2. [System Architecture](#system-architecture)
3. [Core Features](#core-features)
4. [Technical Requirements](#technical-requirements)
5. [Database Schema](#database-schema)
6. [API Endpoints](#api-endpoints)
7. [Security & Authentication](#security--authentication)
8. [User Management](#user-management)
9. [Content Moderation](#content-moderation)
10. [Analytics & Reporting](#analytics--reporting)
11. [System Configuration](#system-configuration)
12. [Deployment Guide](#deployment-guide)

---

## Overview

The Crypted Admin Panel is a comprehensive web-based administration interface for managing the Crypted messaging application. It provides administrators with powerful tools to monitor, manage, and moderate the platform while ensuring user privacy and security.

### Key Objectives
- **Centralized Management**: Single interface for all administrative tasks
- **Real-time Monitoring**: Live dashboard with system health and user activity
- **Content Moderation**: Tools for reviewing and managing reported content
- **User Support**: Integrated help desk for handling user inquiries
- **Analytics**: Comprehensive insights into app usage and performance
- **Security**: Role-based access control and audit logging

### Target Users
- **Super Admins**: Full system access and configuration
- **Moderators**: Content review and user management
- **Support Staff**: Help desk and user assistance
- **Analysts**: Read-only access to analytics and reports

---

## System Architecture

### Technology Stack

#### Frontend
```yaml
Framework: React 18+ with TypeScript
UI Library: Material-UI (MUI) v5
State Management: Redux Toolkit + RTK Query
Routing: React Router v6
Charts: Recharts / Chart.js
Data Tables: Material React Table
Form Handling: React Hook Form + Yup validation
Real-time: Firebase Realtime Database / Firestore listeners
Authentication: Firebase Auth
```

#### Backend
```yaml
Platform: Firebase (Firestore, Functions, Storage, Auth)
Functions Runtime: Node.js 18+
API Style: RESTful + Real-time listeners
Authentication: Firebase Admin SDK
Security: Firebase Security Rules + Custom Claims
```

#### Infrastructure
```yaml
Hosting: Firebase Hosting / Vercel
CDN: Firebase CDN
Database: Cloud Firestore
Storage: Firebase Storage
Analytics: Google Analytics 4 + Custom Analytics
Monitoring: Firebase Performance Monitoring
Logging: Cloud Logging
```

### Architecture Diagram
```
┌─────────────────────────────────────────────────────────────┐
│                     Admin Panel (React)                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │Dashboard │  │  Users   │  │Moderation│  │Analytics │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Firebase Backend Services                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │Firestore │  │  Auth    │  │ Storage  │  │Functions │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   Mobile App (Flutter)                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │   Chat   │  │ Stories  │  │  Calls   │  │ Settings │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## Core Features

### 1. Dashboard

#### Overview Metrics
- **Active Users**: Real-time count of online users
- **Total Users**: Registered user count with growth trends
- **Messages**: Total messages sent (today, week, month)
- **Storage Usage**: Current storage consumption and limits
- **Active Chats**: Number of active conversations
- **Reports**: Pending moderation items
- **System Health**: Server status and performance metrics

#### Real-time Charts
```typescript
interface DashboardMetrics {
  activeUsers: {
    current: number;
    trend: 'up' | 'down' | 'stable';
    percentageChange: number;
  };
  messageActivity: {
    hourly: Array<{timestamp: Date; count: number}>;
    daily: Array<{date: Date; count: number}>;
    weekly: Array<{week: string; count: number}>;
  };
  userGrowth: {
    newUsers: number;
    deletedUsers: number;
    activeUsers: number;
    inactiveUsers: number;
  };
  systemHealth: {
    apiResponseTime: number;
    errorRate: number;
    uptime: number;
    storageUsage: number;
  };
}
```

#### Quick Actions
- Create announcement
- Send push notification
- Review pending reports
- Export analytics
- System backup
- Clear cache

### 2. User Management

#### User List Features
```typescript
interface UserManagement {
  search: {
    byName: string;
    byEmail: string;
    byPhone: string;
    byUID: string;
  };
  filters: {
    status: 'active' | 'suspended' | 'deleted' | 'all';
    registrationDate: DateRange;
    lastActive: DateRange;
    accountType: 'email' | 'google' | 'apple' | 'phone';
    verificationStatus: 'verified' | 'unverified';
  };
  sort: {
    field: 'name' | 'email' | 'createdAt' | 'lastActive';
    order: 'asc' | 'desc';
  };
  pagination: {
    page: number;
    pageSize: 10 | 25 | 50 | 100;
    total: number;
  };
}
```

#### User Details View
- **Profile Information**
  - Full name, email, phone number
  - Profile photo
  - Account creation date
  - Last active timestamp
  - Device information
  - Account provider (email, Google, Apple)

- **Activity Statistics**
  - Total messages sent
  - Total chats created
  - Stories posted
  - Calls made (audio/video)
  - Contacts backed up
  - Storage used

- **Privacy Settings**
  - Profile visibility
  - Last seen status
  - Read receipts
  - Typing indicators
  - Blocked users list

- **Account Actions**
  - Suspend account (temporary)
  - Ban account (permanent)
  - Delete account
  - Reset password
  - Verify email/phone
  - Send notification
  - View activity log

#### Bulk Operations
- Export user data (CSV, JSON)
- Send bulk notifications
- Bulk suspend/unsuspend
- Bulk delete inactive accounts
- Generate user reports

### 3. Content Moderation

#### Message Reports
```typescript
interface MessageReport {
  id: string;
  reportedBy: UserReference;
  reportedUser: UserReference;
  messageId: string;
  messageContent: string;
  messageType: 'text' | 'image' | 'video' | 'audio' | 'file';
  roomId: string;
  reason: 'spam' | 'harassment' | 'inappropriate' | 'violence' | 'other';
  description?: string;
  timestamp: Date;
  status: 'pending' | 'reviewing' | 'resolved' | 'dismissed';
  reviewedBy?: string;
  reviewedAt?: Date;
  action?: 'delete' | 'warn' | 'suspend' | 'ban' | 'none';
  notes?: string;
}
```

#### Moderation Actions
- **Review Queue**
  - Pending reports list
  - Priority sorting (by severity, date)
  - Batch review mode
  - Quick actions (approve/reject)

- **Content Actions**
  - View full message context
  - View conversation history
  - Delete message
  - Delete entire conversation
  - Warn user
  - Suspend user (1 day, 7 days, 30 days, permanent)
  - Ban user permanently

- **Appeal System**
  - User appeal submission
  - Appeal review queue
  - Appeal decision tracking
  - Automated appeal notifications

#### Story Moderation
- Review reported stories
- Auto-delete expired stories
- Inappropriate content detection
- User story history
- Bulk story management

### 4. Help Desk Management

#### Ticket System
```typescript
interface HelpTicket {
  id: string;
  userId: string;
  userEmail: string;
  userName: string;
  subject: string;
  message: string;
  requestType: 'support' | 'bug' | 'feature' | 'account' | 'billing';
  priority: 'low' | 'medium' | 'high' | 'urgent';
  status: 'pending' | 'in_progress' | 'resolved' | 'closed';
  attachments?: string[];
  createdAt: Date;
  updatedAt: Date;
  assignedTo?: string;
  responses: Array<{
    from: 'user' | 'admin';
    message: string;
    timestamp: Date;
    attachments?: string[];
  }>;
  tags: string[];
  satisfaction?: 1 | 2 | 3 | 4 | 5;
}
```

#### Help Desk Features
- **Ticket Management**
  - Inbox view with filters
  - Assign tickets to staff
  - Priority management
  - Status tracking
  - Response templates
  - Internal notes

- **Communication**
  - Reply to tickets
  - Attach files/screenshots
  - Email notifications
  - In-app notifications
  - Auto-responses

- **Knowledge Base**
  - FAQ management
  - Article creation
  - Category organization
  - Search functionality
  - Usage analytics

- **Performance Metrics**
  - Average response time
  - Resolution time
  - Ticket volume trends
  - Customer satisfaction scores
  - Agent performance

### 5. Analytics & Reporting

#### User Analytics
```typescript
interface UserAnalytics {
  overview: {
    totalUsers: number;
    activeUsers: number;
    newUsers: number;
    churnRate: number;
  };
  demographics: {
    byCountry: Record<string, number>;
    byDevice: Record<string, number>;
    byPlatform: Record<string, number>;
    byAge: Record<string, number>;
  };
  engagement: {
    dailyActiveUsers: TimeSeriesData;
    monthlyActiveUsers: TimeSeriesData;
    sessionDuration: number;
    sessionsPerUser: number;
  };
  retention: {
    day1: number;
    day7: number;
    day30: number;
    cohortAnalysis: CohortData;
  };
}
```

#### Message Analytics
- Total messages sent
- Messages by type (text, image, video, etc.)
- Average messages per user
- Peak messaging hours
- Message delivery rates
- Failed message analysis

#### Call Analytics
- Total calls (audio/video)
- Call duration statistics
- Call quality metrics
- Failed call analysis
- Peak calling hours
- Bandwidth usage

#### Story Analytics
- Total stories posted
- Story views
- Story engagement rate
- Popular story types
- Story retention rate

#### Backup Analytics
- Total backups created
- Backup success rate
- Storage usage by backup type
- Most backed up data types
- Backup frequency trends

#### Custom Reports
- Report builder interface
- Scheduled reports
- Export formats (PDF, CSV, Excel)
- Email delivery
- Report templates

### 6. System Configuration

#### App Settings
```typescript
interface AppConfiguration {
  general: {
    appName: string;
    appVersion: string;
    maintenanceMode: boolean;
    maintenanceMessage: string;
    forceUpdate: boolean;
    minimumVersion: string;
  };
  features: {
    chatEnabled: boolean;
    storiesEnabled: boolean;
    callsEnabled: boolean;
    backupEnabled: boolean;
    groupChatEnabled: boolean;
    maxGroupMembers: number;
  };
  limits: {
    maxMessageLength: number;
    maxFileSize: number;
    maxImageSize: number;
    maxVideoSize: number;
    maxStoriesPerDay: number;
    maxBackupSize: number;
  };
  security: {
    passwordMinLength: number;
    passwordRequireSpecialChar: boolean;
    sessionTimeout: number;
    maxLoginAttempts: number;
    twoFactorEnabled: boolean;
  };
  notifications: {
    pushEnabled: boolean;
    emailEnabled: boolean;
    smsEnabled: boolean;
    inAppEnabled: boolean;
  };
}
```

#### Firebase Configuration
- Firestore rules management
- Storage rules management
- Security rules testing
- Index management
- Backup configuration

#### Email Templates
- Welcome email
- Password reset
- Account verification
- Suspension notification
- Ban notification
- Help ticket response
- Newsletter templates

#### Push Notifications
- Notification templates
- Scheduling
- Targeting (all users, specific users, segments)
- A/B testing
- Analytics

### 7. Backup & Recovery

#### System Backups
- **Automated Backups**
  - Daily database backups
  - Weekly full backups
  - Monthly archive backups
  - Backup retention policy

- **Manual Backups**
  - On-demand backup creation
  - Selective data backup
  - Export to external storage
  - Backup verification

- **Recovery**
  - Point-in-time recovery
  - Selective data restoration
  - Disaster recovery procedures
  - Backup testing

#### User Data Export
- GDPR compliance tools
- User data download
- Account deletion tools
- Data portability

---

## Technical Requirements

### Frontend Requirements

#### Development Environment
```json
{
  "node": ">=18.0.0",
  "npm": ">=9.0.0",
  "typescript": "^5.0.0"
}
```

#### Core Dependencies
```json
{
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.20.0",
    "@mui/material": "^5.14.0",
    "@mui/icons-material": "^5.14.0",
    "@mui/x-data-grid": "^6.18.0",
    "@mui/x-date-pickers": "^6.18.0",
    "@reduxjs/toolkit": "^2.0.0",
    "react-redux": "^9.0.0",
    "firebase": "^10.7.0",
    "recharts": "^2.10.0",
    "react-hook-form": "^7.49.0",
    "yup": "^1.3.0",
    "date-fns": "^3.0.0",
    "axios": "^1.6.0",
    "react-toastify": "^9.1.0"
  }
}
```

### Backend Requirements

#### Firebase Services
- **Authentication**: Admin user management
- **Firestore**: Database for all app data
- **Cloud Functions**: Server-side logic
- **Cloud Storage**: File and media storage
- **Hosting**: Admin panel hosting
- **Analytics**: Usage tracking

#### Cloud Functions
```typescript
// Example function structure
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// User management
export const suspendUser = functions.https.onCall(async (data, context) => {
  // Verify admin privileges
  // Suspend user account
  // Log action
  // Send notification
});

// Content moderation
export const deleteReportedMessage = functions.https.onCall(async (data, context) => {
  // Verify moderator privileges
  // Delete message
  // Update report status
  // Notify users
});

// Analytics
export const generateAnalyticsReport = functions.https.onCall(async (data, context) => {
  // Aggregate data
  // Generate report
  // Return or email report
});
```

---

## Database Schema

### Firestore Collections

#### Admin Users Collection
```typescript
// Collection: admin_users
interface AdminUser {
  uid: string;
  email: string;
  displayName: string;
  role: 'super_admin' | 'moderator' | 'support' | 'analyst';
  permissions: string[];
  createdAt: Timestamp;
  lastLogin: Timestamp;
  isActive: boolean;
  createdBy: string;
}
```

#### Reports Collection
```typescript
// Collection: reports
interface Report {
  id: string;
  type: 'message' | 'user' | 'story';
  reportedBy: string;
  reportedUserId: string;
  targetId: string; // message ID, user ID, or story ID
  reason: string;
  description: string;
  status: 'pending' | 'reviewing' | 'resolved' | 'dismissed';
  priority: 'low' | 'medium' | 'high';
  createdAt: Timestamp;
  updatedAt: Timestamp;
  reviewedBy?: string;
  reviewedAt?: Timestamp;
  action?: string;
  notes?: string;
}
```

#### Help Messages Collection
```typescript
// Collection: help_messages
interface HelpMessage {
  id: string;
  userId: string;
  fullName: string;
  email: string;
  message: string;
  requestType: 'support' | 'bug' | 'feature' | 'account';
  priority: 'low' | 'medium' | 'high';
  status: 'pending' | 'in_progress' | 'resolved' | 'closed';
  attachmentUrls?: string[];
  createdAt: Timestamp;
  updatedAt: Timestamp;
  assignedTo?: string;
  response?: string;
  adminId?: string;
}
```

#### System Configuration Collection
```typescript
// Collection: system_config
interface SystemConfig {
  id: 'app_settings';
  maintenanceMode: boolean;
  maintenanceMessage: string;
  forceUpdate: boolean;
  minimumVersion: string;
  features: {
    chatEnabled: boolean;
    storiesEnabled: boolean;
    callsEnabled: boolean;
  };
  limits: {
    maxMessageLength: number;
    maxFileSize: number;
    maxGroupMembers: number;
  };
  updatedAt: Timestamp;
  updatedBy: string;
}
```

#### Analytics Collection
```typescript
// Collection: analytics_daily
interface DailyAnalytics {
  date: string; // YYYY-MM-DD
  metrics: {
    activeUsers: number;
    newUsers: number;
    messagesSent: number;
    callsMade: number;
    storiesPosted: number;
  };
  hourlyBreakdown: Record<string, number>;
  createdAt: Timestamp;
}
```

#### Audit Log Collection
```typescript
// Collection: audit_logs
interface AuditLog {
  id: string;
  adminId: string;
  adminEmail: string;
  action: string;
  targetType: 'user' | 'message' | 'system' | 'report';
  targetId: string;
  details: Record<string, any>;
  ipAddress: string;
  userAgent: string;
  timestamp: Timestamp;
}
```

---

## API Endpoints

### Authentication Endpoints

```typescript
// POST /api/admin/login
interface LoginRequest {
  email: string;
  password: string;
}
interface LoginResponse {
  token: string;
  user: AdminUser;
  expiresIn: number;
}

// POST /api/admin/logout
// GET /api/admin/me
// POST /api/admin/refresh-token
```

### User Management Endpoints

```typescript
// GET /api/users
interface GetUsersRequest {
  page: number;
  pageSize: number;
  search?: string;
  filter?: UserFilter;
  sort?: SortOptions;
}

// GET /api/users/:userId
// PUT /api/users/:userId
// DELETE /api/users/:userId
// POST /api/users/:userId/suspend
// POST /api/users/:userId/unsuspend
// POST /api/users/:userId/ban
// POST /api/users/:userId/send-notification
```

### Content Moderation Endpoints

```typescript
// GET /api/reports
// GET /api/reports/:reportId
// PUT /api/reports/:reportId/review
// POST /api/reports/:reportId/resolve
// DELETE /api/messages/:messageId
// DELETE /api/stories/:storyId
```

### Analytics Endpoints

```typescript
// GET /api/analytics/dashboard
// GET /api/analytics/users
// GET /api/analytics/messages
// GET /api/analytics/calls
// POST /api/analytics/export
```

### System Configuration Endpoints

```typescript
// GET /api/config
// PUT /api/config
// POST /api/config/maintenance
// POST /api/notifications/send
```

---

## Security & Authentication

### Admin Authentication

#### Firebase Custom Claims
```typescript
// Set admin role
await admin.auth().setCustomUserClaims(uid, {
  admin: true,
  role: 'super_admin',
  permissions: ['users.read', 'users.write', 'reports.manage']
});
```

#### Role-Based Access Control (RBAC)
```typescript
enum AdminRole {
  SUPER_ADMIN = 'super_admin',
  MODERATOR = 'moderator',
  SUPPORT = 'support',
  ANALYST = 'analyst'
}

interface RolePermissions {
  [AdminRole.SUPER_ADMIN]: string[]; // All permissions
  [AdminRole.MODERATOR]: [
    'reports.read',
    'reports.write',
    'users.read',
    'users.suspend',
    'messages.delete'
  ];
  [AdminRole.SUPPORT]: [
    'help.read',
    'help.write',
    'users.read'
  ];
  [AdminRole.ANALYST]: [
    'analytics.read',
    'reports.read',
    'users.read'
  ];
}
```

### Security Rules

#### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Admin users collection
    match /admin_users/{userId} {
      allow read: if request.auth != null && 
                     request.auth.token.admin == true;
      allow write: if request.auth != null && 
                      request.auth.token.role == 'super_admin';
    }
    
    // Reports collection
    match /reports/{reportId} {
      allow read: if request.auth != null && 
                     request.auth.token.admin == true;
      allow write: if request.auth != null && 
                      (request.auth.token.role == 'super_admin' ||
                       request.auth.token.role == 'moderator');
    }
    
    // System configuration
    match /system_config/{configId} {
      allow read: if request.auth != null && 
                     request.auth.token.admin == true;
      allow write: if request.auth != null && 
                      request.auth.token.role == 'super_admin';
    }
    
    // Audit logs
    match /audit_logs/{logId} {
      allow read: if request.auth != null && 
                     request.auth.token.admin == true;
      allow create: if request.auth != null && 
                       request.auth.token.admin == true;
      allow update, delete: if false; // Immutable
    }
  }
}
```

### Audit Logging

```typescript
// Log all admin actions
async function logAdminAction(
  adminId: string,
  action: string,
  targetType: string,
  targetId: string,
  details: any
) {
  await admin.firestore().collection('audit_logs').add({
    adminId,
    adminEmail: (await admin.auth().getUser(adminId)).email,
    action,
    targetType,
    targetId,
    details,
    ipAddress: context.rawRequest.ip,
    userAgent: context.rawRequest.headers['user-agent'],
    timestamp: admin.firestore.FieldValue.serverTimestamp()
  });
}
```

---

## Deployment Guide

### Prerequisites
1. Firebase project setup
2. Node.js 18+ installed
3. Firebase CLI installed
4. Admin credentials configured

### Setup Steps

#### 1. Initialize Firebase Project
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize project
firebase init

# Select:
# - Hosting
# - Functions
# - Firestore
# - Storage
```

#### 2. Configure Environment
```bash
# Create .env file
cat > .env << EOF
REACT_APP_FIREBASE_API_KEY=your_api_key
REACT_APP_FIREBASE_AUTH_DOMAIN=your_auth_domain
REACT_APP_FIREBASE_PROJECT_ID=your_project_id
REACT_APP_FIREBASE_STORAGE_BUCKET=your_storage_bucket
REACT_APP_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
REACT_APP_FIREBASE_APP_ID=your_app_id
EOF
```

#### 3. Install Dependencies
```bash
# Install frontend dependencies
npm install

# Install functions dependencies
cd functions
npm install
cd ..
```

#### 4. Build and Deploy
```bash
# Build frontend
npm run build

# Deploy to Firebase
firebase deploy

# Or deploy specific services
firebase deploy --only hosting
firebase deploy --only functions
firebase deploy --only firestore:rules
```

### Post-Deployment

#### 1. Create First Admin User
```typescript
// Run this script once
import * as admin from 'firebase-admin';

admin.initializeApp();

async function createFirstAdmin() {
  const email = 'admin@crypted.com';
  const password = 'SecurePassword123!';
  
  // Create user
  const user = await admin.auth().createUser({
    email,
    password,
    displayName: 'Super Admin'
  });
  
  // Set custom claims
  await admin.auth().setCustomUserClaims(user.uid, {
    admin: true,
    role: 'super_admin'
  });
  
  // Add to admin_users collection
  await admin.firestore().collection('admin_users').doc(user.uid).set({
    uid: user.uid,
    email,
    displayName: 'Super Admin',
    role: 'super_admin',
    permissions: ['*'],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    isActive: true
  });
  
  console.log('First admin created:', user.uid);
}

createFirstAdmin();
```

#### 2. Configure Security Rules
```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage:rules
```

#### 3. Set Up Monitoring
- Enable Firebase Performance Monitoring
- Configure Cloud Logging
- Set up error reporting
- Configure uptime checks

---

## Best Practices

### Security
1. **Always use HTTPS** for admin panel
2. **Implement rate limiting** on all endpoints
3. **Use strong passwords** and enforce 2FA
4. **Regular security audits** of code and dependencies
5. **Principle of least privilege** for all roles
6. **Encrypt sensitive data** at rest and in transit
7. **Regular backup** of all data
8. **Monitor for suspicious activity**

### Performance
1. **Implement caching** for frequently accessed data
2. **Use pagination** for large datasets
3. **Optimize database queries** with proper indexing
4. **Lazy load** components and data
5. **Compress assets** and enable CDN
6. **Monitor performance** metrics regularly

### Maintenance
1. **Regular updates** of dependencies
2. **Automated testing** before deployment
3. **Staged rollouts** for major changes
4. **Backup before** major updates
5. **Monitor error rates** after deployment
6. **Document all changes** in changelog

---

## Support & Resources

### Documentation
- [Firebase Documentation](https://firebase.google.com/docs)
- [React Documentation](https://react.dev)
- [Material-UI Documentation](https://mui.com)
- [TypeScript Documentation](https://www.typescriptlang.org/docs)

### Contact
- Technical Support: support@crypted.com
- Security Issues: security@crypted.com
- General Inquiries: info@crypted.com

---

## Changelog

### Version 1.0.0 (Initial Release)
- Complete admin panel implementation
- User management system
- Content moderation tools
- Help desk integration
- Analytics dashboard
- System configuration
- Audit logging
- Role-based access control

---

## License

Copyright © 2024 Crypted App. All rights reserved.

This documentation is proprietary and confidential. Unauthorized copying, distribution, or use is strictly prohibited.
