class Constants {
  // Authentication
  static const String kSignIn = 'Sign In';
  static const String kSignUp = 'Sign Up';
  static const String kLogout = 'Logout';
  static const String kEmail = 'Email';
  static const String kPassword = 'Password';
  static const String kFullName = 'Full Name';
  static const String kPhoneNumber = 'Phone Number';
  static const String kForgotPassword = 'Forgot Password?';
  static const String kResetPassword = 'Reset Password';
  static const String kDontHaveAnAccount = 'Don\'t have an account?';
  static const String kAlreadyHaveAnAccount = 'Already have an account?';
  static const String kCreateAccount = 'Create Account';
  static const String kLoginHere = 'Login here';
  static const String kEnterYourEmail = 'Enter your email';
  static const String kEnterYourPassword = 'Enter your password';
  static const String kEnterYourFullName = 'Enter your full name';
  static const String kEnterYourPhone = 'Enter your phone number';

  // Validation Messages
  static const String kEmailRequired = 'Email is required';
  static const String kValidEmail = 'Please enter a valid email';
  static const String kPasswordRequired = 'Password is required';
  static const String kPasswordMinLength =
      'Password must be at least 6 characters';
  static const String kNameRequired = 'Name is required';
  static const String kPhoneRequired = 'Phone number is required';

  // Chat
  static const String kChats = 'Chats';
  static const String kNewChat = 'New Chat';
  static const String kTypeAMessage = 'Type a message...';
  static const String kNoMessages = 'No messages yet';
  static const String kNoChats = 'No chats yet';
  static const String kPhoto = 'Photo';
  static const String kVideo = 'Video';
  static const String kStartConversation = 'Start a conversation';
  static const String kArchived = 'Archived';
  static const String kSearchChats = 'Search chats...';
  static const String kOnline = 'Online';
  static const String kOffline = 'Offline';
  static const String kTyping = 'typing...';
  static const String kNewMessage = 'New message';
  static const String kMessage = 'Message';
  static const String kSend = 'Send';
  static const String kReply = 'Reply';
  static const String kForward = 'Forward';
  static const String kCopy = 'Copy';
  static const String kDelete = 'Delete';
  static const String kInfo = 'Info';
  static const String kMedia = 'Media';
  static const String kDocuments = 'Documents';
  static const String kLinks = 'Links';
  static const String kVoiceMessages = 'Voice Messages';
  static const String kNoMedia = 'No media shared yet';
  static const String kNoDocuments = 'No documents shared yet';
  static const String kNoLinks = 'No links shared yet';
  static const String kNoVoiceMessages = 'No voice messages yet';

  // Chat Actions
  static const String kClearChat = 'Clear Chat';
  static const String kBlockUser = 'Block User';
  static const String kUnblockUser = 'Unblock User';
  static const String kDeleteChat = 'Delete Chat';
  static const String kMuteChat = 'Mute Chat';
  static const String kUnmuteChat = 'Unmute Chat';
  static const String kAddToFavorites = 'Add to Favorites';
  static const String kRemoveFromFavorites = 'Remove from Favorites';
  static const String kArchiveChat = 'Archive Chat';
  static const String kUnarchiveChat = 'Unarchive Chat';
  static const String kMarkAsRead = 'Mark as Read';
  static const String kMarkAsUnread = 'Mark as Unread';
  static const String kPinChat = 'Pin Chat';
  static const String kUnpinChat = 'Unpin Chat';
  static const String kResend = 'Resend';
  static const String kDocument = 'Document';
  static const String kcopy = 'copy_action';
  static const String kdelete = 'delete_action';
  static const String kOff = 'Off';
  static const String kOn = 'On';
  static const String kNone = 'None';
  static const String kDisappearingMessages = 'Disappearing Messages';
  static const String kAppLock = 'App Lock';
  static const String kRequireFaceIDtounlockCrypted =
      'Require Face ID to unlock Crypted';
  static const String kChatLock = 'Chat Lock';
  static const String kAllowCameraEffects = 'Allow Camera Effects';
  static const String kUseeffectsinthecameraandvideocalls =
      'Use effects in the camera and video calls';
  static const String kLearnmore = 'Learn more';
  static const String kAdvanced = 'Advanced';
  static const String kPrivacyCheckup = 'Privacy Checkup';
  static const String kDescription = 'Description';
  static const String kTomorrow = 'Tomorrow';
  static const String kHours = 'Hours';
  static const String kMinutes = 'Minutes';
  static const String kAgo = 'Ago';
  static const String kNow = 'Now';
  static const String kDate = 'Date';
  static const String kTime = 'Time';
  static const String kDetails = 'Details';
  static const String kEventName = 'Event Name';
  static const String kEventNameisrequired = 'Event name is required';
  static const String kCreateNewEvent = 'Create New Event';

