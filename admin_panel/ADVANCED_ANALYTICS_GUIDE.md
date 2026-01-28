# Advanced Analytics Implementation Guide

## Overview

This guide provides comprehensive documentation for the Meta/Google-level analytics system implemented for the Crypted messaging app. The system includes event tracking in the mobile app and advanced analytics dashboards in the admin panel.

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                     Mobile App (Flutter)                     │
│  ┌───────────────────────────────────────────────────────┐  │
│  │          AnalyticsService                              │  │
│  │  - Event Tracking                                      │  │
│  │  - Session Management                                  │  │
│  │  - User Properties                                     │  │
│  │  - Batching & Buffering                               │  │
│  └───────────────────────────────────────────────────────┘  │
│                          │                                   │
│                          ↓                                   │
└─────────────────────────────────────────────────────────────┘
                           │
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                   Firebase Firestore                         │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  - analytics_events                                    │  │
│  │  - user_sessions                                       │  │
│  │  - daily_metrics                                       │  │
│  │  - user_analytics_profiles                            │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                           │
                           ↓
┌─────────────────────────────────────────────────────────────┐
│              Admin Panel (React + TypeScript)                │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  advancedAnalyticsService                              │  │
│  │  - Dashboard Stats                                     │  │
│  │  - Retention Analysis                                  │  │
│  │  - User Behavior Metrics                              │  │
│  │  - Event Analytics                                     │  │
│  │  - Geographic Analytics                                │  │
│  │  - Time Series Data                                    │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  AdvancedAnalytics Component                           │  │
│  │  - Overview Dashboard                                  │  │
│  │  - Engagement Metrics                                  │  │
│  │  - Retention Analysis                                  │  │
│  │  - Event Analytics                                     │  │
│  │  - User Behavior                                       │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Mobile App Integration

### 1. Setup AnalyticsService

The `AnalyticsService` is located at:
```
lib/app/core/services/analytics_service.dart
```

#### Initialize in Main Bindings

Add to your initial bindings:

```dart
// In lib/core/services/bindings.dart or main.dart
class InitialBindings extends Bindings {
  @override
  void dependencies() {
    // ... other services
    Get.put(AnalyticsService(), permanent: true);
  }
}
```

### 2. Track Events in Your App

#### Session Tracking (Automatic)

Sessions are automatically tracked when the service initializes. To manually control:

```dart
final analytics = Get.find<AnalyticsService>();

// Start session (called automatically in onInit)
analytics._startSession();

// End session (called automatically in onClose)
analytics.endSession();
```

#### User Lifecycle Events

```dart
final analytics = Get.find<AnalyticsService>();

// On user signup
await analytics.trackUserSignup(
  method: 'email', // or 'google', 'facebook', etc.
  additionalData: {
    'referral_source': 'organic',
  },
);

// On user login
await analytics.trackUserLogin(
  method: 'email',
);

// On user logout
await analytics.trackUserLogout();
```

#### Messaging Events

```dart
// Message sent
await analytics.trackMessageSent(
  messageType: 'text', // 'image', 'video', 'audio', etc.
  chatId: chatRoomId,
  isGroup: true,
);

// Message received
await analytics.trackMessageReceived(
  messageType: 'text',
  chatId: chatRoomId,
  isGroup: false,
);

// Message read
await analytics.trackMessageRead(
  messageId: messageId,
  chatId: chatRoomId,
);

// Message reaction
await analytics.trackMessageReaction(
  messageId: messageId,
  emoji: '👍',
);
```

#### Story Events

```dart
// Story created
await analytics.trackStoryCreated(
  storyType: 'image', // 'video', 'text'
  hasLocation: true,
);

// Story viewed
await analytics.trackStoryViewed(
  storyId: storyId,
  authorId: authorUserId,
);

// Story interaction
await analytics.trackStoryInteraction(
  storyId: storyId,
  interactionType: 'reply', // 'share', 'react', etc.
);
```

#### Call Events

