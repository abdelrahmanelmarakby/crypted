# Crypted Admin Panel

A modern, feature-rich admin panel for managing the Crypted messaging application built with React, TypeScript, and Chakra UI.

## Features

- 🔐 **Authentication & Authorization**: Secure login with role-based access control
- 📊 **Dashboard**: Real-time statistics and analytics with interactive charts
- 👥 **User Management**: View, search, suspend, and manage users
- 💬 **Chat Monitoring**: Monitor and moderate chat conversations
- 📸 **Stories Management**: View, filter, and moderate user stories
- 🚨 **Reports & Moderation**: Handle user reports and take appropriate actions
- 📈 **Analytics**: Comprehensive insights into user engagement and content
- ⚙️ **Settings**: Configure app settings, security, and notifications
- 📝 **Activity Logs**: Track all admin actions and system events

## Tech Stack

- **Frontend**: React 18 with TypeScript
- **UI Framework**: Chakra UI
- **State Management**: React Context + Hooks
- **Routing**: React Router v6
- **Charts**: Recharts
- **Backend**: Firebase (Auth, Firestore, Storage)
- **Build Tool**: Vite

## Getting Started

### Prerequisites

- Node.js 16+ and npm
- Firebase project with Admin credentials

### Installation

1. Install dependencies:
```bash
npm install
```

2. Configure environment variables:
```bash
cp .env.example .env
```

Edit `.env` and add your Firebase credentials.

3. Start the development server:
```bash
npm run dev
```

The app will be available at `http://localhost:5173`

## Building for Production

```bash
npm run build
```

The production-ready files will be in the `dist` directory.

## Deployment

Deploy to Firebase Hosting:

```bash
npm run deploy
```

## Project Structure

```
src/
├── components/       # Reusable UI components
│   ├── auth/        # Authentication components
│   ├── dashboard/   # Dashboard-specific components
│   └── layout/      # Layout components (Sidebar, Header)
├── config/          # Configuration files (Firebase)
├── contexts/        # React Context providers
├── pages/           # Page components
├── services/        # API/Firebase services
├── theme/           # Chakra UI theme customization
├── types/           # TypeScript type definitions
└── utils/           # Utility functions
```

## Firebase Setup

### Required Collections

- `admin_users` - Admin user accounts
- `users` - App users
- `Stories` - User stories
- `chat_rooms` - Chat conversations
- `reports` - User reports
- `admin_logs` - Admin activity logs

### Security Rules

Ensure proper Firestore security rules are configured to restrict admin panel access.

## Features Overview

### Dashboard
- Total users, active users, and growth metrics
- Real-time message and story statistics
- Call activity tracking
- Pending reports count
- Interactive charts for user growth and engagement

### User Management
- Searchable user list with filters
- Detailed user profiles
- User statistics (stories, chats, followers)
- Suspend/delete user actions
- Device information

### Stories Management
- Grid view of all stories
- Filter by status (active/expired)
- Story preview (image/video/text)
- View count and viewer list
- Delete story capability

### Reports & Moderation
- List of all user reports
- Filter by status and priority
- Review and take action on reports
- Add moderation notes
- Mark reports as reviewed/dismissed

### Analytics
- User engagement metrics (DAU, WAU, MAU)
- Content activity (messages, stories, calls)
- User retention analysis
- Platform distribution

### Settings
- App configuration (maintenance mode, features)
- Security settings (2FA, rate limiting)
- Notification preferences
- Backup and data management

## Admin Roles

- **Super Admin**: Full access to all features
- **Admin**: Most features except critical settings
- **Moderator**: Content moderation only
- **Analyst**: Read-only analytics access

## Security

- Firebase Authentication for admin login
- Role-based access control (RBAC)
- Session management with timeout
- Audit logging for all actions
- Protected routes

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

Private - All Rights Reserved

## Support

For support, email admin@crypted.com or open an issue in the repository.

---

Built with ❤️ for Crypted
