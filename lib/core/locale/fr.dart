import 'package:crypted_app/core/locale/constant.dart';

Map<String, String> fr = {
  // Les histoires
  Constants.kStories: 'Stories',
  Constants.krecentStories: 'Stories recentes',

  // Parametres
  Constants.kSetting: 'Parametres',
  Constants.kProfile: 'Profil',
  Constants.kPrivacy: 'Confidentialite',
  Constants.kNotifications: 'Notifications',
  Constants.kBackup: 'Sauvegarde',
  Constants.kHelp: 'Aide',
  Constants.kInviteFriend: 'Inviter un ami',
  Constants.kLogout: 'Deconnexion',
  Constants.kLanguage: 'Langue',

  // Reinitialisation du mot de passe
  Constants.kResetPassword: 'Mot de passe oublie ?',
  Constants.kNewPassword: 'Nouveau mot de passe',
  Constants.kEnteryourpassword: 'Entrez votre mot de passe',
  Constants.kReEnterpaswword: 'Ressaisissez le mot de passe',
  Constants.kSave: 'Enregistrer',

  // Inscription
  Constants.kSignUpToCrypted: 'Inscrivez-vous sur Crypted !',
  Constants.kPhoneNumber: 'Numero de telephone',
  // kEnterYourEmail, kEnterYourPassword, kEnterYourFullName share key values
  // with kEnteryouremail, kEnteryourpassword, kEnteryourfullname -- keep one
  Constants.kEnterYourPhone: 'Entrez votre numero de telephone',
  Constants.kEmailRequired: 'L\'e-mail est requis',
  Constants.kValidEmail: 'Veuillez entrer un e-mail valide',
  Constants.kPasswordRequired: 'Le mot de passe est requis',
  Constants.kPasswordMinLength:
      'Le mot de passe doit comporter au moins 6 caracteres',
  Constants.kNameRequired: 'Le nom est requis',
  Constants.kPhoneRequired: 'Le numero de telephone est requis',
  Constants.kFullName: 'Nom complet',
  Constants.kEmail: 'E-mail',
  Constants.kPassword: 'Mot de passe',
  // kEnteryourfullname, kEnteryouremail, kEmailisrequired, kPasswordisrequired,
  // kPasswordmustbeatleast6characters share same key values as above -- omitted
  Constants.kEnteravalidemailaddress: 'Entrez une adresse e-mail valide',
  Constants.kFullNameisrequired: 'Le nom complet est requis',
  Constants.kEnteravalidemail: 'Entrez un e-mail valide',
  Constants.kSignUp: 'S\'inscrire',
  Constants.kAlreadyHaveAnAccount: 'Vous avez deja un compte ?',
  Constants.kLogin: 'Connexion',
  Constants.kDontHaveAnAccount: 'Vous n\'avez pas de compte ?',
  Constants.kSignIn: 'Se connecter',
  Constants.kLoginHere: 'Connectez-vous ici',
  Constants.kCreateAccount: 'Creer un compte',

  // Connexion
  Constants.kLogInToCrypted: 'Connectez-vous a Crypted !',
  Constants.kForgetPassword: 'Mot de passe oublie ?',

  // Profil
  Constants.kStatus: 'Statut',
  Constants.kEdit: 'Modifier',

  // OTP
  Constants.kEnterOTP: 'Entrez le code OTP',
  Constants.kDidntreceivecode: 'Vous n\'avez pas recu le code ?',
  Constants.kResend: 'Renvoyer',
  Constants.ksend: 'Envoyer',

  // Barre de navigation
  Constants.kHome: 'Accueil',
  Constants.kCalls: 'Appels',

  // Inviter un ami
  Constants.kInviteAFriend: 'Inviter un ami',
  Constants.kSearch: 'Rechercher...',
  Constants.kInvitevialink: 'Inviter via un lien',
  Constants.kContacts: 'Contacts',
  Constants.ksharelink: 'Partager le lien',
  Constants.kcopylink: 'Copier le lien',
  Constants.klinkedIn: 'LinkedIn',
  Constants.kfacebook: 'Facebook',
  Constants.kwhatsApp: 'WhatsApp',
  Constants.kTelegram: 'Telegram',

  // Ecran d'accueil
  Constants.kHello: 'Bonjour',
  Constants.kNewMessage: 'Nouveau message',
  Constants.kCancel: 'Annuler',
  Constants.kNoChatsyet: 'Aucune conversation',
  Constants.kNewChat: 'Nouvelle conversation',
  Constants.kSelectUser: 'Selectionner un ami',
  Constants.kNousersfound: 'Aucun utilisateur trouve',
  Constants.kAll: 'Tous',
  Constants.kUnread: 'Non lus',
  Constants.kGroups: 'Groupes',
  Constants.kFavourite: 'Favoris',

  // Aide
  Constants.ksocialmedia: 'Reseaux sociaux',
  Constants.kcontactus: 'Contactez-nous',
  Constants.kMessage: 'Message',
  Constants.kEnteryourmessage: 'Entrez votre message',

  // Conversations
  Constants.kChats: 'Conversations',
  Constants.kInvalidchatparameters: 'Parametres de conversation invalides',
  Constants.kActivenow: 'En ligne',
  Constants.kToday: 'Aujourd\'hui',
  Constants.kYesterday: 'Hier',
  Constants.kJan: 'Janvier',
  Constants.kfep: 'Fevrier',
  Constants.kmar: 'Mars',
  Constants.kApr: 'Avril',
  Constants.kMay: 'Mai',
  Constants.kJun: 'Juin',
  Constants.kjul: 'Juillet',
  Constants.kAug: 'Aout',
  Constants.kSep: 'Septembre',
  Constants.kOct: 'Octobre',
  Constants.kNov: 'Novembre',
  Constants.kDec: 'Decembre',
  Constants.kJoin: 'Rejoindre',
  Constants.kViewVotes: 'Voir les votes',
  Constants.kSendamessage: 'Envoyer un message',
  Constants.kPhotos: 'Photos',
  Constants.kCamera: 'Camera',
  Constants.kLocation: 'Localisation',
  Constants.kPoll: 'Sondage',
  Constants.kContact: 'Contact',
  Constants.kDocument: 'Document',
  Constants.kEvent: 'Evenement',
  Constants.kreplay: 'Repondre',
  Constants.kforward: 'Transferer',
  Constants.kcopy: 'Copier',
  Constants.kstar: 'Favori',
  Constants.kpin: 'Epingler',
  Constants.kreport: 'Signaler',
  Constants.kdelete: 'Supprimer',
  Constants.kDeleteForMe: 'Supprimer pour moi',
  Constants.kDeleteForEveryone: 'Supprimer pour tous',
  Constants.kDeleteChatConfirmation: 'Confirmation de suppression',
  Constants.kChatDeletedSuccessfully: 'Conversation supprimee avec succes',
  Constants.kTypeamessage: 'Ecrire un message',

  // Chat (additional keys not covered above)
  Constants.kStartConversation: 'Commencer une conversation',
  Constants.kArchived: 'Archives',
  Constants.kSearchChats: 'Rechercher des conversations...',
  Constants.kOnline: 'En ligne',
  Constants.kOffline: 'Hors ligne',
  Constants.kTyping: 'en train d\'ecrire...',
  // kSend, kReply, kForward, kCopy, kDelete share key values with ksend, kreplay, kforward, kcopy, kdelete
  Constants.kInfo: 'Info',
  Constants.kMedia: 'Medias',
  Constants.kDocuments: 'Documents',
  Constants.kLinks: 'Liens',
  Constants.kVoiceMessages: 'Messages vocaux',
  Constants.kNoMedia: 'Aucun media partage',
  Constants.kNoDocuments: 'Aucun document partage',
  Constants.kNoLinks: 'Aucun lien partage',
  Constants.kNoVoiceMessages: 'Aucun message vocal',
  Constants.kNoMessages: 'Aucun message',
  // kNoChats shares key value with kNoChatsyet
  Constants.kTypeAMessage: 'Ecrire un message...',

  // Appels
  Constants.kInComing: 'Entrants',
  Constants.kUpComing: 'A venir',
  Constants.kRinging: 'Appel en cours...',

  // Informations du contact
  Constants.kContactInfo: 'Infos du contact',
  Constants.kContactDetails: 'Details du contact',
  Constants.kmediaLinksdocuments: 'Medias, liens et documents',
  Constants.kstarredmessages: 'Messages favoris',
  Constants.kAddtofavourite: 'Ajouter aux favoris',
  Constants.kAddtolist: 'Ajouter a une liste',
  Constants.kexportchat: 'Exporter la conversation',
  Constants.kClearChat: 'Effacer la conversation',
  // knotification shares key value with kNotifications above
  Constants.kchattheme: 'Theme de conversation',
  Constants.kEncryption: 'Chiffrement',
  Constants.klockchat: 'Verrouiller la conversation',
  // kDisappearingmessages shares key value with kDisappearingMessages below
  Constants.kOff: 'Desactive',
  Constants.kOn: 'Active',
  Constants.kJustenjoyingthelittlethingsinlife:
      'Je profite des petites choses de la vie.',

  // Informations du groupe
  Constants.kGroupInfo: 'Infos du groupe',
  Constants.kMembers: 'Membres',
  Constants.kExitgroup: 'Quitter le groupe',
  Constants.kReportgroup: 'Signaler le groupe',
  // kExportchat shares key value with kexportchat above
  Constants.kAdmin: 'Admin',

  // Notifications
  Constants.kMessagenotification: 'Notifications de messages',
  Constants.kLastSeenOnline: 'Derniere connexion',
  Constants.kSound: 'Son',
  Constants.kNote: 'Note',
  Constants.kReactionNotification: 'Notifications de reactions',
  Constants.kGroupnotification: 'Notifications de groupe',
  Constants.kStatusnotification: 'Notifications de statut',
  Constants.kReminders: 'Rappels',
  Constants.kGetoccasionalremindersaboutmessageorstatusupdatesyouhaventseen:
      'Recevoir des rappels occasionnels sur les messages ou mises a jour non vus',
  Constants.khomescreennotification: 'Notifications sur l\'ecran d\'accueil',
  Constants.kShowPreview: 'Afficher l\'apercu',
  Constants.kresetnotificationsetting:
      'Reinitialiser les parametres de notification',
  Constants
          .kResetallnotificationsettingsincludingcustomnotificationsettingsforyourchats:
      'Reinitialiser tous les parametres de notification, y compris les parametres personnalises de vos conversations',

  // Confidentialite
  Constants.kNobody: 'Personne',
  Constants.kProfilePicture: 'Photo de profil',
  Constants.kExcluded: 'Exclus',
  Constants.kAbout: 'A propos',
  Constants.kEveryOne: 'Tout le monde',
  Constants.kMyContacts: 'Mes contacts',
  Constants.kLiveLocation: 'Position en direct',
  Constants.kNone: 'Aucun',
  Constants.kListofchatswhereyouaresharingyourlivelocation:
      'Liste des conversations ou vous partagez votre position en direct',
  Constants.kBlocked: 'Bloques',
  Constants.kListofcontactsyouhaveblocked:
      'Liste des contacts que vous avez bloques',
  Constants.kDisappearingMessages: 'Messages ephemeres',
  Constants.kDefaultMessageTimer: 'Minuterie par defaut des messages',
  Constants.kStartnewchatwithdisappearingmessagessettoyourtimer:
      'Demarrer une nouvelle conversation avec des messages ephemeres definis selon votre minuterie',
  Constants.kReadReceipts: 'Accuses de lecture',
  Constants
          .kIfyouturnoffreadreceiptsyouwontbeabletoseereadreceiptsfromotherpeople:
      'Si vous desactivez les accuses de lecture, vous ne pourrez pas voir ceux des autres. Les accuses de lecture sont toujours envoyes dans les conversations de groupe.',

  Constants.kAppLock: 'Verrouillage de l\'appli',
  Constants.kRequireFaceIDtounlockCrypted:
      'Exiger Face ID pour deverrouiller Crypted',
  Constants.kChatLock: 'Verrouillage de conversation',
  Constants.kAllowCameraEffects: 'Autoriser les effets camera',
  Constants.kUseeffectsinthecameraandvideocalls:
      'Utiliser les effets dans la camera et les appels video.',
  Constants.kLearnmore: 'En savoir plus',
  Constants.kAdvanced: 'Avance',
  Constants.kPrivacyCheckup: 'Verification de confidentialite',

  Constants.kDescription: 'Description',
  Constants.kTomorrow: 'Demain',
  Constants.kHours: 'Heures',
  Constants.kMinutes: 'Minutes',
  Constants.kAgo: 'Il y a',
  Constants.kNow: 'Maintenant',
  Constants.kDate: 'Date',
  Constants.kTime: 'Heure',
  Constants.kDetails: 'Details',
  Constants.kEventName: 'Nom de l\'evenement',
  Constants.kEventNameisrequired: 'Le nom de l\'evenement est requis',
  Constants.kEventNameExample: 'Ex : Reunion d\'equipe',
  Constants.kAddDescription: 'Ajouter une description',
  Constants.kDateTime: 'Date et heure',
  Constants.kSendEvent: 'Envoyer l\'evenement',
  Constants.kEventNameRequiredPlease:
      'Veuillez entrer le titre de l\'evenement',
  Constants.kCreateNewEvent: 'Saisissez les details de l\'evenement',

  // Sondage
  Constants.kSelectOption: 'Selectionner une option',
  Constants.kChangeOption: 'Changer l\'option',
  Constants.kViewResults: 'Voir les resultats',
  Constants.kEnterPollQuestion: 'Veuillez entrer la question du sondage',
  Constants.kAtLeastTwoOptions: 'Veuillez ajouter au moins deux options',
  Constants.kCreatePoll: 'Creer un sondage',
  Constants.kPollSubtitle: 'Posez une question et obtenez des avis',
  Constants.kQuestion: 'Question',
  Constants.kWhatIsYourQuestion: 'Quelle est votre question ?',
  Constants.kOptions: 'Options',
  Constants.kAddNewOption: 'Ajouter une option',
  Constants.kSubmitPoll: 'Soumettre le sondage',

  Constants.kSelectUserToStartChat:
      'Selectionnez l\'utilisateur avec qui commencer une conversation',

  Constants.kArabic: 'Arabe',
  Constants.kEnglish: 'Anglais',
  Constants.kFrench: 'Francais',

  // Commun
  Constants.kUser: 'Utilisateur',
  Constants.kError: 'Erreur',
  Constants.kSuccess: 'Succes',
  Constants.kPleaseLoginFirst: 'Veuillez vous connecter d\'abord',
  Constants.kFailedToLoadUserProfile:
      'Echec du chargement du profil utilisateur',
  Constants.kImageUploadError: 'Erreur de telechargement d\'image',
  Constants.kAccountCreatedButImageUploadFailed:
      'Compte cree, mais le telechargement de l\'image a echoue',
  Constants.kRegistrationError: 'Erreur d\'inscription',
  Constants.kFailedToPickImage: 'Echec de la selection de l\'image',
  Constants.kFailedToUpdateProfile: 'Echec de la mise a jour du profil',
  Constants.kAnErrorOccurredWhileSavingChanges:
      'Une erreur est survenue lors de l\'enregistrement',
  Constants.kProfileUpdatedSuccessfully: 'Profil mis a jour avec succes',
  Constants.kProfilePictureUpdatedSuccessfully:
      'Photo de profil mise a jour avec succes',
  Constants.kFailedToUpdateProfilePicture:
      'Echec de la mise a jour de la photo de profil',
  Constants.kFailedToUploadProfilePicture:
      'Echec du telechargement de la photo de profil',
  // kChatDeletedSuccessfully, kDeleteChat already defined earlier
  Constants.kFailedToDeleteChat: 'Echec de la suppression de la conversation',
  Constants.kAreYouSureYouWantToDeleteThisChat:
      'Etes-vous sur de vouloir supprimer cette conversation ?',
  Constants.kYes: 'Oui',
  Constants.kNo: 'Non',
  Constants.kNoName: 'Sans nom',
  Constants.kWelcome: 'Bienvenue',
  Constants.kLoading: 'Chargement...',
  Constants.kClose: 'Fermer',
  Constants.kBack: 'Retour',
  Constants.kNext: 'Suivant',
  Constants.kPrevious: 'Precedent',
  Constants.kDone: 'Termine',
  Constants.kOK: 'OK',
  Constants.kYesDelete: 'Oui, supprimer',
  Constants.kNoKeep: 'Non, garder',
  Constants.kDeleteConfirmation: 'Confirmation de suppression',
  Constants.kAreYouSure: 'Etes-vous sur ?',
  Constants.kThisActionCannotBeUndone: 'Cette action est irreversible.',
  Constants.kChatRoomDeleted: 'Salon de discussion supprime',
  Constants.kFailedToDeleteChatRoom:
      'Echec de la suppression du salon de discussion',
  Constants.kMessagesDeleted: 'Messages supprimes',
  Constants.kFailedToDeleteMessages: 'Echec de la suppression des messages',
  Constants.kFilesDeleted: 'Fichiers supprimes',
  Constants.kFailedToDeleteFiles: 'Echec de la suppression des fichiers',

  // Appels
  Constants.kNoCallsFound: 'Aucun appel trouve',
  Constants.kCallHistory: 'Historique des appels',
  Constants.kMissedCall: 'Appel manque',
  Constants.kOutgoingCall: 'Appel sortant',
  Constants.kIncomingCall: 'Appel entrant',
  Constants.kCallDuration: 'Duree de l\'appel',
  Constants.kCallTime: 'Heure de l\'appel',
  'missed': 'Manque',

  // Dialogue de ligne de chat
  Constants.kAreYouSureToDeleteThisChat:
      'Etes-vous sur de vouloir supprimer cette conversation ? Cette action est irreversible.',
  Constants.kAreYouSureToClearThisChat:
      'Etes-vous sur de vouloir effacer cette conversation ? Tous les messages seront supprimes.',
  Constants.kAreYouSureToBlockThisUser:
      'Etes-vous sur de vouloir bloquer cet utilisateur ? Vous ne recevrez plus ses messages.',
  Constants.kAreYouSureToUnblockThisUser:
      'Etes-vous sur de vouloir debloquer cet utilisateur ?',
  Constants.kAreYouSureToDeleteThisMessage:
      'Etes-vous sur de vouloir supprimer ce message ?',

  'failed_to_pick_video': 'Echec de la selection de la video',
  'failed_to_take_photo': 'Echec de la prise de photo',
  'please_select_content': 'Veuillez selectionner un contenu pour la story',
  'story_uploaded_successfully': 'Story publiee avec succes',
  'failed_to_upload_story': 'Echec de la publication de la story',
  'story_deleted_successfully': 'Story supprimee avec succes',
  'failed_to_delete_story': 'Echec de la suppression de la story',
  'add_story': 'Ajouter une story',
  'story_text': 'Texte de la story',
  'story_background': 'Arriere-plan de la story',
  'story_text_color': 'Couleur du texte de la story',
  'story_font_size': 'Taille de police',
  'story_text_position': 'Position du texte',

  // Actions de chat
  Constants.kChatMuted: 'Conversation mise en sourdine',
  Constants.kChatUnmuted: 'Sourdine desactivee',
  Constants.kMuteChat: 'Mettre en sourdine',
  Constants.kUnmuteChat: 'Desactiver la sourdine',
  Constants.kAddToFavorites: 'Ajouter aux favoris',
  Constants.kRemoveFromFavorites: 'Retirer des favoris',
  Constants.kArchiveChat: 'Archiver la conversation',
  Constants.kUnarchiveChat: 'Desarchiver la conversation',
  Constants.kBlockUser: 'Bloquer l\'utilisateur',
  Constants.kUnblockUser: 'Debloquer l\'utilisateur',
  Constants.kMarkAsRead: 'Marquer comme lu',
  Constants.kMarkAsUnread: 'Marquer comme non lu',
  Constants.kPinChat: 'Epingler la conversation',
  Constants.kUnpinChat: 'Desepingler la conversation',

  // Messages de statut
  Constants.kMessageBlocked:
      'Vous ne pouvez pas envoyer de messages a cet utilisateur',
  Constants.kNew: 'Nouveau',
  Constants.kThisWeek: 'Cette semaine',
  Constants.kOlder: 'Plus ancien',
  Constants.kJustNow: 'A l\'instant',
  Constants.kMinutesAgo: 'minutes',
  Constants.kHoursAgo: 'heures',
  Constants.kDaysAgo: 'jours',

  // Messages de succes
  Constants.kAddedToFavorites: 'Ajoute aux favoris',
  Constants.kRemovedFromFavorites: 'Retire des favoris',
  Constants.kChatArchived: 'Conversation archivee',
  Constants.kChatUnarchived: 'Conversation desarchivee',
  Constants.kChatClearedSuccessfully: 'Conversation effacee avec succes',
  Constants.kUserBlocked: 'Utilisateur bloque',
  Constants.kUserUnblocked: 'Utilisateur debloque',
  Constants.kMessageDeleted: 'Message supprime',
  Constants.kChatPinned: 'Conversation epinglee',
  Constants.kChatUnpinned: 'Conversation desepinglee',

  // Messages d'erreur
  Constants.kSomethingWentWrong: 'Une erreur est survenue',
  Constants.kNoInternetConnection: 'Pas de connexion Internet',
  Constants.kTryAgain: 'Veuillez reessayer',
  Constants.kFailedToUpdateFavorite: 'Echec de la mise a jour du statut favori',
  Constants.kFailedToUpdateMute: 'Echec de la mise a jour du statut sourdine',
  Constants.kFailedToUpdateBlock:
      'Echec de la mise a jour du statut de blocage',
  Constants.kFailedToArchiveChat: 'Echec de l\'archivage de la conversation',
  Constants.kFailedToClearChat: 'Echec de l\'effacement de la conversation',
  Constants.kFailedToSendMessage: 'Echec de l\'envoi du message',
  Constants.kFailedToLoadMessages: 'Echec du chargement des messages',
  Constants.kFailedToLoadChats: 'Echec du chargement des conversations',
  Constants.kFailedToLoadUsers: 'Echec du chargement des utilisateurs',
  Constants.kFailedToLoadProfile: 'Echec du chargement du profil',
  Constants.kFailedToUploadFile: 'Echec du telechargement du fichier',
  Constants.kFileTooLarge: 'Le fichier est trop volumineux',
  Constants.kUnsupportedFileType: 'Type de fichier non pris en charge',

  // Interface utilisateur commune
  Constants.kWarning: 'Avertissement',
  Constants.kRetry: 'Reessayer',
  Constants.kContinue: 'Continuer',
  Constants.kSelect: 'Selectionner',
  Constants.kRemove: 'Supprimer',
  Constants.kAdd: 'Ajouter',
  Constants.kCreate: 'Creer',
  Constants.kUpdate: 'Mettre a jour',
  Constants.kNoResults: 'Aucun resultat trouve',
  // kNoInternet shares key value with kNoInternetConnection/kNoConnection
  Constants.kUnknownError: 'Une erreur inconnue est survenue',
  Constants.kPermissionDenied: 'Permission refusee',
  Constants.kPermissionRequired: 'Permission requise',
  Constants.kGoToSettings: 'Aller aux parametres',
  Constants.kNotNow: 'Pas maintenant',
  Constants.kLater: 'Plus tard',
  Constants.kNever: 'Jamais',
  Constants.kAlways: 'Toujours',
  Constants.kAllow: 'Autoriser',
  Constants.kDeny: 'Refuser',
  // kSettings shares key value with kSetting above
  Constants.kFeedback: 'Commentaires',
  // kReport shares key value with kreport above
  Constants.kTerms: 'Conditions d\'utilisation',
  // kAbout already defined in Privacy section above
  Constants.kVersion: 'Version',
  Constants.kLogoutConfirm: 'Etes-vous sur de vouloir vous deconnecter ?',
  Constants.kExitApp: 'Appuyez a nouveau pour quitter',
  Constants.kNoData: 'Aucune donnee disponible',
  // kNoConnection shares key value with kNoInternetConnection
  Constants.kCheckConnection:
      'Veuillez verifier votre connexion Internet et reessayer',
  Constants.kServerError: 'Erreur serveur. Veuillez reessayer plus tard',
  Constants.kTimeoutError:
      'Delai de connexion depasse. Verifiez votre connexion Internet',
  Constants.kUnknownUser: 'Utilisateur inconnu',
  Constants.kUnknown: 'Inconnu',

  // Sauvegarde
  Constants.kBackupNow: 'Sauvegarder maintenant',
  Constants.kBackupProgress: 'Progression de la sauvegarde',
  Constants.kBackupCompleted: 'Sauvegarde terminee',
  Constants.kBackupFailed: 'Echec de la sauvegarde',
  Constants.kBackupCancelled: 'Sauvegarde annulee',
  Constants.kBackupPaused: 'Sauvegarde en pause',
  Constants.kBackupSettings: 'Parametres de sauvegarde',
  Constants.kAutoBackup: 'Sauvegarde automatique',
  Constants.kFullBackup: 'Sauvegarde complete',
  Constants.kQuickBackup: 'Sauvegarde rapide',
  Constants.kDeviceInfoBackup: 'Sauvegarde des infos de l\'appareil',
  Constants.kContactsBackup: 'Sauvegarde des contacts',
  Constants.kImagesBackup: 'Sauvegarde des images',
  Constants.kSettingsBackup: 'Sauvegarde des parametres',
  Constants.kIncludePhotos: 'Inclure les photos',
  Constants.kIncludeGroups: 'Inclure les groupes',
  Constants.kIncludeAccounts: 'Inclure les comptes',
  Constants.kIncludeMetadata: 'Inclure les metadonnees',
  Constants.kMaxImages: 'Images max',
  Constants.kBackupSize: 'Taille de la sauvegarde',
  Constants.kEstimatedSize: 'Taille estimee',
  Constants.kLastBackup: 'Derniere sauvegarde',
  Constants.kBackupInProgress: 'Sauvegarde en cours...',
  Constants.kPreparingBackup: 'Preparation de la sauvegarde...',
  Constants.kUploadingFiles: 'Telechargement des fichiers...',
  Constants.kBackupValidation: 'Validation de la sauvegarde...',
  Constants.kSelectImages: 'Selectionner des images',
  Constants.kBackupSummary: 'Resume de la sauvegarde',
  Constants.kTotalFiles: 'Total des fichiers',
  Constants.kBackupDate: 'Date de la sauvegarde',
  Constants.kDeleteBackup: 'Supprimer la sauvegarde',
  Constants.kDeleteBackupConfirm:
      'Etes-vous sur de vouloir supprimer cette sauvegarde ?',
  Constants.kRestoreBackup: 'Restaurer la sauvegarde',
  Constants.kRestoreBackupConfirm:
      'Etes-vous sur de vouloir restaurer a partir de cette sauvegarde ?',
  Constants.kBackupPermissions: 'Permissions de sauvegarde',
  // kPermissionsRequired shares key value with kPermissionRequired above
  Constants.kGrantPermissions: 'Accorder les permissions',
  Constants.kEnableContactsPermission:
      'Activez la permission des contacts pour sauvegarder les contacts',
  Constants.kEnablePhotosPermission:
      'Activez la permission des photos pour sauvegarder les images',
  Constants.kEnableStoragePermission:
      'Activez la permission de stockage pour enregistrer les sauvegardes',
  Constants.kBackupRecommendations: 'Recommandations de sauvegarde',
  Constants.kNoBackupsFound: 'Aucune sauvegarde trouvee',
  Constants.kCreateFirstBackup: 'Creez votre premiere sauvegarde',
  Constants.kRegularBackupsRecommended:
      'Les sauvegardes regulieres sont recommandees',
  Constants.kDaysSinceLastBackup: 'jours depuis la derniere sauvegarde',
  Constants.kBackupReady: 'Pret pour la sauvegarde',
  Constants.kCheckingPermissions: 'Verification des permissions...',
  Constants.kCalculatingSize: 'Calcul de la taille...',

  // Conditions generales
  Constants.kIAgreeToThe: 'J\'accepte les',
  Constants.kTermsAndConditions: 'Conditions generales',
  Constants.kAndThe: 'et la',
  Constants.kPleaseAcceptTermsAndConditions:
      'Veuillez accepter les conditions generales pour continuer',
  // kTermsOfService shares key value with kTerms above
  Constants.kLastUpdated: 'Derniere mise a jour',
  Constants.kAcceptance: 'Acceptation',
  Constants.kUserAccounts: 'Comptes utilisateurs',
  Constants.kPrivacyAndDataProtection:
      'Confidentialite et protection des donnees',
  Constants.kUserContent: 'Contenu utilisateur',
  Constants.kProhibitedActivities: 'Activites interdites',
  Constants.kIntellectualProperty: 'Propriete intellectuelle',
  Constants.kTermination: 'Resiliation',
  Constants.kDisclaimerOfWarranties: 'Avertissement de garanties',
  Constants.kLimitationOfLiability: 'Limitation de responsabilite',
  Constants.kGoverningLaw: 'Loi applicable',
  Constants.kContactInformation: 'Coordonnees',

  // Actions de message
  Constants.kMessageActions: 'Actions du message',
  Constants.kTranslate: 'Traduire',
  Constants.kHideTranslation: 'Masquer la traduction',
  Constants.kUnfavorite: 'Retirer des favoris',
  Constants.kFavorite: 'Favori',
  Constants.kUnpin: 'Desepingler',
  Constants.kPin: 'Epingler',
  Constants.kRestore: 'Restaurer',

  // Transfere / Supprime
  Constants.kForwarded: 'Transfere',
  Constants.kThisMessageWasDeleted: 'Ce message a ete supprime',

  // Chat bloque
  Constants.kYouBlockedThisContact: 'Vous avez bloque ce contact',
  Constants.kMessageUnavailable: 'Message indisponible',
  Constants.kUnblock: 'Debloquer',
  Constants.kUnblockThisContactToSendMessages:
      'Debloquez ce contact pour envoyer des messages',
  Constants.kYouCantSendMessages:
      'Vous ne pouvez pas envoyer de messages a cette conversation',
  Constants.kContactBlocked: 'Contact bloque',
  Constants.kCannotContact: 'Impossible de contacter',
  Constants.kKeepBlocked: 'Garder bloque',

  // Story
  Constants.kStoryPosted: 'Story publiee !',
  Constants.kDiscardStory: 'Abandonner la story ?',

  // Appels
  Constants.kEndCall: 'Terminer l\'appel',
  Constants.kEndCallConfirmation:
      'Etes-vous sur de vouloir terminer cet appel ?',

  // Message programme
  Constants.kScheduleMessage: 'Programmer un message',

  // Notifications de ligne de chat
  Constants.kChatMutedSnack: 'Conversation mise en sourdine',
  Constants.kChatUnmutedSnack: 'Sourdine desactivee',
  Constants.kChatPinnedSnack: 'Conversation epinglee',
  Constants.kChatUnpinnedSnack: 'Conversation desepinglee',
  Constants.kBlockingUser: 'Blocage de l\'utilisateur...',
  Constants.kDeletingChat: 'Suppression de la conversation...',
  Constants.kDeletingGroupChat: 'Suppression de la conversation de groupe...',
  Constants.kDeleteFailed: 'Echec de la suppression',
  Constants.kFailedToDeleteChatTryAgain:
      'Echec de la suppression. Veuillez reessayer.',
  Constants.kThisActionCanBeReversed:
      'Cette action peut etre annulee plus tard',
  Constants.kDeleteForever: 'Supprimer definitivement',
  Constants.kThisActionCannotBeUndoneWarning: 'Cette action est irreversible',
  Constants.kAllMessagesWillBeDeleted:
      'Etes-vous sur de vouloir supprimer cette conversation ? Tous les messages seront definitivement supprimes.',
  Constants.kBlockUserConfirmation: 'Etes-vous sur de vouloir bloquer',
  Constants.kWontReceiveMessages:
      'Vous ne recevrez plus de messages de cet utilisateur.',
  Constants.kChatRemovedFromFavorites: 'Conversation retiree des favoris',
  Constants.kChatAddedToFavorites: 'Conversation ajoutee aux favoris',
  Constants.kChatUnarchivedSnack: 'Conversation desarchivee',
  Constants.kChatArchivedSnack: 'Conversation archivee',
  Constants.kFailedToToggleMute: 'Echec du basculement de la sourdine',
  Constants.kFailedToTogglePin: 'Echec du basculement de l\'epingle',
  Constants.kFailedToToggleFavorite: 'Echec du basculement du favori',
  Constants.kFailedToToggleArchive: 'Echec du basculement de l\'archive',
  Constants.kFailedToBlockUser: 'Echec du blocage de l\'utilisateur',
  Constants.kUserNotFound: 'Utilisateur introuvable',

  // Parametres - Dialogues
  Constants.kSignOut: 'Deconnexion',
  Constants.kSignOutConfirmation: 'Etes-vous sur de vouloir vous deconnecter ?',
  Constants.kDeleteAccount: 'Supprimer le compte',
  Constants.kDeleteAccountConfirmation:
      'Etes-vous sur de vouloir supprimer definitivement votre compte ? Cette action est irreversible.',
  Constants.kDeletingAccount: 'Suppression du compte...',
  Constants.kAccountDeletedSuccessfully: 'Compte supprime avec succes',
  Constants.kFailedToDeleteAccount: 'Echec de la suppression du compte',

  // Parametres - Sauvegarde
  Constants.kFailedToStartBackup: 'Echec du demarrage de la sauvegarde',
  Constants.kBackupStartedSuccessfully: 'Sauvegarde demarree avec succes',
  Constants.kFailedToCancelBackup: 'Echec de l\'annulation de la sauvegarde',
  Constants.kBackupSettingsSaved:
      'Parametres de sauvegarde enregistres avec succes',
  Constants.kFailedToSaveBackupSettings:
      'Echec de l\'enregistrement des parametres de sauvegarde',
  Constants.kPermissionsGranted:
      'Toutes les autorisations accordees avec succes',
  Constants.kPermissionsMissing:
      'Certaines autorisations sont encore manquantes',
  Constants.kFailedToRequestPermissions: 'Echec de la demande d\'autorisations',
  Constants.kAutoBackupEnabled: 'Sauvegarde automatique activee',
  Constants.kAutoBackupDisabled: 'Sauvegarde automatique desactivee',
  Constants.kCloudBackup: 'Sauvegarde cloud',
  Constants.kCloudBackupConfig: 'Configuration de la sauvegarde cloud',
  Constants.kBackupFrequency: 'Frequence de sauvegarde',
  Constants.kChooseBackupFrequency:
      'Choisissez la frequence de sauvegarde de vos donnees',
  Constants.kDaily: 'Quotidien',
  Constants.kWeekly: 'Hebdomadaire',
  Constants.kMonthly: 'Mensuel',
  Constants.kBackupEveryDay: 'Sauvegarde tous les jours',
  Constants.kBackupOnceAWeek: 'Sauvegarde une fois par semaine',
  Constants.kBackupOnceAMonth: 'Sauvegarde une fois par mois',
  Constants.kBackupFrequencySetTo: 'Frequence de sauvegarde definie a',
  Constants.kRestoreFromBackup: 'Restaurer a partir de la sauvegarde',
  Constants.kSelectBackupToRestore: 'Selectionnez la sauvegarde a restaurer',
  Constants.kAutomaticallyBackupChats:
      'Sauvegarder automatiquement les conversations',
  Constants.kGoogleDriveICloud: 'Google Drive / iCloud',
  Constants.kCancelBackup: 'Annuler la sauvegarde',
  Constants.kInProgress: 'En cours',
  Constants.kCompleted: 'Termine',
  Constants.kFailed: 'Echoue',
  Constants.kPending: 'En attente',
  Constants.kChatMessages: 'Messages de chat',
  Constants.kLocationData: 'Donnees de localisation',
  Constants.kPhotosAndMedia: 'Photos et medias',
  Constants.kDeviceInfo: 'Infos de l\'appareil',

  // Parametres - Confidentialite analytique
  Constants.kAnalyticsPrivacy: 'Confidentialite analytique',
  Constants.kDeviceTrackingEnabled: 'Suivi de l\'appareil active',
  Constants.kDeviceTrackingDisabled:
      'Suivi de l\'appareil desactive. Les informations de votre appareil ne seront pas collectees.',
  Constants.kLocationPermission: 'Autorisation de localisation',
  Constants.kLocationPermissionRequired:
      'L\'autorisation de localisation est requise pour activer le suivi de localisation',
  Constants.kLocationTrackingEnabled: 'Suivi de localisation active',
  Constants.kLocationTrackingDisabled:
      'Suivi de localisation desactive. Votre localisation ne sera pas collectee.',
  Constants.kFailedToUpdateTracking:
      'Echec de la mise a jour du parametre de suivi',
  Constants.kCollectedData: 'Donnees collectees',
  Constants.kCollectedDataDescription:
      'Nous collectons les informations suivantes pour ameliorer votre experience et fournir de meilleures analyses :',
  Constants.kPrivacyNote:
      'Votre vie privee est importante pour nous. Vous pouvez desactiver tout suivi a tout moment depuis la page des parametres. Aucune information personnelle n\'est collectee.',
  Constants.kEnabled: 'Active',
  Constants.kDisabled: 'Desactive',
  Constants.kNoDataCollected:
      'Aucune donnee n\'est collectee pour cette categorie',
  Constants.kDeviceInformation: 'Informations sur l\'appareil',
  Constants.kLocationInformation: 'Informations de localisation',

  // Galerie de medias
  Constants.kDownload: 'Telecharger',
  Constants.kShare: 'Partager',
  Constants.kSelectAll: 'Tout selectionner',
  Constants.kSearchMedia: 'Rechercher des medias...',
  Constants.kSelected: 'selectionne(s)',
  Constants.kNoItemsYet: 'encore',
  Constants.kOpeningLink: 'Ouverture du lien...',
};
