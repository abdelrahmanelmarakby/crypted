/// QUALITY-003: Chat Constants
/// Extracted magic numbers and configuration values
/// to make code more maintainable and self-documenting

class ChatConstants {
  // Private constructor to prevent instantiation
  ChatConstants._();

  // ========== Message Limits ==========

  /// Maximum length for a text message
  static const int maxMessageLength = 5000;

  /// Maximum length for a message preview
  static const int messagePreviewLength = 50;

  /// Time limit for editing messages (in minutes)
  static const int messageEditTimeLimitMinutes = 15;

  /// Maximum number of poll options
  static const int maxPollOptions = 10;

  /// Minimum number of poll options
  static const int minPollOptions = 2;

  // ========== Pagination ==========

  /// Default page size for messages
  static const int defaultMessagePageSize = 30;

  /// Scroll threshold to trigger load more (in pixels)
  static const double loadMoreScrollThreshold = 200;

  /// Cache extent for list views (in pixels)
  static const double listCacheExtent = 500;

  /// Maximum messages to keep in memory
  static const int maxMessagesInMemory = 500;

  // ========== Rate Limiting ==========

  /// Minimum interval between messages (in milliseconds)
  static const int minMessageIntervalMs = 500;

  /// Maximum messages per minute
  static const int maxMessagesPerMinute = 30;

  /// Maximum reactions per minute
  static const int maxReactionsPerMinute = 60;

  /// Debounce delay for search (in milliseconds)
  static const int searchDebounceMs = 300;

  /// Debounce delay for typing indicator (in milliseconds)
  static const int typingDebounceMs = 1000;

  // ========== Timeouts ==========

  /// Message send timeout (in seconds)
  static const int messageSendTimeoutSeconds = 30;

  /// File upload timeout (in seconds)
  static const int fileUploadTimeoutSeconds = 120;

  /// Connection retry timeout (in seconds)
  static const int connectionRetryTimeoutSeconds = 5;

  /// Maximum connection retry attempts
  static const int maxConnectionRetries = 5;

  // ========== UI ==========

  /// Animation duration for message transitions (in milliseconds)
  static const int messageAnimationDurationMs = 200;

  /// Swipe threshold for message actions (in pixels)
  static const double swipeActionThreshold = 80;

  /// Maximum swipe distance (in pixels)
  static const double maxSwipeDistance = 120;

  /// Typing indicator animation duration (in milliseconds)
  static const int typingIndicatorAnimationMs = 600;

  /// Toast display duration (in seconds)
  static const int toastDurationSeconds = 2;

  // ========== Media ==========

  /// Maximum image dimension for upload
  static const int maxImageDimension = 1920;

  /// Image compression quality (0-100)
  static const int imageCompressionQuality = 80;

  /// Maximum video duration for upload (in seconds)
  static const int maxVideoDurationSeconds = 180;

  /// Maximum file size for upload (in MB)
  static const int maxFileSizeMb = 50;

  /// Thumbnail size for videos
  static const int videoThumbnailSize = 256;

  // ========== Presence ==========

  /// Online status check interval (in seconds)
  static const int onlineStatusCheckIntervalSeconds = 30;

  /// Consider user offline after (in minutes)
  static const int offlineThresholdMinutes = 2;

  /// Last seen update interval (in seconds)
  static const int lastSeenUpdateIntervalSeconds = 60;

  // ========== Storage ==========

  /// Maximum contacts to load at once
  static const int maxContactsToLoad = 100;

  /// Maximum recent chats to display
  static const int maxRecentChats = 50;

  /// Maximum search results to show
  static const int maxSearchResults = 50;

  // ========== Group Chat ==========

  /// Maximum group members
  static const int maxGroupMembers = 256;

  /// Maximum group name length
  static const int maxGroupNameLength = 50;

  /// Maximum group description length
  static const int maxGroupDescriptionLength = 500;

  // ========== Audio ==========

  /// Maximum audio message duration (in seconds)
  static const int maxAudioDurationSeconds = 300;

  /// Audio message sample rate
  static const int audioSampleRate = 44100;
}

/// Date format constants
class DateFormatConstants {
  DateFormatConstants._();

  static const String timeFormat = 'HH:mm';
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String shortDateFormat = 'dd MMM';
  static const String monthYearFormat = 'MMMM yyyy';
}

/// Firestore collection names
class CollectionNames {
  CollectionNames._();

  static const String chats = 'chats';
  static const String legacyChats = 'Chats';
  static const String users = 'users';
  static const String messages = 'chat';
  static const String stories = 'Stories';
  static const String reports = 'reports';
  static const String notifications = 'notifications';
  static const String calls = 'calls';
}

/// Firestore field names
class FieldNames {
  FieldNames._();

  static const String timestamp = 'timestamp';
  static const String senderId = 'senderId';
  static const String roomId = 'roomId';
  static const String membersIds = 'membersIds';
  static const String members = 'members';
  static const String isGroupChat = 'isGroupChat';
  static const String lastMessage = 'lastMessage';
  static const String lastChat = 'lastChat';
  static const String isDeleted = 'isDeleted';
  static const String isPinned = 'isPinned';
  static const String isFavorite = 'isFavorite';
  static const String isEdited = 'isEdited';
  static const String reactions = 'reactions';
  static const String readBy = 'readBy';
}
