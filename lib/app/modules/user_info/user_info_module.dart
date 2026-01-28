/// User Info Module
///
/// Enterprise-grade module for viewing and managing user and group information.
/// Provides comprehensive features for:
/// - Other user profile viewing
/// - Group information management
/// - Media sharing statistics
/// - Privacy controls (block, report)
/// - Chat options (mute, favorite, archive)
library;

// Repositories
export 'repositories/user_info_repository.dart';
export 'repositories/group_info_repository.dart';

// Models
export 'models/user_info_state.dart';
export 'models/group_info_state.dart';

// Controllers
export 'controllers/other_user_info_controller.dart';
export 'controllers/enhanced_group_info_controller.dart';

// Bindings
export 'bindings/other_user_info_binding.dart';
export 'bindings/group_info_binding.dart';

// Views
export 'views/other_user_info_view.dart';
export 'views/group_info_view.dart';

// Widgets
export 'widgets/user_info_header.dart';
export 'widgets/user_info_section.dart';
export 'widgets/user_info_action_tile.dart';
