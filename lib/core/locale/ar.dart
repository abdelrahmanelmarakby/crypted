import 'package:crypted_app/core/locale/constant.dart';

Map<String, String> ar = {
  // القصص
  Constants.kStories: 'القصص',
  Constants.krecentStories: 'القصص الحديثة',

  // الإعدادات
  Constants.kSetting: 'الإعدادات',
  Constants.kProfile: 'الملف الشخصي',
  Constants.kPrivacy: 'الخصوصية',
  Constants.kNotifications: 'الإشعارات',
  Constants.kBackup: 'النسخ الاحتياطي',
  Constants.kHelp: 'مساعدة',
  Constants.kInviteFriend: 'دعوة صديق',
  Constants.kLogout: 'تسجيل الخروج',
  Constants.kLanguage: 'اللغة',

  // إعادة تعيين كلمة المرور
  Constants.kResetPassword: 'هل نسيت كلمة المرور؟',

  Constants.kNewPassword: 'كلمة مرور جديدة',
  Constants.kEnteryourpassword: 'أدخل كلمة المرور',
  Constants.kReEnterpaswword: 'أعد إدخال كلمة المرور',
  Constants.kSave: 'حفظ',

  // التسجيل
  Constants.kSignUpToCrypted: 'سجّل في Crypted!',
  Constants.kPhoneNumber: 'رقم الهاتف',
  Constants.kEnterYourEmail: 'أدخل بريدك الإلكتروني',
  Constants.kEnterYourPassword: 'أدخل كلمة المرور',
  Constants.kEnterYourFullName: 'أدخل الاسم الكامل',
  Constants.kEnterYourPhone: 'أدخل رقم هاتفك',
  Constants.kEmailRequired: 'البريد الإلكتروني مطلوب',
  Constants.kValidEmail: 'الرجاء إدخال بريد إلكتروني صالح',
  Constants.kPasswordRequired: 'كلمة المرور مطلوبة',
  Constants.kPasswordMinLength: 'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل',
  Constants.kNameRequired: 'الاسم مطلوب',
  Constants.kPhoneRequired: 'رقم الهاتف مطلوب',
  Constants.kFullName: 'الاسم الكامل',
  Constants.kEnteryourfullname: 'أدخل الاسم الكامل',
  Constants.kFullNameisrequired: 'الاسم الكامل مطلوب',
  // Email and password constants are defined above with kEnterYourEmail and kEnterYourPassword
  // Removing duplicates to fix lint errors
  Constants.kPasswordmustbeatleast6characters:
      'يجب أن تكون كلمة المرور 6 أحرف على الأقل',
  Constants.kSignUp: 'إنشاء حساب',
  Constants.kAlreadyHaveAnAccount: 'هل لديك حساب؟',
  Constants.kLogin: 'تسجيل الدخول',
  Constants.kDontHaveAnAccount: 'ليس لديك حساب؟',
  Constants.kSignIn: 'تسجيل الدخول',

  // تسجيل الدخول
  Constants.kLogInToCrypted: 'سجل الدخول إلى Crypted!',
  Constants.kEnteravalidemailaddress: 'أدخل بريدًا إلكترونيًا صحيحًا',
  Constants.kForgetPassword: 'نسيت كلمة المرور؟',
  Constants.kCreateAccount: 'إنشاء حساب',

  // الملف الشخصي
  Constants.kStatus: 'الحالة',
  Constants.kEdit: 'تعديل',

  // OTP
  Constants.kEnterOTP: 'أدخل رمز التحقق',
  Constants.kDidntreceivecode: 'لم يصلك الرمز؟',
  Constants.kResend: 'إعادة الإرسال',
  Constants.ksend: 'ارسال',

  // شريط التنقل
  Constants.kHome: 'الرئيسية',
  Constants.kCalls: 'المكالمات',

  // دعوة صديق
  Constants.kInviteAFriend: 'دعوة صديق',
  Constants.kSearch: 'بحث',
  Constants.kInvitevialink: 'دعوة عبر رابط',
  Constants.kContacts: 'جهات الاتصال',
  Constants.ksharelink: 'مشاركة الرابط',
  Constants.kcopylink: 'نسخ الرابط',
  Constants.klinkedIn: 'لينكدإن',
  Constants.kfacebook: 'فيسبوك',
  Constants.kwhatsApp: 'واتساب',
  Constants.kTelegram: 'تيليجرام',

  // الشاشة الرئيسية
  Constants.kHello: 'مرحباً',
  Constants.kNewMessage: 'رسالة جديدة',
  Constants.kCancel: 'إلغاء',
  Constants.kNoChatsyet: 'لا توجد محادثات بعد',
  Constants.kNewChat: 'انشاء محادثه',
  Constants.kSelectUser: 'اختر صديق',
  Constants.kNousersfound: 'لم يتم العثور على مستخدمين',
  Constants.kAll: 'الكل',
  Constants.kUnread: 'غير المقروءة',
  Constants.kGroups: 'المجموعات',
  Constants.kFavourite: 'المفضلة',

  // المساعدة
  Constants.ksocialmedia: 'وسائل التواصل الاجتماعي',
  Constants.kcontactus: 'اتصل بنا',
  Constants.kMessage: 'رسالة',
  Constants.kEnteryourmessage: 'أدخل رسالتك',

  // المحادثات
  Constants.kChats: 'المحادثات',
  Constants.kInvalidchatparameters: 'بيانات المحادثة غير صالحة',
  Constants.kActivenow: 'نشط الآن',
  Constants.kToday: 'اليوم',
  Constants.kYesterday: 'أمس',
  Constants.kJan: 'يناير',
  Constants.kfep: 'فبراير',
  Constants.kmar: 'مارس',
  Constants.kApr: 'أبريل',
  Constants.kMay: 'مايو',
  Constants.kJun: 'يونيو',
  Constants.kjul: 'يوليو',
  Constants.kAug: 'أغسطس',
  Constants.kSep: 'سبتمبر',
  Constants.kOct: 'أكتوبر',
  Constants.kNov: 'نوفمبر',
  Constants.kDec: 'ديسمبر',
  Constants.kJoin: 'انضمام',
  Constants.kViewVotes: 'عرض التصويتات',
  Constants.kSendamessage: 'إرسال رسالة',
  Constants.kPhotos: 'الصور',
  Constants.kCamera: 'الكاميرا',
  Constants.kLocation: 'الموقع',
  Constants.kPoll: 'استطلاع',
  Constants.kContact: 'جهة اتصال',
  Constants.kDocument: 'مستند',
  Constants.kEvent: 'حدث',
  Constants.kreplay: 'الرد',
  Constants.kforward: 'إعادة التوجيه',
  Constants.kcopy: 'نسخ',
  Constants.kstar: 'تمييز',
  Constants.kpin: 'تثبيت',
  Constants.kreport: 'إبلاغ',
  Constants.kdelete: 'حذف',
  Constants.kDeleteForMe: 'حذف من عندي',
  Constants.kDeleteForEveryone: 'حذف للجميع',
  Constants.kDeleteChatConfirmation: 'حذف المحادثة',
  Constants.kChatDeletedSuccessfully: 'تم حذف المحادثة بنجاح',
  Constants.kTypeamessage: 'اكتب رسالة',

  // المكالمات
  Constants.kInComing: 'الواردة',
  Constants.kUpComing: 'القادمة',

  // اتصال صديق
  Constants.kRinging: 'يرن...',

  // معلومات الاتصال
  Constants.kContactInfo: 'معلومات الاتصال',
  Constants.kContactDetails: 'تفاصيل الاتصال',
  Constants.kmediaLinksdocuments: 'الوسائط، الروابط، المستندات',
  Constants.kstarredmessages: 'الرسائل المميزة',
  Constants.kAddtofavourite: 'إضافة إلى المفضلة',
  Constants.kAddtolist: 'إضافة إلى قائمة',
  Constants.kexportchat: 'تصدير المحادثة',
  Constants.kClearChat: 'مسح المحادثة',
  Constants.knotification: 'الإشعارات',
  Constants.kchattheme: 'سمة المحادثة',
  Constants.kEncryption: 'التشفير',
  Constants.klockchat: 'قفل المحادثة',
  Constants.kDisappearingmessages: 'رسائل مؤقتة',
  Constants.kOff: 'إيقاف',
  Constants.kOn: 'تشغيل',
  Constants.kJustenjoyingthelittlethingsinlife:
      'أستمتع بالأشياء الصغيرة في الحياة.',

  // معلومات المجموعة
  Constants.kGroupInfo: 'معلومات المجموعة',
  Constants.kMembers: 'الأعضاء',
  Constants.kExitgroup: 'مغادرة المجموعة',
  Constants.kReportgroup: 'الإبلاغ عن المجموعة',
  Constants.kExportchat: 'تصدير المحادثة',
  Constants.kAdmin: 'مشرف',

  // الإشعارات
  Constants.kMessagenotification: 'إشعارات الرسائل',
  Constants.kLastSeenOnline: 'آخر ظهور ومتصل الآن',
  Constants.kSound: 'الصوت',
  Constants.kNote: 'ملاحظة',
  Constants.kReactionNotification: 'إشعارات التفاعل',
  Constants.kGroupnotification: 'إشعارات المجموعة',
  Constants.kStatusnotification: 'إشعارات الحالة',
  Constants.kReminders: 'تذكيرات',
  Constants.kGetoccasionalremindersaboutmessageorstatusupdatesyouhaventseen:
      'تلقي تذكيرات عرضية عن الرسائل أو التحديثات التي لم تشاهدها',
  Constants.khomescreennotification: 'إشعارات الشاشة الرئيسية',
  Constants.kShowPreview: 'عرض المعاينة',
  Constants.kresetnotificationsetting: 'إعادة تعيين إعدادات الإشعارات',
  Constants
          .kResetallnotificationsettingsincludingcustomnotificationsettingsforyourchats:
      'إعادة تعيين جميع إعدادات الإشعارات، بما في ذلك الإعدادات المخصصة للمحادثات',

  // الخصوصية
  Constants.kNobody: 'لا أحد',
  Constants.kProfilePicture: 'صورة الملف الشخصي',
  Constants.kExcluded: 'المستبعدون',
  Constants.kAbout: 'حول',
  Constants.kEveryOne: 'الجميع',
  Constants.kMyContacts: 'جهات الاتصال',
  Constants.kLiveLocation: 'الموقع المباشر',
  Constants.kNone: 'لا شيء',
  Constants.kListofchatswhereyouaresharingyourlivelocation:
      'قائمة المحادثات التي تشارك بها موقعك المباشر',
  Constants.kBlocked: 'المحظورون',
  Constants.kListofcontactsyouhaveblocked: 'قائمة جهات الاتصال المحظورة',
  Constants.kDisappearingMessages: 'رسائل مؤقتة',
  Constants.kDefaultMessageTimer: 'المؤقت الافتراضي للرسائل',
  Constants.kStartnewchatwithdisappearingmessagessettoyourtimer:
      'بدء محادثة جديدة برسائل مؤقتة وفقًا للمؤقت المحدد',
  Constants.kReadReceipts: 'إيصالات القراءة',
  Constants
          .kIfyouturnoffreadreceiptsyouwontbeabletoseereadreceiptsfromotherpeople:
      'إيصالات القراءة يتم إرسالها دائمًا في المحادثات الجماعية. إذا أوقفت إيصالات القراءة، لن تتمكن من رؤية إيصالات القراءة من الآخرين.',

  Constants.kAppLock: 'قفل التطبيق',
  Constants.kRequireFaceIDtounlockCrypted: 'يتطلب Face ID لفتح Crypted',
  Constants.kChatLock: 'قفل المحادثة',
  Constants.kAllowCameraEffects: 'السماح بتأثيرات الكاميرا',
  Constants.kUseeffectsinthecameraandvideocalls:
      'استخدم التأثيرات في الكاميرا ومكالمات الفيديو.',
  Constants.kLearnmore: 'اعرف المزيد',
  Constants.kAdvanced: 'متقدم',
  Constants.kPrivacyCheckup: 'مراجعة الخصوصية',

  Constants.kDescription: 'الوصف',
  Constants.kTomorrow: 'غدًا',
  Constants.kHours: 'ساعة',
  Constants.kMinutes: 'دقيقة',
  Constants.kAgo: 'منذ',
  Constants.kNow: 'الآن',
  Constants.kDate: 'التاريخ',
  Constants.kTime: 'الوقت',
  Constants.kDetails: 'التفاصيل',
  Constants.kEventName: 'اسم الحدث',
  Constants.kEventNameisrequired: 'اسم الحدث مطلوب',
  Constants.kEventNameExample: 'مثال: اجتماع فريق العمل',
  Constants.kAddDescription: 'أضف وصفاً للحدث...',
  Constants.kDateTime: 'التاريخ والوقت',
  Constants.kSendEvent: 'إرسال الحدث',
  Constants.kEventNameRequiredPlease: 'يرجى إدخال عنوان الحدث',
///////////////////////////////////////////////////////////
  ///poll
  Constants.kSelectOption: 'اختر خيارًا',
  Constants.kChangeOption: 'غير الخيار',
  Constants.kViewResults: 'عرض النتائج',
  Constants.kEnterPollQuestion: 'يرجى إدخال سؤال الاستطلاع',
  Constants.kAtLeastTwoOptions: 'يجب إضافة خيارين على الأقل',
  Constants.kCreatePoll: 'إنشاء استطلاع رأي',
  Constants.kPollSubtitle: 'اطرح سؤالاً واحصل على آراء الآخرين',
  Constants.kQuestion: 'السؤال',
  Constants.kWhatIsYourQuestion: 'ما هو سؤالك؟',
  Constants.kOptions: 'الخيارات',
  Constants.kAddNewOption: 'إضافة خيار جديد',
  Constants.kSubmitPoll: 'إرسال الاستطلاع',

  Constants.kSelectUserToStartChat: 'اختر المستخدم الذي تريد بدء محادثة معه',

  Constants.kArabic: 'عربي',
  Constants.kEnglish: 'إنجليزي',

  // Common
  Constants.kUser: 'المستخدم',
  Constants.kError: 'خطأ',
  Constants.kSuccess: 'نجح',
  Constants.kPleaseLoginFirst: 'يرجى تسجيل الدخول أولاً',
  Constants.kFailedToLoadUserProfile: 'فشل في تحميل ملف المستخدم',
  Constants.kImageUploadError: 'خطأ في رفع الصورة',
  Constants.kAccountCreatedButImageUploadFailed:
      'تم إنشاء الحساب، لكن حدث خطأ أثناء رفع الصورة',
  Constants.kRegistrationError: 'خطأ في التسجيل',
  Constants.kFailedToPickImage: 'فشل في اختيار الصورة',
  Constants.kFailedToUpdateProfile: 'فشل في تحديث الملف الشخصي',
  Constants.kAnErrorOccurredWhileSavingChanges: 'حدث خطأ أثناء حفظ التغييرات',
  Constants.kProfileUpdatedSuccessfully: 'تم تحديث الملف الشخصي بنجاح',
  Constants.kProfilePictureUpdatedSuccessfully:
      'تم تحديث صورة الملف الشخصي بنجاح',
  Constants.kFailedToUpdateProfilePicture: 'فشل في تحديث صورة الملف الشخصي',
  Constants.kFailedToUploadProfilePicture: 'فشل في رفع صورة الملف الشخصي',
  Constants.kChatDeletedSuccessfully: 'تم حذف المحادثة بنجاح',
  Constants.kFailedToDeleteChat: 'فشل في حذف المحادثة',
  Constants.kDeleteChat: 'حذف المحادثة',
  Constants.kAreYouSureYouWantToDeleteThisChat:
      'هل أنت متأكد من حذف هذه المحادثة؟',
  Constants.kYes: 'نعم',
  Constants.kNo: 'لا',
  Constants.kNoName: 'بدون اسم',
  Constants.kWelcome: 'مرحباً',
  Constants.kLoading: 'جاري التحميل...',
  Constants.kNoMessages: 'لا توجد رسائل',
  Constants.kTypeAMessage: 'اكتب رسالة...',
  Constants.kClose: 'إغلاق',
  Constants.kBack: 'رجوع',
  Constants.kNext: 'التالي',
  Constants.kPrevious: 'السابق',
  Constants.kDone: 'تم',
  Constants.kOK: 'موافق',
  Constants.kYesDelete: 'نعم، احذف',
  Constants.kNoKeep: 'لا، احتفظ',
  Constants.kDeleteConfirmation: 'تأكيد الحذف',
  Constants.kAreYouSure: 'هل أنت متأكد؟',
  Constants.kThisActionCannotBeUndone: 'لا يمكن التراجع عن هذا الإجراء.',
  Constants.kChatRoomDeleted: 'تم حذف غرفة المحادثة بنجاح',
  Constants.kFailedToDeleteChatRoom: 'فشل في حذف غرفة المحادثة',
  Constants.kMessagesDeleted: 'تم حذف الرسائل بنجاح',
  Constants.kFailedToDeleteMessages: 'فشل في حذف الرسائل',
  Constants.kFilesDeleted: 'تم حذف الملفات بنجاح',
  Constants.kFailedToDeleteFiles: 'فشل في حذف الملفات',

  // Calls
  Constants.kNoCallsFound: 'لا توجد مكالمات',
  Constants.kCallHistory: 'سجل المكالمات',
  Constants.kMissedCall: 'مكالمة فائتة',
  Constants.kOutgoingCall: 'مكالمة صادرة',
  Constants.kIncomingCall: 'مكالمة واردة',
  Constants.kCallDuration: 'مدة المكالمة',
  Constants.kCallTime: 'وقت المكالمة',
  'missed': 'مفقودة',

  // Chat Row Dialog
  Constants.kDeleteChatConfirmation: 'تأكيد حذف المحادثة',
  Constants.kAreYouSureToDeleteThisChat:
      'هل أنت متأكد من حذف هذه المحادثة؟ لا يمكن التراجع عن هذا الإجراء.',
  Constants.kDelete: 'حذف',
  'failed_to_pick_video': 'فشل في اختيار الفيديو',
  'failed_to_take_photo': 'فشل في التقاط الصورة',
  'please_select_content': 'يرجى اختيار محتوى للقصة',
  'story_uploaded_successfully': 'تم رفع القصة بنجاح',
  'failed_to_upload_story': 'فشل في رفع القصة',
  'story_deleted_successfully': 'تم حذف القصة بنجاح',
  'failed_to_delete_story': 'فشل في حذف القصة',
  'add_story': 'إضافة قصة',
  'story_text': 'نص القصة',
  'story_background': 'خلفية القصة',
  'story_text_color': 'لون نص القصة',
  'story_font_size': 'حجم الخط',
  'story_text_position': 'موضع النص',
  
  // Chat Actions
  Constants.kChatMuted: 'تم كتم المحادثة',
  Constants.kChatUnmuted: 'تم إلغاء كتم المحادثة',
  Constants.kMuteChat: 'كتم المحادثة',
  Constants.kUnmuteChat: 'إلغاء كتم المحادثة',
  Constants.kAddToFavorites: 'إضافة إلى المفضلة',
  Constants.kRemoveFromFavorites: 'إزالة من المفضلة',
  Constants.kArchiveChat: 'أرشفة المحادثة',
  Constants.kBlockUser: 'حظر المستخدم',
  Constants.kUnblockUser: 'إلغاء حظر المستخدم',
  
  // Status Messages
  Constants.kMessageBlocked: 'لا يمكنك إرسال رسائل إلى هذا المستخدم',
  
  // Confirmation Messages
  Constants.kAreYouSureToClearThisChat: 'هل أنت متأكد من مسح هذه المحادثة؟ سيتم حذف جميع الرسائل.',
  Constants.kAreYouSureToBlockThisUser: 'هل أنت متأكد من حظر هذا المستخدم؟ لن تستلم رسائله بعد الآن.',
  Constants.kAreYouSureToUnblockThisUser: 'هل أنت متأكد من إلغاء حظر هذا المستخدم؟',
  
  // Success Messages
  Constants.kAddedToFavorites: 'تمت الإضافة إلى المفضلة',
  Constants.kRemovedFromFavorites: 'تمت الإزالة من المفضلة',
  Constants.kChatArchived: 'تمت أرشفة المحادثة',
  Constants.kChatClearedSuccessfully: 'تم مسح المحادثة بنجاح',
  Constants.kUserBlocked: 'تم حظر المستخدم',
  Constants.kUserUnblocked: 'تم إلغاء حظر المستخدم',
  
  // Error Messages
  Constants.kFailedToUpdateFavorite: 'فشل تحديث حالة المفضلة',
  Constants.kFailedToUpdateMute: 'فشل تحديث حالة الكتم',
  Constants.kFailedToUpdateBlock: 'فشل تحديث حالة الحظر',
  Constants.kFailedToArchiveChat: 'فشل في أرشفة المحادثة',
  Constants.kFailedToClearChat: 'فشل في مسح المحادثة',
  Constants.kCreateNewEvent: 'أدخل تفاصيل الحدث',
  Constants.kCreatePoll: 'إنشاء استطلاع رأي',
};
