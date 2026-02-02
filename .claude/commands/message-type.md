Create a new chat message type for the messaging system, following the established message type architecture.

Message type: $ARGUMENTS

Steps:
1. Read existing message types in `lib/app/data/models/messages/` and `lib/app/modules/chat/widgets/message_type_widget/` to understand the exact pattern

2. **Create the model** in `lib/app/data/models/messages/`:
   - Extend or follow the base message model pattern
   - Include `fromQuery()` constructor for Firestore deserialization
   - Include `toMap()` for Firestore serialization
   - Handle all nullable fields safely

3. **Create the widget** in `lib/app/modules/chat/widgets/message_type_widget/`:
   - Match the visual style of existing message bubbles
   - Handle sent vs received message styling
   - Use project theme system (ColorsManager, StylesManager)
   - Support RTL layout

4. **Register the type**:
   - Update the message factory/parser in the chat controller
   - Add Firestore serialization in the chat data source
   - Update any message type enums

5. **Handle sending**:
   - Follow the optimistic UI pattern: show locally first, then sync with Firestore
   - Upload media to Firebase Storage if applicable
   - Update with Firestore-assigned IDs after save
