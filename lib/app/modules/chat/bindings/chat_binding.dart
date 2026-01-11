// ARCH-016 FIX: Updated Chat Binding with Architecture Support
// Properly registers all chat-related controllers and dependencies

import 'package:crypted_app/app/core/di/service_locator.dart';
import 'package:crypted_app/app/core/error_handling/error_handler.dart';
import 'package:crypted_app/app/core/repositories/chat_repository.dart';
import 'package:crypted_app/app/core/repositories/firebase_chat_repository.dart';
import 'package:crypted_app/app/modules/chat/controllers/chat_controller.dart';
import 'package:crypted_app/app/modules/chat/controllers/chat_state_manager.dart';
import 'package:crypted_app/app/modules/chat/controllers/group_management_controller.dart';
import 'package:crypted_app/app/modules/chat/controllers/message_actions_controller.dart';
import 'package:get/get.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure ServiceLocator is initialized
    _ensureServicesInitialized();

    // Register core dependencies if not already registered
    _registerCoreDependencies();

    // Register specialized controllers
    _registerControllers();
  }

  void _ensureServicesInitialized() {
    // Initialize ServiceLocator if not done in main.dart
    if (!Get.isRegistered<ServiceLocator>()) {
      Get.put(ServiceLocator(), permanent: true);
    }
  }

  void _registerCoreDependencies() {
    // Error Handler - singleton
    if (!Get.isRegistered<ErrorHandler>()) {
      Get.put(ErrorHandler(), permanent: true);
    }

    // Chat Repository - singleton
    if (!Get.isRegistered<IChatRepository>()) {
      Get.put<IChatRepository>(
        FirebaseChatRepository(),
        permanent: true,
      );
    }
  }

  void _registerControllers() {
    // Chat State Manager - manages reactive state
    Get.lazyPut<ChatStateManager>(
      () => ChatStateManager(),
      fenix: true,
    );

    // Message Actions Controller - handles message operations
    Get.lazyPut<MessageActionsController>(
      () => MessageActionsController(
        repository: Get.find<IChatRepository>(),
        errorHandler: Get.find<ErrorHandler>(),
      ),
      fenix: true,
    );

    // Group Management Controller - handles group operations
    Get.lazyPut<GroupManagementController>(
      () => GroupManagementController(
        repository: Get.find<IChatRepository>(),
        errorHandler: Get.find<ErrorHandler>(),
      ),
      fenix: true,
    );

    // Main Chat Controller - orchestrates all chat functionality
    Get.lazyPut<ChatController>(
      () => ChatController(),
      fenix: true,
    );
  }
}

/// Extended binding for group chat creation/management screens
class GroupChatBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure chat binding dependencies are available
    ChatBinding().dependencies();

    // Additional group-specific dependencies can be added here
  }
}

/// Binding for chat info/details screens
class ChatInfoBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure base dependencies
    if (!Get.isRegistered<IChatRepository>()) {
      ChatBinding().dependencies();
    }

    // Group management controller for info screen
    if (!Get.isRegistered<GroupManagementController>()) {
      Get.lazyPut<GroupManagementController>(
        () => GroupManagementController(
          repository: Get.find<IChatRepository>(),
          errorHandler: Get.find<ErrorHandler>(),
        ),
      );
    }
  }
}
