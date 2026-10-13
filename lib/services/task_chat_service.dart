import 'dart:typed_data';

import 'package:dio/dio.dart' show FormData, MultipartFile;

import '../core/network/api_client.dart';
import '../models/task_chat.dart';

/// 2026-10-08 part C — the chat between a task's creator and its assignee
/// (nobody else, not even their managers: 403). The database side is
/// already live.
class TaskChatService {
  TaskChatService(this._api);

  final ApiClient _api;

  /// `GET /api/tasks/{taskId}/chat?afterId=` — the whole thread state.
  /// `afterId=0` loads everything; poll with the last message's id after
  /// that. Also marks whatever it returns as read, so only call this while
  /// the chat is on screen.
  Future<ChatThread> load(String taskId, {int afterId = 0}) async {
    final dynamic body = await _api.get<dynamic>(
      '/api/tasks/$taskId/chat',
      query: <String, dynamic>{'afterId': afterId},
    );
    return ChatThread.fromJson(
      body is Map ? Map<String, dynamic>.from(body) : const <String, dynamic>{},
    );
  }

  /// `POST /api/tasks/{taskId}/chat` `{ "body": "…" }` (max 2000 chars) →
  /// the saved message. `400` once the chat has locked.
  Future<ChatMessage> send(String taskId, String body) async {
    final dynamic json = await _api.post<dynamic>(
      '/api/tasks/$taskId/chat',
      data: <String, dynamic>{'body': body},
    );
    return ChatMessage.fromJson(
      json is Map ? Map<String, dynamic>.from(json) : const <String, dynamic>{},
    );
  }

  /// `POST /api/tasks/{taskId}/chat/files` multipart (1-5 files, 100 MB
  /// together; `body` and `durationSeconds` — the latter for a voice
  /// message — are both optional) → the saved message.
  Future<ChatMessage> sendFiles(
    String taskId, {
    required List<PendingChatFile> files,
    String? body,
    int? durationSeconds,
  }) async {
    final FormData form = FormData();
    if (body != null && body.isNotEmpty) {
      form.fields.add(MapEntry<String, String>('body', body));
    }
    if (durationSeconds != null) {
      form.fields.add(
        MapEntry<String, String>('durationSeconds', '$durationSeconds'),
      );
    }
    for (final PendingChatFile file in files) {
      form.files.add(
        MapEntry<String, MultipartFile>(
          'files',
          MultipartFile.fromBytes(file.bytes, filename: file.fileName),
        ),
      );
    }
    final dynamic json = await _api.postFormData<dynamic>(
      '/api/tasks/$taskId/chat/files',
      form,
    );
    return ChatMessage.fromJson(
      json is Map ? Map<String, dynamic>.from(json) : const <String, dynamic>{},
    );
  }

  /// `GET /api/tasks/chat/files/{fileId}` — the raw file bytes.
  Future<Uint8List> fileBytes(String fileId) =>
      _api.getBytes('/api/tasks/chat/files/$fileId');

  /// `GET /api/tasks/chat/unread` → unread count per task id, only tasks
  /// that have any.
  Future<Map<String, int>> unreadCounts() async {
    final dynamic body = await _api.get<dynamic>('/api/tasks/chat/unread');
    if (body is! Map) return const <String, int>{};
    return body.map(
      (dynamic key, dynamic value) =>
          MapEntry<String, int>(key.toString(), (value as num).toInt()),
    );
  }
}

/// A file picked locally, waiting to be sent — kept as bytes (rather than a
/// [File]) so the caller doesn't care whether it came from the file picker,
/// the camera or a finished recording.
class PendingChatFile {
  const PendingChatFile({required this.fileName, required this.bytes});

  final String fileName;
  final Uint8List bytes;
}
