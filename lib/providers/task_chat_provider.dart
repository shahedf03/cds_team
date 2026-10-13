import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/task_chat.dart';
import '../services/task_chat_service.dart';

/// One task's chat (2026-10-08 part C): loads the whole thread once, then
/// polls every ~4s with the last message's id while the screen is open —
/// the GET also marks whatever it returns as read, so this must stop
/// polling once the screen leaves.
class TaskChatProvider extends ChangeNotifier {
  TaskChatProvider({required TaskChatService service, required this.taskId})
    : _service = service;

  static const Duration _pollInterval = Duration(seconds: 4);

  final TaskChatService _service;
  final String taskId;

  final List<ChatMessage> _messages = <ChatMessage>[];
  bool _isOpen = true;
  DateTime? _closesAt;
  String _otherUserName = '';
  Timer? _timer;
  bool _loading = false;
  bool _sending = false;
  String? _error;

  List<ChatMessage> get messages => List<ChatMessage>.unmodifiable(_messages);
  bool get isOpen => _isOpen;
  DateTime? get closesAt => _closesAt;
  String get otherUserName => _otherUserName;
  bool get isLoading => _loading;
  bool get isSending => _sending;
  String? get error => _error;

  int get _lastId => _messages.isEmpty ? 0 : _messages.last.id;

  Future<void> start() async {
    await _refresh(afterId: 0);
    _timer ??= Timer.periodic(
      _pollInterval,
      (_) => _refresh(afterId: _lastId),
    );
  }

  Future<void> _refresh({required int afterId}) async {
    if (afterId == 0) {
      _loading = true;
      notifyListeners();
    }
    try {
      final ChatThread thread = await _service.load(taskId, afterId: afterId);
      if (afterId == 0) {
        _messages
          ..clear()
          ..addAll(thread.messages);
      } else if (thread.messages.isNotEmpty) {
        _messages.addAll(thread.messages);
      }
      _isOpen = thread.isOpen;
      _closesAt = thread.closesAt;
      if (thread.otherUserName.isNotEmpty) {
        _otherUserName = thread.otherUserName;
      }
      _error = null;
    } on ApiException catch (e) {
      if (afterId == 0) _error = e.message;
    } catch (e) {
      if (afterId == 0) _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// `null` on success, the API's error message otherwise (e.g. the chat
  /// just locked).
  Future<String?> send(String body) => _runSend(() => _service.send(taskId, body));

  Future<String?> sendFiles({
    required List<PendingChatFile> files,
    String? body,
    int? durationSeconds,
  }) => _runSend(
    () => _service.sendFiles(
      taskId,
      files: files,
      body: body,
      durationSeconds: durationSeconds,
    ),
  );

  Future<String?> _runSend(Future<ChatMessage> Function() call) async {
    _sending = true;
    notifyListeners();
    String? error;
    try {
      final ChatMessage sent = await call();
      _messages.add(sent);
    } on ApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      _sending = false;
      notifyListeners();
    }
    return error;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
