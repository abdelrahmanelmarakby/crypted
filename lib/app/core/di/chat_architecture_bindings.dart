/// New Architecture Bindings for Chat Module
///
/// This file contains GetX bindings for the new clean architecture components.
/// It integrates with the existing ChatBinding for incremental migration.
///
/// Usage:
/// 1. In main.dart, call GlobalChatBindings().dependencies() once at startup
/// 2. ChatBinding automatically includes these bindings when entering chat
///
/// Migration Strategy:
/// - New components are registered alongside existing ones
/// - Feature flag `useNewArchitecture` enables gradual migration
/// - Once migration is complete, old bindings can be removed
library;

import 'package:crypted_app/app/core/caching/query_cache.dart';
import 'package:crypted_app/app/core/caching/user_profile_cache.dart';
import 'package:crypted_app/app/core/connectivity/connectivity_service.dart';
import 'package:crypted_app/app/core/events/event_bus.dart';
import 'package:crypted_app/app/data/datasources/firebase/firebase_message_datasource.dart';
import 'package:crypted_app/app/data/datasources/firebase/firebase_reaction_datasource.dart';
import 'package:crypted_app/app/data/datasources/local/hive_message_datasource.dart';
import 'package:crypted_app/app/data/repositories/message_repository_impl.dart';
import 'package:crypted_app/app/data/repositories/reaction_repository_impl.dart';
import 'package:crypted_app/app/data/repositories/forward_repository_impl.dart';
import 'package:crypted_app/app/data/repositories/group_repository_impl.dart';
import 'package:crypted_app/app/domain/repositories/i_message_repository.dart';
import 'package:crypted_app/app/domain/repositories/i_reaction_repository.dart';
import 'package:crypted_app/app/domain/repositories/i_forward_repository.dart';
import 'package:crypted_app/app/domain/repositories/i_group_repository.dart';
import 'package:crypted_app/app/domain/usecases/message/send_message_usecase.dart';
import 'package:crypted_app/app/domain/usecases/message/edit_message_usecase.dart';
import 'package:crypted_app/app/domain/usecases/message/delete_message_usecase.dart';
import 'package:crypted_app/app/domain/usecases/reaction/toggle_reaction_usecase.dart';
import 'package:crypted_app/app/domain/usecases/forward/forward_message_usecase.dart';
import 'package:crypted_app/app/domain/usecases/group/group_member_usecases.dart';
import 'package:crypted_app/app/domain/usecases/group/group_info_usecases.dart';
import 'package:get/get.dart';

/// Global bindings - initialize once at app startup
/// These are singletons that persist across the entire app lifecycle
class GlobalChatBindings extends Bindings {
  @override
  void dependencies() {
    // Event Bus - singleton for app-wide events
    if (!Get.isRegistered<EventBus>()) {
      Get.put(EventBus(), permanent: true);
    }

    // Query Cache - singleton for caching Firestore queries
    if (!Get.isRegistered<QueryCache>()) {
      Get.put(QueryCache(), permanent: true);
    }

    // User Profile Cache - singleton for caching user profiles
    if (!Get.isRegistered<UserProfileCache>()) {
      Get.put(UserProfileCache(), permanent: true);
    }

    // Connectivity Service - might already exist
    if (!Get.isRegistered<ConnectivityService>()) {
      Get.put(ConnectivityService(), permanent: true);
    }
  }
}

