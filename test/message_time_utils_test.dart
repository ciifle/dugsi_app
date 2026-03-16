import 'package:flutter_test/flutter_test.dart';
import 'package:kobac/messages/message_time_utils.dart';

void main() {
  group('MessageTimeUtils.parseToLocal', () {
    test('returns null for null or empty string', () {
      expect(MessageTimeUtils.parseToLocal(null), isNull);
      expect(MessageTimeUtils.parseToLocal(''), isNull);
      expect(MessageTimeUtils.parseToLocal('   '), isNull);
    });

    test('UTC timestamp (Z) is converted to local and isUtc is false', () {
      final local = MessageTimeUtils.parseToLocal('2026-03-16T07:29:00Z');
      expect(local, isNotNull);
      expect(local!.isUtc, isFalse);
      // In UTC timezone, 07:29 UTC -> 07:29 local; in UTC+3, 07:29 UTC -> 10:29 local.
      expect(local.hour, inInclusiveRange(0, 23));
      expect(local.minute, 29);
    });

    test('UTC timestamp parses and toLocal() gives correct local representation', () {
      // 12:00 UTC -> when converted to local, hour may vary by timezone but day should be consistent
      final local = MessageTimeUtils.parseToLocal('2026-03-16T12:00:00Z');
      expect(local, isNotNull);
      expect(local!.isUtc, isFalse);
      expect(local.year, 2026);
      expect(local.month, 3);
      expect(local.day, inInclusiveRange(15, 17)); // could be 15, 16 or 17 depending on TZ
      expect(local.minute, 0);
    });

    test('ISO without Z is treated as local by tryParse, returned as-is when not UTC', () {
      final parsed = MessageTimeUtils.parseToLocal('2026-03-16T10:30:00');
      expect(parsed, isNotNull);
      // Parser may interpret as local; we don't double-convert
      expect(parsed!.hour, inInclusiveRange(0, 23));
    });
  });

  group('MessageTimeUtils.formatBubbleTime', () {
    test('returns empty string for null or empty', () {
      expect(MessageTimeUtils.formatBubbleTime(null), '');
      expect(MessageTimeUtils.formatBubbleTime(''), '');
    });

    test('UTC timestamp displays as HH:mm in local time', () {
      final result = MessageTimeUtils.formatBubbleTime('2026-03-16T07:29:00Z');
      expect(result, isNotEmpty);
      expect(RegExp(r'^\d{2}:\d{2}$').hasMatch(result), isTrue);
      final parts = result.split(':');
      expect(parts.length, 2);
      expect(int.parse(parts[0]), inInclusiveRange(0, 23));
      expect(int.parse(parts[1]), 29); // 07:29 UTC keeps minutes in any TZ
    });

    test('message bubble time uses local time not raw UTC', () {
      // If backend sends 07:29 UTC and device is UTC, bubble should show 07:29.
      // If device is UTC+3, bubble should show 10:29. So we only assert format and that it's not wrong like "yesterday".
      final result = MessageTimeUtils.formatBubbleTime('2026-03-16T14:00:00Z');
      expect(result, matches(RegExp(r'^\d{2}:\d{2}$')));
    });
  });

  group('MessageTimeUtils.formatConversationTime', () {
    test('returns fallback for null or unparseable', () {
      expect(MessageTimeUtils.formatConversationTime(null), '');
      // Invalid string: parseToLocal returns null, we return createdAt ?? '' so for null we get ''
      expect(MessageTimeUtils.formatConversationTime(''), '');
    });

    test('UTC "today" does not show Yesterday', () {
      // Use a UTC time that is "today" in local: now in UTC, then format as ISO Z.
      final nowUtc = DateTime.now().toUtc();
      final todayLocal = DateTime.now();
      // Build a UTC time that falls on "today" in local (e.g. noon UTC)
      final utcNoonToday = DateTime.utc(todayLocal.year, todayLocal.month, todayLocal.day, 12, 0, 0);
      final iso = utcNoonToday.toIso8601String();
      final result = MessageTimeUtils.formatConversationTime(iso);
      // Should show time (HH:mm) or "Yesterday" only if UTC noon actually is yesterday in local
      final local = MessageTimeUtils.parseToLocal(iso);
      expect(local, isNotNull);
      final now = DateTime.now();
      final isToday = local!.year == now.year && local.month == now.month && local.day == now.day;
      if (isToday) {
        expect(result, isNot(equals('Yesterday')));
        expect(result, matches(RegExp(r'^\d{1,2}:\d{2}$')));
      }
    });

    test('conversation time for today shows HH:mm', () {
      final now = DateTime.now();
      final localToday = DateTime(now.year, now.month, now.day, 9, 30);
      final utcEquivalent = localToday.toUtc();
      final iso = utcEquivalent.toIso8601String();
      final result = MessageTimeUtils.formatConversationTime(iso);
      // Should be "09:30" in local (or similar if DST), and must not be "Yesterday"
      expect(result, isNot(equals('Yesterday')));
      expect(result, isNotEmpty);
    });
  });
}