```dart
// Call initiated
await analytics.trackCallInitiated(
  callType: 'video', // 'audio'
  calleeId: calleeUserId,
);

// Call answered
await analytics.trackCallAnswered(
  callId: callId,
  callType: 'video',
);

// Call ended
await analytics.trackCallEnded(
  callId: callId,
  durationSeconds: 125,
  endReason: 'completed', // 'missed', 'canceled', 'failed'
);
```

#### Feature Usage & Navigation

```dart
// Track screen view
await analytics.trackScreenView(
  screenName: 'ChatScreen',
  context: {
    'chat_type': 'group',
    'member_count': 5,
  },
);

// Track feature usage
await analytics.trackFeatureUsage(
  featureName: 'voice_message',
  context: {
    'duration_seconds': 10,
  },
);

// Track search
await analytics.trackSearch(
  searchQuery: 'john',
  searchContext: 'users', // 'messages', 'chats', etc.
  resultsCount: 5,
);
```

#### Engagement Events

```dart
// Profile viewed
await analytics.trackProfileViewed(
  profileUserId: userId,
);

// Settings changed
await analytics.trackSettingsChanged(
  settingName: 'notification_sound',
  newValue: 'chime',
);

// Content shared
await analytics.trackShare(
  contentType: 'story',
  contentId: storyId,
);
```

#### User Properties

Update user properties for segmentation:

```dart
await analytics.updateUserProperties({
  'user_type': 'premium',
  'language': 'en',
  'notification_enabled': true,
  'theme': 'dark',
});
```

#### Daily Active User Tracking

Track daily active users:

```dart
// Call this once per day (e.g., in app initialization)
await analytics.trackDailyActive();
```

### 3. Integration Examples

#### Example 1: Chat Controller

```dart
class ChatController extends GetxController {
  final AnalyticsService _analytics = Get.find<AnalyticsService>();

  @override
  void onInit() {
    super.onInit();
    _analytics.trackScreenView(
      screenName: 'ChatScreen',
      context: {'chat_id': chatRoom.id},
    );
  }

  Future<void> sendMessage(String text) async {
    // ... send message logic

    await _analytics.trackMessageSent(
      messageType: 'text',
      chatId: chatRoom.id,
      isGroup: chatRoom.isGroupChat ?? false,
    );
  }

  Future<void> addReaction(String messageId, String emoji) async {
    // ... add reaction logic

    await _analytics.trackMessageReaction(
      messageId: messageId,
      emoji: emoji,
    );
  }
}
```

#### Example 2: Stories Controller

```dart
class StoriesController extends GetxController {
  final AnalyticsService _analytics = Get.find<AnalyticsService>();

  Future<void> createStory(StoryModel story) async {
    // ... create story logic

    await _analytics.trackStoryCreated(
      storyType: story.storyType?.name ?? 'image',
      hasLocation: story.hasLocation,
    );
  }

  Future<void> viewStory(StoryModel story) async {
    // ... view story logic

    await _analytics.trackStoryViewed(
      storyId: story.id!,
      authorId: story.uid!,
    );
  }
}
```

#### Example 3: Auth Controller

```dart
class AuthController extends GetxController {
  final AnalyticsService _analytics = Get.find<AnalyticsService>();

  Future<void> signup(String email, String password) async {
    // ... signup logic

    await _analytics.trackUserSignup(
      method: 'email',
      additionalData: {
        'signup_date': DateTime.now().toIso8601String(),
      },
    );

    // Update user properties
    await _analytics.updateUserProperties({
      'signup_method': 'email',
      'account_type': 'free',
    });
  }

  Future<void> login(String email, String password) async {
    // ... login logic

    await _analytics.trackUserLogin(method: 'email');
    await _analytics.trackDailyActive();
  }
}
```

## Firebase Collections Structure

### analytics_events
```javascript
{
  event_name: string,
  user_id: string,
  session_id: string,
  timestamp: Timestamp,
  local_timestamp: string,
  properties: {
    // Event-specific properties
  },
  platform: 'android' | 'ios',
  app_version: string,
}
```

### user_sessions
```javascript
{
  session_id: string,
  user_id: string,
  start_time: Timestamp,
  end_time: Timestamp,
  duration_seconds: number,
  events_count: number,
  platform: string,
  device_info: object,
}
```

