Generate Firestore CRUD operations (data source) for a collection, following the project's established patterns.

Collection/feature name: $ARGUMENTS

Steps:
1. Read existing data sources in `lib/app/data/data_source/` to understand the exact patterns used
2. Create a new data source file at `lib/app/data/data_source/<name>_data_sources.dart`
3. Include all standard CRUD operations:

   - **Create**: Add document with auto-generated ID or custom ID
   - **Read (single)**: Get document by ID with null safety
   - **Read (stream)**: Real-time Firestore stream using `.snapshots().map()`
   - **Read (list)**: Query with ordering, pagination, and filters
   - **Update**: Update specific fields using `update()` with proper merge options
   - **Delete**: Delete document with proper error handling

4. Follow existing project patterns:
   - Use `FirebaseFirestore.instance` for Firestore access
   - Include `Timestamp` for date fields
   - Use `FieldValue.arrayUnion/arrayRemove` for array operations
   - Implement Firestore transactions where needed (e.g., counters, votes)
   - Include user metadata in documents to avoid extra lookups
   - Handle null cases for Firestore data
   - Error handling with `log()` from `dart:developer`

5. Create the corresponding model in `lib/app/data/models/` if one doesn't exist, with `fromQuery()` and `toMap()` methods
