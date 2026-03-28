import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:kobac/services/api_client.dart';
import 'package:kobac/services/api_error_helpers.dart';

const String _base = 'api/messages';

// ==================== HELPERS ====================
int _parseId(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
String _str(dynamic v) => v == null ? '' : v.toString().trim();

dynamic _parseJson(String body) {
  try {
    return body.isNotEmpty ? jsonDecode(body) : null;
  } catch (_) {
    return null;
  }
}

String? _errorMessage(dynamic responseBody) {
  if (responseBody == null) return null;
  try {
    final m = responseBody is String ? jsonDecode(responseBody) : responseBody;
    if (m is Map && m['message'] != null) return m['message'] as String;
    if (m is Map && m['error'] != null) return m['error'] as String;
  } catch (_) {}
  return null;
}

// ==================== MODELS ====================

/// One conversation from GET /api/messages (conversations list).
class ConversationModel {
  final int userId;
  final String name;
  final String lastMessage;
  final String createdAt;
  final int unreadCount;

  ConversationModel({
    required this.userId,
    required this.name,
    required this.lastMessage,
    required this.createdAt,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final uid = _parseId(json['user_id'] ?? json['userId']);
    final name = _str(json['name'] ?? json['userName'] ?? json['user_name'] ?? 'Unknown');
    final msg = _str(json['lastMessage'] ?? json['last_message'] ?? json['message'] ?? '');
    final at = _str(json['created_at'] ?? json['createdAt'] ?? '');
    final unread = _parseId(json['unreadCount'] ?? json['unread_count'] ?? json['unread'] ?? 0);
    return ConversationModel(
      userId: uid, 
      name: name, 
      lastMessage: msg, 
      createdAt: at,
      unreadCount: unread,
    );
  }
}

/// User from GET /api/messages/users (start new conversation).
class MessageUserModel {
  final int id;
  final String name;
  final String role;

  MessageUserModel({required this.id, required this.name, required this.role});

  factory MessageUserModel.fromJson(Map<String, dynamic> json) {
    return MessageUserModel(
      id: _parseId(json['id'] ?? json['user_id'] ?? json['userId']),
      name: _str(json['name'] ?? json['userName'] ?? json['user_name'] ?? 'Unknown'),
      role: _str(json['role'] ?? json['user_role'] ?? json['userRole'] ?? ''),
    );
  }
}

/// One message from GET /api/messages/{user_id}.
class MessageModel {
  final int id;
  final int senderId;
  final int receiverId;
  final String message;
  final String createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: _parseId(json['id']),
      senderId: _parseId(json['sender_id'] ?? json['senderId']),
      receiverId: _parseId(json['receiver_id'] ?? json['receiverId']),
      message: _str(json['message'] ?? json['content'] ?? json['body'] ?? ''),
      createdAt: _str(json['created_at'] ?? json['createdAt'] ?? ''),
    );
  }
}

// ==================== RESULT TYPES ====================
sealed class MessageResult<T> {}
class MessageSuccess<T> extends MessageResult<T> {
  final T data;
  MessageSuccess(this.data);
}
class MessageError extends MessageResult<Never> {
  final String message;
  final int? statusCode;
  MessageError(this.message, [this.statusCode]);
}

// ==================== SERVICE ====================
final _client = ApiClient();

class MessageService {
  MessageService._();
  static final MessageService _instance = MessageService._();
  factory MessageService() => _instance;

