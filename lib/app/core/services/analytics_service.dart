import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_device_context_service.dart';

/// Comprehensive analytics service for tracking user behavior and app usage
/// Inspired by Meta/Google Analytics architecture
class AnalyticsService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final AnalyticsDeviceContextService _deviceContext;

  // Session tracking
  String? _currentSessionId;
  DateTime? _sessionStartTime;
  final Map<String, dynamic> _sessionProperties = {};

  // Event buffer for batch processing
  final List<Map<String, dynamic>> _eventBuffer = [];
  static const int _bufferSize = 10;
  static const Duration _flushInterval = Duration(seconds: 30);

  // Privacy settings
  bool _deviceTrackingEnabled = true;
  bool _locationTrackingEnabled = false; // Opt-in by default

  @override
  void onInit() {
    super.onInit();
    _deviceContext = Get.put(AnalyticsDeviceContextService());
    _loadPrivacySettings();
    _startSession();
    _schedulePeriodicFlush();
  }

  // ============================================
  // SESSION MANAGEMENT
  // ============================================

  /// Start a new analytics session
  void _startSession() {
    _currentSessionId = _generateSessionId();
    _sessionStartTime = DateTime.now();
    _sessionProperties.clear();

    trackEvent('session_start', properties: {
      'session_id': _currentSessionId,
      'timestamp': _sessionStartTime!.toIso8601String(),
    }, includeLocation: true); // Always include location at session start
  }

  /// End the current session
  void endSession() {
    if (_currentSessionId == null || _sessionStartTime == null) return;

    final sessionDuration = DateTime.now().difference(_sessionStartTime!);

    trackEvent('session_end', properties: {
      'session_id': _currentSessionId,
      'duration_seconds': sessionDuration.inSeconds,
      'duration_minutes': sessionDuration.inMinutes,
    });

    _flushEvents();
    _currentSessionId = null;
    _sessionStartTime = null;
  }

  /// Generate a unique session ID
  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final userId = _auth.currentUser?.uid ?? 'anonymous';
    return '${userId}_$timestamp';
  }

  // ============================================
  // EVENT TRACKING
  // ============================================

  /// Track a custom event with optional properties
  Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic>? properties,
    bool immediate = false,
    bool includeLocation = false,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Get device context (with caching)
      final deviceContext = await _getDeviceContext();

      // Get location context if requested (with caching)
      final locationContext = includeLocation
          ? await _getLocationContext()
          : <String, dynamic>{};

      final event = {
        'event_name': eventName,
        'user_id': userId,
        'session_id': _currentSessionId,
        'timestamp': FieldValue.serverTimestamp(),
        'local_timestamp': DateTime.now().toIso8601String(),
        'properties': properties ?? {},
        'device': deviceContext,
        if (locationContext.isNotEmpty) 'location': locationContext,
      };

      if (immediate) {
        await _sendEvent(event);
      } else {
        _eventBuffer.add(event);
        if (_eventBuffer.length >= _bufferSize) {
          await _flushEvents();
        }
      }

      developer.log('📊 Analytics: $eventName', name: 'Analytics');
    } catch (e) {
      developer.log('❌ Analytics error: $e', name: 'Analytics');
    }
  }

  /// Get device context from service
  Future<Map<String, dynamic>> _getDeviceContext() async {
    try {
      return await _deviceContext.getDeviceContext();
    } catch (e) {
      developer.log('⚠️ Failed to get device context: $e', name: 'Analytics');
      return {};
    }
  }

  /// Get location context from service
  Future<Map<String, dynamic>> _getLocationContext() async {
    try {
      return await _deviceContext.getLocationContext();
    } catch (e) {
      developer.log('⚠️ Failed to get location context: $e', name: 'Analytics');
      return {};
    }
  }

  /// Send event to Firebase
  Future<void> _sendEvent(Map<String, dynamic> event) async {
    await _firestore.collection('analytics_events').add(event);
  }

  /// Flush buffered events to Firebase
  Future<void> _flushEvents() async {
    if (_eventBuffer.isEmpty) return;

    try {
      final batch = _firestore.batch();
      for (final event in _eventBuffer) {
        final docRef = _firestore.collection('analytics_events').doc();
        batch.set(docRef, event);
      }
      await batch.commit();
      _eventBuffer.clear();
      developer.log('✅ Flushed ${_eventBuffer.length} events', name: 'Analytics');
    } catch (e) {
      developer.log('❌ Failed to flush events: $e', name: 'Analytics');
    }
  }

  /// Schedule periodic event flushing
  void _schedulePeriodicFlush() {
    Future.delayed(_flushInterval, () {
      _flushEvents();
      _schedulePeriodicFlush();
    });
  }

  // ============================================
  // USER LIFECYCLE EVENTS
  // ============================================

  /// Track user signup
  Future<void> trackUserSignup({
    required String method,
    Map<String, dynamic>? additionalData,
  }) async {
    await trackEvent('user_signup', properties: {
      'method': method,
      ...?additionalData,
    }, immediate: true);
  }

  /// Track user login
  Future<void> trackUserLogin({
    required String method,
    Map<String, dynamic>? additionalData,
  }) async {
    await trackEvent('user_login', properties: {
      'method': method,
      ...?additionalData,
    }, immediate: true);
  }

  /// Track user logout
  Future<void> trackUserLogout() async {
    await trackEvent('user_logout', immediate: true);
    endSession();
  }

  // ============================================
  // MESSAGING EVENTS
  // ============================================

  /// Track message sent
  Future<void> trackMessageSent({
    required String messageType,
    required String chatId,
    bool isGroup = false,
    bool includeLocation = false,
  }) async {
    await trackEvent('message_sent', properties: {
      'message_type': messageType,
      'chat_id': chatId,
      'is_group': isGroup,
    }, includeLocation: includeLocation);

    // Update daily metrics
    await updateDailyMetrics(metricType: 'messages_sent');
  }

  /// Track message received
  Future<void> trackMessageReceived({
    required String messageType,
    required String chatId,
    bool isGroup = false,
  }) async {
    await trackEvent('message_received', properties: {
      'message_type': messageType,
      'chat_id': chatId,
      'is_group': isGroup,
    });

    // Update daily metrics
    await updateDailyMetrics(metricType: 'messages_received');
  }

  /// Track message read
  Future<void> trackMessageRead({
    required String messageId,
    required String chatId,
  }) async {
    await trackEvent('message_read', properties: {
      'message_id': messageId,
      'chat_id': chatId,
    });
  }

  /// Track message reaction
  Future<void> trackMessageReaction({
    required String messageId,
    required String emoji,
  }) async {
    await trackEvent('message_reaction', properties: {
      'message_id': messageId,
      'emoji': emoji,
    });
  }

  // ============================================
  // STORY EVENTS
  // ============================================

  /// Track story created
  Future<void> trackStoryCreated({
    required String storyType,
    bool hasLocation = false,
  }) async {
    await trackEvent('story_created', properties: {
      'story_type': storyType,
      'has_location': hasLocation,
    }, includeLocation: true); // Always include location for stories

    // Update daily metrics
    await updateDailyMetrics(metricType: 'stories_created');
  }

  /// Track story viewed
  Future<void> trackStoryViewed({
    required String storyId,
    required String authorId,
  }) async {
    await trackEvent('story_viewed', properties: {
      'story_id': storyId,
      'author_id': authorId,
    });

    // Update daily metrics
    await updateDailyMetrics(metricType: 'stories_viewed');
  }

  /// Track story interaction
  Future<void> trackStoryInteraction({
    required String storyId,
    required String interactionType, // 'reply', 'share', etc.
  }) async {
    await trackEvent('story_interaction', properties: {
      'story_id': storyId,
      'interaction_type': interactionType,
    });
  }

  // ============================================
  // CALL EVENTS
  // ============================================

  /// Track call initiated
  Future<void> trackCallInitiated({
    required String callType,
    required String calleeId,
    bool includeLocation = false,
  }) async {
    await trackEvent('call_initiated', properties: {
      'call_type': callType,
      'callee_id': calleeId,
    }, includeLocation: includeLocation);

    // Update daily metrics
    await updateDailyMetrics(metricType: 'calls_made');
  }

  /// Track call answered
  Future<void> trackCallAnswered({
    required String callId,
    required String callType,
  }) async {
    await trackEvent('call_answered', properties: {
      'call_id': callId,
      'call_type': callType,
    });
  }

  /// Track call ended
  Future<void> trackCallEnded({
    required String callId,
    required int durationSeconds,
    required String endReason,
  }) async {
    await trackEvent('call_ended', properties: {
      'call_id': callId,
      'duration_seconds': durationSeconds,
      'end_reason': endReason,
    });
  }

  // ============================================
  // FEATURE USAGE EVENTS
  // ============================================

  /// Track feature usage
  Future<void> trackFeatureUsage({
    required String featureName,
    Map<String, dynamic>? context,
  }) async {
    await trackEvent('feature_used', properties: {
      'feature_name': featureName,
      ...?context,
    });
  }

  /// Track screen view
  Future<void> trackScreenView({
    required String screenName,
    Map<String, dynamic>? context,
  }) async {
    await trackEvent('screen_view', properties: {
      'screen_name': screenName,
      ...?context,
    });
  }

  /// Track search performed
  Future<void> trackSearch({
    required String searchQuery,
    required String searchContext,
    int? resultsCount,
  }) async {
    await trackEvent('search_performed', properties: {
      'search_query': searchQuery,
      'search_context': searchContext,
      'results_count': resultsCount,
    });
  }

  // ============================================
  // ENGAGEMENT EVENTS
  // ============================================

  /// Track profile viewed
  Future<void> trackProfileViewed({
    required String profileUserId,
  }) async {
    await trackEvent('profile_viewed', properties: {
      'profile_user_id': profileUserId,
    });
  }

  /// Track settings changed
  Future<void> trackSettingsChanged({
    required String settingName,
    required dynamic newValue,
  }) async {
    await trackEvent('settings_changed', properties: {
      'setting_name': settingName,
      'new_value': newValue.toString(),
    });
  }

  /// Track share action
  Future<void> trackShare({
    required String contentType,
    required String contentId,
  }) async {
    await trackEvent('content_shared', properties: {
      'content_type': contentType,
      'content_id': contentId,
    });
  }

  // ============================================
  // USER PROPERTIES
  // ============================================

  /// Update user properties for analytics segmentation
  Future<void> updateUserProperties(Map<String, dynamic> properties) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('user_analytics_profiles')
          .doc(userId)
          .set({
        'user_id': userId,
        'properties': properties,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      developer.log('❌ Failed to update user properties: $e', name: 'Analytics');
    }
  }

  /// Track daily active user
  Future<void> trackDailyActive() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final today = DateTime.now().toIso8601String().split('T')[0];

    await _firestore
        .collection('daily_metrics')
        .doc('${today}_$userId')
        .set({
      'user_id': userId,
      'date': today,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ============================================
  // DAILY METRICS
  // ============================================

  /// Update daily metrics for pre-aggregation
  Future<void> updateDailyMetrics({
    required String metricType,
    int count = 1,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final today = DateTime.now().toIso8601String().split('T')[0];

      await _firestore
          .collection('daily_metrics')
          .doc('${today}_$userId')
          .set({
        'user_id': userId,
        'date': today,
        'timestamp': FieldValue.serverTimestamp(),
        '${metricType}_count': FieldValue.increment(count),
      }, SetOptions(merge: true));
    } catch (e) {
      developer.log('❌ Failed to update daily metrics: $e', name: 'Analytics');
    }
  }

  // ============================================
  // PRIVACY CONTROLS
  // ============================================

  /// Load privacy settings from SharedPreferences
  Future<void> _loadPrivacySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _deviceTrackingEnabled = prefs.getBool('analytics_device_tracking') ?? true;
      _locationTrackingEnabled = prefs.getBool('analytics_location_tracking') ?? false;

      // Update device context service
      _deviceContext.setDeviceTrackingEnabled(_deviceTrackingEnabled);
      _deviceContext.setLocationTrackingEnabled(_locationTrackingEnabled);
    } catch (e) {
      developer.log('⚠️ Failed to load privacy settings: $e', name: 'Analytics');
    }
  }

  /// Enable or disable device tracking
  Future<void> setDeviceTrackingEnabled(bool enabled) async {
    _deviceTrackingEnabled = enabled;
    _deviceContext.setDeviceTrackingEnabled(enabled);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('analytics_device_tracking', enabled);
    } catch (e) {
      developer.log('⚠️ Failed to save device tracking setting: $e', name: 'Analytics');
    }
  }

  /// Enable or disable location tracking
  Future<void> setLocationTrackingEnabled(bool enabled) async {
    // Request permission if enabling
    if (enabled) {
      final hasPermission = await _deviceContext.requestLocationPermission();
      if (!hasPermission) {
        developer.log('⚠️ Location permission denied', name: 'Analytics');
        return;
      }
    }

    _locationTrackingEnabled = enabled;
    _deviceContext.setLocationTrackingEnabled(enabled);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('analytics_location_tracking', enabled);
    } catch (e) {
      developer.log('⚠️ Failed to save location tracking setting: $e', name: 'Analytics');
    }
  }

  /// Check if device tracking is enabled
  bool get isDeviceTrackingEnabled => _deviceTrackingEnabled;

  /// Check if location tracking is enabled
  bool get isLocationTrackingEnabled => _locationTrackingEnabled;

  /// Get example of collected data (for privacy info display)
  Map<String, dynamic> getCollectedDataExample() {
    return _deviceContext.getCollectedDataExample();
  }

  @override
  void onClose() {
    endSession();
    super.onClose();
  }
}