  // Status Messages
  static const String kMessageBlocked = 'You cannot send messages to this user';
  static const String kNew = 'New';
  static const String kToday = 'Today';
  static const String kYesterday = 'Yesterday';
  static const String kThisWeek = 'This Week';
  static const String kOlder = 'Older';
  static const String kJustNow = 'Just now';
  static const String kMinutesAgo = 'minutes ago';
  static const String kHoursAgo = 'hours ago';
  static const String kDaysAgo = 'days ago';

  // Confirmation Messages
  static const String kDeleteChatConfirmation = 'delete_chat_confirmation';
  static const String kAreYouSureToClearThisChat =
      'Are you sure you want to clear this chat? All messages will be deleted.';
  static const String kAreYouSureToDeleteThisChat =
      'Are you sure you want to delete this chat? This action cannot be undone.';
  static const String kAreYouSureToBlockThisUser =
      'Are you sure you want to block this user? You will not receive messages from them.';
  static const String kAreYouSureToUnblockThisUser =
      'Are you sure you want to unblock this user?';
  static const String kAreYouSureToDeleteThisMessage =
      'Are you sure you want to delete this message?';
  static const String kDeleteForMe = 'Delete for me';
  static const String kDeleteForEveryone = 'Delete for everyone';
  static const String kChatDeletedSuccessfully = 'Chat deleted successfully';

  // Success Messages
  static const String kAddedToFavorites = 'Added to favorites';
  static const String kRemovedFromFavorites = 'Removed from favorites';
  static const String kChatArchived = 'Chat archived';
  static const String kChatUnarchived = 'Chat unarchived';
  static const String kChatClearedSuccessfully = 'Chat cleared successfully';
  static const String kUserBlocked = 'User blocked';
  static const String kUserUnblocked = 'User unblocked';
  static const String kMessageDeleted = 'Message deleted';
  static const String kChatMuted = 'Chat muted';
  static const String kChatUnmuted = 'Chat unmuted';
  static const String kChatPinned = 'Chat pinned';
  static const String kChatUnpinned = 'Chat unpinned';

  // Error Messages
  static const String kError = 'Error';
  static const String kSomethingWentWrong = 'Something went wrong';
  static const String kNoInternetConnection = 'No internet connection';
  static const String kTryAgain = 'Please try again';
  static const String kFailedToUpdateFavorite =
      'Failed to update favorite status';
  static const String kFailedToUpdateMute = 'Failed to update mute status';
  static const String kFailedToUpdateBlock = 'Failed to update block status';
  static const String kFailedToArchiveChat = 'Failed to archive chat';
  static const String kFailedToClearChat = 'Failed to clear chat';
  static const String kFailedToDeleteChat = 'Failed to delete chat';
  static const String kFailedToSendMessage = 'Failed to send message';
  static const String kFailedToLoadMessages = 'Failed to load messages';
  static const String kFailedToLoadChats = 'Failed to load chats';
  static const String kFailedToLoadUsers = 'Failed to load users';
  static const String kFailedToLoadProfile = 'Failed to load profile';
  static const String kFailedToUpdateProfile = 'Failed to update profile';
  static const String kFailedToUploadFile = 'Failed to upload file';
  static const String kFileTooLarge = 'File is too large';
  static const String kUnsupportedFileType = 'Unsupported file type';

