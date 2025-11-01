# Crypted Admin Panel

A comprehensive, modern admin panel for the Crypted messaging application built with React, TypeScript, Firebase, and Material-UI.

## Quick Start

\`\`\`bash
cd admin-panel
npm install
npm run dev
\`\`\`

Visit http://localhost:5173

## Features

✅ **Authentication**: Secure admin login with role-based access  
✅ **Dashboard**: Real-time analytics and statistics  
🚧 **User Management**: View, search, suspend, ban users  
⏳ **Chat Monitoring**: Monitor chat rooms and messages  
⏳ **Story Management**: View and moderate user stories  
⏳ **Reports & Moderation**: Handle flagged content  

## Documentation

- **ADMIN_PANEL_PLAN.md**: Complete feature specifications
- **IMPLEMENTATION_GUIDE.md**: Step-by-step implementation guide

## First Admin User

Create in Firebase Console → Firestore → `admin_users` collection:

\`\`\`json
{
  "email": "admin@example.com",
  "displayName": "Super Admin",
  "role": "super_admin",
  "permissions": {
    "canManageUsers": true,
    "canDeleteContent": true,
    "canBanUsers": true,
    "canManageAdmins": true,
    "canViewAnalytics": true,
    "canSendNotifications": true,
    "canManageSettings": true,
    "canAccessAuditLogs": true
  },
  "createdAt": "2025-01-01T00:00:00.000Z",
  "isActive": true
}
\`\`\`

## Deploy to Firebase

\`\`\`bash
npm run build
firebase deploy --only hosting
\`\`\`

## Tech Stack

React 18 • TypeScript • Material-UI • Redux Toolkit • Firebase • Vite
