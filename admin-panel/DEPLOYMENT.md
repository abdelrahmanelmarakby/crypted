# Crypted Admin Panel - Deployment Guide

## Prerequisites

✅ Firebase CLI installed: `npm install -g firebase-tools`
✅ Firebase project: crypted-8468f
✅ Admin user created in Firestore

## Step 1: Build the Project

\`\`\`bash
cd admin-panel
npm run build
\`\`\`

This creates a `dist/` folder with optimized production files.

## Step 2: Deploy to Firebase Hosting

\`\`\`bash
firebase deploy --only hosting
\`\`\`

Your admin panel will be live at: **https://crypted-8468f.web.app**

## Step 3: Create First Admin User

1. Go to [Firebase Console](https://console.firebase.google.com/project/crypted-8468f)
2. Navigate to **Authentication** → **Users**
3. Click **Add User** and create with email/password
4. Copy the User UID
5. Go to **Firestore Database**
6. Create collection `admin_users`
7. Add document with the copied UID:

\`\`\`json
{
  "email": "your-admin@example.com",
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

## Step 4: Update Firestore Security Rules

Go to **Firestore Database** → **Rules** and update:

\`\`\`javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAdmin() {
      return request.auth != null &&
        exists(/databases/$(database)/documents/admin_users/$(request.auth.uid));
    }

    function isSuperAdmin() {
      return request.auth != null &&
        get(/databases/$(database)/documents/admin_users/$(request.auth.uid)).data.role == 'super_admin';
    }

    match /users/{userId} {
      allow read: if isAdmin();
      allow write: if isSuperAdmin();
    }

    match /admin_users/{userId} {
      allow read: if isAdmin();
      allow write: if isSuperAdmin();
    }

    match /Stories/{storyId} {
      allow read, write: if isAdmin();
    }

    match /chat_rooms/{roomId} {
      allow read: if isAdmin();
      allow write: if isSuperAdmin();

      match /chat/{messageId} {
        allow read: if isAdmin();
        allow write: if isSuperAdmin();
      }
    }

    match /reports/{reportId} {
      allow read, write: if isAdmin();
    }

    match /admin_logs/{logId} {
      allow read: if isAdmin();
      allow create: if isAdmin();
    }

    match /app_settings/{settingId} {
      allow read: if isAdmin();
      allow write: if isSuperAdmin();
    }
  }
}
\`\`\`

## Step 5: Test the Deployment

1. Visit https://crypted-8468f.web.app
2. Login with your admin credentials
3. Verify dashboard loads
4. Check navigation works

## Troubleshooting

### Build fails
\`\`\`bash
rm -rf node_modules
npm install
npm run build
\`\`\`

### Firebase deploy fails
\`\`\`bash
firebase login
firebase use crypted-8468f
firebase deploy --only hosting
\`\`\`

### Cannot login
- Verify admin user exists in `admin_users` collection
- Check Firestore security rules are updated
- Clear browser cache

## Continuous Deployment

For automatic deployments:

1. Connect GitHub repository to Firebase
2. Enable automatic builds on push
3. Configure build settings in Firebase Console

## Rollback

If something goes wrong:

\`\`\`bash
firebase hosting:clone crypted-8468f:live crypted-8468f:previous
\`\`\`

## Custom Domain (Optional)

1. Go to Firebase Console → Hosting
2. Click "Add custom domain"
3. Follow DNS setup instructions
4. SSL certificate is automatically provided

---

**Your admin panel is now live!** 🎉
