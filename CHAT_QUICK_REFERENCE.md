# Chat Implementation - Quick Reference

## Key Files & Line Numbers

### Controllers
- **ChatController** (`/lib/app/modules/chat/controllers/chat_controller.dart` - 1,430 lines)
  - Message sending: lines 396-456
  - Message actions: lines 697-900
  - Reply functionality: lines 354-394
  - Forward logic: lines 904-1021
  - Group management: lines 534-656
  - Copy message: lines 1109-1125
  - Delete/Restore: lines 697-754
  - Pin/Favorite: lines 757-820
  - Report message: lines 1127-1196
  - Call handling: lines 488-631

### Views
- **ChatScreen** (`/lib/app/modules/chat/views/chat_screen.dart` - 1,038 lines)
  - App bar title: lines 211-319
  - Call buttons: lines 346-379
  - Message list: lines 114-140
  - Group settings menu: lines 672-760
  - Members list: lines 769-817
  - Group settings dialog: lines 821-871
  - Edit group name: lines 875-904
  - Edit group description: lines 908-936
  - Change group photo: lines 945-1008

### Widgets
- **MessageActionsBottomSheet** (`/lib/app/modules/chat/widgets/message_actions_bottom_sheet.dart` - 331 lines)
  - All 8 message actions available
  - Dynamic action availability based on state

- **AttachmentWidget** (`/lib/app/modules/chat/widgets/attachment_widget.dart`)
  - Message input field
  - Audio recording (SocialMediaRecorder)
  - Attachment menu (image, video, file, location, contact, poll, event)
  - Text input with send button

- **MsgBuilder** (`/lib/app/modules/chat/widgets/msg_builder.dart`)
  - Message type routing: lines 255-308
  - Deleted message handling: lines 192-252
  - Forwarded indicator: lines 134-155

### Data Sources
- **ChatDataSources** (`/lib/app/data/data_source/chat/chat_data_sources.dart` - 1,298 lines)
  - Create chat room: lines 137-218
  - Add member: lines 221-291
  - Remove member: lines 294-373
  - Update chat info: lines 376-404
  - Update message: lines 409-430
  - Vote on poll: lines 432-512
  - Get live messages: lines 569-590
  - Send message: lines 593-625
  - Post message: lines 628-641

### Services
- **TypingService** (`/lib/app/core/services/typing_service.dart`)
  - Typing indicators with 5-second auto-stop
  - 300ms debouncing

- **ReadReceiptService** (`/lib/app/core/services/read_receipt_service.dart`)
  - Single message read: lines 15-55
  - Batch read marking: lines 58-88

- **ChatSessionManager** (`/lib/app/core/services/chat_session_manager.dart`)
  - Session tracking
  - Member management
  - Group info streaming

## Message Types

| Type | Model | Widget | Features |
|------|-------|--------|----------|
| Text | `text_message_model.dart` | `text_message.dart` | Plain text |
| Photo | `image_message_model.dart` | `image_message.dart` | Image upload/display |
| Video | `video_message_model.dart` | `video_message.dart` | Video playback |
| Audio | `audio_message_model.dart` | `audio_message.dart` | Voice recording/playback |
| File | `file_message_model.dart` | `file_message.dart` | Document sharing |
| Location | `location_message_model.dart` | `location_message.dart` | GPS sharing |
| Contact | `contact_message_model.dart` | `contact_message.dart` | Contact card |
| Poll | `poll_message_model.dart` | `poll_message.dart` | Interactive voting |
| Event | `event_message_model.dart` | `event_message.dart` | Event invites |
| Call | `call_message_model.dart` | `call_message.dart` | Call history |

## Feature Status

### Complete (✅)
- All 10 message types
- Reply with quote
- Forward to other users
- Copy, Pin, Favorite, Delete, Restore
- Audio/Video/File upload
- Location sharing
- Contact sharing
- Polling with real-time votes
- Group chat (add/remove/edit)
- Typing indicators
- Read receipts
- Presence tracking
- Call history
- Message search (controller ready)

### Incomplete (⚠️)
- Message reactions (model ready, UI missing)
- Message editing
- Search UI integration
- Pinned messages view
- Message sharing/export
- Chat blocking UI
- End-to-end encryption
- Favorites list/view

### Missing (❌)
- E2E encryption
- Message expiration
- Screenshot protection
- Advanced notification control

## Patterns Used

1. **GetX Reactive** - `.obs` properties, GetBuilder, Obx
2. **Firebase Firestore** - Real-time streams, transactions for polls
3. **Provider Pattern** - Message streams via Provider widget
4. **Soft Delete** - Logical delete with restore option
5. **Singleton Services** - TypingService, ReadReceiptService, etc.
6. **Bottom Sheet Actions** - Context menus for messages
7. **Stream Subscription Management** - Cleanup in onClose()

## Firebase Structure

```
chats/{roomId}/
├── isGroupChat: bool
├── members: [UserModel]
├── membersIds: [string]
├── name: string (group name)
├── description: string
├── lastMsg: string
├── lastChat: timestamp
└── chat/ (subcollection)
    ├── {messageId}
    │   ├── id: string
    │   ├── type: string
    │   ├── senderId: string
    │   ├── timestamp: datetime
    │   ├── isPinned: bool
    │   ├── isFavorite: bool
    │   ├── isDeleted: bool
    │   ├── isForwarded: bool
    │   ├── reactions: [Reaction]
    │   ├── replyTo: ReplyToMessage
    │   └── [type-specific fields]
    └── readReceipts/
        └── {messageId}/{userId}
            └── readAt: timestamp
```

## Important Methods

### ChatController
- `sendQuickTextMessage()` - Send text
- `sendMessage()` - Send any message type
- `sendCurrentLocation()` - Share GPS
- `forwardMessage()` - Forward to other user
- `deleteMessage()` / `restoreMessage()` - Soft delete/restore
- `togglePinMessage()` / `toggleFavoriteMessage()` - Mark message
- `addMemberToGroup()` / `removeMemberFromGroup()` - Member management
- `updateGroupInfo()` - Edit group details
- `changeGroupPhoto()` - Update group image
- `handleMessageLongPress()` - Show action menu
- `reportMessage()` - Report abuse
- `markMessagesAsRead()` - Update read receipts

### ChatDataSources
- `getLivePrivateMessage()` - Real-time message stream
- `sendMessage()` - Post message
- `votePoll()` - Cast poll vote
- `updateMessage()` - Update message fields
- `addMemberToChat()` - Add user to group
- `removeMemberFromChat()` - Remove user from group
- `updateChatRoomInfo()` - Edit group properties

## Development Tips

1. **Adding new message type:**
   - Create model in `/lib/app/data/models/messages/`
   - Create widget in `/lib/app/modules/chat/widgets/message_type_widget/`
   - Add to Message.fromMap() factory
   - Add case to msg_builder.dart

2. **Testing message flow:**
   - Use `sendTestMessage()` method
   - Use `printChatInfo()` for debugging
   - Check chat_controller.dart print statements with 🔍, 📤, ✅ prefixes

3. **Group chat detection:**
   - Determined by member count > 2
   - Different UI in chat_screen.dart
   - App bar shows different buttons

4. **Member initialization:**
   - Loads from ChatSessionManager if available
   - Falls back to legacy arguments method
   - Current user always at index 0

5. **Real-time updates:**
   - Typing: TypingService via Firestore
   - Read: ReadReceiptService for receipts
   - Presence: PresenceService for online status
   - Messages: Stream via Provider widget

