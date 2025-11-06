# Creating Admin Users

## Manual Setup via Firebase Console

Since this is a web admin panel, you'll need to manually create admin users in Firestore:

### Steps:

1. **Create a Firebase Auth User**
   - Go to Firebase Console → Authentication
   - Add a new user with email and password
   - Copy the user's UID

2. **Add Admin Document**
   - Go to Firestore Database
   - Create a new collection called `admin_users`
   - Add a document with the user's UID as the document ID
   - Add the following fields:

   ```json
   {
     "uid": "user-uid-here",
     "email": "admin@crypted.com",
     "displayName": "Admin Name",
     "role": "super_admin",
     "permissions": ["all"],
     "createdAt": Timestamp.now(),
     "lastLogin": null
   }
   ```

### Available Roles:

- `super_admin` - Full access to all features
- `admin` - Most features except critical settings
- `moderator` - Content moderation only
- `analyst` - Read-only analytics access

### Example Admin Users:

**Super Admin:**
```json
{
  "uid": "abc123...",
  "email": "admin@crypted.com",
  "displayName": "Super Admin",
  "role": "super_admin",
  "permissions": ["all"],
  "createdAt": "Timestamp",
  "lastLogin": null
}
```

**Moderator:**
```json
{
  "uid": "def456...",
  "email": "moderator@crypted.com",
  "displayName": "Content Moderator",
  "role": "moderator",
  "permissions": ["view_users", "view_reports", "manage_reports", "view_stories", "manage_stories"],
  "createdAt": "Timestamp",
  "lastLogin": null
}
```

## First Time Login

1. Start the admin panel: `npm run dev`
2. Go to `http://localhost:5173/login`
3. Enter the admin email and password
4. You should be redirected to the dashboard

## Security Notes

- Never share admin credentials
- Enable 2FA when available
- All admin actions are logged
- Regular users cannot access the admin panel
- Use strong passwords for admin accounts
