import 'package:flutter/foundation.dart';

/// Centralized parsing and display of message timestamps.
/// Backend may send ISO UTC (e.g. "2026-03-16T07:29:00Z") or ISO without timezone.
/// All display uses local time to avoid "yesterday" / wrong clock for recent messages.
class MessageTimeUtils {
  MessageTimeUtils._();

  /// Parses [createdAt] (ISO string; backend often sends UTC with "Z") and returns local [DateTime], or null if invalid.
  /// Dart: tryParse("...Z") yields UTC; tryParse without timezone yields local. We convert UTC to local for display.
  static DateTime? parseToLocal(String? createdAt) {
    if (createdAt == null || createdAt.trim().isEmpty) return null;
    if (kDebugMode) debugPrint('[MessageTime] raw created_at: "$createdAt"');
    try {
      final dt = DateTime.tryParse(createdAt.trim());
      if (dt == null) return null;
      if (dt.isUtc) return dt.toLocal();
      return dt;
    } catch (_) {
      return null;
    }
  }

  /// Clock time for message bubble: "07:29" (local time).
  static String formatBubbleTime(String? createdAt) {
    final local = parseToLocal(createdAt);
    if (local == null) return '';
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  /// Conversation list: "10:00" today, "Yesterday", or "16/3" for older (day/month). All in local time.
  static String formatConversationTime(String? createdAt) {
    final local = parseToLocal(createdAt);
    if (local == null) return createdAt ?? '';
    final now = DateTime.now();
    if (local.year == now.year && local.month == now.month && local.day == now.day) {
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (local.year == yesterday.year && local.month == yesterday.month && local.day == yesterday.day) {
      return 'Yesterday';
    }
    return '${local.day}/${local.month}';
  }
}
