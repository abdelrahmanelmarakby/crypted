// ARCH-007 FIX: Dependency Injection Container
// Provides centralized service registration and resolution

import 'package:get/get.dart';
import 'package:crypted_app/app/core/repositories/chat_repository.dart';
import 'package:crypted_app/app/core/repositories/firebase_chat_repository.dart';
import 'package:crypted_app/app/core/error_handling/error_handler.dart';
import 'package:crypted_app/app/core/factories/message_factory.dart';
import 'package:crypted_app/app/core/services/chat_session_manager.dart';
import 'package:crypted_app/app/modules/chat/services/typing_service.dart';

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

    // Message Factory - global singleton
    Get.put<MessageFactory>(MessageFactory(), permanent: true);

    // Chat Session Manager - global singleton
    Get.put<ChatSessionManager>(ChatSessionManager.instance, permanent: true);
  }

  /// Register factory services (new instance each time)
  void _registerFactories() {
    // Typing Service - new instance for each chat
    Get.lazyPut<TypingService>(() => TypingService(), fenix: true);
  }

  /// Register lazy singletons (created when first accessed)
  void _registerLazySingletons() {
    // Chat Repository - lazy singleton
    Get.lazyPut<IChatRepository>(
      () => FirebaseChatRepository(),
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
}

/// Mixin for easy service access in controllers
mixin ServiceLocatorMixin {
  ErrorHandler get errorHandler => Services.errorHandler;
  MessageFactory get messageFactory => Services.messageFactory;
  ChatSessionManager get chatSession => Services.chatSession;
  IChatRepository get chatRepository => Services.chatRepository;
}
