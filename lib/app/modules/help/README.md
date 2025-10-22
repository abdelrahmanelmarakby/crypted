## Help Module Documentation

The Help module is a comprehensive Firebase-integrated support system that allows users to submit help requests and view their inquiry history.

### Features

1. **Firebase Integration**
   - Help messages are stored in Firebase Firestore
   - Real-time updates for user inquiry history
   - Authentication-based access control

2. **Form Validation**
   - Full name validation (minimum 2 characters)
   - Email format validation
   - Message validation (minimum 10 characters)
   - Real-time error feedback

3. **User Experience**
   - Loading states during submission
   - Success/error feedback messages
   - Recent inquiries history display
   - Status tracking (pending, in_progress, resolved, closed)

4. **Responsive UI**
   - Clean, modern design following app theme
   - Proper form field styling with error states
   - Status indicators with color coding

### Firebase Configuration

#### Firestore Collection: `help_messages`

```javascript
// Firebase Security Rules Example
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /help_messages/{messageId} {
      // Users can only read their own messages
      allow read: if request.auth != null &&
                    request.auth.uid == resource.data.userId;

      // Users can only create messages for themselves
      allow create: if request.auth != null &&
                      request.auth.uid == request.resource.data.userId &&
                      request.resource.data.keys().hasAll(['fullName', 'email', 'message', 'status', 'userId']);

      // Only admins can update status and add responses
      allow update: if request.auth != null &&
                      (request.auth.token.admin == true ||
                       request.auth.uid == resource.data.userId);

      // Users can delete their own messages if status is pending
      allow delete: if request.auth != null &&
                      request.auth.uid == resource.data.userId &&
                      resource.data.status == 'pending';
    }
  }
}
```

#### Collection Structure
```json
{
  "help_messages": {
    "messageId": {
      "fullName": "John Doe",
      "email": "john@example.com",
      "message": "Help request message...",
      "status": "pending", // pending, in_progress, resolved, closed
      "userId": "user_uid",
      "createdAt": "2025-01-21T10:30:00Z",
      "updatedAt": "2025-01-21T10:30:00Z",
      "response": "Optional admin response",
      "adminId": "admin_uid"
    }
  }
}
```

### File Structure

```
lib/app/modules/help/
├── bindings/
│   └── help_binding.dart          # GetX dependency injection
├── controllers/
│   └── help_controller.dart       # Business logic and state management
├── views/
│   └── help_view.dart            # UI implementation
└── widgets/
    └── help_icon.dart            # Social media icon component

lib/app/data/
├── models/
│   └── help_message_model.dart   # Data model for Firebase
└── data_source/
    └── help_data_source.dart     # Firebase operations
```

### Usage

1. **Navigation**: Access via `/help` route or through app navigation
2. **Authentication**: Users must be logged in to submit help requests
3. **Form Submission**: Fill out all fields and tap send button
4. **Status Tracking**: View inquiry status in recent history section

### API Methods

#### HelpController
- `submitHelpMessage()`: Submit new help request
- `validateForm()`: Validate form fields
- `clearForm()`: Clear all form fields
- `getStatusColor(status)`: Get status indicator color
- `getStatusText(status)`: Get status display text

#### HelpDataSource
- `submitHelpMessage()`: Save message to Firebase
- `getUserHelpMessages()`: Stream user's messages
- `getAllHelpMessages()`: Stream all messages (admin)
- `updateHelpMessageStatus()`: Update message status

### Dependencies

- Firebase Firestore
- Firebase Authentication
- GetX for state management
- Flutter SVG for icons
- Custom UI components (CustomTextField, AppProgressButton)

### Security Considerations

1. Authentication required for all operations
2. Users can only access their own messages
3. Status updates restricted to admins
4. Input validation on both client and server
5. Rate limiting recommended for production

### Future Enhancements

- Admin dashboard for managing inquiries
- Email notifications for status updates
- File attachment support
- Priority levels for urgent issues
- Knowledge base integration
- Chat-based support system