  // Common
  static const String kStories = 'Stories';
  static const String krecentStories = 'Recent Stories';
  static const String kSetting = 'Settings';
  static const String kProfile = 'Profile';
  static const String kNotifications = 'Notifications';
  static const String kBackup = 'Backup';
  static const String kInviteFriend = 'Invite Friend';
  static const String kLanguage = 'Language';
  static const String kNewPassword = 'New Password';
  static const String kEnteryourpassword = 'enter_your_password';
  static const String kReEnterpaswword = 'Re-enter password';
  static const String kSignUpToCrypted = 'Sign up to Crypted!';
  static const String kEnteryourfullname = 'enter_your_full_name';
  static const String kEnteravalidemailaddress = 'Enter a valid email address';
  static const String kFullNameisrequired = 'Full name is required';
  static const String kEnteryouremail = 'enter_your_email';
  static const String kEmailisrequired = 'email_is_required';
  static const String kEnteravalidemail = 'Enter a valid email';
  static const String kPasswordisrequired = 'password_is_required';
  static const String kPasswordmustbeatleast6characters = 'password_min_length';
  static const String kLogin = 'Login';
  static const String kLogInToCrypted = 'Login to Crypted!';
  static const String kForgetPassword = 'forget_password';
  static const String kEnterOTP = 'Enter OTP';
  static const String kDidntreceivecode = 'Didn\'t receive code?';
  static const String ksend = 'send_action';
  static const String kHome = 'Home';
  static const String kCalls = 'Calls';
  static const String kInviteAFriend = 'Invite a Friend';
  static const String kInvitevialink = 'Invite via link';
  static const String kContacts = 'Contacts';
  static const String ksharelink = 'Share link';
  static const String kcopylink = 'Copy link';
  static const String klinkedIn = 'LinkedIn';
  static const String kfacebook = 'Facebook';
  static const String kwhatsApp = 'WhatsApp';
  static const String kTelegram = 'Telegram';
  static const String kHello = 'Hello';
  static const String kNoChatsyet = 'no_chats_yet';
  static const String kSelectUser = 'Select User';
  static const String kNousersfound = 'No users found';
  static const String kAll = 'All';
  static const String kUnread = 'Unread';
  static const String kGroups = 'Groups';
  static const String kFavourite = 'Favourite';
  static const String ksocialmedia = 'Social Media';
  static const String kcontactus = 'Contact Us';
  static const String kEnteryourmessage = 'Enter your message';
  static const String kInvalidchatparameters = 'Invalid chat parameters';
  static const String kActivenow = 'Active now';
  static const String kJan = 'January';
  static const String kfep = 'February';
  static const String kmar = 'March';
  static const String kApr = 'April';
  static const String kMay = 'May';
  static const String kJun = 'June';
  static const String kjul = 'July';
  static const String kAug = 'August';
  static const String kSep = 'September';
  static const String kOct = 'October';
  static const String kNov = 'November';
  static const String kDec = 'December';
  static const String kJoin = 'Join';
  static const String kViewVotes = 'View Votes';
  static const String kSendamessage = 'Send a message';
  static const String kPhotos = 'Photos';
  static const String kCamera = 'Camera';
  static const String kLocation = 'Location';
  static const String kPoll = 'Poll';
  static const String kContact = 'Contact';
  static const String kEvent = 'Event';
  static const String kreplay = 'reply_action';
  static const String kforward = 'forward_action';
  static const String kstar = 'Star';
  static const String kpin = 'pin_bubble_action';
  static const String kreport = 'report_action';
  static const String kTypeamessage = 'Type a message';
  static const String kInComing = 'Incoming';
  static const String kUpComing = 'Upcoming';
  static const String kRinging = 'Ringing...';
  static const String kContactInfo = 'Contact Info';
  static const String kContactDetails = 'Contact Details';
  static const String kmediaLinksdocuments = 'Media, Links & Documents';
  static const String kstarredmessages = 'Starred Messages';
  static const String kAddtofavourite = 'Add to Favourite';
  static const String kAddtolist = 'Add to List';
  static const String kexportchat = 'export_chat_action';
  static const String knotification = 'notifications_setting';
  static const String kchattheme = 'Chat Theme';
  static const String kEncryption = 'Encryption';
  static const String klockchat = 'Lock Chat';
  static const String kDisappearingmessages = 'disappearing_messages_setting';
  static const String kJustenjoyingthelittlethingsinlife =
      'Just enjoying the little things in life.';
  static const String kGroupInfo = 'Group Info';
  static const String kMembers = 'Members';
  static const String kExitgroup = 'Exit Group';
  static const String kReportgroup = 'Report Group';
  static const String kExportchat = 'export_chat_group';
  static const String kAdmin = 'Admin';
  static const String kMessagenotification = 'Message Notifications';
  static const String kLastSeenOnline = 'Last Seen & Online';
  static const String kSound = 'Sound';
  static const String kNote = 'Note';
  static const String kReactionNotification = 'Reaction Notifications';
  static const String kGroupnotification = 'Group Notifications';
  static const String kStatusnotification = 'Status Notifications';
  static const String kReminders = 'Reminders';
  static const String
      kGetoccasionalremindersaboutmessageorstatusupdatesyouhaventseen =
      'Get occasional reminders about message or status updates you haven\'t seen';
  static const String khomescreennotification = 'Home Screen Notifications';
  static const String kShowPreview = 'Show Preview';
  static const String kresetnotificationsetting = 'Reset Notification Settings';
  static const String
      kResetallnotificationsettingsincludingcustomnotificationsettingsforyourchats =
      'Reset all notification settings including custom notification settings for your chats';
  static const String kNobody = 'Nobody';
  static const String kProfilePicture = 'Profile Picture';
  static const String kExcluded = 'Excluded';
  static const String kEveryOne = 'Everyone';
  static const String kMyContacts = 'My Contacts';
  static const String kLiveLocation = 'Live Location';
  static const String kListofchatswhereyouaresharingyourlivelocation =
      'List of chats where you are sharing your live location';
  static const String kBlocked = 'Blocked';
  static const String kListofcontactsyouhaveblocked =
      'List of contacts you have blocked';
  static const String kDefaultMessageTimer = 'Default Message Timer';
  static const String kStartnewchatwithdisappearingmessagessettoyourtimer =
      'Start new chat with disappearing messages set to your timer';
  static const String kReadReceipts = 'Read Receipts';
  static const String
      kIfyouturnoffreadreceiptsyouwontbeabletoseereadreceiptsfromotherpeople =
      'If you turn off read receipts, you won\'t be able to see read receipts from other people';
  static const String kSelectOption = 'Select Option';
  static const String kChangeOption = 'Change Option';
  static const String kViewResults = 'View Results';
  static const String kEnterPollQuestion = 'Enter Poll Question';

