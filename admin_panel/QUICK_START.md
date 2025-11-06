# 🚀 Quick Start Guide

## Prerequisites Completed ✅

- ✅ React + TypeScript + Vite setup
- ✅ Chakra UI configured
- ✅ Firebase integration
- ✅ All dependencies installed
- ✅ Build tested successfully

## Getting Started

### 1. Start Development Server

```bash
cd admin_panel
npm run dev
```

The admin panel will be available at: `http://localhost:5173`

### 2. Create Your First Admin User

Before you can log in, you need to create an admin user in Firebase:

#### Step 1: Create Firebase Auth User
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: `crypted-8468f`
3. Go to **Authentication** → **Users**
4. Click **Add User**
5. Enter email (e.g., `admin@crypted.com`) and password
6. Copy the generated **User UID**

#### Step 2: Create Admin Document in Firestore
1. Go to **Firestore Database**
2. Create a new collection: `admin_users`
3. Add a document with the User UID as the document ID
4. Add these fields:

```
uid: "your-user-uid-here"
email: "admin@crypted.com"
displayName: "Admin Name"
role: "super_admin"
permissions: ["all"]
createdAt: [Click "Add field" → Select "timestamp" → Click "Set to current time"]
lastLogin: null
```

### 3. Login to Admin Panel

1. Open `http://localhost:5173/login`
2. Enter your admin email and password
3. You'll be redirected to the dashboard!

## Available Scripts

```bash
# Start development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview

# Deploy to Firebase Hosting
npm run deploy
```

## Project Structure

```
admin_panel/
├── src/
│   ├── components/       # Reusable UI components
│   │   ├── auth/        # Login, ProtectedRoute
│   │   ├── dashboard/   # StatCard, charts
│   │   └── layout/      # Sidebar, Header, Layout
│   ├── pages/           # All page components
│   │   ├── Dashboard.tsx
│   │   ├── Users.tsx
│   │   ├── UserDetail.tsx
│   │   ├── Stories.tsx
│   │   ├── Reports.tsx
│   │   ├── Analytics.tsx
│   │   ├── Settings.tsx
│   │   └── more...
│   ├── services/        # Firebase services
│   │   ├── userService.ts
│   │   ├── storyService.ts
│   │   ├── reportService.ts
│   │   └── analyticsService.ts
│   ├── contexts/        # React contexts
│   │   └── AuthContext.tsx
│   ├── config/          # Firebase config
│   ├── theme/           # Chakra UI theme
│   ├── types/           # TypeScript types
│   └── utils/           # Helper functions
├── .env                 # Environment variables (already configured)
└── package.json
```

## Features Implemented

### ✅ Core Features
- [x] Authentication with Firebase
- [x] Protected routes
- [x] Role-based access control
- [x] Responsive layout with Sidebar & Header

### ✅ Dashboard
- [x] Real-time statistics cards
- [x] User growth chart (30 days)
- [x] Message activity chart (7 days)
- [x] Platform distribution chart
- [x] Active users tracking

### ✅ User Management
- [x] User list with search
- [x] User details page
- [x] User statistics
- [x] Suspend/delete user actions
- [x] Device information display

### ✅ Stories Management
- [x] Stories grid with filters
- [x] Story preview (image/video/text)
- [x] View count and status
- [x] Delete story capability

### ✅ Reports & Moderation
- [x] Reports list with filters
- [x] Review reports
- [x] Take action (reviewed/action_taken/dismissed)
- [x] Add moderation notes

### ✅ Analytics
- [x] User engagement charts
- [x] Content activity charts
- [x] Retention analysis

### ✅ Settings
- [x] App configuration
- [x] Security settings
- [x] Notification preferences
- [x] Backup settings

## Navigation

The sidebar includes links to:
- 🏠 Dashboard
- 👥 Users
- 💬 Chats
- 📸 Stories
- 🚨 Reports
- 📊 Analytics
- 📝 Logs
- ⚙️ Settings

## Theme & Design

- **Primary Color**: `#31A354` (Crypted brand green)
- **UI Framework**: Chakra UI
- **Charts**: Recharts
- **Icons**: React Icons (Feather Icons)
- **Font**: IBM Plex Sans Arabic

## Deployment

### Deploy to Firebase Hosting

1. Build the project:
```bash
npm run build
```

2. Deploy:
```bash
npm run deploy
```

The admin panel will be deployed to: `https://crypted-8468f.web.app`

## Troubleshooting

### Issue: Can't log in
- **Solution**: Make sure you created an admin user in both Firebase Auth AND Firestore `admin_users` collection

### Issue: "Unauthorized" error
- **Solution**: Check that the user's UID in Firestore matches the Firebase Auth UID

### Issue: Data not loading
- **Solution**: Verify your Firebase security rules allow admin access

### Issue: Charts not showing
- **Solution**: Make sure you have data in your Firebase collections

## Next Steps

1. ✅ Add more admin users
2. ✅ Configure Firebase security rules
3. ✅ Test all features
4. ✅ Customize theme colors if needed
5. ✅ Deploy to production

## Security Notes

- 🔐 All admin actions should be logged
- 🔐 Use strong passwords
- 🔐 Enable 2FA when available
- 🔐 Regular users cannot access admin panel
- 🔐 Session timeout is 30 minutes

## Support

For issues or questions, refer to:
- `README.md` - Comprehensive documentation
- `scripts/createAdmin.md` - Admin user creation guide
- Firebase Console - Check logs and data

---

🎉 **Your admin panel is ready to use!**

Start the dev server with `npm run dev` and visit `http://localhost:5173`