/// New architecture bindings for chat module
/// Call this from the existing ChatBinding to add new architecture components
class NewArchitectureBindings extends Bindings {
  @override
  void dependencies() {
    // Ensure global bindings are registered
    GlobalChatBindings().dependencies();

    // =================== Data Sources ===================

    // Firebase Message Data Source
    Get.lazyPut<IFirebaseMessageDataSource>(
      () => FirebaseMessageDataSource(),
      fenix: true,
    );

    // Firebase Reaction Data Source
    Get.lazyPut<IFirebaseReactionDataSource>(
      () => FirebaseReactionDataSource(),
      fenix: true,
    );

    // Local Message Data Source (Hive)
    Get.lazyPut<ILocalMessageDataSource>(
      () => HiveMessageDataSource(),
      fenix: true,
    );

    // =================== Repositories ===================

    // Message Repository - NEW architecture
    Get.lazyPut<IMessageRepository>(
      () => MessageRepositoryImpl(
        remoteDataSource: Get.find<IFirebaseMessageDataSource>(),
        localDataSource: Get.find<ILocalMessageDataSource>(),
        eventBus: Get.find<EventBus>(),
        cache: Get.find<QueryCache>(),
        connectivity: Get.find<ConnectivityService>(),
      ),
      fenix: true,
    );

    // Reaction Repository - NEW architecture
    Get.lazyPut<IReactionRepository>(
      () => ReactionRepositoryImpl(
        remoteDataSource: Get.find<IFirebaseReactionDataSource>(),
        userCache: Get.find<UserProfileCache>(),
        eventBus: Get.find<EventBus>(),
      ),
      fenix: true,
    );

    // =================== Use Cases ===================

    Get.lazyPut<SendMessageUseCase>(
      () => SendMessageUseCase(
        repository: Get.find<IMessageRepository>(),
      ),
      fenix: true,
    );

    Get.lazyPut<EditMessageUseCase>(
      () => EditMessageUseCase(
        repository: Get.find<IMessageRepository>(),
      ),
      fenix: true,
    );

    Get.lazyPut<DeleteMessageUseCase>(
      () => DeleteMessageUseCase(
        repository: Get.find<IMessageRepository>(),
      ),
      fenix: true,
    );

    Get.lazyPut<ToggleReactionUseCase>(
      () => ToggleReactionUseCase(
        repository: Get.find<IReactionRepository>(),
      ),
      fenix: true,
    );

    // =================== Forward Repository ===================

    Get.lazyPut<IForwardRepository>(
      () => ForwardRepositoryImpl(
        eventBus: Get.find<EventBus>(),
      ),
      fenix: true,
    );

    // =================== Group Repository ===================

    Get.lazyPut<IGroupRepository>(
      () => GroupRepositoryImpl(
        eventBus: Get.find<EventBus>(),
      ),
      fenix: true,
    );

    // =================== Forward Use Cases ===================

    Get.lazyPut<ForwardMessageUseCase>(
      () => ForwardMessageUseCase(
        repository: Get.find<IForwardRepository>(),
      ),
      fenix: true,
    );

    Get.lazyPut<BatchForwardUseCase>(
      () => BatchForwardUseCase(
        repository: Get.find<IForwardRepository>(),
      ),
      fenix: true,
    );

    Get.lazyPut<ForwardToMultipleUseCase>(
      () => ForwardToMultipleUseCase(
        repository: Get.find<IForwardRepository>(),
      ),
      fenix: true,
    );

    // =================== Group Member Use Cases ===================

    Get.lazyPut<AddMemberUseCase>(
      () => AddMemberUseCase(
        repository: Get.find<IGroupRepository>(),
      ),
      fenix: true,
    );

    Get.lazyPut<AddMembersUseCase>(
      () => AddMembersUseCase(
        repository: Get.find<IGroupRepository>(),
      ),
      fenix: true,
    );

    Get.lazyPut<RemoveMemberUseCase>(
      () => RemoveMemberUseCase(
        repository: Get.find<IGroupRepository>(),
      ),
      fenix: true,
    );

    Get.lazyPut<LeaveGroupUseCase>(
      () => LeaveGroupUseCase(
        repository: Get.find<IGroupRepository>(),
      ),
      fenix: true,
    );

    Get.lazyPut<MakeAdminUseCase>(
      () => MakeAdminUseCase(
        repository: Get.find<IGroupRepository>(),
      ),
      fenix: true,
    );

    Get.lazyPut<RemoveAdminUseCase>(
      () => RemoveAdminUseCase(
        repository: Get.find<IGroupRepository>(),
      ),
      fenix: true,
    );

    Get.lazyPut<TransferOwnershipUseCase>(
      () => TransferOwnershipUseCase(
        repository: Get.find<IGroupRepository>(),
      ),
      fenix: true,
    );

    // =================== Group Info Use Cases ===================

    Get.lazyPut<UpdateGroupNameUseCase>(
      () => UpdateGroupNameUseCase(
        repository: Get.find<IGroupRepository>(),
      ),
      fenix: true,
    );

    Get.lazyPut<UpdateGroupDescriptionUseCase>(
      () => UpdateGroupDescriptionUseCase(
        repository: Get.find<IGroupRepository>(),
      ),
      fenix: true,
    );

    Get.lazyPut<UpdateGroupImageUseCase>(
      () => UpdateGroupImageUseCase(
        repository: Get.find<IGroupRepository>(),
      ),
      fenix: true,
    );

    Get.lazyPut<UpdateGroupPermissionsUseCase>(
      () => UpdateGroupPermissionsUseCase(
        repository: Get.find<IGroupRepository>(),
      ),
      fenix: true,
    );

    Get.lazyPut<GetGroupInfoUseCase>(
      () => GetGroupInfoUseCase(
        repository: Get.find<IGroupRepository>(),
      ),
      fenix: true,
    );
  }
}

/// Feature flag for gradual migration
/// Set to true to use new architecture, false for legacy
class ChatArchitectureConfig {
  static bool useNewArchitecture = true;

  /// Check if new architecture should be used
  static bool get shouldUseNewArchitecture => useNewArchitecture;

  /// Enable new architecture
  static void enableNewArchitecture() {
    useNewArchitecture = true;
  }

  /// Disable new architecture (fallback to legacy)
  static void disableNewArchitecture() {
    useNewArchitecture = false;
  }
}