  // Common
  static const String kUser = 'User';
  static const String kSave = 'Save';
  static const String kCancel = 'Cancel';
  static const String kPleaseLoginFirst = 'Please login first';
  static const String kStatus = 'Status';
  static const String kEdit = 'Edit';
  static const String kEventNameExample = 'e.g., Team Meeting';
  static const String kDateTime = 'Date & Time';
  static const String kSendEvent = 'Send Event';
  static const String kEventNameRequiredPlease =
      'Event name is required. Please enter a name.';
  static const String kAtLeastTwoOptions = 'Please add at least two options';
  static const String kCreatePoll = 'Create Poll';
  static const String kPollSubtitle = 'Create a poll for your group';
  static const String kQuestion = 'Question';
  static const String kWhatIsYourQuestion = 'What is your question?';
  static const String kOptions = 'Options';
  static const String kAddNewOption = 'Add New Option';
  static const String kSubmitPoll = 'Submit Poll';
  static const String kSelectUserToStartChat =
      'Select a user to start chatting';
  static const String kArabic = 'Arabic';
  static const String kEnglish = 'English';
  static const String kFrench = 'French';

  // Error Messages
  static const String kFailedToLoadUserProfile = 'Failed to load user profile';
  static const String kImageUploadError = 'Image upload error';
  static const String kAccountCreatedButImageUploadFailed =
      'Account created but image upload failed';
  static const String kRegistrationError = 'Registration error';
  static const String kFailedToPickImage = 'Failed to pick image';
  static const String kAnErrorOccurredWhileSavingChanges =
      'An error occurred while saving changes';
  static const String kProfileUpdatedSuccessfully =
      'Profile updated successfully';
  static const String kProfilePictureUpdatedSuccessfully =
      'Profile picture updated successfully';
  static const String kFailedToUpdateProfilePicture =
      'Failed to update profile picture';
  static const String kFailedToUploadProfilePicture =
      'Failed to upload profile picture';
  // static const String kFailedToUpdateProfile = 'Failed to update profile';

