// ARCH-007 FIX: Dependency Injection Container
// Provides centralized service registration and resolution
// ARCH-002: Now includes split repositories

import 'package:get/get.dart';
import 'package:crypted_app/app/core/repositories/chat_repository.dart';
import 'package:crypted_app/app/core/repositories/offline_chat_repository.dart';
import 'package:crypted_app/app/core/repositories/message_repository.dart';
import 'package:crypted_app/app/core/repositories/chat_room_repository.dart';
import 'package:crypted_app/app/core/error_handling/error_handler.dart';
import 'package:crypted_app/app/core/factories/message_factory.dart';
import 'package:crypted_app/app/core/services/chat_session_manager.dart';
import 'package:crypted_app/app/core/services/local_database_service.dart';
import 'package:crypted_app/app/core/sync/sync_service.dart';
import 'package:crypted_app/app/core/offline/offline_queue.dart';
import 'package:crypted_app/app/core/security/input_sanitizer.dart';
import 'package:crypted_app/app/core/services/typing_service.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';

/// Service Locator using GetX for dependency injection
/// This provides a centralized way to register and resolve dependencies
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  bool _initialized = false;

  /// Initialize all services
  /// Call this in main() before runApp()
  Future<void> init() async {
    if (_initialized) return;

    // Register singletons
    _registerSingletons();

    // Register factories
    _registerFactories();

    // Register lazy singletons
    _registerLazySingletons();

    _initialized = true;
  }

  /// Register singleton services
  void _registerSingletons() {
    // Error Handler - global singleton
    Get.put<ErrorHandler>(ErrorHandler(), permanent: true);

    // Message Factory - global singleton (ARCH-012)
    Get.put<MessageFactory>(MessageFactory(), permanent: true);

    // Chat Session Manager - global singleton
    Get.put<ChatSessionManager>(ChatSessionManager.instance, permanent: true);

    // Input Sanitizer - global singleton (SEC-001)
    Get.put<InputSanitizer>(InputSanitizer(), permanent: true);

    // Offline Queue - global singleton (ARCH-010)
    Get.put<OfflineQueue>(OfflineQueue(), permanent: true);
  }

  /// Register factory services (new instance each time)
  void _registerFactories() {
    // Typing Service - new instance for each chat
    Get.lazyPut<TypingService>(() => TypingService(), fenix: true);
  }

  /// Register lazy singletons (created when first accessed)
  void _registerLazySingletons() {
    // Chat Repository - lazy singleton (ARCH-003)
    // Using OfflineChatRepository for offline-first architecture
    Get.lazyPut<IChatRepository>(
      () => OfflineChatRepository(),
      fenix: true,
    );

    // Local Database Service - lazy singleton
    Get.lazyPut<LocalDatabaseService>(
      () => LocalDatabaseService(),
      fenix: true,
    );

    // Sync Service - lazy singleton
    Get.lazyPut<SyncService>(
      () => SyncService(),
      fenix: true,
    );

    // Message Repository - lazy singleton (ARCH-002)
    Get.lazyPut<IMessageRepository>(
      () => FirebaseMessageRepository(
        messageFactory: Get.find<MessageFactory>(),
      ),
      fenix: true,
    );

    // Chat Room Repository - lazy singleton (ARCH-002)
    // Note: Requires current user ID, registered per-session
    Get.lazyPut<IChatRoomRepository>(
      () {
        final currentUserId = UserService.currentUser.value?.uid ?? '';
        return FirebaseChatRoomRepository(currentUserId: currentUserId);
      },
      fenix: true,
    );
  }

  /// Register a service
  static void register<T>(T service, {bool permanent = false}) {
    Get.put<T>(service, permanent: permanent);
  }

  /// Register a lazy service
  static void registerLazy<T>(T Function() factory, {bool fenix = false}) {
    Get.lazyPut<T>(factory, fenix: fenix);
  }

  /// Get a registered service
  static T get<T>() {
    return Get.find<T>();
  }

  /// Try to get a registered service, returns null if not found
  static T? tryGet<T>() {
    try {
      return Get.find<T>();
    } catch (e) {
      return null;
    }
  }

  /// Check if a service is registered
  static bool isRegistered<T>() {
    return Get.isRegistered<T>();
  }

  /// Reset all services (useful for testing)
  static void reset() {
    Get.reset();
  }

  /// Delete a specific service
  static void delete<T>({bool force = false}) {
    Get.delete<T>(force: force);
  }
}

/// Convenience getters for commonly used services
class Services {
  static ErrorHandler get errorHandler => ServiceLocator.get<ErrorHandler>();
  static MessageFactory get messageFactory => ServiceLocator.get<MessageFactory>();
  static ChatSessionManager get chatSession => ServiceLocator.get<ChatSessionManager>();
  static IChatRepository get chatRepository => ServiceLocator.get<IChatRepository>();
  static IMessageRepository get messageRepository => ServiceLocator.get<IMessageRepository>();
  static IChatRoomRepository get chatRoomRepository => ServiceLocator.get<IChatRoomRepository>();
  static InputSanitizer get inputSanitizer => ServiceLocator.get<InputSanitizer>();
  static OfflineQueue get offlineQueue => ServiceLocator.get<OfflineQueue>();
  static LocalDatabaseService get localDatabase => ServiceLocator.get<LocalDatabaseService>();
  static SyncService get syncService => ServiceLocator.get<SyncService>();
}

/// Mixin for easy service access in controllers
mixin ServiceLocatorMixin {
  ErrorHandler get errorHandler => Services.errorHandler;
  MessageFactory get messageFactory => Services.messageFactory;
  ChatSessionManager get chatSession => Services.chatSession;
  IChatRepository get chatRepository => Services.chatRepository;
  IMessageRepository get messageRepository => Services.messageRepository;
  IChatRoomRepository get chatRoomRepository => Services.chatRoomRepository;
  InputSanitizer get inputSanitizer => Services.inputSanitizer;
  OfflineQueue get offlineQueue => Services.offlineQueue;
  LocalDatabaseService get localDatabase => Services.localDatabase;
  SyncService get syncService => Services.syncService;
}