### daily_metrics
```javascript
{
  date: string, // YYYY-MM-DD
  user_id: string,
  timestamp: Timestamp,
  sessions_count: number,
  total_session_duration: number,
  messages_sent: number,
  messages_received: number,
  stories_created: number,
  stories_viewed: number,
  calls_made: number,
  calls_received: number,
}
```

### user_analytics_profiles
```javascript
{
  user_id: string,
  properties: {
    // User properties for segmentation
  },
  updated_at: Timestamp,
}
```

## Admin Panel Usage

### Access Advanced Analytics

Navigate to: `http://your-admin-panel.com/analytics`

### Dashboard Tabs

#### 1. Overview Tab
- **Key Metrics**: DAU, WAU, MAU, Stickiness
- **Growth Metrics**: User growth rate, new users
- **Trend Analysis**: Customizable time series charts
- **Content Metrics**: Messages, stories, calls breakdown

**Key Insights:**
- **Stickiness (DAU/MAU)**: Measures user engagement. Good: >20%, Excellent: >40%
- **User Growth Rate**: Month-over-month user acquisition
- **Session Metrics**: Average session duration and sessions per user

#### 2. Engagement Tab
- **Engagement Breakdown**: Visual representation of feature usage
- **Session Metrics**: Detailed session analysis
- **Per-user Averages**: Messages, stories, calls per user

#### 3. Retention Tab
- **Retention Rates**: Day 1, 7, and 30 retention
- **Cohort Analysis**: Retention by signup cohort
- **Retention Table**: Detailed cohort performance

**Interpreting Retention:**
- **Day 1**: >40% is great, 30-40% is good
- **Day 7**: >20% is great, 15-20% is good
- **Day 30**: >10% is great, 5-10% is fair

#### 4. Events Tab
- **Top Events**: Most frequent user actions
- **Event Metrics**: Total count, unique users, avg per user
- **Event Trends**: Coming soon

#### 5. User Behavior Tab
- **User Segments**: Power users, active, casual, at-risk, dormant
- **User Journeys**: Coming soon

### Time Range Selection

Use the dropdown to select:
- Last 7 days
- Last 30 days
- Last 90 days
- Last year

### Export Data

Click the "Export" button to download analytics data (coming soon).

## Advanced Analytics Service API

### getAdvancedDashboardStats()
Returns comprehensive dashboard statistics including all metrics.

```typescript
const stats = await getAdvancedDashboardStats();
console.log(stats.dau, stats.mau, stats.stickiness);
```

### getRetentionData(startDate, endDate)
Returns retention data for cohort analysis.

```typescript
const retention = await getRetentionData(
  new Date('2024-01-01'),
  new Date('2024-12-31')
);
```

### getUserBehaviorMetrics(userId)
Returns detailed behavior metrics for a specific user.

```typescript
const metrics = await getUserBehaviorMetrics('user_id_123');
console.log(metrics.engagement_score, metrics.user_segment);
```

### getGeoAnalytics()
Returns geographic distribution of users and content.

```typescript
const geoData = await getGeoAnalytics();
```

### getEventAnalytics(startDate, endDate)
Returns aggregated event analytics.

```typescript
const events = await getEventAnalytics(
  startDate,
  endDate
);
```

### getTimeSeriesData(metric, days)
Returns time series data for charting.

```typescript
const data = await getTimeSeriesData('users', 30);
```

## Performance Considerations

### Mobile App

1. **Event Buffering**: Events are buffered and sent in batches of 10
2. **Automatic Flushing**: Events are flushed every 30 seconds
3. **Immediate Events**: Critical events (signup, login) are sent immediately
4. **Error Handling**: Failed events are logged but don't block app functionality

### Admin Panel

1. **Query Optimization**: Use appropriate indexes in Firestore
2. **Data Caching**: Consider implementing caching for frequently accessed data
3. **Pagination**: Implement pagination for large datasets
4. **Real-time Updates**: Use Firestore listeners for real-time metrics

## Firestore Security Rules

