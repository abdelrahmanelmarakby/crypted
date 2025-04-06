import 'package:timeago/timeago.dart' as timeago;

mixin TimeAgoMixin {
  DateTime get time;

  String get timeAgo {
    return timeago.format(time.toLocal());
  }
}