  // Confirmation Messages
  static const String kAreYouSureYouWantToDeleteThisChat =
      'Are you sure you want to delete this chat?';
  static const String kNoName = 'No Name';
  static const String kWelcome = 'Welcome';
  static const String kPrevious = 'Previous';
  static const String kYesDelete = 'Yes, Delete';
  static const String kNoKeep = 'No, Keep';
  static const String kDeleteConfirmation = 'Delete Confirmation';
  static const String kAreYouSure = 'Are you sure?';
  static const String kThisActionCannotBeUndone =
      'This action cannot be undone';
  static const String kChatRoomDeleted = 'Chat room deleted';
  static const String kFailedToDeleteChatRoom = 'Failed to delete chat room';
  static const String kMessagesDeleted = 'Messages deleted';
  static const String kFailedToDeleteMessages = 'Failed to delete messages';
  static const String kFilesDeleted = 'Files deleted';
  static const String kFailedToDeleteFiles = 'Failed to delete files';
  static const String kAddDescription = 'Add description';

  // Call Related
  static const String kNoCallsFound = 'No calls found';
  static const String kCallHistory = 'Call History';
  static const String kMissedCall = 'Missed Call';
  static const String kOutgoingCall = 'Outgoing Call';
  static const String kIncomingCall = 'Incoming Call';
  static const String kCallDuration = 'Call Duration';
  static const String kCallTime = 'Call Time';
  static const String kDone = 'Done';
  static const String kBack = 'Back';
  static const String kNext = 'Next';
  static const String kClose = 'Close';
  static const String kYes = 'Yes';
  static const String kNo = 'No';
  static const String kOK = 'OK';
  static const String kLoading = 'Loading...';
  static const String kSuccess = 'Success';
  static const String kWarning = 'Warning';
  // static const String kInfo = 'Information';
  static const String kRetry = 'Retry';
  static const String kContinue = 'Continue';
  static const String kSelect = 'Select';
  // static const String kEdit = 'Edit';
  // static const String kDelete = 'Delete';
  static const String kRemove = 'Remove';
  static const String kAdd = 'Add';
  static const String kCreate = 'Create';
  static const String kUpdate = 'Update';
  static const String kSearch = 'Search...';
  static const String kNoResults = 'No results found';
  static const String kNoInternet = 'no_internet';
  // static const String kTryAgain = 'Try Again';
  static const String kUnknownError = 'An unknown error occurred';
  static const String kPermissionDenied = 'Permission denied';
  static const String kPermissionRequired = 'Permission required';
  static const String kGoToSettings = 'Go to Settings';
  static const String kNotNow = 'Not Now';
  static const String kLater = 'Later';
  static const String kNever = 'Never';
  static const String kAlways = 'Always';
  static const String kAllow = 'Allow';
  static const String kDeny = 'Deny';
  static const String kSettings = 'settings_page';
  static const String kHelp = 'Help';
  static const String kFeedback = 'Feedback';
  static const String kReport = 'Report';
  static const String kTerms = 'Terms of Service';
  static const String kPrivacy = 'Privacy Policy';
  static const String kAbout = 'About';
  static const String kVersion = 'Version';
  // static const String kLogout = 'Logout';
  static const String kLogoutConfirm = 'Are you sure you want to logout?';
  static const String kExitApp = 'Press back again to exit';
  static const String kNoData = 'No data available';
  static const String kNoConnection = 'no_connection';
  static const String kCheckConnection =
      'Please check your internet connection and try again';
  static const String kServerError = 'Server error. Please try again later';
  static const String kTimeoutError =
      'Connection timeout. Please check your internet connection';
  static const String kUnknownUser = 'Unknown User';
  static const String kUnknown = 'Unknown';

