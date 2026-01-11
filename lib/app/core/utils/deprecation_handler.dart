import 'package:flutter/foundation.dart';
import 'package:crypted_app/app/core/utils/debug_logger.dart';

/// QUALITY-008: Deprecation Handler
/// Provides utilities for handling deprecated code gracefully
/// Tracks deprecation usage and provides migration paths

class DeprecationHandler {
  static final DeprecationHandler _instance = DeprecationHandler._();
  static DeprecationHandler get instance => _instance;

  DeprecationHandler._();

  // Track deprecation usage count
  final Map<String, int> _usageCount = {};

  // Track if warnings have been shown
  final Set<String> _warningsShown = {};

  /// Log deprecation warning (only once per session)
  void logDeprecation({
    required String feature,
    required String replacement,
    String? version,
    String? reason,
  }) {
    if (_warningsShown.contains(feature)) {
      // Already warned, just increment counter
      _usageCount[feature] = (_usageCount[feature] ?? 0) + 1;
      return;
    }

    _warningsShown.add(feature);
    _usageCount[feature] = 1;

    final buffer = StringBuffer();
    buffer.writeln('⚠️ DEPRECATION WARNING');
    buffer.writeln('Feature: $feature');
    buffer.writeln('Replacement: $replacement');
    if (version != null) {
      buffer.writeln('Deprecated since: $version');
    }
    if (reason != null) {
      buffer.writeln('Reason: $reason');
    }

    if (kDebugMode) {
      warnLog(buffer.toString(), tag: 'DEPRECATION');
    }
  }

  /// Execute deprecated code with warning
  T executeDeprecated<T>({
    required String feature,
    required String replacement,
    required T Function() code,
    String? version,
  }) {
    logDeprecation(
      feature: feature,
      replacement: replacement,
      version: version,
    );
    return code();
  }

  /// Execute deprecated async code with warning
  Future<T> executeDeprecatedAsync<T>({
    required String feature,
    required String replacement,
    required Future<T> Function() code,
    String? version,
  }) async {
    logDeprecation(
      feature: feature,
      replacement: replacement,
      version: version,
    );
    return await code();
  }

  /// Get deprecation usage stats
  Map<String, int> getUsageStats() => Map.unmodifiable(_usageCount);

  /// Reset tracking (for testing)
  void reset() {
    _usageCount.clear();
    _warningsShown.clear();
  }
}

/// Annotation for marking deprecated methods with migration info
class DeprecatedWithMigration {
  final String replacement;
  final String? version;
  final String? reason;

  const DeprecatedWithMigration({
    required this.replacement,
    this.version,
    this.reason,
  });
}

/// Extension for deprecated method handling
extension DeprecatedMethodExtension on Object {
  /// Mark this call as deprecated
  void markDeprecated(String feature, String replacement) {
    DeprecationHandler.instance.logDeprecation(
      feature: feature,
      replacement: replacement,
    );
  }
}

/// Wrapper for deprecated parameter handling
class DeprecatedParameter<T> {
  final T value;
  final String paramName;
  final String replacement;

  DeprecatedParameter({
    required this.value,
    required this.paramName,
    required this.replacement,
  }) {
    DeprecationHandler.instance.logDeprecation(
      feature: 'Parameter: $paramName',
      replacement: replacement,
    );
  }
}

/// Mixin for classes with deprecated methods
mixin DeprecationAwareMixin {
  final _deprecationHandler = DeprecationHandler.instance;

  /// Log deprecation for a method
  void deprecatedMethod(String methodName, String replacement) {
    _deprecationHandler.logDeprecation(
      feature: '$runtimeType.$methodName',
      replacement: replacement,
    );
  }

  /// Execute deprecated code
  T deprecated<T>(
    String methodName,
    String replacement,
    T Function() code,
  ) {
    deprecatedMethod(methodName, replacement);
    return code();
  }
}