  /// GET /api/messages — list conversations.
  /// Response: { "conversations": [ { "user_id", "name", "lastMessage", "created_at" } ] }
  Future<MessageResult<List<ConversationModel>>> getConversations() async {
    try {
      final response = await _client.get(apiUrl(_base));
      if (response.statusCode == 401) {
        return MessageError('Please sign in again.', 401);
      }
      if (response.statusCode != 200) {
        return MessageError(_errorMessage(response.body) ?? 'Could not load conversations.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      if (raw is! Map) return MessageError('Invalid response.');
      List<dynamic> list = raw['conversations'] is List ? raw['conversations'] as List<dynamic> : (raw['data'] is List ? raw['data'] as List<dynamic> : []);
      final items = list.whereType<Map<String, dynamic>>().map((e) => ConversationModel.fromJson(e)).toList();
      return MessageSuccess(items);
    } catch (e, st) {
      return MessageError(userFriendlyMessage(e, st, 'MessageService.getConversations'));
    }
  }

  /// GET /api/messages/{user_id} — messages with that user.
  /// Response: { "messages": [ { id, sender_id, receiver_id, message, created_at } ] }
  Future<MessageResult<List<MessageModel>>> getMessages(int userId) async {
    try {
      final response = await _client.get(apiUrl('$_base/$userId'));
      if (response.statusCode == 401) {
        return MessageError('Please sign in again.', 401);
      }
      if (response.statusCode == 404) {
        return MessageError('Conversation not found.', 404);
      }
      if (response.statusCode != 200) {
        return MessageError(_errorMessage(response.body) ?? 'Could not load messages.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      if (raw is! Map) return MessageError('Invalid response.');
      List<dynamic> list = raw['messages'] is List ? raw['messages'] as List<dynamic> : (raw['data'] is List ? raw['data'] as List<dynamic> : []);
      if (kDebugMode && list.isNotEmpty) {
        final first = list.first;
        if (first is Map) {
          final createdAt = first['created_at'] ?? first['createdAt'];
          debugPrint('[MessageService.getMessages] raw created_at from backend: $createdAt');
        }
      }
      final items = list.whereType<Map<String, dynamic>>().map((e) => MessageModel.fromJson(e)).toList();
      return MessageSuccess(items);
    } catch (e, st) {
      return MessageError(userFriendlyMessage(e, st, 'MessageService.getMessages'));
    }
  }

  /// GET /api/messages/users — list users (for starting new conversation).
  /// Response: { "users": [ { "id", "name", "role" } ] } or array at root
  Future<MessageResult<List<MessageUserModel>>> getUsers() async {
    try {
      final response = await _client.get(apiUrl('$_base/users'));
      if (response.statusCode == 401) {
        return MessageError('Please sign in again.', 401);
      }
      if (response.statusCode != 200) {
        return MessageError(_errorMessage(response.body) ?? 'Could not load users.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      List<dynamic> list = [];
      if (raw is List) {
        list = raw;
      } else if (raw is Map) {
        list = raw['users'] is List ? raw['users'] as List<dynamic> : (raw['data'] is List ? raw['data'] as List<dynamic> : []);
      }
      final items = list.whereType<Map<String, dynamic>>().map((e) => MessageUserModel.fromJson(e)).toList();
      return MessageSuccess(items);
    } catch (e, st) {
      return MessageError(userFriendlyMessage(e, st, 'MessageService.getUsers'));
    }
  }

  /// POST /api/messages — send a message.
  /// Body: { "receiver_id": 12, "message": "Hello" }
  Future<MessageResult<MessageModel>> sendMessage(int receiverId, String message) async {
    try {
      final body = <String, dynamic>{
        'receiver_id': receiverId,
        'message': message.trim(),
      };
      final response = await _client.post(apiUrl(_base), body: body);
      if (response.statusCode == 401) {
        return MessageError('Please sign in again.', 401);
      }
      if (response.statusCode == 404) {
        return MessageError('User not found.', 404);
      }
      if (response.statusCode != 200 && response.statusCode != 201) {
        return MessageError(_errorMessage(response.body) ?? 'Could not send message.', response.statusCode);
      }
      final raw = _parseJson(response.body);
      final map = raw is Map ? (raw['message'] ?? raw['data'] ?? raw) : null;
      if (map is! Map<String, dynamic>) return MessageError('Invalid response.');
      return MessageSuccess(MessageModel.fromJson(map));
    } catch (e, st) {
      return MessageError(userFriendlyMessage(e, st, 'MessageService.sendMessage'));
    }
  }
}