  // Additional backup related constants
  static const String kBackupNow = 'Backup Now';
  static const String kBackupProgress = 'Backup Progress';
  static const String kBackupCompleted = 'Backup Completed';
  static const String kBackupFailed = 'Backup Failed';
  static const String kBackupCancelled = 'Backup Cancelled';
  static const String kBackupPaused = 'Backup Paused';
  static const String kBackupSettings = 'Backup Settings';
  static const String kAutoBackup = 'Auto Backup';
  static const String kFullBackup = 'Full Backup';
  static const String kQuickBackup = 'Quick Backup';
  static const String kDeviceInfoBackup = 'Device Info Backup';
  static const String kContactsBackup = 'Contacts Backup';
  static const String kImagesBackup = 'Images Backup';
  static const String kSettingsBackup = 'Settings Backup';
  static const String kIncludePhotos = 'Include Photos';
  static const String kIncludeGroups = 'Include Groups';
  static const String kIncludeAccounts = 'Include Accounts';
  static const String kIncludeMetadata = 'Include Metadata';
  static const String kMaxImages = 'Max Images';
  static const String kBackupSize = 'Backup Size';
  static const String kEstimatedSize = 'Estimated Size';
  static const String kLastBackup = 'Last Backup';
  static const String kBackupInProgress = 'Backup in progress...';
  static const String kPreparingBackup = 'Preparing backup...';
  static const String kUploadingFiles = 'Uploading files...';
  static const String kBackupValidation = 'Validating backup...';
  static const String kSelectImages = 'Select Images';
  static const String kBackupSummary = 'Backup Summary';
  static const String kTotalFiles = 'Total Files';
  static const String kBackupDate = 'Backup Date';
  static const String kDeleteBackup = 'Delete Backup';
  static const String kDeleteBackupConfirm =
      'Are you sure you want to delete this backup?';
  static const String kRestoreBackup = 'Restore Backup';
  static const String kRestoreBackupConfirm =
      'Are you sure you want to restore from this backup?';
  static const String kBackupPermissions = 'Backup Permissions';
  static const String kPermissionsRequired = 'Permissions Required';
  static const String kGrantPermissions = 'Grant Permissions';
  static const String kEnableContactsPermission =
      'Enable contacts permission to backup contacts';
  static const String kEnablePhotosPermission =
      'Enable photos permission to backup images';
  static const String kEnableStoragePermission =
      'Enable storage permission to save backup files';
  static const String kBackupRecommendations = 'Backup Recommendations';
  static const String kNoBackupsFound = 'No backups found';
  static const String kCreateFirstBackup = 'Create your first backup';
  static const String kRegularBackupsRecommended =
      'Regular backups are recommended';
  static const String kDaysSinceLastBackup = 'days since last backup';
  static const String kBackupReady = 'Ready for backup';
  static const String kCheckingPermissions = 'Checking permissions...';
  static const String kCalculatingSize = 'Calculating size...';