// ============================================================================
// MIGRATION UTILITIES
// ============================================================================

/// Migration path definition
class MigrationPath {
  final String fromVersion;
  final String toVersion;
  final String description;
  final List<MigrationStep> steps;

  const MigrationPath({
    required this.fromVersion,
    required this.toVersion,
    required this.description,
    required this.steps,
  });
}

/// Single migration step
class MigrationStep {
  final String description;
  final String codeExample;
  final String? note;

  const MigrationStep({
    required this.description,
    required this.codeExample,
    this.note,
  });
}

/// Common migration paths for the chat module
class ChatMigrationPaths {
  static const legacyArgumentsToNew = MigrationPath(
    fromVersion: '1.0.0',
    toVersion: '2.0.0',
    description: 'Migrate from legacy chat arguments to new ChatRoomArguments',
    steps: [
      MigrationStep(
        description: 'Replace direct argument passing with ChatRoomArguments',
        codeExample: '''
// Before (deprecated):
Get.toNamed(Routes.CHAT, arguments: {
  'members': members,
  'roomId': roomId,
  'isGroupChat': isGroupChat,
});

// After:
Get.toNamed(Routes.CHAT, arguments: ChatRoomArguments(
  members: members,
  roomId: roomId,
  isGroupChat: isGroupChat,
));
''',
      ),
    ],
  );

  static const streamProviderToGetX = MigrationPath(
    fromVersion: '1.0.0',
    toVersion: '2.0.0',
    description: 'Migrate from StreamProvider to GetX observables',
    steps: [
      MigrationStep(
        description: 'Replace StreamProvider with StreamBuilder or Obx',
        codeExample: '''
// Before (deprecated):
StreamProvider<List<Message>>.value(
  value: dataSource.getMessages(),
  builder: (context, child) {
    final messages = Provider.of<List<Message>>(context);
    ...
  },
);

// After:
StreamBuilder<List<Message>>(
  stream: dataSource.getMessages(),
  builder: (context, snapshot) {
    final messages = snapshot.data ?? [];
    ...
  },
);
''',
      ),
    ],
  );

  static const printToLogger = MigrationPath(
    fromVersion: '1.0.0',
    toVersion: '2.0.0',
    description: 'Migrate from print statements to LoggerService',
    steps: [
      MigrationStep(
        description: 'Replace print with debugLog or LoggerService',
        codeExample: '''
// Before (deprecated):
print('Error: \$error');

// After:
debugLog('Error occurred', tag: 'MyClass', error: error);
// or
_logger.logError('Error occurred', error: error, context: 'MyClass');
''',
      ),
    ],
  );

  static const directFirestoreToRepository = MigrationPath(
    fromVersion: '1.0.0',
    toVersion: '2.0.0',
    description: 'Migrate from direct Firestore access to repository pattern',
    steps: [
      MigrationStep(
        description: 'Use repository instead of direct Firestore calls',
        codeExample: '''
// Before (deprecated):
final doc = await FirebaseFirestore.instance
    .collection('chats')
    .doc(roomId)
    .get();

// After:
final chatRoom = await _chatRepository.getChatRoomById(roomId);
''',
      ),
    ],
  );
}

/// Helper to check if code is using deprecated patterns
class DeprecationChecker {
  /// Check for deprecated StreamProvider usage
  static bool usesStreamProvider(String code) {
    return code.contains('StreamProvider<') ||
        code.contains('Provider.of<');
  }

  /// Check for print statements
  static bool usesPrint(String code) {
    return RegExp(r'\bprint\s*\(').hasMatch(code);
  }

  /// Check for direct Firestore access
  static bool usesDirectFirestore(String code) {
    return code.contains('FirebaseFirestore.instance') &&
        !code.contains('// Allowed:');
  }

  /// Check for legacy collection names
  static bool usesLegacyCollections(String code) {
    return code.contains("collection('Chats')") ||
        code.contains('collection("Chats")');
  }
}