Add these rules to your `firestore.rules`:

```javascript
// Analytics collections
match /analytics_events/{eventId} {
  allow read, write: if request.auth != null;
}

match /user_sessions/{sessionId} {
  allow read, write: if request.auth != null;
}

match /daily_metrics/{metricId} {
  allow read, write: if request.auth != null;
}

match /user_analytics_profiles/{userId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null && request.auth.uid == userId;
}
```

## Firestore Indexes

Create composite indexes for optimal query performance:

```
Collection: analytics_events
- user_id (Ascending) + timestamp (Descending)
- event_name (Ascending) + timestamp (Descending)
- session_id (Ascending) + timestamp (Descending)

Collection: user_sessions
- user_id (Ascending) + start_time (Descending)

Collection: daily_metrics
- user_id (Ascending) + date (Descending)
- date (Ascending)
```

## Future Enhancements

### Planned Features

1. **Real-time Dashboard**: Live user count, active sessions
2. **Funnel Analysis**: Track user conversion through defined paths
3. **A/B Testing**: Experiment framework for feature testing
4. **Custom Reports**: User-defined reports and exports
5. **Automated Insights**: AI-powered insights and anomaly detection
6. **Push Notification Analytics**: Track notification performance
7. **Revenue Analytics**: If implementing monetization
8. **Crash Analytics Integration**: Link crashes to user journeys
9. **User Feedback Correlation**: Connect analytics to user feedback
10. **Predictive Analytics**: Churn prediction, LTV estimation

### Advanced Segmentation

Implement user segments based on:
- Engagement score
- Feature usage patterns
- Geographic location
- Device type
- Acquisition channel
- Behavioral patterns

### Data Warehouse Integration

For large-scale analytics:
1. Export data to BigQuery or similar
2. Implement ETL pipelines
3. Create advanced data models
4. Build custom dashboards with BI tools

## Troubleshooting

### No Events Appearing in Admin Panel

1. Check if AnalyticsService is initialized in the mobile app
2. Verify Firebase credentials and project ID
3. Check Firestore security rules
4. Look for errors in mobile app logs

### Incorrect Metrics

1. Verify time zones are consistent
2. Check if daily_metrics collection is being populated
3. Ensure user's lastSeen field is being updated
4. Verify createdAt timestamps on documents

### Performance Issues

1. Add appropriate Firestore indexes
2. Implement data pagination
3. Cache frequently accessed data
4. Consider pre-aggregating metrics

## Best Practices

### Mobile App

1. **Track Important Events**: Focus on events that matter for your business
2. **Add Context**: Include relevant properties with events
3. **Don't Over-track**: Avoid tracking every single user action
4. **Test Thoroughly**: Ensure events are firing correctly
5. **Handle Errors**: Don't let analytics failures affect app functionality

### Admin Panel

1. **Regular Review**: Check analytics daily/weekly
2. **Set Benchmarks**: Establish KPI targets
3. **Monitor Trends**: Look for patterns and anomalies
4. **Act on Insights**: Use data to drive decisions
5. **Share Insights**: Communicate findings with the team

## Metrics Glossary

- **DAU**: Daily Active Users - users active in the last 24 hours
- **WAU**: Weekly Active Users - users active in the last 7 days
- **MAU**: Monthly Active Users - users active in the last 30 days
- **Stickiness**: DAU/MAU ratio - measures user engagement
- **Retention**: Percentage of users who return after signup
- **Cohort**: Group of users who signed up in the same time period
- **Engagement Score**: Calculated score (0-100) based on user activity
- **User Segment**: Classification of users by engagement level

## Support

For questions or issues:
1. Check this guide
2. Review code comments in AnalyticsService
3. Check Firebase console for data
4. Review admin panel logs

## Changelog

### Version 1.0.0 (2024-01-27)
- Initial implementation
- Event tracking system
- Advanced dashboard
- Retention analysis
- User behavior metrics
- Event analytics
- Time series data

---

**Note**: This is a comprehensive analytics system designed for growth and scalability. Start with basic metrics and gradually add more advanced features as your app grows.