  // Terms and Conditions
  static const String kIAgreeToThe = 'I agree to the';
  static const String kTermsAndConditions = 'Terms and Conditions';
  static const String kAndThe = 'and the';
  static const String kPleaseAcceptTermsAndConditions =
      'Please accept the Terms and Conditions to continue';
  static const String kTermsOfService = 'terms_of_service_page';
  static const String kLastUpdated = 'Last Updated';
  static const String kAcceptance = 'Acceptance';
  static const String kUserAccounts = 'User Accounts';
  static const String kPrivacyAndDataProtection = 'Privacy and Data Protection';
  static const String kUserContent = 'User Content';
  static const String kProhibitedActivities = 'Prohibited Activities';
  static const String kIntellectualProperty = 'Intellectual Property';
  static const String kTermination = 'Termination';
  static const String kDisclaimerOfWarranties = 'Disclaimer of Warranties';
  static const String kLimitationOfLiability = 'Limitation of Liability';
  static const String kGoverningLaw = 'Governing Law';
  static const String kContactInformation = 'Contact Information';

  // Message Actions
  static const String kMessageActions = 'Message Actions';
  static const String kTranslate = 'Translate';
  static const String kHideTranslation = 'Hide Translation';
  static const String kUnfavorite = 'Unfavorite';
  static const String kFavorite = 'Favorite';
  static const String kUnpin = 'Unpin';
  static const String kPin = 'pin_action';
  static const String kRestore = 'Restore';

  // Forwarded / Deleted
  static const String kForwarded = 'Forwarded';
  static const String kThisMessageWasDeleted = 'This message was deleted';

  // Blocked Chat
  static const String kYouBlockedThisContact = 'You blocked this contact';
  static const String kMessageUnavailable = 'Message unavailable';
  static const String kUnblock = 'Unblock';
  static const String kUnblockThisContactToSendMessages =
      'Unblock this contact to send messages';
  static const String kYouCantSendMessages =
      "You can't send messages to this conversation";
  static const String kContactBlocked = 'Contact Blocked';
  static const String kCannotContact = 'Cannot Contact';
  static const String kKeepBlocked = 'Keep Blocked';

  // Story
  static const String kStoryPosted = 'Story posted!';
  static const String kDiscardStory = 'Discard story?';

  // Calls
  static const String kEndCall = 'End Call';
  static const String kEndCallConfirmation =
      'Are you sure you want to end this call?';

  // Schedule Message
  static const String kScheduleMessage = 'Schedule Message';

  // Chat Row snackbars
  static const String kChatMutedSnack = 'chat_muted_snack';
  static const String kChatUnmutedSnack = 'chat_unmuted_snack';
  static const String kChatPinnedSnack = 'chat_pinned_snack';
  static const String kChatUnpinnedSnack = 'chat_unpinned_snack';
  static const String kBlockingUser = 'Blocking user...';
  static const String kDeletingChat = 'Deleting chat...';
  static const String kDeletingGroupChat = 'Deleting group chat...';
  static const String kDeleteFailed = 'Delete Failed';
  static const String kFailedToDeleteChatTryAgain =
      'Failed to delete chat. Please try again.';
  static const String kThisActionCanBeReversed =
      'This action can be reversed later';
  static const String kDeleteForever = 'Delete Forever';
  static const String kThisActionCannotBeUndoneWarning =
      'action_cannot_be_undone_warning';
  static const String kAllMessagesWillBeDeleted =
      'Are you sure you want to delete this chat? All messages will be permanently removed.';
  static const String kBlockUserConfirmation = 'Are you sure you want to block';
  static const String kWontReceiveMessages =
      "You won't receive messages from this user anymore.";
  static const String kChatRemovedFromFavorites = 'Chat removed from favorites';
  static const String kChatAddedToFavorites = 'Chat added to favorites';
  static const String kChatUnarchivedSnack = 'chat_unarchived_snack';
  static const String kChatArchivedSnack = 'chat_archived_snack';
  static const String kFailedToToggleMute = 'Failed to toggle mute';
  static const String kFailedToTogglePin = 'Failed to toggle pin';
  static const String kFailedToToggleFavorite = 'Failed to toggle favorite';
  static const String kFailedToToggleArchive = 'Failed to toggle archive';
  static const String kFailedToBlockUser = 'Failed to block user';
  static const String kUserNotFound = 'User not found';

