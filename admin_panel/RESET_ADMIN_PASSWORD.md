# 🔐 Reset Admin Password

## Method 1: Reset Password via Firebase Console

### Steps:

1. **Go to Firebase Console:**
   - Visit: https://console.firebase.google.com
   - Select project: **crypted-8468f**

2. **Navigate to Authentication:**
   - Click **Authentication** in the left sidebar
   - Go to **Users** tab

3. **Find your admin user:**
   - Look for the admin email (e.g., `admin@crypted.com`)
   - Click on the user

4. **Reset the password:**
   - Click the **three dots** menu (⋮) on the right
   - Select **Reset password**
   - Firebase will send a password reset email to the admin email address

5. **Check email and reset:**
   - Open the password reset email
   - Click the reset link
   - Set a new password
   - Return to admin panel and login with new password

---

## Method 2: Manually Set New Password in Firebase Console

### Steps:

1. **Go to Firebase Console:**
   - Visit: https://console.firebase.google.com
   - Select project: **crypted-8468f**

2. **Navigate to Authentication:**
   - Click **Authentication** → **Users**

3. **Find and edit user:**
   - Find your admin email
   - Click the user row

4. **Set new password:**
   - Look for **Password** section
   - Click **Reset password** or **Set password**
   - Enter a new password directly
   - Click **Save**

5. **Login immediately:**
   - Go to: http://localhost:5173/login
   - Use your email and new password

---

## Method 3: Create a New Admin User (If email not accessible)

If you can't access the email or want a fresh start:

### Step 1: Create Firebase Auth User

1. Go to Firebase Console → **Authentication** → **Users**
2. Click **Add User**
3. Enter:
   - Email: `newadmin@crypted.com`
   - Password: Your chosen password
4. Copy the generated **User UID**

### Step 2: Create Admin Document

1. Go to **Firestore Database**
2. Navigate to `admin_users` collection
3. Click **Add Document**
4. Document ID: Paste the UID from Step 1
5. Add fields:
   ```
   uid: "your-user-uid"
   email: "newadmin@crypted.com"
   displayName: "New Admin"
   role: "super_admin"
   permissions: ["all"]
   createdAt: [Timestamp - current time]
   lastLogin: null
   ```
6. Save

### Step 3: Login

- Go to: http://localhost:5173/login
- Email: `newadmin@crypted.com`
- Password: [your chosen password]

---

## Method 4: Check Existing Admin Users

Want to see what admin accounts exist?

1. Go to Firebase Console → **Firestore Database**
2. Navigate to `admin_users` collection
3. You'll see all admin user documents
4. Each document shows:
   - UID
   - Email
   - Display name
   - Role

Then use Method 1 or 2 to reset the password for any of these users.

---

## Quick Reference

**Firebase Console URL:**
https://console.firebase.google.com/project/crypted-8468f

**Authentication URL:**
https://console.firebase.google.com/project/crypted-8468f/authentication/users

**Firestore URL:**
https://console.firebase.google.com/project/crypted-8468f/firestore

**Admin Panel Login:**
http://localhost:5173/login

---

## Security Best Practices

After resetting:
- ✅ Use a strong password (12+ characters, mixed case, numbers, symbols)
- ✅ Store password in a secure password manager
- ✅ Don't share admin credentials
- ✅ Consider setting up 2FA when available

---

## Troubleshooting

**Password reset email not received:**
- Check spam/junk folder
- Verify email address is correct in Firebase Auth
- Try Method 2 (manual password set) instead

**"User not found" after reset:**
- Verify the user exists in both:
  1. Firebase Authentication → Users
  2. Firestore → admin_users collection
- UIDs must match in both places

**Still can't login:**
- Check browser console for errors (F12)
- Verify `.env` file has correct Firebase config
- Make sure admin panel server is running (`npm run dev`)

---

Last Updated: 2026-01-27