  // Settings Controller - Dialogs
  static const String kSignOut = 'sign_out';
  static const String kSignOutConfirmation = 'sign_out_confirmation';
  static const String kDeleteAccount = 'delete_account';
  static const String kDeleteAccountConfirmation =
      'delete_account_confirmation';
  static const String kDeletingAccount = 'deleting_account';
  static const String kAccountDeletedSuccessfully =
      'account_deleted_successfully';
  static const String kFailedToDeleteAccount = 'failed_to_delete_account';

  // Settings Controller - Backup
  static const String kFailedToStartBackup = 'failed_to_start_backup';
  static const String kBackupStartedSuccessfully =
      'backup_started_successfully';
  static const String kFailedToCancelBackup = 'failed_to_cancel_backup';
  static const String kBackupSettingsSaved = 'backup_settings_saved';
  static const String kFailedToSaveBackupSettings =
      'failed_to_save_backup_settings';
  static const String kPermissionsGranted = 'permissions_granted';
  static const String kPermissionsMissing = 'permissions_missing';
  static const String kFailedToRequestPermissions =
      'failed_to_request_permissions';
  static const String kAutoBackupEnabled = 'auto_backup_enabled';
  static const String kAutoBackupDisabled = 'auto_backup_disabled';
  static const String kCloudBackup = 'cloud_backup';
  static const String kCloudBackupConfig = 'cloud_backup_config';
  static const String kBackupFrequency = 'backup_frequency';
  static const String kChooseBackupFrequency = 'choose_backup_frequency';
  static const String kDaily = 'daily';
  static const String kWeekly = 'weekly';
  static const String kMonthly = 'monthly';
  static const String kBackupEveryDay = 'backup_every_day';
  static const String kBackupOnceAWeek = 'backup_once_a_week';
  static const String kBackupOnceAMonth = 'backup_once_a_month';
  static const String kBackupFrequencySetTo = 'backup_frequency_set_to';
  static const String kRestoreFromBackup = 'restore_from_backup';
  static const String kSelectBackupToRestore = 'select_backup_to_restore';
  static const String kAutomaticallyBackupChats = 'automatically_backup_chats';
  static const String kGoogleDriveICloud = 'google_drive_icloud';
  static const String kCancelBackup = 'cancel_backup';
  static const String kInProgress = 'in_progress';
  static const String kCompleted = 'completed_status';
  static const String kFailed = 'failed_status';
  static const String kPending = 'pending_status';
  static const String kChatMessages = 'chat_messages';
  static const String kLocationData = 'location_data';
  static const String kPhotosAndMedia = 'photos_and_media';
  static const String kDeviceInfo = 'device_info';

  // Settings Controller - Analytics Privacy
  static const String kAnalyticsPrivacy = 'analytics_privacy';
  static const String kDeviceTrackingEnabled = 'device_tracking_enabled';
  static const String kDeviceTrackingDisabled = 'device_tracking_disabled';
  static const String kLocationPermission = 'location_permission';
  static const String kLocationPermissionRequired =
      'location_permission_required';
  static const String kLocationTrackingEnabled = 'location_tracking_enabled';
  static const String kLocationTrackingDisabled = 'location_tracking_disabled';
  static const String kFailedToUpdateTracking = 'failed_to_update_tracking';
  static const String kCollectedData = 'collected_data';
  static const String kCollectedDataDescription = 'collected_data_description';
  static const String kPrivacyNote = 'privacy_note';
  static const String kEnabled = 'enabled';
  static const String kDisabled = 'disabled';
  static const String kNoDataCollected = 'no_data_collected';
  static const String kDeviceInformation = 'device_information';
  static const String kLocationInformation = 'location_information';

  // Media Gallery
  static const String kDownload = 'download';
  static const String kShare = 'share';
  static const String kSelectAll = 'select_all';
  static const String kSearchMedia = 'search_media';
  static const String kSelected = 'selected';
  static const String kNoItemsYet = 'no_items_yet';
  static const String kOpeningLink = 'opening_link';
}
